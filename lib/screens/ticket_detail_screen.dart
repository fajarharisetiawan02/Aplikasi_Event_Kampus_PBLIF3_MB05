import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ticket_model.dart';
import '../utils/app_colors.dart';

class TicketDetailScreen extends StatelessWidget {
  final TicketModel ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  Color get _statusColor {
    switch (ticket.status) {
      case TicketStatus.aktif:
        return const Color(0xFF16A34A);
      case TicketStatus.digunakan:
        return Colors.grey;
      case TicketStatus.kadaluarsa:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Tiket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      ticket.eventImage,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        child: Icon(Icons.image_outlined, size: 50, color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          ticket.eventTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(ticket.statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor)),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200, width: 1), borderRadius: BorderRadius.circular(16)),
                          child: Opacity(
                            opacity: ticket.status == TicketStatus.aktif ? 1 : 0.35,
                            child: QrImageView(data: ticket.id, version: QrVersions.auto, size: 190, backgroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(ticket.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.textDark)),
                        const SizedBox(height: 4),
                        const Text('Tunjukkan QR ini ke panitia saat check-in', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _infoRow(Icons.calendar_today_outlined, 'Tanggal', ticket.eventDate),
                        const SizedBox(height: 12),
                        _infoRow(Icons.access_time_outlined, 'Waktu', ticket.eventTime),
                        const SizedBox(height: 12),
                        _infoRow(Icons.location_on_outlined, 'Lokasi', ticket.eventLocation),
                        const SizedBox(height: 12),
                        _infoRow(Icons.confirmation_number_outlined, 'Jenis Tiket', ticket.ticketType),
                        const SizedBox(height: 12),
                        _infoRow(Icons.payments_outlined, 'Harga', ticket.price),
                        const SizedBox(height: 12),
                        _infoRow(Icons.receipt_long_outlined, 'No. Pesanan', ticket.orderId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 10),
        Text('$label  ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ),
      ],
    );
  }
}