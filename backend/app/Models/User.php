<?php

namespace App\Models;

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

        if ($token !== null) {
            $data['token'] = $token;
        }

        return $data;
    }
}
