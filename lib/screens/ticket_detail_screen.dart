import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ticket_model.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';
import '../utils/app_colors.dart';
import '../widgets/event_image.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late TicketModel _ticket = widget.ticket;
  bool _cancelling = false;

  Color get _statusColor {
    switch (_ticket.status) {
      case TicketStatus.aktif:
        return const Color(0xFF16A34A);
      case TicketStatus.menunggu:
        return AppColors.accentOrange;
      case TicketStatus.digunakan:
        return Colors.grey;
      case TicketStatus.kadaluarsa:
      case TicketStatus.dibatalkan:
        return Colors.red;
    }
  }

  Future<void> _cancel() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan Pendaftaran'),
        content: const Text('Pendaftaran ini akan dibatalkan dan kuota dikembalikan. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Tidak')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (yakin != true) return;

    setState(() => _cancelling = true);

    try {
      final updated = await TicketService.cancel(_ticket.registrationId);
      if (!mounted) return;
      setState(() => _ticket = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran dibatalkan')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    final aktif = ticket.status == TicketStatus.aktif;

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
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  EventImage(url: ticket.eventImage, height: 150, width: double.infinity),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          ticket.eventTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ticket.statusLabel,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Opacity(
                            opacity: aktif ? 1 : 0.3,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                QrImageView(
                                  data: ticket.id,
                                  version: 4,
                                  size: 190,
                                  backgroundColor: Colors.white,
                                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFD9DEE5)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset('assets/images/logo.png'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          ticket.id,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hint(ticket),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _infoRow(Icons.calendar_today_outlined, 'Tanggal', ticket.eventDate),
                        const SizedBox(height: 12),
                        _infoRow(Icons.access_time_outlined, 'Waktu', ticket.eventTime),
                        const SizedBox(height: 12),
                        _infoRow(Icons.location_on_outlined, 'Lokasi', ticket.eventLocation),
                        const SizedBox(height: 12),
                        _infoRow(Icons.confirmation_number_outlined, 'Jumlah Tiket', '${ticket.jumlah}'),
                        const SizedBox(height: 12),
                        _infoRow(Icons.payments_outlined, 'Total', ticket.totalLabel),
                        const SizedBox(height: 12),
                        _infoRow(
                          Icons.account_balance_wallet_outlined,
                          'Pembayaran',
                          ticket.metode == 'gratis' ? 'Gratis' : 'Tunai ke panitia',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (ticket.bisaDibatalkan) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: _cancelling ? null : _cancel,
                  child: _cancelling
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Batalkan Pendaftaran'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _hint(TicketModel ticket) {
    switch (ticket.status) {
      case TicketStatus.aktif:
        return 'Tunjukkan QR ini ke panitia saat check-in';
      case TicketStatus.menunggu:
        return 'Bayar tunai ke panitia. QR aktif setelah pembayaran dikonfirmasi';
      case TicketStatus.digunakan:
        return 'Tiket ini sudah digunakan untuk check-in';
      case TicketStatus.kadaluarsa:
        return 'Acara sudah lewat';
      case TicketStatus.dibatalkan:
        return 'Pendaftaran ini sudah dibatalkan';
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 10),
        Text('$label  ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }
}