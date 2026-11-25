<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Pengajuan mahasiswa untuk menjadi penyelenggara. Status: menunggu, disetujui, ditolak, dicabut.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pengajuan_penyelenggara', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('organisasi', 100);
            $table->string('jabatan', 60);
            $table->string('bukti_url', 500)->nullable();
            $table->string('status', 20)->default('menunggu');
            $table->text('alasan')->nullable(); // alasan penolakan atau pencabutan
            $table->foreignId('diputuskan_oleh')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('diputuskan_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });

        // Panitia dinonaktifkan saat penyelenggaranya dicabut.
        Schema::table('panitia', function (Blueprint $table) {
            $table->timestamp('nonaktif_at')->nullable()->after('aktif_at');
        });
    }

    public function down(): void
    {
        Schema::table('panitia', function (Blueprint $table) {
            $table->dropColumn('nonaktif_at');
        });
        Schema::dropIfExists('pengajuan_penyelenggara');
    }
};
