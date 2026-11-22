<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Panitia extends Model
{
    protected $table = 'panitia';

    protected $fillable = ['user_id', 'event_id', 'dibuat_oleh', 'undangan_dikirim_at', 'aktif_at'];

    protected function casts(): array
    {
        return [
            'undangan_dikirim_at' => 'datetime',
            'aktif_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'nama' => $this->user->nama,
            'email' => $this->user->email,
            'no_hp' => $this->user->no_hp,
            'status' => $this->aktif_at ? 'aktif' : 'menunggu',
            'event_id' => $this->event_id,
            'dibuat' => $this->created_at?->toIso8601String(),
        ];
    }
}
