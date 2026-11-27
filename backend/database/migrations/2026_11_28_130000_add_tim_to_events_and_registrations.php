<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {
            // tiket, daftar, atau tim. Kosong untuk event lama (ditentukan dari kategori).
            $table->string('tipe', 10)->nullable()->after('kuota');
            $table->unsignedSmallInteger('min_anggota')->nullable()->after('tipe');
            $table->unsignedSmallInteger('max_anggota')->nullable()->after('min_anggota');
        });

        Schema::table('registrations', function (Blueprint $table) {
            $table->string('nama_tim', 60)->nullable()->after('status');
            $table->json('anggota')->nullable()->after('nama_tim');
        });
    }

    public function down(): void
    {
        Schema::table('registrations', function (Blueprint $table) {
            $table->dropColumn(['nama_tim', 'anggota']);
        });

        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn(['tipe', 'min_anggota', 'max_anggota']);
        });
    }
};
