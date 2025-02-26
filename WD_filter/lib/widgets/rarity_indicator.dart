import 'package:adv_basics/utils/utils.dart';
import 'package:flutter/material.dart';

class RarityIndicator extends StatelessWidget {
  const RarityIndicator({super.key, required this.rarity});

  final String rarity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(rarityToString(context, rarity).toUpperCase()),
        const SizedBox(width: 10),
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: getRarityColor(rarity),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
