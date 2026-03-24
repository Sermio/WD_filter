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
    this.isStatusEffect = false,
    this.isDebuff,
    this.description,
    this.iconAtlas,
    this.iconCol,
    this.iconRow,
    this.iconAssetPathOverride,
    required this.usedByUnits,
  });

  final String name;
  final bool isActive;
  final bool isStatusEffect;
  final bool? isDebuff;
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

  List<String> get iconAssetPathCandidates {
    final out = <String>[];

    void addPath(String? atlas, int? row, int? col) {
      if (atlas == null || row == null || col == null) {
        return;
      }
      if (row < 0 || col < 0) {
        return;
      }
      final path = 'assets/generated/ui_icons/$atlas/r${row}_c$col.png';
      if (!out.contains(path)) {
        out.add(path);
      }
    }

    if (iconAssetPathOverride != null && iconAssetPathOverride!.isNotEmpty) {
      addPath(iconAtlas, iconRow, iconCol);
      if (!out.contains(iconAssetPathOverride!)) {
        out.insert(0, iconAssetPathOverride!);
      }
      return out;
    }

    if (!hasIcon || iconAtlas == null || iconRow == null || iconCol == null) {
      return out;
    }

    final atlas = iconAtlas!;
    final row = iconRow!;
    final col = iconCol!;

    if (atlas == 'buff_icons' || isStatusEffect) {
      if (row > 0 && col > 0) {
        addPath(atlas, row - 1, col - 1);
      }
      addPath(atlas, row, col);
      addPath(atlas, col, row);
      if (row > 0 && col > 0) {
        addPath(atlas, col - 1, row - 1);
      }
      return out;
    }

    addPath(atlas, row, col);
    return out;
  }

  String get typeKey {
    if (isStatusEffect) {
      return 'status';
    }
    return isActive ? 'active' : 'passive';
  }

  String get typeLabel {
    if (isStatusEffect) {
      return isDebuff == true ? 'Debuff' : 'Buff';
    }
    return isActive ? 'Active' : 'Passive';
  }
}
