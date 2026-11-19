<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class EventBannerTest extends TestCase
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

    public function test_penyelenggara_bisa_unggah_banner(): void
    {
        Storage::fake('public');

        $res = $this->actingAs($this->eo(), 'sanctum')->postJson('/api/events/banner', [
            'banner' => UploadedFile::fake()->image('banner.jpg', 1280, 720),
        ]);

        $res->assertCreated();
        $url = $res->json('data.banner_url');
        $this->assertStringContainsString('/storage/banners/', $url);
        Storage::disk('public')->assertExists('banners/' . basename($url));
    }

    public function test_mahasiswa_tidak_bisa_unggah_banner(): void
    {
        Storage::fake('public');

        $this->actingAs($this->user('mhs@tes.test'), 'sanctum')->postJson('/api/events/banner', [
            'banner' => UploadedFile::fake()->image('banner.jpg'),
        ])->assertForbidden();
    }

    public function test_file_bukan_gambar_ditolak(): void
    {
        Storage::fake('public');

        $this->actingAs($this->eo(), 'sanctum')->postJson('/api/events/banner', [
            'banner' => UploadedFile::fake()->create('dokumen.pdf', 100, 'application/pdf'),
        ])->assertUnprocessable();
    }

    public function test_gambar_lebih_dari_2mb_ditolak(): void
    {
        Storage::fake('public');

        $this->actingAs($this->eo(), 'sanctum')->postJson('/api/events/banner', [
            'banner' => UploadedFile::fake()->image('besar.jpg')->size(3000),
        ])->assertUnprocessable();
    }

    public function test_banner_disimpan_relatif_dan_dikembalikan_sebagai_url_lengkap(): void
    {
        $eo = $this->eo();

        $res = $this->actingAs($eo, 'sanctum')->postJson('/api/events', [
            'judul' => 'Seminar Banner',
            'deskripsi' => 'Deskripsi.',
            'kategori' => 'Seminar',
            'tanggal' => '2026-12-20',
            'waktu' => '09.00 WIB',
            'lokasi' => 'Aula',
            'harga' => 0,
            'kuota' => 10,
            'banner_url' => 'http://10.0.0.5:8000/storage/banners/abc.jpg',
        ]);

        $res->assertCreated();
        $this->assertSame('storage/banners/abc.jpg', Event::first()->getRawOriginal('banner_url'));
        $this->assertStringEndsWith('/storage/banners/abc.jpg', $res->json('data.banner_url'));
        $this->assertStringStartsWith('http', $res->json('data.banner_url'));
    }
}
