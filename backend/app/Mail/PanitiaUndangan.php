<?php

namespace App\Mail;

use App\Models\Panitia;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class PanitiaUndangan extends Mailable
{
    public function __construct(public Panitia $panitia, public string $password)
    {
    }

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Undangan menjadi panitia ' . $this->panitia->event->judul);
    }

    public function content(): Content
    {
        return new Content(view: 'emails.undangan-panitia');
    }
}
