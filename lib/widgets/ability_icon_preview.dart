import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worldshift_assistant/data/ability_icon_fallbacks.dart';

/// Icono de habilidad: intenta el path principal y, si falla o no hay, un PNG del atlas
/// pasivo o activo ([AbilityIconFallbacks]); el icono de Material solo si todo falla.
class AbilityIconPreview extends StatelessWidget {
  const AbilityIconPreview({
    super.key,
    required this.assetPath,
    this.size = 40,
    this.fallbackKind,
  });

  final String? assetPath;
  final double size;

  /// Si es null, no se añade PNG de respaldo (p. ej. buffs/debuffs).
  final AbilityIconFallbackKind? fallbackKind;

  List<String> _candidates() {
    final list = <String>[];
    final p = assetPath?.trim();
    if (p != null && p.isNotEmpty) {
      list.add(p);
    }
    switch (fallbackKind) {
      case AbilityIconFallbackKind.passive:
        list.add(AbilityIconFallbacks.passivePng);
        break;
      case AbilityIconFallbackKind.active:
        list.add(AbilityIconFallbacks.activePng);
        break;
      case null:
        break;
    }
    return list;
  }

  Future<String?> _resolve(List<String> candidates) async {
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
    final candidates = _candidates();
    if (candidates.isEmpty) {
      return _materialPlaceholder();
    }

    return FutureBuilder<String?>(
      future: _resolve(candidates),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return _materialPlaceholder();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size,
            height: size,
            color: const Color(0xFFE2E8F0),
            child: Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _materialPlaceholder(),
            ),
          ),
        );
      },
    );
  }

  Widget _materialPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.auto_awesome_outlined,
        size: size * 0.55,
        color: const Color(0xFF64748B),
      ),
    );
  }
}
