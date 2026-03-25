import 'package:flutter/material.dart';

/// Franja vertical izquierda (estilo listados / builder) con gradiente.
///
/// Colores de raza: tonos **más claros** que `chipSide`, inspirados en el chip
/// **seleccionado** del builder (`chipSelected`) mezclados hacia acentos claros
/// (p. ej. `chipLabelSelected` / blanco) para que se distingan bien en cards claras.
abstract final class CatalogCardStripe {
  CatalogCardStripe._();

  static const double width = 5;

  static (Color top, Color bottom) _raceStripeColors(String raceLabel) {
    switch (raceLabel) {
      case 'Humans':
        return (const Color(0xFF5E7194), const Color(0xFFB8CAF0));
      case 'Tribes':
        return (const Color(0xFFB8824A), const Color(0xFFF2D9B8));
      case 'Aliens':
        return (const Color(0xFF2E9B68), const Color(0xFF8CF0C8));
      case 'Bosses':
        return (const Color(0xFF8B2942), const Color(0xFFF0B8C8));
      default:
        return (const Color(0xFF7B8794), const Color(0xFFD1D9E3));
    }
  }

  /// Tono principal de la franja (mismo que el superior del gradiente).
  static Color accentForRaceLabel(String raceLabel) =>
      _raceStripeColors(raceLabel).$1;

  /// Gradientes por raza: arriba = tono medio-saturado; abajo = highlight claro.
  static Widget forRaceLabel(String raceLabel) {
    final (top, bottom) = _raceStripeColors(raceLabel);
    return verticalGradient(top, bottom);
  }

  static Widget verticalGradient(Color top, Color bottom) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
    );
  }

  static Widget forRarityColor(Color rarityColor) {
    return verticalGradient(
      rarityColor,
      Color.alphaBlend(rarityColor.withValues(alpha: 0.55), Colors.white),
    );
  }

  static const Color _genericMid = Color(0xFF7B8794);
  static const Color _genericEnd = Color(0xFFC9D2DC);

  /// Habilidades compartidas por varias razas / sin raza única.
  static Widget forAbilityGeneric() {
    return verticalGradient(_genericMid, _genericEnd);
  }
}
