<!DOCTYPE html>
<html lang="id">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body style="margin:0;background:#F1F4F9;font-family:Arial,Helvetica,sans-serif;color:#0F172A;">
  <div style="max-width:480px;margin:0 auto;padding:24px 16px;">
    <div style="background:#ffffff;border-radius:12px;padding:28px;">
      <div style="font-size:20px;font-weight:bold;color:#1565E0;margin-bottom:16px;">EventIn</div>
      <p style="font-size:15px;margin:0 0 12px;">Halo {{ $panitia->user->nama }},</p>
      <p style="font-size:14px;line-height:1.6;margin:0 0 16px;">
        Kamu diundang menjadi panitia untuk event <b>{{ $panitia->event->judul }}</b>
        ({{ $panitia->event->tanggal?->format('d-m-Y') }}, {{ $panitia->event->lokasi }}).
        Sebagai panitia, kamu bertugas memindai QR tiket peserta di aplikasi EventIn.
      </p>
      <p style="font-size:14px;margin:0 0 8px;">Masuk ke aplikasi EventIn memakai akun berikut:</p>
      <div style="background:#F5F8FF;border-radius:10px;padding:14px 16px;margin-bottom:16px;">
        <div style="font-size:12px;color:#64748B;">Email</div>
        <div style="font-size:14px;font-weight:bold;margin-bottom:10px;">{{ $panitia->user->email }}</div>
        <div style="font-size:12px;color:#64748B;">Password awal</div>
        <div style="font-size:18px;font-weight:bold;letter-spacing:1px;font-family:'Courier New',monospace;color:#1565E0;">{{ $password }}</div>
      </div>
      <p style="font-size:13px;line-height:1.6;margin:0;">
        Akun ini hanya bisa dipakai untuk memindai tiket event tersebut.
      </p>
      <p style="font-size:12px;color:#64748B;margin:16px 0 0;">Jangan bagikan email ini ke orang lain. Abaikan kalau kamu tidak merasa diundang.</p>
    </div>
  </div>
</body>
</html>
