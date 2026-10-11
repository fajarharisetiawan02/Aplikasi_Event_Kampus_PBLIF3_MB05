<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->renameColumn('name', 'nama');
            $table->string('nim')->nullable()->unique()->after('email');
            $table->string('no_hp')->nullable()->after('nim');
            $table->boolean('is_admin')->default(false)->after('no_hp');
            $table->json('roles')->nullable()->after('is_admin');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['nim']);
            $table->dropColumn(['nim', 'no_hp', 'is_admin', 'roles']);
            $table->renameColumn('nama', 'name');
        });
    }
};
