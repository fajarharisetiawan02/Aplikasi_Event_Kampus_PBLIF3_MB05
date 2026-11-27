<?php

return [
    'base_url' => env('PAYKITA_BASE_URL', 'https://pay.digikita.id/api'),
    'api_key' => env('PAYKITA_API_KEY'),
    // Masa aktif pesanan QRIS dalam detik (60 sampai 86400).
    'ttl' => (int) env('PAYKITA_TTL', 900),
];
