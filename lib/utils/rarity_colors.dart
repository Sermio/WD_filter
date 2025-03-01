import 'package:flutter/material.dart';

class RarityColors {
  // Método que devuelve un color basado en la rareza
  static Color getColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'gray':
        return Colors.grey;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.blue; // Color por defecto si no se encuentra la rareza
    }
  }
}
