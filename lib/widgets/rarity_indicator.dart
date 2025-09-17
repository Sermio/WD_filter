import 'package:worldshift_filters/utils/utils.dart';
import 'package:flutter/material.dart';

class RarityIndicator extends StatelessWidget {
  const RarityIndicator({super.key, required this.rarity});

  final String rarity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            rarityToString(rarity).toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: getRarityColor(rarity),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
