<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Event extends Model
{
    protected $fillable = [
        'judul', 'deskripsi', 'kategori', 'banner_url',
        'tanggal', 'waktu', 'lokasi', 'harga', 'kuota', 'status',
    ];

    protected function casts(): array
    {
        return [
            'tanggal' => 'date:Y-m-d',
            'harga' => 'integer',
            'kuota' => 'integer',
            'kuota_terjual' => 'integer',
        ];
    }

    public function organizer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'organizer_id');
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'judul' => $this->judul,
            'deskripsi' => $this->deskripsi,
            'kategori' => $this->kategori,
            'banner_url' => $this->banner_url,
            'tanggal' => $this->tanggal?->format('Y-m-d'),
            'waktu' => $this->waktu,
            'lokasi' => $this->lokasi,
            'harga' => $this->harga,
            'kuota' => $this->kuota,
            'kuota_terjual' => $this->kuota_terjual,
            'status' => $this->status,
            'organizer' => [
                'id' => $this->organizer_id,
                'nama' => $this->organizer?->nama,
            ],
        ];
    }
}
