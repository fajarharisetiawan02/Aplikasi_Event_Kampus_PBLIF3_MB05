<?php

namespace Tests\Feature;

use App\Mail\PanitiaUndangan;
use App\Models\Event;
use App\Models\Panitia;
use App\Models\PengajuanPenyelenggara;
use App\Models\Registration;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PengajuanPenyelenggaraTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $email, array $extra = []): User
    {
        return User::unguarded(fn () => User::create(array_merge([
            'nama' => 'Tes ' . $email,
            'email' => $email,
            'password' => 'rahasia123',
            'roles' => ['user'],
            'is_admin' => false,
        ], $extra)));
    }

    private function admin(): User
    {
        return User::where('email', 'admin@tes.test')->first()
            ?? $this->user('admin@tes.test', ['is_admin' => true]);
    }

    private function event(User $eo, array $extra = []): Event
    {
        $e = new Event(array_merge([
            'judul' => 'Seminar Contoh',
            'deskripsi' => 'Deskripsi.',
            'kategori' => 'Seminar',
            'tanggal' => now()->addDays(30)->toDateString(),
            'waktu' => '09.00 WIB',
            'lokasi' => 'Aula',
            'harga' => 0,
            'kuota' => 50,
            'status' => 'published',
        ], $extra));
        $e->organizer_id = $eo->id;
        $e->save();

        return $e;
    }

    private function tiket(User $peserta, Event $event, string $status = 'lunas', string $kode = 'EVT-AAAA1111'): Registration
    {
        return Registration::create([
            'user_id' => $peserta->id, 'event_id' => $event->id, 'kode' => $kode,
            'jumlah' => 1, 'total_harga' => 0, 'metode' => 'gratis', 'status' => $status,
        ]);
    }

    private function data(array $extra = []): array
    {
        return array_merge(['organisasi' => 'HIMA Informatika', 'jabatan' => 'Ketua'], $extra);
    }

    private function ajukan(User $mhs, array $extra = []): PengajuanPenyelenggara
    {
        $this->actingAs($mhs, 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data($extra))->assertCreated();

        return PengajuanPenyelenggara::latest('id')->firstOrFail();
    }

    // ===== mengajukan =====

    public function test_mahasiswa_bisa_mengajukan_dan_statusnya_tampil_di_profil(): void
    {
        $mhs = $this->user('mhs@tes.test');

        $this->actingAs($mhs, 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data(['bukti_url' => 'http://x.test/b.png']))
            ->assertCreated()
            ->assertJsonPath('data.status', 'menunggu')
            ->assertJsonPath('data.organisasi', 'HIMA Informatika');

        $this->actingAs($mhs, 'sanctum')->getJson('/api/profile')
            ->assertOk()
            ->assertJsonPath('data.pengajuan_penyelenggara.status', 'menunggu')
            ->assertJsonPath('data.pengajuan_penyelenggara.jabatan', 'Ketua');
    }

    public function test_pengajuan_divalidasi(): void
    {
        $this->actingAs($this->user('mhs@tes.test'), 'sanctum')
            ->postJson('/api/pengajuan-penyelenggara', ['organisasi' => 'ab', 'jabatan' => ''])
            ->assertStatus(422)->assertJsonValidationErrors(['organisasi', 'jabatan']);
    }

    public function test_tidak_bisa_mengajukan_dua_kali_selagi_menunggu(): void
    {
        $mhs = $this->user('mhs@tes.test');
        $this->ajukan($mhs);

        $this->actingAs($mhs, 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data())->assertStatus(422);
        $this->assertSame(1, PengajuanPenyelenggara::count());
    }

    public function test_tidak_bisa_mengajukan_kalau_punya_tiket_aktif_untuk_event_yang_belum_selesai(): void
    {
        $eo = $this->user('eo@tes.test', ['roles' => ['user', 'event_organizer']]);
        $mhs = $this->user('mhs@tes.test');
        $this->tiket($mhs, $this->event($eo, ['judul' => 'Seminar AI']));

        $this->actingAs($mhs, 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data())
            ->assertStatus(422)
            ->assertJsonPath('message', fn ($m) => str_contains($m, 'Seminar AI'));

        $this->assertSame(0, PengajuanPenyelenggara::count());
    }

    public function test_tiket_yang_sudah_lewat_atau_dibatalkan_tidak_menghalangi(): void
    {
        $eo = $this->user('eo@tes.test', ['roles' => ['user', 'event_organizer']]);
        $mhs = $this->user('mhs@tes.test');
        $lewat = $this->event($eo, ['judul' => 'Lama', 'tanggal' => now()->subDays(5)->toDateString()]);
        $depan = $this->event($eo, ['judul' => 'Depan']);
        $this->tiket($mhs, $lewat, 'hadir', 'EVT-LAMA0001');
        $this->tiket($mhs, $depan, 'dibatalkan', 'EVT-BATAL001');

        $this->actingAs($mhs, 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data())->assertCreated();
    }

    public function test_penyelenggara_dan_admin_tidak_perlu_mengajukan(): void
    {
        $eo = $this->user('eo@tes.test', ['roles' => ['user', 'event_organizer']]);

        $this->actingAs($eo, 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data())->assertStatus(422);
        $this->actingAs($this->admin(), 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data())->assertStatus(422);
    }

    public function test_unggah_bukti_gambar(): void
    {
        Storage::fake('public');
        $mhs = $this->user('mhs@tes.test');

        $this->actingAs($mhs, 'sanctum')
            ->post('/api/pengajuan-penyelenggara/bukti', ['bukti' => UploadedFile::fake()->image('sk.png')], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonStructure(['data' => ['bukti_url']]);

        $this->actingAs($mhs, 'sanctum')
            ->post('/api/pengajuan-penyelenggara/bukti', ['bukti' => UploadedFile::fake()->create('sk.pdf', 10, 'application/pdf')], ['Accept' => 'application/json'])
            ->assertStatus(422);
    }

    // ===== keputusan admin =====

    public function test_hanya_admin_yang_bisa_melihat_dan_memutuskan(): void
    {
        $mhs = $this->user('mhs@tes.test');
        $p = $this->ajukan($mhs);
        $lain = $this->user('lain@tes.test');

        $this->actingAs($lain, 'sanctum')->getJson('/api/pengajuan-penyelenggara')->assertForbidden();
        $this->actingAs($lain, 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/setujui")->assertForbidden();
        $this->actingAs($lain, 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/tolak", ['alasan' => 'tidak'])->assertForbidden();
        $this->actingAs($lain, 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/cabut", ['alasan' => 'tidak'])->assertForbidden();
    }

    public function test_admin_melihat_daftar_dengan_data_pemohon_dan_filter_status(): void
    {
        $this->ajukan($this->user('a@tes.test'));
        $b = $this->ajukan($this->user('b@tes.test'));
        $b->forceFill(['status' => 'ditolak'])->save();

        $admin = $this->admin();
        $this->actingAs($admin, 'sanctum')->getJson('/api/pengajuan-penyelenggara')->assertOk()->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.pemohon.email', 'b@tes.test');
        $this->actingAs($admin, 'sanctum')->getJson('/api/pengajuan-penyelenggara?status=menunggu')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_setujui_memberi_role_penyelenggara_dan_tidak_bisa_dua_kali(): void
    {
        $mhs = $this->user('mhs@tes.test');
        $p = $this->ajukan($mhs);
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/setujui")
            ->assertOk()->assertJsonPath('data.status', 'disetujui');

        $this->assertContains('event_organizer', $mhs->fresh()->roles);
        $this->assertContains('user', $mhs->fresh()->roles);

        $this->actingAs($admin, 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/setujui")->assertStatus(422);
    }

    public function test_setujui_ditolak_kalau_setelah_mengajukan_pemohon_membeli_tiket(): void
    {
        $eo = $this->user('eo@tes.test', ['roles' => ['user', 'event_organizer']]);
        $mhs = $this->user('mhs@tes.test');
        $p = $this->ajukan($mhs);
        $this->tiket($mhs, $this->event($eo, ['judul' => 'Seminar AI']));

        $this->actingAs($this->admin(), 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/setujui")
            ->assertStatus(422)
            ->assertJsonPath('message', fn ($m) => str_contains($m, 'Seminar AI'));

        $this->assertNotContains('event_organizer', $mhs->fresh()->roles);
        $this->assertSame('menunggu', $p->fresh()->status);
    }

    public function test_tolak_butuh_alasan_dan_pemohon_bisa_mengajukan_lagi(): void
    {
        $mhs = $this->user('mhs@tes.test');
        $p = $this->ajukan($mhs);
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/tolak", [])->assertStatus(422);
        $this->actingAs($admin, 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/tolak", ['alasan' => 'Bukti kurang jelas'])
            ->assertOk()->assertJsonPath('data.status', 'ditolak');

        $this->actingAs($mhs, 'sanctum')->getJson('/api/profile')
            ->assertJsonPath('data.pengajuan_penyelenggara.status', 'ditolak')
            ->assertJsonPath('data.pengajuan_penyelenggara.alasan', 'Bukti kurang jelas');

        $this->actingAs($mhs, 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data())->assertCreated();
    }

    // ===== cabut =====

    private function penyelenggaraDisetujui(string $email = 'eo@tes.test'): User
    {
        $u = $this->user($email);
        $p = $this->ajukan($u);
        $this->actingAs($this->admin(), 'sanctum')
            ->putJson("/api/pengajuan-penyelenggara/{$p->id}/setujui")->assertOk();

        return $u->fresh();
    }

    public function test_cabut_mengembalikan_akun_menjadi_mahasiswa_biasa(): void
    {
        $eo = $this->penyelenggaraDisetujui();
        $p = PengajuanPenyelenggara::firstOrFail();

        $this->actingAs($this->admin(), 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/cabut", [])->assertStatus(422);
        $this->actingAs($this->admin(), 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/cabut", ['alasan' => 'Organisasi bubar'])
            ->assertOk()->assertJsonPath('data.status', 'dicabut');

        $this->assertSame(['user'], $eo->fresh()->roles);
        $this->actingAs($eo->fresh(), 'sanctum')->getJson('/api/my-events')->assertForbidden();
    }

    public function test_cabut_hanya_untuk_yang_sudah_disetujui(): void
    {
        $p = $this->ajukan($this->user('mhs@tes.test'));

        $this->actingAs($this->admin(), 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/cabut", ['alasan' => 'tes'])->assertStatus(422);
    }

    public function test_cabut_menonaktifkan_panitia_dari_event_penyelenggara(): void
    {
        Mail::fake();
        $eo = $this->penyelenggaraDisetujui();
        $event = $this->event($eo);

        $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$event->id}/panitia", [
            'nama' => 'Budi Panitia', 'email' => 'budi@tes.test', 'no_hp' => '081234567890',
        ])->assertCreated();
        $password = null;
        Mail::assertSent(PanitiaUndangan::class, function ($m) use (&$password) {
            $password = $m->password;

            return true;
        });
        $panitia = Panitia::firstOrFail();
        $panitia->forceFill(['aktif_at' => now()])->save();
        $token = $this->postJson('/api/login', ['email' => 'budi@tes.test', 'password' => $password])->assertOk()->json('data.token');

        $p = PengajuanPenyelenggara::firstOrFail();
        $this->app['auth']->forgetGuards();
        $this->actingAs($this->admin(), 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/cabut", ['alasan' => 'Organisasi bubar'])->assertOk();

        $this->assertNotNull($panitia->fresh()->nonaktif_at);
        $this->assertSame(0, $panitia->user->tokens()->count());
        $this->postJson('/api/login', ['email' => 'budi@tes.test', 'password' => $password])->assertForbidden();

        $this->app['auth']->forgetGuards();
        $this->actingAs($panitia->user->fresh(), 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-AAAA1111'])->assertForbidden();
        $this->assertNotEmpty($token);
    }

    public function test_setelah_dicabut_bisa_mengajukan_lagi(): void
    {
        $eo = $this->penyelenggaraDisetujui();
        $p = PengajuanPenyelenggara::firstOrFail();
        $this->actingAs($this->admin(), 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/cabut", ['alasan' => 'tes'])->assertOk();

        $this->actingAs($eo->fresh(), 'sanctum')->postJson('/api/pengajuan-penyelenggara', $this->data())->assertCreated();
    }

    // ===== penyelenggara dan panitia tidak jadi peserta =====

    public function test_penyelenggara_tidak_bisa_mendaftar_event_termasuk_milik_sendiri(): void
    {
        $eo = $this->penyelenggaraDisetujui();
        $milikSendiri = $this->event($eo);
        $milikLain = $this->event($this->user('lain@tes.test', ['roles' => ['user', 'event_organizer']]));

        $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$milikSendiri->id}/register")->assertForbidden();
        $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$milikLain->id}/register")->assertForbidden();
        $this->assertSame(0, Registration::count());
    }

    public function test_mahasiswa_biasa_tetap_bisa_mendaftar_event(): void
    {
        $event = $this->event($this->user('eo@tes.test', ['roles' => ['user', 'event_organizer']]));

        $this->actingAs($this->user('mhs@tes.test'), 'sanctum')->postJson("/api/events/{$event->id}/register")->assertCreated();
    }

    public function test_setelah_dicabut_akun_bisa_mendaftar_event_lagi(): void
    {
        $eo = $this->penyelenggaraDisetujui();
        $p = PengajuanPenyelenggara::firstOrFail();
        $this->actingAs($this->admin(), 'sanctum')->putJson("/api/pengajuan-penyelenggara/{$p->id}/cabut", ['alasan' => 'tes'])->assertOk();
        $event = $this->event($this->user('lain@tes.test', ['roles' => ['user', 'event_organizer']]));

        $this->actingAs($eo->fresh(), 'sanctum')->postJson("/api/events/{$event->id}/register")->assertCreated();
    }
}
