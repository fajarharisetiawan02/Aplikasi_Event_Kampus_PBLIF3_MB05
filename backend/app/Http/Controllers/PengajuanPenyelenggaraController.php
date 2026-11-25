<?php

namespace App\Http\Controllers;

use App\Models\Panitia;
use App\Models\PengajuanPenyelenggara;
use App\Models\Registration;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

// Mahasiswa mengajukan diri menjadi penyelenggara (atas nama organisasi), admin menyetujui,
// menolak, atau mencabut. Satu akun, dan setelah disetujui akun hanya dipakai di mode penyelenggara.
class PengajuanPenyelenggaraController extends Controller
{
    // CREATE: mahasiswa mengajukan diri
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'organisasi' => ['required', 'string', 'min:3', 'max:100'],
            'jabatan' => ['required', 'string', 'min:2', 'max:60'],
            'bukti_url' => ['nullable', 'string', 'max:500'],
        ], [
            'organisasi.min' => 'Nama organisasi minimal 3 karakter.',
            'jabatan.min' => 'Jabatan minimal 2 karakter.',
        ]);

        if ($user->is_admin || $user->isPenyelenggara()) {
            return response()->json(['message' => 'Akunmu sudah bisa membuat event.'], 422);
        }

        if ($user->isPanitia()) {
            return response()->json(['message' => 'Akun panitia tidak bisa mengajukan diri sebagai penyelenggara.'], 403);
        }

        if ($user->pengajuanPenyelenggara()->where('status', 'menunggu')->exists()) {
            return response()->json(['message' => 'Pengajuanmu masih menunggu persetujuan admin.'], 422);
        }

        if ($pesan = $this->pesanTiketAktif($user)) {
            return response()->json(['message' => $pesan], 422);
        }

        $pengajuan = new PengajuanPenyelenggara($data);
        $pengajuan->user_id = $user->id;
        $pengajuan->save();

        return response()->json([
            'message' => 'Pengajuan terkirim. Admin akan memeriksanya.',
            'data' => $pengajuan->toApiArray(),
        ], 201);
    }

    // CREATE: unggah bukti (foto surat tugas atau SK pengurus)
    public function uploadBukti(Request $request): JsonResponse
    {
        $request->validate([
            'bukti' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ], [
            'bukti.image' => 'File harus berupa gambar.',
            'bukti.mimes' => 'Format gambar harus JPG, PNG, atau WEBP.',
            'bukti.max' => 'Ukuran gambar maksimal 2 MB.',
        ]);

        $path = $request->file('bukti')->store('bukti-penyelenggara', 'public');

        return response()->json([
            'message' => 'Bukti berhasil diunggah.',
            'data' => ['bukti_url' => url('storage/' . $path)],
        ], 201);
    }

    // READ (admin): daftar pengajuan, bisa difilter menurut status
    public function index(Request $request): JsonResponse
    {
        if (! $request->user()->is_admin) {
            return $this->forbidden();
        }

        $query = PengajuanPenyelenggara::with('user')->latest('id');

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        return response()->json([
            'data' => $query->get()->map(fn ($p) => $p->toApiArray(true))->values(),
        ]);
    }

    // UPDATE (admin): setujui, pemohon mendapat role penyelenggara
    public function setujui(Request $request, PengajuanPenyelenggara $pengajuan): JsonResponse
    {
        if (! $request->user()->is_admin) {
            return $this->forbidden();
        }

        if ($pengajuan->status !== 'menunggu') {
            return response()->json(['message' => 'Hanya pengajuan yang menunggu yang bisa disetujui.'], 422);
        }

        $pemohon = $pengajuan->user;

        // Tiket bisa saja dibeli setelah pengajuan dikirim, jadi dicek lagi saat disetujui.
        if ($pesan = $this->pesanTiketAktif($pemohon, true)) {
            return response()->json(['message' => $pesan], 422);
        }

        DB::transaction(function () use ($pengajuan, $pemohon, $request) {
            $roles = $pemohon->roles ?? ['user'];
            if (! in_array('event_organizer', $roles, true)) {
                $roles[] = 'event_organizer';
            }
            $pemohon->forceFill(['roles' => array_values($roles)])->save();

            $this->putuskan($pengajuan, 'disetujui', $request->user(), null);
        });

        return response()->json([
            'message' => $pemohon->nama . ' kini menjadi penyelenggara.',
            'data' => $pengajuan->fresh('user')->toApiArray(true),
        ]);
    }

    // UPDATE (admin): tolak, alasan wajib
    public function tolak(Request $request, PengajuanPenyelenggara $pengajuan): JsonResponse
    {
        if (! $request->user()->is_admin) {
            return $this->forbidden();
        }

        $data = $request->validate(['alasan' => ['required', 'string', 'min:3', 'max:500']]);

        if ($pengajuan->status !== 'menunggu') {
            return response()->json(['message' => 'Hanya pengajuan yang menunggu yang bisa ditolak.'], 422);
        }

        $this->putuskan($pengajuan, 'ditolak', $request->user(), $data['alasan']);

        return response()->json([
            'message' => 'Pengajuan ditolak.',
            'data' => $pengajuan->fresh('user')->toApiArray(true),
        ]);
    }

    // UPDATE (admin): cabut role penyelenggara. Akun kembali menjadi mahasiswa biasa
    // dan akun panitia dari event miliknya dinonaktifkan.
    public function cabut(Request $request, PengajuanPenyelenggara $pengajuan): JsonResponse
    {
        if (! $request->user()->is_admin) {
            return $this->forbidden();
        }

        $data = $request->validate(['alasan' => ['required', 'string', 'min:3', 'max:500']]);

        if ($pengajuan->status !== 'disetujui') {
            return response()->json(['message' => 'Hanya penyelenggara yang sudah disetujui yang bisa dicabut.'], 422);
        }

        $pemohon = $pengajuan->user;

        DB::transaction(function () use ($pengajuan, $pemohon, $request, $data) {
            $roles = array_values(array_filter($pemohon->roles ?? ['user'], fn ($r) => $r !== 'event_organizer'));
            $pemohon->forceFill(['roles' => $roles ?: ['user']])->save();

            $this->putuskan($pengajuan, 'dicabut', $request->user(), $data['alasan']);

            $panitia = Panitia::whereHas('event', fn ($q) => $q->where('organizer_id', $pemohon->id))->get();
            foreach ($panitia as $p) {
                $p->forceFill(['nonaktif_at' => now()])->save();
                $p->user->tokens()->delete();
            }
        });

        return response()->json([
            'message' => $pemohon->nama . ' kembali menjadi mahasiswa biasa.',
            'data' => $pengajuan->fresh('user')->toApiArray(true),
        ]);
    }

    private function putuskan(PengajuanPenyelenggara $pengajuan, string $status, User $admin, ?string $alasan): void
    {
        $pengajuan->forceFill([
            'status' => $status,
            'alasan' => $alasan,
            'diputuskan_oleh' => $admin->id,
            'diputuskan_at' => now(),
        ])->save();
    }

    // Mahasiswa yang masih punya tiket aktif (belum lunas atau lunas untuk event yang belum lewat)
    // belum boleh menjadi penyelenggara, karena akun penyelenggara tidak punya tampilan peserta.
    private function pesanTiketAktif(User $user, bool $untukAdmin = false): ?string
    {
        $tiket = Registration::with('event')
            ->where('user_id', $user->id)
            ->whereIn('status', Registration::AKTIF)
            ->whereHas('event', fn ($q) => $q->whereDate('tanggal', '>=', today()))
            ->first();

        if (! $tiket) {
            return null;
        }

        $subjek = $untukAdmin ? $user->nama . ' masih' : 'Kamu masih';

        return "$subjek punya tiket untuk event \"{$tiket->event->judul}\" yang belum selesai. "
            . ($untukAdmin
                ? 'Pengajuan bisa disetujui setelah acara itu selesai atau pendaftarannya dibatalkan.'
                : 'Pengajuan bisa dilakukan setelah acaranya selesai atau pendaftaranmu dibatalkan.');
    }

    private function forbidden(): JsonResponse
    {
        return response()->json(['message' => 'Hanya admin yang boleh melakukan ini.'], 403);
    }
}
