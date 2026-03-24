import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/models/game_unit.dart';

class UnitsCatalog {
  UnitsCatalog._(this.units);

  final List<GameUnit> units;

  static Future<UnitsCatalog> load() async {
    final raw = await rootBundle.loadString(WorldshiftAssets.unitsCatalogFile);
    final list = jsonDecode(raw) as List<dynamic>;
    final byId = <String, GameUnit>{};
    for (final e in list) {
      final u = GameUnit.fromJson(e as Map<String, dynamic>);
      byId[u.id] = u;
    }
    try {
      final manualRaw =
          await rootBundle.loadString(WorldshiftAssets.unitsManualFile);
      final manualList = jsonDecode(manualRaw) as List<dynamic>;
      for (final e in manualList) {
        try {
          final u = GameUnit.fromJson(e as Map<String, dynamic>);
          byId[u.id] = u;
        } catch (err, st) {
          debugPrint(
            'UnitsCatalog: entrada manual ignorada (${e is Map ? e['id'] : e}): $err',
          );
          debugPrint('$st');
        }
      }
    } catch (e, st) {
      // Sin archivo o JSON inválido en builds antiguos; el resto del catálogo sigue valiendo.
      debugPrint('UnitsCatalog: no se pudo cargar ${WorldshiftAssets.unitsManualFile}: $e');
      debugPrint('$st');
    }
    final units = byId.values.toList()
      ..sort((a, b) {
        final rc = a.raceFolder.compareTo(b.raceFolder);
        if (rc != 0) return rc;
        return (a.displayName ?? a.id).compareTo(b.displayName ?? b.id);
      });
    return UnitsCatalog._(units);
  }

  List<GameUnit> filter({
    List<String>? raceFolders,
    String? search,
  }) {
    var result = units;
    if (raceFolders != null && raceFolders.isNotEmpty) {
      result = result
          .where((u) => raceFolders.contains(u.raceFolder))
          .toList();
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
