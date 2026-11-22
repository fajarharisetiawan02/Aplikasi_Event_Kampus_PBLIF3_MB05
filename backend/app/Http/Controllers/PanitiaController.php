<?php

namespace App\Http\Controllers;

use App\Mail\PanitiaUndangan;
use App\Models\Event;
use App\Models\Panitia;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Throwable;

// Penyelenggara menambah panitia untuk event miliknya. Panitia hanya bisa scan tiket event itu.
class PanitiaController extends Controller
{
    private const MAKS_PER_EVENT = 20;

    // READ: daftar panitia sebuah event
    public function index(Request $request, Event $event): JsonResponse
    {
        if (! $this->canModify($request->user(), $event)) {
            return $this->forbidden();
        }

        $items = Panitia::with('user')->where('event_id', $event->id)->latest()->get();

        return response()->json([
            'data' => $items->map->toApiArray()->values(),
        ]);
    }

    // CREATE: tambah panitia, akun dibuat dengan password acak lalu undangan dikirim lewat email
    public function store(Request $request, Event $event): JsonResponse
    {
        $pembuat = $request->user();

        if (! $this->canModify($pembuat, $event)) {
            return $this->forbidden();
        }

        $data = $request->validate([
            'nama' => ['required', 'string', 'min:3', 'max:100'],
            'email' => ['required', 'email', 'max:100', 'unique:users,email'],
            'no_hp' => ['required', 'regex:/^[0-9]{9,13}$/'],
        ], [
            'email.unique' => 'Email ini sudah terdaftar.',
            'no_hp.regex' => 'Nomor telepon harus 9-13 angka.',
        ]);

        if (Panitia::where('event_id', $event->id)->count() >= self::MAKS_PER_EVENT) {
            return response()->json(['message' => 'Jumlah panitia event ini sudah mencapai batas.'], 422);
        }

        $password = $this->passwordAcak();

        $panitia = DB::transaction(function () use ($data, $event, $pembuat, $password) {
            $user = new User([
                'nama' => $data['nama'],
                'email' => strtolower($data['email']),
                'no_hp' => $data['no_hp'],
                'password' => $password,
            ]);
            $user->forceFill(['roles' => ['panitia'], 'is_admin' => false])->save();

            return Panitia::create([
                'user_id' => $user->id,
                'event_id' => $event->id,
                'dibuat_oleh' => $pembuat->id,
            ]);
        });

        $terkirim = $this->kirimUndangan($panitia->load('user', 'event'), $password);

        return response()->json([
            'message' => $terkirim
                ? 'Panitia ditambahkan. Password awal sudah dikirim ke email.'
                : 'Panitia ditambahkan, tetapi email gagal terkirim. Kirim ulang undangannya.',
            'email_terkirim' => $terkirim,
            'data' => $panitia->toApiArray(),
        ], 201);
    }

    // UPDATE: kirim ulang undangan (hanya untuk panitia yang belum aktif)
    public function kirimUlang(Request $request, Event $event, Panitia $panitia): JsonResponse
    {
        if (! $this->canModify($request->user(), $event)) {
            return $this->forbidden();
        }

        if ($panitia->event_id !== $event->id) {
            return response()->json(['message' => 'Panitia tidak ditemukan.'], 404);
        }

        if ($panitia->aktif_at) {
            return response()->json(['message' => 'Panitia ini sudah aktif.'], 422);
        }

        // Password lama tidak bisa dibaca lagi, jadi dibuat yang baru. Password lama otomatis tidak berlaku.
        $password = $this->passwordAcak();
        $panitia->user->update(['password' => $password]);
        $panitia->user->tokens()->delete();

        $terkirim = $this->kirimUndangan($panitia->load('user', 'event'), $password);

        return response()->json([
            'message' => $terkirim ? 'Password baru dikirim ke email.' : 'Email gagal terkirim. Coba kirim ulang lagi.',
            'email_terkirim' => $terkirim,
            'data' => $panitia->fresh()->load('user')->toApiArray(),
        ], $terkirim ? 200 : 502);
    }

    // DELETE: hapus panitia beserta akunnya
    public function destroy(Request $request, Event $event, Panitia $panitia): JsonResponse
    {
        if (! $this->canModify($request->user(), $event)) {
            return $this->forbidden();
        }

        if ($panitia->event_id !== $event->id) {
            return response()->json(['message' => 'Panitia tidak ditemukan.'], 404);
        }

        $user = $panitia->user;
        $user->tokens()->delete();
        $user->delete(); // baris panitia ikut terhapus (cascade)

        return response()->json(['message' => 'Panitia dihapus.']);
    }

    // Huruf yang mudah tertukar (0/O, 1/l/I) tidak dipakai supaya password mudah diketik dari email.
    private function passwordAcak(int $panjang = 10): string
    {
        $huruf = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
        $hasil = '';

        for ($i = 0; $i < $panjang; $i++) {
            $hasil .= $huruf[random_int(0, strlen($huruf) - 1)];
        }

        return $hasil;
    }

    private function kirimUndangan(Panitia $panitia, string $password): bool
    {
        try {
            Mail::to($panitia->user->email)->send(new PanitiaUndangan($panitia, $password));
        } catch (Throwable $e) {
            report($e);

            return false;
        }

        $panitia->forceFill(['undangan_dikirim_at' => now()])->save();

        return true;
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
        return response()->json(['message' => 'Kamu tidak punya akses untuk mengelola panitia event ini.'], 403);
    }
}
