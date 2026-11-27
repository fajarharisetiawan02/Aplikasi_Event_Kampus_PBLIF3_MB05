<?php

namespace App\Http\Controllers;

use App\Models\Event;
use App\Models\Registration;
use App\Models\User;
use App\Services\PayKitaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Throwable;

class RegistrationController extends Controller
{
    public function __construct(private PayKitaService $paykita)
    {
    }

    // CREATE: mahasiswa mendaftar ke sebuah event
    public function store(Request $request, Event $event): JsonResponse
    {
        $request->validate([
            'metode' => ['nullable', 'in:cash,qris'],
        ]);
        $metode = $request->input('metode', 'cash');

        // Satu akun hanya mendapat satu tiket per event, jumlah dari klien diabaikan.
        $jumlah = 1;
        $user = $request->user();

        // Akun penyelenggara dan panitia hanya mengurus event, tidak jadi peserta.
        if ($user->isPenyelenggara() || $user->isPanitia()) {
            return response()->json(['message' => 'Akun penyelenggara dan panitia tidak bisa mendaftar event.'], 403);
        }

        if ($event->status !== 'published') {
            return response()->json(['message' => 'Event tidak ditemukan.'], 404);
        }

        if ($event->tanggal->isBefore(today())) {
            return response()->json(['message' => 'Pendaftaran event ini sudah ditutup.'], 422);
        }

        // Event tim: ketua mendaftar dengan nama tim dan daftar anggota.
        $namaTim = null;
        $anggota = null;

        if ($event->tipeEfektif() === 'tim') {
            $min = $event->min_anggota ?? 1;
            $max = $event->max_anggota ?? 50;

            $tim = $request->validate([
                'nama_tim' => ['required', 'string', 'min:2', 'max:60'],
                'anggota' => ['required', 'array', 'min:' . $min, 'max:' . $max],
                'anggota.*.nama' => ['required', 'string', 'min:2', 'max:80'],
                'anggota.*.keterangan' => ['nullable', 'string', 'max:50'],
            ], [
                'anggota.required' => 'Isi daftar anggota tim.',
                'anggota.min' => "Jumlah anggota minimal {$min} orang.",
                'anggota.max' => "Jumlah anggota maksimal {$max} orang.",
                'anggota.*.nama.required' => 'Nama anggota tidak boleh kosong.',
            ]);

            $namaTim = trim($tim['nama_tim']);
            $anggota = collect($tim['anggota'])
                ->map(fn ($a) => [
                    'nama' => trim($a['nama']),
                    'keterangan' => isset($a['keterangan']) && trim($a['keterangan']) !== '' ? trim($a['keterangan']) : null,
                ])
                ->values()
                ->all();
        }

        $hasil = DB::transaction(function () use ($event, $user, $jumlah, $metode, $namaTim, $anggota) {
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
                'metode' => $gratis ? 'gratis' : $metode,
                'status' => $gratis ? 'lunas' : 'menunggu_pembayaran',
                'nama_tim' => $namaTim,
                'anggota' => $anggota,
            ]);

            $event->increment('kuota_terjual', $jumlah);

            return ['registration' => $registration];
        });

        if (isset($hasil['error'])) {
            return response()->json(['message' => $hasil['error']], 422);
        }

        $registration = $hasil['registration'];

        // Pembayaran QRIS: order dibuat di PayKita setelah pendaftaran tersimpan.
        // Kalau gagal, pendaftaran dibatalkan supaya kuota kembali.
        if ($registration->metode === 'qris') {
            try {
                $order = $this->paykita->buatOrder($registration->total_harga, $registration->kode);
                $registration->update([
                    'paykita_order_id' => $order['id'],
                    'pay_amount' => $order['pay_amount'],
                    'qris' => $order['qris'] ?? null,
                    'checkout_url' => $order['checkout_url'] ?? null,
                    'expires_at' => $order['expires_at'] ?? null,
                ]);
            } catch (Throwable $e) {
                report($e);
                $this->batalkan($registration);

                return response()->json([
                    'message' => 'Pembayaran QRIS sedang tidak tersedia. Coba lagi sebentar.',
                ], 503);
            }
        }

        $registration = $registration->fresh()->load('event.organizer');

        return response()->json([
            'message' => match (true) {
                $registration->status === 'lunas' && $registration->nama_tim !== null => 'Tim berhasil didaftarkan.',
                $registration->status === 'lunas' => 'Pendaftaran berhasil. Tiketmu sudah aktif.',
                $registration->metode === 'qris' => 'Pendaftaran berhasil. Selesaikan pembayaran QRIS.',
                default => 'Pendaftaran berhasil. Silakan bayar tunai ke panitia.',
            },
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

        // Pesanan QRIS yang waktunya habis dicocokkan dengan PayKita supaya statusnya mutakhir.
        $items = $items->map(function (Registration $r) {
            $kedaluwarsa = $r->metode === 'qris'
                && $r->status === 'menunggu_pembayaran'
                && $r->expires_at?->isPast();

            return $kedaluwarsa ? $this->sinkron($r)->load('event.organizer') : $r;
        });

        return response()->json([
            'data' => $items->map->toApiArray()->values(),
        ]);
    }

    // READ: status terbaru satu tiket. Untuk QRIS, status dicocokkan dengan PayKita.
    public function status(Request $request, Registration $registration): JsonResponse
    {
        if ($registration->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Tiket tidak ditemukan.'], 404);
        }

        $registration = $this->sinkron($registration);

        return response()->json([
            'data' => $registration->load('event.organizer')->toApiArray(),
        ]);
    }

    // UPDATE: peserta membatalkan pendaftarannya
    public function cancel(Request $request, Registration $registration): JsonResponse
    {
        if ($registration->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Tiket tidak ditemukan.'], 404);
        }

        // Pembayaran QRIS yang sudah masuk atau sudah habis waktunya dicocokkan dulu dengan PayKita.
        $registration = $this->sinkron($registration);

        $bisaBatal = $registration->status === 'menunggu_pembayaran'
            || ($registration->status === 'lunas' && $registration->metode === 'gratis');

        if (! $bisaBatal) {
            return response()->json(['message' => 'Tiket ini tidak bisa dibatalkan.'], 422);
        }

        if ($registration->metode === 'qris' && $registration->paykita_order_id) {
            try {
                $this->paykita->batalkanOrder($registration->paykita_order_id);
            } catch (Throwable $e) {
                report($e);

                return response()->json(['message' => 'Pembatalan belum bisa diproses. Coba lagi sebentar.'], 422);
            }
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

    // Pembatalan dikunci per baris supaya kuota tidak dikembalikan dua kali
    // kalau dua permintaan datang bersamaan.
    private function batalkan(Registration $registration): void
    {
        DB::transaction(function () use ($registration) {
            $baris = Registration::whereKey($registration->id)->lockForUpdate()->first();

            if (! $baris || ! $baris->isAktif()) {
                return;
            }

            $baris->update(['status' => 'dibatalkan']);
            Event::whereKey($baris->event_id)->decrement('kuota_terjual', $baris->jumlah);
        });
    }

    // Cocokkan status pesanan QRIS dengan PayKita: paid -> lunas, expired/cancelled -> dibatalkan.
    private function sinkron(Registration $registration): Registration
    {
        if ($registration->status !== 'menunggu_pembayaran'
            || $registration->metode !== 'qris'
            || ! $registration->paykita_order_id) {
            return $registration;
        }

        try {
            $order = $this->paykita->ambilOrder($registration->paykita_order_id);
        } catch (Throwable $e) {
            report($e);

            return $registration;
        }

        $statusOrder = $order['status'] ?? null;

        DB::transaction(function () use ($registration, $statusOrder) {
            $baris = Registration::whereKey($registration->id)->lockForUpdate()->first();

            if (! $baris || $baris->status !== 'menunggu_pembayaran') {
                return;
            }

            if ($statusOrder === 'paid') {
                $baris->update(['status' => 'lunas']);
            } elseif (in_array($statusOrder, ['expired', 'cancelled'], true)) {
                $baris->update(['status' => 'dibatalkan']);
                Event::whereKey($baris->event_id)->decrement('kuota_terjual', $baris->jumlah);
            }
        });

        return $registration->fresh();
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
