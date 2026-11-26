<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->string('narahubung', 100)->nullable()->after('alamat');
            $table->string('narahubung_telepon', 20)->nullable()->after('narahubung');
        });
    }

    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn(['narahubung', 'narahubung_telepon']);
        });
    }
};
