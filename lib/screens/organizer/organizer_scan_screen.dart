
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/app_colors.dart';

class OrganizerScanScreen extends StatefulWidget {
  const OrganizerScanScreen({super.key});

  @override
  State<OrganizerScanScreen> createState() =>
      _OrganizerScanScreenState();
}

class _OrganizerScanScreenState
    extends State<OrganizerScanScreen> {
  final MobileScannerController _controller =
      MobileScannerController();

  bool _alreadyScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_alreadyScanned) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.isNotEmpty) {
        _alreadyScanned = true;
        _controller.stop();

        if (!mounted) return;

        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('QR Berhasil Dibaca'),
            content: SelectableText(
              'Isi QR:\n$value',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _alreadyScanned = false;
                  _controller.start();
                },
                child: const Text('Scan Lagi'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Tiket'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Container(
                color: const Color(0xFFF4F7FC),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.no_photography_outlined,
                        size: 60,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kamera tidak dapat dibuka',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorCode.message ??
                            'Periksa izin kamera perangkat atau browser.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _controller.start(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Bingkai panduan QR di atas preview kamera.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Arahkan kamera ke QR Code tiket peserta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
