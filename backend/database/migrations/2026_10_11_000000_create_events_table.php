<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organizer_id')->constrained('users')->cascadeOnDelete();
            $table->string('judul');
            $table->text('deskripsi');
            $table->string('kategori');
            $table->string('banner_url')->nullable();
            $table->date('tanggal');
            $table->string('waktu')->nullable();
            $table->string('lokasi');
            $table->unsignedInteger('harga')->default(0);
            $table->unsignedInteger('kuota');
            $table->unsignedInteger('kuota_terjual')->default(0);
            $table->string('status')->default('published');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('events');
    }
};
