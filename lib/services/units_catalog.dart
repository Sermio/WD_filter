import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/models/game_unit.dart';

class UnitsCatalog {
  UnitsCatalog._(this.units);

  final List<GameUnit> units;

  static Future<UnitsCatalog> load() async {
    final raw = await rootBundle.loadString(WorldshiftAssets.unitsCatalogFile);
    final list = jsonDecode(raw) as List<dynamic>;
    final units = list
        .map((e) => GameUnit.fromJson(e as Map<String, dynamic>))
        .toList();
    return UnitsCatalog._(units);
  }

  List<GameUnit> filter({
    String? raceFolder,
    String? search,
  }) {
    var result = units;
    if (raceFolder != null && raceFolder.isNotEmpty) {
      result =
          result.where((u) => u.raceFolder == raceFolder).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      result = result
          .where((u) =>
              u.id.toLowerCase().contains(q) ||
              (u.displayName ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  }
}
