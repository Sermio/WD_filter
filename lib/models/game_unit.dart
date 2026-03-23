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
      };
}
