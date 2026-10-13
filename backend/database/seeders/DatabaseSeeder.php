<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $akun = [
            ['nama' => 'Fajar Hari Setiawan', 'email' => 'fajar@kampus.ac.id', 'nim' => '21051234', 'no_hp' => '081234567890', 'password' => 'user123', 'roles' => ['user'], 'is_admin' => false],
            ['nama' => 'Muhammad Rafie', 'email' => 'eo@kampus.ac.id', 'nim' => '20051987', 'no_hp' => '081234567891', 'password' => 'event123', 'roles' => ['user', 'event_organizer'], 'is_admin' => false],
            ['nama' => 'Admin Kampus', 'email' => 'admin@kampus.ac.id', 'nim' => null, 'no_hp' => '081234567892', 'password' => 'admin123', 'roles' => ['user'], 'is_admin' => true],
        ];

        foreach ($akun as $data) {
            User::unguarded(fn () => User::updateOrCreate(['email' => $data['email']], $data));
        }

        $eo = User::where('email', 'eo@kampus.ac.id')->first();

        $events = [
            ['judul' => 'Festival Musik Batam', 'kategori' => 'Musik', 'banner_url' => 'assets/images/festival_musik.png', 'tanggal' => '2026-10-20', 'waktu' => '19.00 WIB - Selesai', 'lokasi' => 'Lapangan Polibatam, Batam', 'harga' => 150000, 'kuota' => 500, 'deskripsi' => 'Festival musik tahunan terbesar di Batam, menghadirkan musisi lokal dan nasional dalam satu panggung.'],
            ['judul' => 'Seminar Teknologi 2026', 'kategori' => 'Teknologi', 'banner_url' => 'assets/images/seminar_teknologi.png', 'tanggal' => '2026-10-25', 'waktu' => '09.00 WIB - 12.00 WIB', 'lokasi' => 'Aula Polibatam', 'harga' => 0, 'kuota' => 300, 'deskripsi' => 'Seminar tentang perkembangan teknologi AI dan dampaknya bagi mahasiswa serta dunia kerja.'],
            ['judul' => 'Turnamen Futsal Kampus', 'kategori' => 'Olahraga', 'banner_url' => 'assets/images/futsal_kampus.png', 'tanggal' => '2026-11-02', 'waktu' => '13.00 WIB - Selesai', 'lokasi' => 'GOR Kampus', 'harga' => 50000, 'kuota' => 200, 'deskripsi' => 'Kompetisi futsal antar jurusan yang diadakan setiap semester dengan total hadiah jutaan rupiah.'],
            ['judul' => 'Workshop UI/UX Design', 'kategori' => 'Teknologi', 'banner_url' => 'assets/images/seminar_teknologi.png', 'tanggal' => '2026-11-05', 'waktu' => '10.00 WIB - 15.00 WIB', 'lokasi' => 'Lab Multimedia Polibatam', 'harga' => 25000, 'kuota' => 60, 'deskripsi' => 'Belajar dasar riset pengguna, wireframe, dan prototipe langsung bersama praktisi.'],
            ['judul' => 'Pameran Seni Mahasiswa', 'kategori' => 'Seni', 'banner_url' => 'assets/images/festival_musik.png', 'tanggal' => '2026-11-10', 'waktu' => '10.00 WIB - 17.00 WIB', 'lokasi' => 'Galeri Kampus, Batam', 'harga' => 0, 'kuota' => 250, 'deskripsi' => 'Pameran karya lukis, fotografi, dan seni rupa dari mahasiswa berbagai jurusan.'],
        ];

        foreach ($events as $data) {
            $event = Event::firstOrNew(['judul' => $data['judul']]);
            $event->fill($data);
            $event->organizer_id = $eo->id;
            $event->save();
        }
    }
}
