/// Unidad que posee una habilidad concreta en el catálogo agregado.
class AbilityUnitRef {
  const AbilityUnitRef({
    required this.unitId,
    required this.displayName,
    required this.raceFolder,
    this.race,
  });

  final String unitId;
  final String displayName;
  final String raceFolder;
  final String? race;

  String get raceLabel {
    switch (race) {
      case 'humans':
        return 'Humans';
      case 'mutants':
        return 'Tribes';
      case 'aliens':
        return 'Aliens';
      default:
        return race ?? raceFolder;
    }
  }
}

/// Habilidad pasiva o activa deduplicada por nombre + tipo, con todas las unidades que la usan.
class CatalogAbility {
  const CatalogAbility({
    required this.name,
    required this.isActive,
    this.description,
    this.iconAtlas,
    this.iconCol,
    this.iconRow,
    this.iconAssetPathOverride,
    required this.usedByUnits,
  });

  final String name;
  final bool isActive;
  final String? description;
  final String? iconAtlas;
  final int? iconCol;
  final int? iconRow;
  final String? iconAssetPathOverride;
  final List<AbilityUnitRef> usedByUnits;

  bool get hasIcon => iconAtlas != null && iconCol != null && iconRow != null;

  String? get iconAssetPath {
    if (iconAssetPathOverride != null &&
        iconAssetPathOverride!.isNotEmpty) {
      return iconAssetPathOverride;
    }
    if (!hasIcon) {
      return null;
    }
    return 'assets/generated/ui_icons/$iconAtlas/r${iconRow}_c$iconCol.png';
  }

  String get typeLabel => isActive ? 'Active' : 'Passive';
}
