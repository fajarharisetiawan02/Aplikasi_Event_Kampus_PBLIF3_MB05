<?php

namespace Database\Seeders;

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
    }
}
