<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    // CREATE: register
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'min:3', 'max:100'],
            'nim' => ['required', 'regex:/^[0-9]{6,15}$/', 'unique:users,nim'],
            'email' => ['required', 'email', 'max:100', 'unique:users,email'],
            'no_hp' => ['required', 'regex:/^[0-9]{9,13}$/'],
            'password' => ['required', 'string', 'min:6'],
        ]);

        $data['email'] = strtolower($data['email']);

        $user = User::create($data);
        $user->forceFill(['roles' => ['user']])->save();

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'message' => 'Akun berhasil dibuat.',
            'data' => $user->toApiArray($token),
        ], 201);
    }

    // READ: login
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', strtolower($request->email))->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Email atau password salah.'], 401);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil.',
            'data' => $user->toApiArray($token),
        ]);
    }

    // READ: lihat profil
    public function profile(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $request->user()->toApiArray(),
        ]);
    }

    // UPDATE: edit profil
    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'nama' => ['required', 'string', 'min:3', 'max:100'],
            'nim' => ['required', 'regex:/^[0-9]{6,15}$/', Rule::unique('users', 'nim')->ignore($user->id)],
            'no_hp' => ['required', 'regex:/^[0-9]{9,13}$/'],
        ]);

        $user->update($data);

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'data' => $user->toApiArray(),
        ]);
    }

    // UPDATE: ganti password
    public function changePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'min:6', 'different:current_password'],
        ]);

        $user = $request->user();

        if (! Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Password lama salah.',
                'errors' => ['current_password' => ['Password lama salah.']],
            ], 422);
        }

        $user->update(['password' => $request->new_password]);

        // token di perangkat lain dicabut, token yang sedang dipakai tetap hidup
        $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();

        return response()->json(['message' => 'Password berhasil diganti.']);
    }

    // DELETE: hapus akun
    public function destroy(Request $request): JsonResponse
    {
        $request->validate(['password' => ['required', 'string']]);

        $user = $request->user();

        if (! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Password salah.',
                'errors' => ['password' => ['Password salah.']],
            ], 422);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'Akun berhasil dihapus.']);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Berhasil keluar.']);
    }
}
