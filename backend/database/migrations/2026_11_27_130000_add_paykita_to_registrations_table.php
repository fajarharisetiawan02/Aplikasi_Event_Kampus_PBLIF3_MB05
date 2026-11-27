<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('registrations', function (Blueprint $table) {
            $table->string('paykita_order_id')->nullable()->index()->after('status');
            $table->unsignedInteger('pay_amount')->nullable()->after('paykita_order_id');
            $table->text('qris')->nullable()->after('pay_amount');
            $table->string('checkout_url')->nullable()->after('qris');
            $table->timestamp('expires_at')->nullable()->after('checkout_url');
        });
    }

    public function down(): void
    {
        Schema::table('registrations', function (Blueprint $table) {
            $table->dropColumn(['paykita_order_id', 'pay_amount', 'qris', 'checkout_url', 'expires_at']);
        });
    }
};
