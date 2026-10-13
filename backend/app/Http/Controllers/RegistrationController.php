<?php

namespace App\Http\Controllers;

use App\Models\Event;
use App\Models\Registration;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class RegistrationController extends Controller
{
    private const MAKS_PER_PESANAN = 5;

    // CREATE: mahasiswa mendaftar ke sebuah event
    public function store(Request $request, Event $event): JsonResponse
    {
        $data = $request->validate([
            'jumlah' => ['nullable', 'integer', 'min:1', 'max:' . self::MAKS_PER_PESANAN],
        ]);
        $jumlah = $data['jumlah'] ?? 1;
        $user = $request->user();

        if ($event->status !== 'published') {
            return response()->json(['message' => 'Event tidak ditemukan.'], 404);
        }

        if ($event->tanggal->isBefore(today())) {
            return response()->json(['message' => 'Pendaftaran event ini sudah ditutup.'], 422);
        }

        $hasil = DB::transaction(function () use ($event, $user, $jumlah) {
            $event = Event::whereKey($event->id)->lockForUpdate()->first();

            $sudah = Registration::where('user_id', $user->id)
                ->where('event_id', $event->id)
                ->whereIn('status', Registration::AKTIF)
                ->exists();

            if ($sudah) {
                return ['error' => 'Kamu sudah terdaftar di event ini.'];
            }

            if ($event->kuota - $event->kuota_terjual < $jumlah) {
                return ['error' => 'Kuota tidak mencukupi.'];
            }

            $total = $event->harga * $jumlah;
            $gratis = $total === 0;

            $registration = Registration::create([
                'user_id' => $user->id,
                'event_id' => $event->id,
                'kode' => 'EVT-' . strtoupper(Str::random(8)),
                'jumlah' => $jumlah,
                'total_harga' => $total,
                'metode' => $gratis ? 'gratis' : 'cash',
                'status' => $gratis ? 'lunas' : 'menunggu_pembayaran',
            ]);

            $event->increment('kuota_terjual', $jumlah);

            return ['registration' => $registration];
        });

        if (isset($hasil['error'])) {
            return response()->json(['message' => $hasil['error']], 422);
        }

        $registration = $hasil['registration']->load('event.organizer');

        return response()->json([
            'message' => $registration->status === 'lunas'
                ? 'Pendaftaran berhasil. Tiketmu sudah aktif.'
                : 'Pendaftaran berhasil. Silakan bayar tunai ke panitia.',
            'data' => $registration->toApiArray(),
        ], 201);
    }

    // READ: tiket / pendaftaran milik user yang login
    public function mine(Request $request): JsonResponse
    {
        $items = Registration::with('event.organizer')
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'data' => $items->map->toApiArray()->values(),
        ]);
    }

    // UPDATE: peserta membatalkan pendaftarannya
    public function cancel(Request $request, Registration $registration): JsonResponse
    {
        if ($registration->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Tiket tidak ditemukan.'], 404);
        }

        $bisaBatal = $registration->status === 'menunggu_pembayaran'
            || ($registration->status === 'lunas' && $registration->metode === 'gratis');

        if (! $bisaBatal) {
            return response()->json(['message' => 'Tiket ini tidak bisa dibatalkan.'], 422);
        }

        $this->batalkan($registration);

        return response()->json([
            'message' => 'Pendaftaran dibatalkan.',
            'data' => $registration->fresh()->load('event.organizer')->toApiArray(),
        ]);
    }

    // READ: daftar peserta sebuah event (EO pemilik / admin)
    public function participants(Request $request, Event $event): JsonResponse
    {
        if (! $this->canModify($request->user(), $event)) {
            return $this->forbidden();
        }

        $items = Registration::with('user')
            ->where('event_id', $event->id)
            ->latest()
            ->get();

        return response()->json([
            'data' => $items->map->toApiArray()->values(),
        ]);
    }

    // UPDATE: EO menandai lunas / hadir / batal
    public function updateStatus(Request $request, Registration $registration): JsonResponse
    {
        if (! $this->canModify($request->user(), $registration->event)) {
            return $this->forbidden();
        }

        $data = $request->validate([
            'status' => ['required', 'in:lunas,hadir,dibatalkan'],
        ]);
        $baru = $data['status'];

        $boleh = match ($baru) {
            'lunas' => $registration->status === 'menunggu_pembayaran',
            'hadir' => $registration->status === 'lunas',
            'dibatalkan' => $registration->isAktif(),
        };

        if (! $boleh) {
            return response()->json(['message' => 'Perubahan status tidak valid.'], 422);
        }

        if ($baru === 'dibatalkan') {
            $this->batalkan($registration);
        } else {
            $registration->update(['status' => $baru]);
        }

        return response()->json([
            'message' => 'Status diperbarui.',
            'data' => $registration->fresh()->load('user')->toApiArray(),
        ]);
    }

    private function batalkan(Registration $registration): void
    {
        DB::transaction(function () use ($registration) {
            $registration->update(['status' => 'dibatalkan']);
            Event::whereKey($registration->event_id)->decrement('kuota_terjual', $registration->jumlah);
        });
    }

    private function canModify(User $user, Event $event): bool
    {
        if ($user->is_admin) {
            return true;
        }

        return in_array('event_organizer', $user->roles ?? [], true)
            && $event->organizer_id === $user->id;
    }

    private function forbidden(): JsonResponse
    {
        return response()->json(['message' => 'Kamu tidak punya akses untuk mengelola event ini.'], 403);
    }
}
