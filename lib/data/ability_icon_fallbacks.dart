/// Iconos genéricos del juego (atlas) solo si falla el path concreto de la habilidad.
abstract final class AbilityIconFallbacks {
  /// Celda 0,0 de `passive_abilities` (varias pasivas comparten tile en el DDS).
  static const String passivePng =
      'assets/generated/ui_icons/passive_abilities/r0_c0.png';

  /// Celda 0,0 de `buttons` (acciones activas).
  static const String activePng =
      'assets/generated/ui_icons/buttons/r0_c0.png';
}

/// Qué imagen de respaldo usar tras fallar el asset principal.
enum AbilityIconFallbackKind {
  passive,
  active,
}
