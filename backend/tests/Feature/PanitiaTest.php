<?php

namespace Tests\Feature;

use App\Mail\PanitiaUndangan;
use App\Models\Event;
use App\Models\Panitia;
use App\Models\Registration;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PanitiaTest extends TestCase
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

    private function eo(string $email = 'eo@tes.test'): User
    {
        return $this->user($email, ['roles' => ['user', 'event_organizer']]);
    }

    private function event(User $eo, array $extra = []): Event
    {
        $e = new Event(array_merge([
            'judul' => 'Seminar Contoh',
            'deskripsi' => 'Deskripsi.',
            'kategori' => 'Seminar',
            'tanggal' => '2026-12-20',
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

    private function data(array $extra = []): array
    {
        return array_merge(['nama' => 'Budi Panitia', 'email' => 'budi@tes.test', 'no_hp' => '081234567890'], $extra);
    }

    private function tambah(User $eo, Event $event, array $extra = []): Panitia
    {
        Mail::fake();
        $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$event->id}/panitia", $this->data($extra))->assertCreated();

        return Panitia::firstOrFail();
    }

    // Password awal dari email yang terkirim.
    private function passwordDariEmail(): string
    {
        $password = null;
        Mail::assertSent(PanitiaUndangan::class, function ($m) use (&$password) {
            $password = $m->password;

            return true;
        });

        return $password;
    }

    private function tiket(Event $event, string $status, string $kode = 'EVT-AAAA1111'): Registration
    {
        $peserta = $this->user('peserta' . $kode . '@tes.test');

        return Registration::create([
            'user_id' => $peserta->id, 'event_id' => $event->id, 'kode' => $kode,
            'jumlah' => 1, 'total_harga' => 0, 'metode' => 'gratis', 'status' => $status,
        ]);
    }

    public function test_penyelenggara_menambah_panitia_dan_email_undangan_terkirim(): void
    {
        Mail::fake();
        $eo = $this->eo();
        $event = $this->event($eo);

        $res = $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$event->id}/panitia", $this->data());

        $res->assertCreated()
            ->assertJsonPath('email_terkirim', true)
            ->assertJsonPath('data.status', 'menunggu');

        $user = User::where('email', 'budi@tes.test')->first();
        $this->assertSame(['panitia'], $user->roles);
        $this->assertFalse($user->is_admin);
        $this->assertDatabaseHas('panitia', ['user_id' => $user->id, 'event_id' => $event->id, 'dibuat_oleh' => $eo->id]);

        Mail::assertSent(PanitiaUndangan::class, fn ($m) => $m->hasTo('budi@tes.test') && strlen($m->password) === 10);
    }

    public function test_password_acak_dari_email_dipakai_login_dan_menandai_wajib_ganti(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->tambah($eo, $event);
        $password = $this->passwordDariEmail();

        $this->postJson('/api/login', ['email' => 'budi@tes.test', 'password' => 'salah123'])->assertStatus(401);

        $this->postJson('/api/login', ['email' => 'budi@tes.test', 'password' => $password])
            ->assertOk()
            ->assertJsonPath('data.roles.0', 'panitia')
            ->assertJsonPath('data.wajib_ganti_password', true)
            ->assertJsonPath('data.panitia_event.id', $event->id);
    }

    public function test_password_acak_berbeda_tiap_panitia(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->tambah($eo, $event);
        $satu = $this->passwordDariEmail();

        Mail::fake();
        $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$event->id}/panitia", $this->data(['email' => 'dua@tes.test']))->assertCreated();
        $dua = $this->passwordDariEmail();

        $this->assertNotSame($satu, $dua);
    }

    public function test_email_yang_sudah_terdaftar_ditolak(): void
    {
        Mail::fake();
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->user('budi@tes.test');

        $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$event->id}/panitia", $this->data())
            ->assertStatus(422)->assertJsonValidationErrors('email');
    }

    public function test_validasi_data_panitia(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);

        $this->actingAs($eo, 'sanctum')
            ->postJson("/api/events/{$event->id}/panitia", ['nama' => 'Bu', 'email' => 'salah', 'no_hp' => 'abc'])
            ->assertStatus(422)->assertJsonValidationErrors(['nama', 'email', 'no_hp']);
    }

    public function test_penyelenggara_lain_tidak_bisa_menambah_panitia_ke_event_orang(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $lain = $this->eo('lain@tes.test');

        $this->actingAs($lain, 'sanctum')->postJson("/api/events/{$event->id}/panitia", $this->data())->assertForbidden();
        $this->actingAs($lain, 'sanctum')->getJson("/api/events/{$event->id}/panitia")->assertForbidden();
    }

    public function test_mahasiswa_biasa_tidak_bisa_menambah_panitia(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);

        $this->actingAs($this->user('mhs@tes.test'), 'sanctum')
            ->postJson("/api/events/{$event->id}/panitia", $this->data())->assertForbidden();
    }

    public function test_daftar_panitia_hanya_milik_event_itu(): void
    {
        $eo = $this->eo();
        $a = $this->event($eo);
        $b = $this->event($eo, ['judul' => 'Event B']);
        $this->tambah($eo, $a);

        $this->actingAs($eo, 'sanctum')->getJson("/api/events/{$a->id}/panitia")->assertOk()->assertJsonCount(1, 'data');
        $this->actingAs($eo, 'sanctum')->getJson("/api/events/{$b->id}/panitia")->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_ganti_password_mengaktifkan_panitia(): void
    {
        $eo = $this->eo();
        $panitia = $this->tambah($eo, $this->event($eo));
        $awal = $this->passwordDariEmail();
        $this->assertNull($panitia->aktif_at);

        $token = $this->postJson('/api/login', ['email' => 'budi@tes.test', 'password' => $awal])->json('data.token');

        // lepaskan actingAs penyelenggara dari langkah tambah panitia, supaya yang dipakai token panitia
        $this->app['auth']->forgetGuards();
        $this->withToken($token)->putJson('/api/password', ['current_password' => $awal, 'new_password' => 'passbaru1'])->assertOk();

        $this->assertNotNull($panitia->fresh()->aktif_at);
        $this->postJson('/api/login', ['email' => 'budi@tes.test', 'password' => 'passbaru1'])
            ->assertOk()->assertJsonPath('data.wajib_ganti_password', false);
    }

    public function test_panitia_belum_ganti_password_tidak_bisa_scan(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->tiket($event, 'lunas');
        $pan = $this->loginPanitia($event, false);

        $this->actingAs($pan, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-AAAA1111'])->assertForbidden();
        $this->actingAs($pan, 'sanctum')->getJson('/api/panitia/event')->assertForbidden();
        $this->assertDatabaseHas('registrations', ['kode' => 'EVT-AAAA1111', 'status' => 'lunas']);
    }

    public function test_kirim_ulang_membuat_password_baru_dan_yang_lama_tidak_berlaku(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $panitia = $this->tambah($eo, $event);
        $lama = $this->passwordDariEmail();

        Mail::fake();
        $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$event->id}/panitia/{$panitia->id}/kirim-ulang")->assertOk();
        $baru = $this->passwordDariEmail();

        $this->assertNotSame($lama, $baru);
        $this->postJson('/api/login', ['email' => 'budi@tes.test', 'password' => $lama])->assertStatus(401);
        $this->postJson('/api/login', ['email' => 'budi@tes.test', 'password' => $baru])->assertOk();
    }

    public function test_kirim_ulang_ditolak_untuk_panitia_yang_sudah_aktif(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $panitia = $this->tambah($eo, $event);
        $panitia->forceFill(['aktif_at' => now()])->save();

        Mail::fake();
        $this->actingAs($eo, 'sanctum')->postJson("/api/events/{$event->id}/panitia/{$panitia->id}/kirim-ulang")->assertStatus(422);
        Mail::assertNothingSent();
    }

    public function test_hapus_panitia_menghapus_akunnya(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $panitia = $this->tambah($eo, $event);
        $userId = $panitia->user_id;

        $this->actingAs($eo, 'sanctum')->deleteJson("/api/events/{$event->id}/panitia/{$panitia->id}")->assertOk();

        $this->assertDatabaseMissing('users', ['id' => $userId]);
        $this->assertDatabaseMissing('panitia', ['id' => $panitia->id]);
    }

    public function test_panitia_event_lain_tidak_bisa_dihapus_lewat_event_ini(): void
    {
        $eo = $this->eo();
        $a = $this->event($eo);
        $b = $this->event($eo, ['judul' => 'Event B']);
        $panitia = $this->tambah($eo, $a);

        $this->actingAs($eo, 'sanctum')->deleteJson("/api/events/{$b->id}/panitia/{$panitia->id}")->assertNotFound();
        $this->assertDatabaseHas('panitia', ['id' => $panitia->id]);
    }

    // ===== scan =====

    // $aktif = true meniru panitia yang sudah mengganti password awalnya.
    private function loginPanitia(Event $event, bool $aktif = true): User
    {
        $eo = User::find($event->organizer_id);
        $panitia = $this->tambah($eo, $event);

        if ($aktif) {
            $panitia->forceFill(['aktif_at' => now()])->save();
        }

        return $panitia->user;
    }

    public function test_scan_tiket_lunas_menjadi_hadir(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->tiket($event, 'lunas');
        $pan = $this->loginPanitia($event);

        $res = $this->actingAs($pan, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'evt-aaaa1111']);

        $res->assertOk()
            ->assertJsonPath('hasil', 'berhasil')
            ->assertJsonPath('ringkasan.hadir', 1)
            ->assertJsonPath('ringkasan.total', 1);
        $this->assertDatabaseHas('registrations', ['kode' => 'EVT-AAAA1111', 'status' => 'hadir']);
    }

    public function test_tiket_tidak_bisa_dipakai_dua_kali(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->tiket($event, 'lunas');
        $pan = $this->loginPanitia($event);

        $this->actingAs($pan, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-AAAA1111'])->assertJsonPath('hasil', 'berhasil');
        $this->actingAs($pan, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-AAAA1111'])->assertJsonPath('hasil', 'sudah_dipakai');
    }

    public function test_scan_tiket_belum_lunas_dan_dibatalkan_ditolak(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->tiket($event, 'menunggu_pembayaran', 'EVT-BELUM001');
        $this->tiket($event, 'dibatalkan', 'EVT-BATAL001');
        $pan = $this->loginPanitia($event);

        $this->actingAs($pan, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-BELUM001'])->assertJsonPath('hasil', 'belum_lunas');
        $this->actingAs($pan, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-BATAL001'])->assertJsonPath('hasil', 'dibatalkan');
        $this->assertDatabaseHas('registrations', ['kode' => 'EVT-BELUM001', 'status' => 'menunggu_pembayaran']);
    }

    public function test_tiket_event_lain_dan_qr_asing_ditolak(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $lain = $this->event($eo, ['judul' => 'Event Lain']);
        $this->tiket($lain, 'lunas', 'EVT-LAIN0001');
        $pan = $this->loginPanitia($event);

        $this->actingAs($pan, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-LAIN0001'])->assertJsonPath('hasil', 'event_lain');
        $this->actingAs($pan, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'https://contoh.com'])->assertJsonPath('hasil', 'tidak_dikenali');
        $this->assertDatabaseHas('registrations', ['kode' => 'EVT-LAIN0001', 'status' => 'lunas']);
    }

    public function test_hanya_panitia_yang_boleh_scan(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->tiket($event, 'lunas');

        $this->actingAs($eo, 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-AAAA1111'])->assertForbidden();
        $this->actingAs($this->user('mhs@tes.test'), 'sanctum')->postJson('/api/panitia/scan', ['kode' => 'EVT-AAAA1111'])->assertForbidden();
    }

    public function test_scan_tanpa_login_ditolak(): void
    {
        $this->postJson('/api/panitia/scan', ['kode' => 'EVT-AAAA1111'])->assertUnauthorized();
    }

    public function test_panitia_tidak_bisa_mengelola_event_atau_panitia(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $pan = $this->loginPanitia($event);

        $this->actingAs($pan, 'sanctum')->getJson('/api/my-events')->assertForbidden();
        $this->actingAs($pan, 'sanctum')->getJson("/api/events/{$event->id}/participants")->assertForbidden();
        $this->actingAs($pan, 'sanctum')->postJson("/api/events/{$event->id}/panitia", $this->data(['email' => 'x@tes.test']))->assertForbidden();
    }

    public function test_info_event_dan_daftar_hadir_panitia(): void
    {
        $eo = $this->eo();
        $event = $this->event($eo);
        $this->tiket($event, 'lunas');
        $this->tiket($event, 'hadir', 'EVT-HADIR001');
        $pan = $this->loginPanitia($event);

        $this->actingAs($pan, 'sanctum')->getJson('/api/panitia/event')->assertOk()
            ->assertJsonPath('data.event.id', $event->id)->assertJsonPath('data.hadir', 1)->assertJsonPath('data.total', 2);
        $this->actingAs($pan, 'sanctum')->getJson('/api/panitia/hadir')->assertOk()->assertJsonCount(1, 'data');
    }
}
