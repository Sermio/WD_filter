import 'package:flutter/material.dart';

/// Small “eye” control on catalog tiles (skill tree nodes, item frames, etc.).
class CatalogInfoEyeButton extends StatelessWidget {
  const CatalogInfoEyeButton({
    super.key,
    required this.frameSize,
    required this.onPressed,
    this.tooltip = 'View details',
  });

  final double frameSize;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final side = (frameSize * 0.34).clamp(26.0, 34.0);
    final iconSize = (side * 0.55).clamp(14.0, 18.0);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(7),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
          highlightColor: Colors.white.withValues(alpha: 0.12),
          child: SizedBox(
            width: side,
            height: side,
            child: Icon(
              Icons.visibility_rounded,
              size: iconSize,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      ),
    );
  }
}
