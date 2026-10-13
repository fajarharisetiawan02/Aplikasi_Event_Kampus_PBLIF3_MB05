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

        $event = new Event($this->validated($request));
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

        $event->update($this->validated($request));

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
            'harga' => ['required', 'integer', 'min:0'],
            'kuota' => ['required', 'integer', 'min:1'],
            'status' => ['sometimes', 'in:draft,published,cancelled'],
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