<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Event extends Model
{
    protected $fillable = [
        'judul', 'deskripsi', 'kategori', 'banner_url',
        'tanggal', 'waktu', 'lokasi', 'alamat', 'narahubung', 'narahubung_telepon',
        'harga', 'kuota', 'status',
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

    // Banner hasil unggah disimpan sebagai path relatif (storage/banners/...), supaya
    // tidak ikut berubah kalau alamat server berganti. URL/asset lain disimpan apa adanya.
    public function setBannerUrlAttribute(?string $value): void
    {
        if ($value !== null && str_contains($value, '/storage/banners/')) {
            $value = 'storage/banners/' . Str::after($value, '/storage/banners/');
        } elseif ($value !== null && str_contains($value, '/api/banners/')) {
            $value = 'storage/banners/' . Str::after($value, '/api/banners/');
        }

        $this->attributes['banner_url'] = $value;
    }

    private function bannerLengkap(): ?string
    {
        // Banner unggahan dilayani lewat rute API supaya mendapat header CORS (dibutuhkan Flutter web).
        if ($this->banner_url && str_starts_with($this->banner_url, 'storage/banners/')) {
            return url('api/banners/' . basename($this->banner_url));
        }

        if ($this->banner_url && str_starts_with($this->banner_url, 'storage/')) {
            return url($this->banner_url);
        }

        return $this->banner_url;
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'judul' => $this->judul,
            'deskripsi' => $this->deskripsi,
            'kategori' => $this->kategori,
            'banner_url' => $this->bannerLengkap(),
            'tanggal' => $this->tanggal?->format('Y-m-d'),
            'waktu' => $this->waktu,
            'lokasi' => $this->lokasi,
            'alamat' => $this->alamat,
            'narahubung' => $this->narahubung,
            'narahubung_telepon' => $this->narahubung_telepon,
            'harga' => $this->harga,
            'kuota' => $this->kuota,
            'kuota_terjual' => $this->kuota_terjual,
            'status' => $this->status,
            'alasan_penolakan' => $this->alasan_penolakan,
            'organizer' => [
                'id' => $this->organizer_id,
                'nama' => $this->organizer?->nama,
            ],
        ];
    }
}