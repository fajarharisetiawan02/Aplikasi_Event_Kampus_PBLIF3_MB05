<?php

namespace App\Http\Controllers;

use App\Models\Event;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EventController extends Controller
{
    private const KATEGORI = ['Musik', 'Olahraga', 'Seminar', 'Seni', 'Teknologi'];

    // READ: daftar event yang tayang (semua pengguna)
    public function index(Request $request): JsonResponse
    {
        $query = Event::with('organizer')->where('status', 'published')->orderBy('tanggal');

        if ($request->filled('kategori')) {
            $query->where('kategori', $request->kategori);
        }

        if ($request->filled('q')) {
            $query->where('judul', 'like', '%' . $request->q . '%');
        }

        return response()->json([
            'data' => $query->get()->map->toApiArray()->values(),
        ]);
    }

    // READ: detail satu event
    public function show(Event $event): JsonResponse
    {
        if ($event->status !== 'published') {
            return response()->json(['message' => 'Event tidak ditemukan.'], 404);
        }

        return response()->json(['data' => $event->load('organizer')->toApiArray()]);
    }

    // READ: event milik EO yang sedang login (admin melihat semua)
    public function mine(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $this->canManage($user)) {
            return $this->forbidden();
        }

        $query = Event::with('organizer')->latest();

        if (! $user->is_admin) {
            $query->where('organizer_id', $user->id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        return response()->json([
            'data' => $query->get()->map->toApiArray()->values(),
        ]);
    }

    // CREATE
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $this->canManage($user)) {
            return $this->forbidden();
        }

        $data = $this->validated($request);
        $data['status'] = $this->statusBaru($user, null, $data['status'] ?? null);

        $event = new Event($data);
        $event->organizer_id = $user->id;
        $event->save();

        return response()->json([
            'message' => 'Event berhasil dibuat.',
            'data' => $event->load('organizer')->toApiArray(),
        ], 201);
    }

    // UPDATE
    public function update(Request $request, Event $event): JsonResponse
    {
        if (! $this->canModify($request->user(), $event)) {
            return $this->forbidden();
        }

        $data = $this->validated($request);
        $data['status'] = $this->statusBaru($request->user(), $event, $data['status'] ?? null);

        // Diajukan ulang setelah ditolak: alasan lama dihapus.
        if ($data['status'] !== 'rejected') {
            $data['alasan_penolakan'] = null;
        }

        $event->forceFill($data)->save();

        return response()->json([
            'message' => 'Event berhasil diperbarui.',
            'data' => $event->load('organizer')->toApiArray(),
        ]);
    }

    // DELETE
    public function destroy(Request $request, Event $event): JsonResponse
    {
        if (! $this->canModify($request->user(), $event)) {
            return $this->forbidden();
        }

        $event->delete();

        return response()->json(['message' => 'Event berhasil dihapus.']);
    }

    // Unggah gambar banner. Hasilnya berupa URL yang dikirim lagi lewat field banner_url saat simpan event.
    public function uploadBanner(Request $request): JsonResponse
    {
        if (! $this->canManage($request->user())) {
            return $this->forbidden();
        }

        $request->validate([
            'banner' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ], [
            'banner.image' => 'File harus berupa gambar.',
            'banner.mimes' => 'Format gambar harus JPG, PNG, atau WEBP.',
            'banner.max' => 'Ukuran gambar maksimal 2 MB.',
        ]);

        $path = $request->file('banner')->store('banners', 'public');

        return response()->json([
            'message' => 'Banner berhasil diunggah.',
            'data' => ['banner_url' => url('api/banners/' . basename($path))],
        ], 201);
    }

    // ADMIN: setujui event yang menunggu (atau yang sebelumnya ditolak)
    public function approve(Request $request, Event $event): JsonResponse
    {
        if (! $request->user()->is_admin) {
            return $this->forbidden();
        }

        if (! in_array($event->status, ['pending', 'rejected'], true)) {
            return response()->json(['message' => 'Hanya event yang menunggu persetujuan yang bisa disetujui.'], 422);
        }

        $event->forceFill(['status' => 'published', 'alasan_penolakan' => null])->save();

        return response()->json([
            'message' => 'Event disetujui dan sudah tampil ke mahasiswa.',
            'data' => $event->load('organizer')->toApiArray(),
        ]);
    }

    // ADMIN: tolak event yang menunggu, alasan wajib diisi
    public function reject(Request $request, Event $event): JsonResponse
    {
        if (! $request->user()->is_admin) {
            return $this->forbidden();
        }

        $data = $request->validate([
            'alasan' => ['required', 'string', 'min:3', 'max:500'],
        ]);

        if ($event->status !== 'pending') {
            return response()->json(['message' => 'Hanya event yang menunggu persetujuan yang bisa ditolak.'], 422);
        }

        $event->forceFill(['status' => 'rejected', 'alasan_penolakan' => $data['alasan']])->save();

        return response()->json([
            'message' => 'Event ditolak.',
            'data' => $event->load('organizer')->toApiArray(),
        ]);
    }

    // Penyelenggara tidak boleh menerbitkan sendiri: event baru selalu menunggu admin.
    // Event yang sudah tayang tetap tayang saat diedit. Admin bebas menentukan status.
    private function statusBaru(User $user, ?Event $event, ?string $diminta): string
    {
        if ($user->is_admin) {
            return $diminta ?? $event?->status ?? 'published';
        }

        if ($event && $diminta === 'cancelled') {
            return 'cancelled';
        }

        if ($event?->status === 'published') {
            return 'published';
        }

        $diminta ??= $event?->status === 'draft' ? 'draft' : 'pending';

        return $diminta === 'draft' ? 'draft' : 'pending';
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'judul' => ['required', 'string', 'min:3', 'max:150'],
            'deskripsi' => ['required', 'string'],
            'kategori' => ['required', 'in:' . implode(',', self::KATEGORI)],
            'banner_url' => ['nullable', 'string', 'max:500'],
            'tanggal' => ['required', 'date'],
            'waktu' => ['nullable', 'string', 'max:50'],
            'lokasi' => ['required', 'string', 'max:150'],
            'alamat' => ['nullable', 'string', 'max:255'],
            'narahubung' => ['nullable', 'string', 'max:100'],
            'narahubung_telepon' => ['nullable', 'string', 'max:20', 'regex:/^[0-9+\-\s]+$/'],
            'harga' => ['required', 'integer', 'min:0'],
            'kuota' => ['required', 'integer', 'min:1'],
            'status' => ['sometimes', 'in:draft,pending,published,rejected,cancelled'],
        ]);
    }

    private function canManage(User $user): bool
    {
        return $user->is_admin || in_array('event_organizer', $user->roles ?? [], true);
    }

    private function canModify(User $user, Event $event): bool
    {
        return $user->is_admin || ($this->canManage($user) && $event->organizer_id === $user->id);
    }

    private function forbidden(): JsonResponse
    {
        return response()->json(['message' => 'Kamu tidak punya akses untuk mengelola event.'], 403);
    }
}