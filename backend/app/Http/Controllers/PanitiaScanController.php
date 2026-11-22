<?php

namespace App\Http\Controllers;

use App\Models\Panitia;
use App\Models\Registration;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

// Fitur khusus akun panitia: lihat event yang dijaga dan scan tiket peserta (check-in).
class PanitiaScanController extends Controller
{
    // READ: event yang dijaga panitia + ringkasan kehadiran
    public function event(Request $request): JsonResponse
    {
        $panitia = $this->panitia($request);
        if (! $panitia) {
            return $this->forbidden();
        }
        if (! $panitia->aktif_at) {
            return $this->harusGanti();
        }

        return response()->json(['data' => $this->ringkasan($panitia)]);
    }

    // READ: daftar peserta yang sudah check-in
    public function hadir(Request $request): JsonResponse
    {
        $panitia = $this->panitia($request);
        if (! $panitia) {
            return $this->forbidden();
        }
        if (! $panitia->aktif_at) {
            return $this->harusGanti();
        }

        $items = Registration::with('user')
            ->where('event_id', $panitia->event_id)
            ->where('status', 'hadir')
            ->latest('updated_at')
            ->get();

        return response()->json(['data' => $items->map->toApiArray()->values()]);
    }

    // UPDATE: scan kode tiket. Hasil scan selalu 200, jenis hasilnya ada di field "hasil".
    public function scan(Request $request): JsonResponse
    {
        $panitia = $this->panitia($request);
        if (! $panitia) {
            return $this->forbidden();
        }
        if (! $panitia->aktif_at) {
            return $this->harusGanti();
        }

        $data = $request->validate(['kode' => ['required', 'string', 'max:100']]);
        $kode = strtoupper(trim($data['kode']));

        $reg = Registration::with('user')->where('kode', $kode)->first();

        if (! $reg) {
            return $this->hasil('tidak_dikenali', 'QR tidak dikenali. Kode ini bukan tiket EventIn.');
        }

        if ($reg->event_id !== $panitia->event_id) {
            return $this->hasil('event_lain', 'Tiket ini bukan untuk event yang kamu jaga.');
        }

        if ($reg->status === 'dibatalkan') {
            return $this->hasil('dibatalkan', 'Pendaftaran peserta ini sudah dibatalkan.', $reg);
        }

        if ($reg->status === 'menunggu_pembayaran') {
            return $this->hasil('belum_lunas', 'Tiket belum lunas. Arahkan peserta ke meja pembayaran.', $reg);
        }

        if ($reg->status === 'hadir') {
            return $this->hasil('sudah_dipakai', 'Tiket ini sudah dipakai check-in sebelumnya.', $reg);
        }

        // Update bersyarat: kalau dua panitia scan bersamaan, hanya satu yang berhasil.
        $berubah = Registration::whereKey($reg->id)->where('status', 'lunas')->update(['status' => 'hadir']);

        if ($berubah === 0) {
            return $this->hasil('sudah_dipakai', 'Tiket ini sudah dipakai check-in sebelumnya.', $reg->fresh('user'));
        }

        return $this->hasil('berhasil', 'Check-in berhasil.', $reg->fresh('user'), $panitia);
    }

    private function hasil(string $hasil, string $pesan, ?Registration $reg = null, ?Panitia $panitia = null): JsonResponse
    {
        return response()->json([
            'hasil' => $hasil,
            'message' => $pesan,
            'data' => $reg?->toApiArray(),
            'ringkasan' => $panitia ? $this->ringkasan($panitia) : null,
        ]);
    }

    private function ringkasan(Panitia $panitia): array
    {
        $event = $panitia->event;
        $aktif = Registration::where('event_id', $event->id)->whereIn('status', Registration::AKTIF);

        return [
            'event' => [
                'id' => $event->id,
                'judul' => $event->judul,
                'tanggal' => $event->tanggal?->format('Y-m-d'),
                'waktu' => $event->waktu,
                'lokasi' => $event->lokasi,
            ],
            'hadir' => (clone $aktif)->where('status', 'hadir')->count(),
            'total' => (clone $aktif)->count(),
        ];
    }

    private function panitia(Request $request): ?Panitia
    {
        $user = $request->user();

        if (! $user->isPanitia()) {
            return null;
        }

        return Panitia::with('event')->where('user_id', $user->id)->first();
    }

    private function harusGanti(): JsonResponse
    {
        return response()->json(['message' => 'Ganti password awalmu dulu sebelum memindai tiket.'], 403);
    }

    private function forbidden(): JsonResponse
    {
        return response()->json(['message' => 'Fitur ini hanya untuk akun panitia.'], 403);
    }
}
