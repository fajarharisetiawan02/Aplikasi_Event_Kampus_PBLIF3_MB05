<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

// Pembungkus API PayKita (https://pay.digikita.id/api). Kunci API hanya dipakai di server.
class PayKitaService
{
    public function buatOrder(int $nominal, string $referensi): array
    {
        return $this->kirim('post', '/orders', [
            'base_amount' => $nominal,
            'reference' => $referensi,
            'ttl_seconds' => config('paykita.ttl'),
        ]);
    }

    public function ambilOrder(string $id): array
    {
        return $this->kirim('get', '/orders/' . rawurlencode($id));
    }

    public function batalkanOrder(string $id): array
    {
        return $this->kirim('post', '/orders/' . rawurlencode($id) . '/cancel');
    }

    private function kirim(string $metode, string $path, array $isi = []): array
    {
        $kunci = config('paykita.api_key');

        if (! $kunci) {
            throw new RuntimeException('PAYKITA_API_KEY belum diisi.');
        }

        $url = rtrim(config('paykita.base_url'), '/') . $path;
        $klien = Http::withHeaders(['x-api-key' => $kunci])->acceptJson()->timeout(15);

        try {
            $respons = $metode === 'get' ? $klien->get($url) : $klien->asJson()->post($url, $isi);
        } catch (ConnectionException $e) {
            throw new RuntimeException('PayKita tidak dapat dihubungi.', 0, $e);
        }

        if (! $respons->json('ok')) {
            $kode = $respons->json('error.code', 'unknown');
            $pesan = $respons->json('error.message', 'Permintaan ke PayKita gagal.');

            throw new RuntimeException("PayKita [{$kode}]: {$pesan}");
        }

        return $respons->json('data') ?? [];
    }
}
