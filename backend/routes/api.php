<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\RegistrationController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

Route::get('/events', [EventController::class, 'index']);
Route::get('/events/{event}', [EventController::class, 'show'])->whereNumber('event');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);
    Route::delete('/profile', [AuthController::class, 'destroy']);
    Route::put('/password', [AuthController::class, 'changePassword']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/my-events', [EventController::class, 'mine']);
    Route::post('/events', [EventController::class, 'store']);
    Route::put('/events/{event}', [EventController::class, 'update'])->whereNumber('event');
    Route::delete('/events/{event}', [EventController::class, 'destroy'])->whereNumber('event');

    Route::post('/events/{event}/register', [RegistrationController::class, 'store'])->whereNumber('event');
    Route::get('/my-tickets', [RegistrationController::class, 'mine']);
    Route::post('/tickets/{registration}/cancel', [RegistrationController::class, 'cancel'])->whereNumber('registration');

    Route::get('/events/{event}/participants', [RegistrationController::class, 'participants'])->whereNumber('event');
    Route::put('/tickets/{registration}/status', [RegistrationController::class, 'updateStatus'])->whereNumber('registration');
});
