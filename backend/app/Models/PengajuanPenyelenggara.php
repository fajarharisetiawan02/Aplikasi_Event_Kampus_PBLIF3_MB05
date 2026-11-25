<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PengajuanPenyelenggara extends Model
{
    protected $table = 'pengajuan_penyelenggara';

    protected $fillable = ['user_id', 'organisasi', 'jabatan', 'bukti_url'];

    protected $attributes = ['status' => 'menunggu'];

    protected function casts(): array
    {
        return ['diputuskan_at' => 'datetime'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function toApiArray(bool $denganPemohon = false): array
    {
        $data = [
            'id' => $this->id,
            'organisasi' => $this->organisasi,
            'jabatan' => $this->jabatan,
            'bukti_url' => $this->bukti_url,
            'status' => $this->status,
            'alasan' => $this->alasan,
            'diajukan' => $this->created_at?->toIso8601String(),
            'diputuskan' => $this->diputuskan_at?->toIso8601String(),
        ];

        if ($denganPemohon) {
            $data['pemohon'] = [
                'id' => $this->user_id,
                'nama' => $this->user->nama,
                'email' => $this->user->email,
                'nim' => $this->user->nim,
            ];
        }

        return $data;
    }
}
