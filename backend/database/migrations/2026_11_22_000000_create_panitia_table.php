<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Satu akun panitia terikat ke satu event. Akun dibuat oleh penyelenggara.
        Schema::create('panitia', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('dibuat_oleh')->constrained('users')->cascadeOnDelete();
            $table->timestamp('undangan_dikirim_at')->nullable();
            $table->timestamp('aktif_at')->nullable(); // terisi saat panitia pertama kali login (kosong = belum pernah login)
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('panitia');
    }
};
