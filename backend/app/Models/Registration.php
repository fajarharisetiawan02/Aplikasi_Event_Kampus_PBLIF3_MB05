<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Registration extends Model
{
    public const AKTIF = ['menunggu_pembayaran', 'lunas', 'hadir'];

    protected $fillable = ['user_id', 'event_id', 'kode', 'jumlah', 'total_harga', 'metode', 'status'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function isAktif(): bool
    {
        return in_array($this->status, self::AKTIF, true);
    }

    public function toApiArray(): array
    {
        $data = [
            'id' => $this->id,
            'kode' => $this->kode,
            'jumlah' => $this->jumlah,
            'total_harga' => $this->total_harga,
            'metode' => $this->metode,
            'status' => $this->status,
            'dibuat' => $this->created_at?->toIso8601String(),
        ];

        if ($this->relationLoaded('event')) {
            $data['event'] = $this->event->toApiArray();
        }

        if ($this->relationLoaded('user')) {
            $data['peserta'] = [
                'id' => $this->user->id,
                'nama' => $this->user->nama,
                'email' => $this->user->email,
                'nim' => $this->user->nim,
                'no_hp' => $this->user->no_hp,
            ];
        }

        return $data;
    }
}
