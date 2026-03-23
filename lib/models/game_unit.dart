class GameUnitAbility {
  final String name;
  final String? description;
  final String? iconAtlas;
  final int? iconCol;
  final int? iconRow;
  final String? iconAssetPathOverride;

  const GameUnitAbility({
    required this.name,
    this.description,
    this.iconAtlas,
    this.iconCol,
    this.iconRow,
    this.iconAssetPathOverride,
  });

  bool get hasIcon => iconAtlas != null && iconCol != null && iconRow != null;

  String? get iconAssetPath {
    if (iconAssetPathOverride != null && iconAssetPathOverride!.isNotEmpty) {
      return iconAssetPathOverride;
    }
    if (!hasIcon) {
      return null;
    }
    return 'assets/generated/ui_icons/$iconAtlas/r${iconRow}_c$iconCol.png';
  }

  factory GameUnitAbility.fromJson(Map<String, dynamic> json) {
    return GameUnitAbility(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconAtlas: json['iconAtlas'] as String?,
      iconCol: (json['iconCol'] as num?)?.toInt(),
      iconRow: (json['iconRow'] as num?)?.toInt(),
      iconAssetPathOverride: json['iconAssetPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'iconAtlas': iconAtlas,
        'iconCol': iconCol,
        'iconRow': iconRow,
        'iconAssetPath': iconAssetPath,
      };
}

class GameUnitStatusEffect {
  final String name;
  final String? description;
  final bool? isDebuff;
  final String? iconAtlas;
  final int? iconCol;
  final int? iconRow;
  final String? iconAssetPathOverride;

  const GameUnitStatusEffect({
    required this.name,
    this.description,
    this.isDebuff,
    this.iconAtlas,
    this.iconCol,
    this.iconRow,
    this.iconAssetPathOverride,
  });

  bool get hasIcon => iconAtlas != null && iconCol != null && iconRow != null;

  String? get iconAssetPath {
    if (iconAssetPathOverride != null && iconAssetPathOverride!.isNotEmpty) {
      return iconAssetPathOverride;
    }
    if (!hasIcon) {
      return null;
    }
    return 'assets/generated/ui_icons/$iconAtlas/r${iconRow}_c$iconCol.png';
  }

  factory GameUnitStatusEffect.fromJson(Map<String, dynamic> json) {
    return GameUnitStatusEffect(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isDebuff: json['isDebuff'] as bool?,
      iconAtlas: json['iconAtlas'] as String?,
      iconCol: (json['iconCol'] as num?)?.toInt(),
      iconRow: (json['iconRow'] as num?)?.toInt(),
      iconAssetPathOverride: json['iconAssetPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'isDebuff': isDebuff,
        'iconAtlas': iconAtlas,
        'iconCol': iconCol,
        'iconRow': iconRow,
        'iconAssetPath': iconAssetPath,
      };
}

class GameUnit {
  final String id;
  final String raceFolder;
  final String? displayName;
  final String? race;
  final String? movementType;
  final String? tags;
  final String unitIconClass;
  final int? mainIconCol;
  final int? mainIconRow;
  final int? conversationIconCol;
  final int? conversationIconRow;
  final Map<String, String> stats;
  final List<String> auraNames;
  final List<GameUnitAbility> passiveAbilities;
  final List<GameUnitAbility> activeAbilities;
  final List<GameUnitStatusEffect> statusEffects;

  const GameUnit({
    required this.id,
    required this.raceFolder,
    this.displayName,
    this.race,
    this.movementType,
    this.tags,
    this.unitIconClass = 'unit',
    this.mainIconCol,
    this.mainIconRow,
    this.conversationIconCol,
    this.conversationIconRow,
    this.stats = const {},
    this.auraNames = const [],
    this.passiveAbilities = const [],
    this.activeAbilities = const [],
    this.statusEffects = const [],
  });

  String get raceLabel {
    switch (race) {
      case 'humans':
        return 'Humans';
      case 'mutants':
        return 'Tribes';
      case 'aliens':
        return 'Aliens';
      default:
        return race ?? '—';
    }
  }

  bool get hasMainAtlasIcon => mainIconCol != null && mainIconRow != null;

  List<String> get detailIconAssetCandidates {
    final candidates = <String>[];

    candidates.add('assets/generated/unit_icons/named/units/$id.png');

    if (unitIconClass == 'officer' || unitIconClass == 'commander') {
      candidates.add('assets/generated/unit_icons/named/officers/$id.png');
    }

    return candidates;
  }

  String get detailIconSourceLabel {
    switch (unitIconClass) {
      case 'officer':
        return 'officers-70x70.dds';
      case 'unit':
        return 'units-70x70.dds';
      case 'commander':
        return 'units consolidado';
      default:
        return 'desconocido';
    }
  }

  factory GameUnit.fromJson(Map<String, dynamic> json) {
    final statsRaw = json['stats'];
    final Map<String, String> stats = {};
    if (statsRaw is Map) {
      statsRaw.forEach((k, v) {
        stats['$k'] = '$v';
      });
    }
    final auras = json['auraNames'];
    final passiveAbilities = json['passiveAbilities'];
    final activeAbilities = json['activeAbilities'];
    final statusEffects = json['statusEffects'];
    return GameUnit(
      id: json['id'] as String,
      raceFolder: json['raceFolder'] as String? ?? '',
      displayName: json['displayName'] as String?,
      race: json['race'] as String?,
      movementType: json['movementType'] as String?,
      tags: json['tags'] as String?,
      unitIconClass: json['unitIconClass'] as String? ?? 'unit',
      mainIconCol: json['mainIconCol'] as int?,
      mainIconRow: json['mainIconRow'] as int?,
      conversationIconCol: json['conversationIconCol'] as int?,
      conversationIconRow: json['conversationIconRow'] as int?,
      stats: stats,
      auraNames: auras is List ? auras.map((e) => '$e').toList() : const [],
      passiveAbilities: passiveAbilities is List
          ? passiveAbilities
              .whereType<Map<String, dynamic>>()
              .map(GameUnitAbility.fromJson)
              .toList()
          : const [],
      activeAbilities: activeAbilities is List
          ? activeAbilities
              .whereType<Map<String, dynamic>>()
              .map(GameUnitAbility.fromJson)
              .toList()
          : const [],
      statusEffects: statusEffects is List
          ? statusEffects
              .whereType<Map<String, dynamic>>()
              .map(GameUnitStatusEffect.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'raceFolder': raceFolder,
        'displayName': displayName,
        'race': race,
        'movementType': movementType,
        'tags': tags,
        'unitIconClass': unitIconClass,
        'mainIconCol': mainIconCol,
        'mainIconRow': mainIconRow,
        'conversationIconCol': conversationIconCol,
        'conversationIconRow': conversationIconRow,
        'stats': stats,
        'auraNames': auraNames,
        'passiveAbilities':
            passiveAbilities.map((ability) => ability.toJson()).toList(),
        'activeAbilities':
            activeAbilities.map((ability) => ability.toJson()).toList(),
        'statusEffects': statusEffects.map((effect) => effect.toJson()).toList(),
      };
}
