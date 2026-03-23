import 'package:worldshift_assistant/utils/utils.dart';
import 'package:flutter/material.dart';

class RarityIndicator extends StatelessWidget {
  const RarityIndicator({super.key, required this.rarity});

  final String rarity;

  @override
  Widget build(BuildContext context) {
    final color = getRarityColor(rarity);
    final isBright = color.computeLuminance() > 0.6;
    final textColor = Color.alphaBlend(
      Colors.black.withValues(alpha: isBright ? 0.72 : 0.58),
      color,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isBright ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: color.withValues(alpha: isBright ? 0.14 : 0.2),
              ),
            ),
            child: Text(
              rarityToString(rarity),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
