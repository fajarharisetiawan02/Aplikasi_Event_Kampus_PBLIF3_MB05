<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EventApprovalTest extends TestCase
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

    private function eo(): User
    {
        return $this->user('eo@tes.test', ['roles' => ['user', 'event_organizer']]);
    }

    private function admin(): User
    {
        return $this->user('admin@tes.test', ['is_admin' => true]);
    }

    private function payload(array $extra = []): array
    {
        return array_merge([
            'judul' => 'Seminar Contoh',
            'deskripsi' => 'Deskripsi event contoh.',
            'kategori' => 'Seminar',
            'tanggal' => '2026-12-20',
            'waktu' => '09.00 WIB',
            'lokasi' => 'Aula Polibatam',
            'harga' => 0,
            'kuota' => 50,
        ], $extra);
    }

    public function test_event_baru_dari_penyelenggara_menunggu_persetujuan(): void
    {
        $eo = $this->eo();

        $res = $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload());

        $res->assertCreated()->assertJsonPath('data.status', 'pending');
    }

    public function test_penyelenggara_tidak_bisa_menerbitkan_sendiri(): void
    {
        $eo = $this->eo();

        $res = $this->actingAs($eo, 'sanctum')
            ->postJson('/api/events', $this->payload(['status' => 'published']));

        $res->assertCreated()->assertJsonPath('data.status', 'pending');
    }

    public function test_draft_boleh_disimpan(): void
    {
        $eo = $this->eo();

        $res = $this->actingAs($eo, 'sanctum')
            ->postJson('/api/events', $this->payload(['status' => 'draft']));

        $res->assertCreated()->assertJsonPath('data.status', 'draft');
    }

    public function test_event_pending_tidak_tampil_ke_mahasiswa(): void
    {
        $eo = $this->eo();
        $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload())->assertCreated();
        $id = Event::first()->id;

        $this->getJson('/api/events')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson("/api/events/$id")->assertNotFound();
    }

    public function test_admin_menyetujui_lalu_event_tampil(): void
    {
        $eo = $this->eo();
        $admin = $this->admin();
        $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload())->assertCreated();
        $id = Event::first()->id;

        $this->actingAs($admin, 'sanctum')->putJson("/api/events/$id/approve")
            ->assertOk()->assertJsonPath('data.status', 'published');

        $this->getJson('/api/events')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson("/api/events/$id")->assertOk();
    }

    public function test_admin_menolak_dengan_alasan(): void
    {
        $eo = $this->eo();
        $admin = $this->admin();
        $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload())->assertCreated();
        $id = Event::first()->id;

        $this->actingAs($admin, 'sanctum')->putJson("/api/events/$id/reject", [])->assertUnprocessable();

        $this->actingAs($admin, 'sanctum')
            ->putJson("/api/events/$id/reject", ['alasan' => 'Deskripsi kurang lengkap'])
            ->assertOk()
            ->assertJsonPath('data.status', 'rejected')
            ->assertJsonPath('data.alasan_penolakan', 'Deskripsi kurang lengkap');

        $this->getJson('/api/events')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_diedit_setelah_ditolak_diajukan_ulang(): void
    {
        $eo = $this->eo();
        $admin = $this->admin();
        $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload())->assertCreated();
        $id = Event::first()->id;
        $this->actingAs($admin, 'sanctum')
            ->putJson("/api/events/$id/reject", ['alasan' => 'Perlu revisi'])->assertOk();

        $this->actingAs($eo, 'sanctum')
            ->putJson("/api/events/$id", $this->payload(['judul' => 'Seminar Revisi']))
            ->assertOk()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.alasan_penolakan', null);
    }

    public function test_event_tayang_tetap_tayang_saat_diedit_penyelenggara(): void
    {
        $eo = $this->eo();
        $admin = $this->admin();
        $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload())->assertCreated();
        $id = Event::first()->id;
        $this->actingAs($admin, 'sanctum')->putJson("/api/events/$id/approve")->assertOk();

        $this->actingAs($eo, 'sanctum')
            ->putJson("/api/events/$id", $this->payload(['judul' => 'Judul Baru', 'status' => 'draft']))
            ->assertOk()
            ->assertJsonPath('data.status', 'published');
    }

    public function test_bukan_admin_tidak_bisa_menyetujui_atau_menolak(): void
    {
        $eo = $this->eo();
        $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload())->assertCreated();
        $id = Event::first()->id;

        $this->actingAs($eo, 'sanctum')->putJson("/api/events/$id/approve")->assertForbidden();
        $this->actingAs($eo, 'sanctum')
            ->putJson("/api/events/$id/reject", ['alasan' => 'coba'])->assertForbidden();
    }

    public function test_admin_bisa_menyaring_event_menunggu(): void
    {
        $eo = $this->eo();
        $admin = $this->admin();
        $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload())->assertCreated();
        $this->actingAs($eo, 'sanctum')->postJson('/api/events', $this->payload(['judul' => 'Draft Saja', 'status' => 'draft']))->assertCreated();

        $this->actingAs($admin, 'sanctum')->getJson('/api/my-events?status=pending')
            ->assertOk()->assertJsonCount(1, 'data');
    }
}
