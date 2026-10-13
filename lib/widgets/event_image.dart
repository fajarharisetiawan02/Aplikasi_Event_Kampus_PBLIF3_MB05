import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// banner_url bisa berupa URL (http...) atau path asset (assets/images/...).
class EventImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const EventImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryBlue.withValues(alpha: 0.1),
      child: const Icon(Icons.image_outlined, color: AppColors.primaryBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = url;
    if (path == null || path.isEmpty) return _placeholder();

    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }
}
