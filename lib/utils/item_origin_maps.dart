import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/data/map_mission_meta.dart';
import 'package:worldshift_assistant/data/worldshift_assets.dart';

int? _parseItemId(dynamic raw) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse('$raw');
}

/// Convierte una cadena de ubicación del loot (p. ej. `JY - Gorgar`) al nombre
/// mostrado en [maps] (p. ej. `Junkyard`), igual que `parseLootFile1`.
String? mapDisplayValueFromLocation(String location) {
  final loc = location.trim();
  if (loc.isEmpty) {
    return null;
  }
  for (final mapEntry in maps) {
    final key = mapEntry['key'] ?? '';
    if (key.isNotEmpty && loc.startsWith(key)) {
      return mapEntry['value'];
    }
  }
  return null;
}

void _addHintsFromOrigin(Map<String, dynamic> origin, Set<String> out) {
  final mapName = '${origin['mapName'] ?? ''}'.trim();
  if (mapName.isNotEmpty) {
    out.add(mapName);
  }
  final mapKey = '${origin['mapKey'] ?? ''}'.trim();
  if (mapKey.isNotEmpty) {
    for (final m in maps) {
      if (m['key'] == mapKey) {
        final v = m['value'];
        if (v != null && v.isNotEmpty) {
          out.add(v);
        }
      }
    }
  }
  final ctx = '${origin['contextLabel'] ?? ''}'.trim();
  final fromCtx = mapDisplayValueFromLocation(ctx);
  if (fromCtx != null) {
    out.add(fromCtx);
  }
}

void _addHintsFromDirectLootRows(dynamic directLootRows, Set<String> out) {
  if (directLootRows is! List) {
    return;
  }
  for (final row in directLootRows) {
    if (row is! Map<String, dynamic>) {
      continue;
    }
    final loc = '${row['locationLabel'] ?? ''}'.trim();
    final v = mapDisplayValueFromLocation(loc);
    if (v != null) {
      out.add(v);
    }
  }
}

/// Resultado de un solo parse de [item_origin_index.json].
class ItemOriginDerived {
  const ItemOriginDerived({
    required this.mapNamesByItemId,
  });

  final Map<int, Set<String>> mapNamesByItemId;
}

/// Un solo parse del JSON: mapas por ítem.
Future<ItemOriginDerived> loadItemOriginDerived() async {
  final raw =
      await rootBundle.loadString(WorldshiftAssets.itemOriginIndexFile);
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    return const ItemOriginDerived(mapNamesByItemId: {});
  }
  final items = decoded['items'];
  if (items is! List) {
    return const ItemOriginDerived(mapNamesByItemId: {});
  }

  final mapOut = <int, Set<String>>{};

  for (final item in items) {
    if (item is! Map<String, dynamic>) {
      continue;
    }
    final itemId = _parseItemId(item['id']);
    if (itemId == null) {
      continue;
    }

    final mapNames = <String>{};
    final resolvedOrigins = item['resolvedOrigins'];
    if (resolvedOrigins is List) {
      for (final origin in resolvedOrigins) {
        if (origin is Map<String, dynamic>) {
          _addHintsFromOrigin(origin, mapNames);
        }
      }
    }
    _addHintsFromDirectLootRows(item['directLootRows'], mapNames);
    if (mapNames.isNotEmpty) {
      mapOut[itemId] = mapNames;
    }
  }

  return ItemOriginDerived(mapNamesByItemId: mapOut);
}

/// Nombres de mapa por ítem (valores de [maps] y derivados del índice de orígenes).
Future<Map<int, Set<String>>> loadResolvedMapNamesByItem() async {
  final d = await loadItemOriginDerived();
  return d.mapNamesByItemId;
}

/// Sigla para chips: primero [mapMissionMetaByFileStem] (loot/misiones),
/// luego [maps] en `data.dart` (otros prefijos de ubicación), y si no,
/// iniciales heurísticas.
String mapAbbreviationForDisplayName(String fullName) {
  final n = fullName.trim();
  if (n.isEmpty) {
    return n;
  }
  final fromMission = mapMissionKeyForDisplayName(n);
  if (fromMission != null) {
    return fromMission;
  }
  final normalized = normalizeMapDisplayNameForLookup(n);
  for (final m in maps) {
    final v = (m['value'] ?? '').toString().trim();
    if (v.isEmpty) {
      continue;
    }
    if (normalizeMapDisplayNameForLookup(v) == normalized) {
      return (m['key'] ?? n).toString().trim();
    }
  }
  return _fallbackMapAbbreviation(n);
}

String _fallbackMapAbbreviation(String fullName) {
  const skip = {'the', 'a', 'an', 'of', 'and'};
  final raw = fullName.replaceAll(RegExp(r"[^a-zA-Z0-9\s']"), ' ');
  final parts = raw
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w.toLowerCase())
      .where((w) => !skip.contains(w))
      .toList();
  if (parts.isEmpty) {
    return fullName.length <= 4
        ? fullName.toUpperCase()
        : fullName.substring(0, 3).toUpperCase();
  }
  if (parts.length == 1) {
    final w = parts.first;
    return w.length <= 4 ? w.toUpperCase() : w.substring(0, 3).toUpperCase();
  }
  return parts.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
}

/// Misma orden que [formatMapNamesForDisplay] (alfabética, sin distinguir mayúsculas).
List<String> sortedMapNamesList(Set<String>? names) {
  if (names == null || names.isEmpty) {
    return const [];
  }
  final list = names.toList()
    ..sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
  return list;
}

/// Texto único para la UI: mapas ordenados separados por coma.
String? formatMapNamesForDisplay(Set<String>? names) {
  final list = sortedMapNamesList(names);
  if (list.isEmpty) {
    return null;
  }
  return list.join(', ');
}
