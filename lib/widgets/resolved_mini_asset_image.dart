import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Prueba candidatos en el bundle hasta que uno exista (iconos 16×16 típicos en chips).
class ResolvedMiniAssetImage extends StatelessWidget {
  const ResolvedMiniAssetImage({
    super.key,
    required this.candidates,
    this.size = 16,
    this.borderRadius = 4,
    this.fallbackIcon = Icons.category_outlined,
    this.fallbackColor = const Color(0xFF5E6678),
  });

  final List<String> candidates;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;
  final Color fallbackColor;

  Future<String?> _resolve() async {
    for (final path in candidates) {
      try {
        await rootBundle.load(path);
        return path;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolve(),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return Icon(
            fallbackIcon,
            size: size * 0.875,
            color: fallbackColor,
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.asset(
            path,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
