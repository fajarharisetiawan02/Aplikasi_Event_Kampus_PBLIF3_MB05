<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable;

    // is_admin dan roles sengaja tidak masuk fillable supaya tidak bisa diisi dari request
    protected $fillable = ['nama', 'email', 'password', 'nim', 'no_hp'];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            'roles' => 'array',
        ];
    }

    public function panitia(): HasOne
    {
        return $this->hasOne(Panitia::class);
    }

    public function pengajuanPenyelenggara(): HasMany
    {
        return $this->hasMany(PengajuanPenyelenggara::class);
    }

    public function isPenyelenggara(): bool
    {
        return in_array('event_organizer', $this->roles ?? [], true);
    }

    public function isPanitia(): bool
    {
        return in_array('panitia', $this->roles ?? [], true);
    }

    public function toApiArray(?string $token = null): array
    {
        $data = [
            'id' => $this->id,
            'nama' => $this->nama,
            'email' => $this->email,
            'nim' => $this->nim,
            'no_hp' => $this->no_hp,
            'roles' => $this->roles ?? ['user'],
            'is_admin' => $this->is_admin,
        ];

        // Pengajuan terakhir ditampilkan di Profil: menunggu, disetujui, ditolak, atau dicabut.
        $pengajuan = $this->pengajuanPenyelenggara()->latest('id')->first();
        $data['pengajuan_penyelenggara'] = $pengajuan?->toApiArray();

        if ($this->isPanitia() && $this->panitia?->event && ! $this->panitia->nonaktif_at) {
            $data['panitia_event'] = [
                'id' => $this->panitia->event->id,
                'judul' => $this->panitia->event->judul,
                'tanggal' => $this->panitia->event->tanggal?->format('Y-m-d'),
            ];
        }

        if ($token !== null) {
            $data['token'] = $token;
        }

        return $data;
    }
}
