import 'dart:convert';
import 'dart:io';

import 'package:worldshift_assistant/data/map_mission_meta.dart';

const _itemsPath = r'assets\loot\source_game\items\items.tsv';
const _lootPath = r'assets\loot\source_game\items\loot.tsv';
const _lootIndexPath = r'assets\loot\source_game\items\loot index.tsv';
const _dropPath = r'assets\loot\source_game\items\drop.tsv';
const _missionsPath = r'assets\loot\source_game\texts\missions.tsv';
const _mapRefsPath = r'assets\loot\source_game\refs\map_drop_refs.tsv';
const _unitRefsPath = r'assets\loot\source_game\refs\unit_drop_refs.tsv';
const _outputPath = r'assets\data\item_origin_index.json';

void main() {
  final itemDefinitions = _parseItemDefinitions(File(_itemsPath));
  final lootRows = _parseLootRows(File(_lootPath));
  final lootIndexRows = _parseLootIndexRows(File(_lootIndexPath));
  final dropRows = _parseDropRows(File(_dropPath));
  final missionTitles = _parseMissionTitles(File(_missionsPath));
  final mapRefs = _parseRefs(File(_mapRefsPath), hasContextColumn: false);
  final unitRefs = _parseRefs(File(_unitRefsPath), hasContextColumn: true);

  final lootIndexById = {
    for (final row in lootIndexRows) row.tableId: row,
  };
  final lootByItem = <int, List<_LootRow>>{};
  for (final row in lootRows) {
    lootByItem.putIfAbsent(row.itemId, () => []).add(row);
  }

  final dropParentsByTo = <int, List<_DropRow>>{};
  final dropChildrenByFrom = <int, List<_DropRow>>{};
  for (final row in dropRows) {
    dropParentsByTo.putIfAbsent(row.toId, () => []).add(row);
    dropChildrenByFrom.putIfAbsent(row.fromId, () => []).add(row);
  }

  final mapRefsByValue = <String, List<_RefRow>>{};
  for (final ref in mapRefs) {
    mapRefsByValue.putIfAbsent(ref.refValue, () => []).add(ref);
  }
  final unitRefsByValue = <String, List<_RefRow>>{};
  for (final ref in unitRefs) {
    unitRefsByValue.putIfAbsent(ref.refValue, () => []).add(ref);
  }

  final allTableIds = <int>{
    ...lootIndexById.keys,
    ...lootRows.map((row) => row.tableId),
    ...dropRows.map((row) => row.fromId),
    ...dropRows.map((row) => row.toId),
  }.toList()
    ..sort();

  final tables = allTableIds
      .map(
        (tableId) => _buildTableJson(
          tableId: tableId,
          lootIndexById: lootIndexById,
          lootRows: lootRows,
          dropChildrenByFrom: dropChildrenByFrom,
          mapRefsByValue: mapRefsByValue,
          unitRefsByValue: unitRefsByValue,
          missionTitles: missionTitles,
        ),
      )
      .toList();

  final itemIds = <int>{
    ...itemDefinitions.keys,
    ...lootByItem.keys,
  }.toList()
    ..sort();

  final items = itemIds
      .map(
        (itemId) => _buildItemJson(
          itemId: itemId,
          definition: itemDefinitions[itemId],
          directLootRows: lootByItem[itemId] ?? const [],
          lootIndexById: lootIndexById,
          dropParentsByTo: dropParentsByTo,
          mapRefsByValue: mapRefsByValue,
          unitRefsByValue: unitRefsByValue,
          missionTitles: missionTitles,
        ),
      )
      .toList();

  final output = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sources': {
      'items': _itemsPath.replaceAll(r'\', '/'),
      'loot': _lootPath.replaceAll(r'\', '/'),
      'lootIndex': _lootIndexPath.replaceAll(r'\', '/'),
      'drop': _dropPath.replaceAll(r'\', '/'),
      'missions': _missionsPath.replaceAll(r'\', '/'),
      'mapRefs': _mapRefsPath.replaceAll(r'\', '/'),
      'unitRefs': _unitRefsPath.replaceAll(r'\', '/'),
    },
    'summary': {
      'itemDefinitions': itemDefinitions.length,
      'lootRows': lootRows.length,
      'lootIndexRows': lootIndexRows.length,
      'dropRows': dropRows.length,
      'mapRefs': mapRefs.length,
      'unitRefs': unitRefs.length,
      'tables': tables.length,
      'items': items.length,
    },
    'tables': tables,
    'items': items,
  };

  final outputFile = File(_outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(output),
  );

  stdout.writeln(
    'Generado indice de origen de items en ${outputFile.path}\n'
    'Items: ${items.length}\n'
    'Mesas: ${tables.length}',
  );
}

Map<String, dynamic> _buildTableJson({
  required int tableId,
  required Map<int, _LootIndexRow> lootIndexById,
  required List<_LootRow> lootRows,
  required Map<int, List<_DropRow>> dropChildrenByFrom,
  required Map<String, List<_RefRow>> mapRefsByValue,
  required Map<String, List<_RefRow>> unitRefsByValue,
  required Map<String, String> missionTitles,
}) {
  final lootIndex = lootIndexById[tableId];
  final label = lootIndex?.label ??
      lootRows
          .where((row) => row.tableId == tableId)
          .map((row) => row.locationLabel)
          .cast<String?>()
          .firstWhere((value) => value != null && value.isNotEmpty,
              orElse: () => '')!;

  final mapRefs = mapRefsByValue['$tableId'] ?? const <_RefRow>[];
  final unitRefs = unitRefsByValue['$tableId'] ?? const <_RefRow>[];
  final contextMeta = _deriveContextMeta(
    label: label,
    mapRefs: mapRefs,
    unitRefs: unitRefs,
    missionTitles: missionTitles,
  );

  return {
    'tableId': tableId,
    'label': label,
    'rarityWeights': lootIndex?.rarityWeights,
    'directItemCount': lootRows.where((row) => row.tableId == tableId).length,
    'children': (dropChildrenByFrom[tableId] ?? const <_DropRow>[])
        .map((row) => row.toJson())
        .toList(),
    'mapRefs': mapRefs.map((ref) => ref.toJson()).toList(),
    'unitRefs': unitRefs.map((ref) => ref.toJson()).toList(),
    ...contextMeta,
  };
}

Map<String, dynamic> _buildItemJson({
  required int itemId,
  required _ItemDefinition? definition,
  required List<_LootRow> directLootRows,
  required Map<int, _LootIndexRow> lootIndexById,
  required Map<int, List<_DropRow>> dropParentsByTo,
  required Map<String, List<_RefRow>> mapRefsByValue,
  required Map<String, List<_RefRow>> unitRefsByValue,
  required Map<String, String> missionTitles,
}) {
  final directTableIds =
      directLootRows.map((row) => row.tableId).toSet().toList()..sort();

  final directTables = directTableIds.map((tableId) {
    final label = lootIndexById[tableId]?.label ??
        directLootRows
            .firstWhere((row) => row.tableId == tableId)
            .locationLabel;
    final mapRefs = mapRefsByValue['$tableId'] ?? const <_RefRow>[];
    final unitRefs = unitRefsByValue['$tableId'] ?? const <_RefRow>[];
    return {
      'tableId': tableId,
      'label': label,
      'mapRefs': mapRefs.map((ref) => ref.toJson()).toList(),
      'unitRefs': unitRefs.map((ref) => ref.toJson()).toList(),
      ..._deriveContextMeta(
        label: label,
        mapRefs: mapRefs,
        unitRefs: unitRefs,
        missionTitles: missionTitles,
      ),
    };
  }).toList();

  final resolvedOrigins = <Map<String, dynamic>>[];
  final seenPaths = <String>{};
  for (final tableId in directTableIds) {
    for (final path in _buildReversePaths(
      targetTableId: tableId,
      dropParentsByTo: dropParentsByTo,
    )) {
      final key = path.join('>');
      if (!seenPaths.add(key)) {
        continue;
      }
      final contextTableId = path.first;
      final contextLabel = lootIndexById[contextTableId]?.label ??
          lootIndexById[tableId]?.label ??
          directLootRows
              .firstWhere((row) => row.tableId == tableId)
              .locationLabel;
      final mapRefs = mapRefsByValue['$contextTableId'] ?? const <_RefRow>[];
      final unitRefs = unitRefsByValue['$contextTableId'] ?? const <_RefRow>[];
      resolvedOrigins.add({
        'contextTableId': contextTableId,
        'contextLabel': contextLabel,
        'viaDirectTableId': tableId,
        'pathTableIds': path,
        'pathLabels':
            path.map((id) => lootIndexById[id]?.label ?? 'Table $id').toList(),
        'mapRefs': mapRefs.map((ref) => ref.toJson()).toList(),
        'unitRefs': unitRefs.map((ref) => ref.toJson()).toList(),
        ..._deriveContextMeta(
          label: contextLabel,
          mapRefs: mapRefs,
          unitRefs: unitRefs,
          missionTitles: missionTitles,
        ),
      });
    }
  }

  resolvedOrigins.sort((a, b) {
    final tableCompare =
        (a['contextTableId'] as int).compareTo(b['contextTableId'] as int);
    if (tableCompare != 0) {
      return tableCompare;
    }
    final aPath = (a['pathTableIds'] as List<dynamic>).join('>');
    final bPath = (b['pathTableIds'] as List<dynamic>).join('>');
    return aPath.compareTo(bPath);
  });

  return {
    'id': itemId,
    'name': definition?.name ?? _firstNonEmptyName(directLootRows),
    'rarity': definition?.rarity,
    'race': definition?.race,
    'slot': definition?.slot,
    'affectedUnits': definition?.affectedUnits ?? const <String>[],
    'attributes': definition?.attributes ?? const <String, dynamic>{},
    'rawAttributeLines': definition?.rawAttributeLines ?? const <String>[],
    'flavorText': definition?.flavorText,
    'notes': definition?.notes,
    'directLootRows': directLootRows.map((row) => row.toJson()).toList(),
    'directTables': directTables,
    'resolvedOrigins': resolvedOrigins,
  };
}

String _firstNonEmptyName(List<_LootRow> rows) {
  for (final row in rows) {
    if (row.itemName.isNotEmpty) {
      return row.itemName;
    }
  }
  return '';
}

List<List<int>> _buildReversePaths({
  required int targetTableId,
  required Map<int, List<_DropRow>> dropParentsByTo,
}) {
  final results = <List<int>>[
    [targetTableId],
  ];
  final seen = <String>{'$targetTableId'};

  void visit({
    required int currentId,
    required List<int> path,
    required Set<int> visited,
    required int depth,
  }) {
    if (depth >= 8) {
      return;
    }
    for (final parent in dropParentsByTo[currentId] ?? const <_DropRow>[]) {
      if (parent.fromId == currentId || visited.contains(parent.fromId)) {
        continue;
      }
      final nextPath = [parent.fromId, ...path];
      final key = nextPath.join('>');
      if (seen.add(key)) {
        results.add(nextPath);
      }
      visit(
        currentId: parent.fromId,
        path: nextPath,
        visited: {...visited, parent.fromId},
        depth: depth + 1,
      );
    }
  }

  visit(
    currentId: targetTableId,
    path: [targetTableId],
    visited: {targetTableId},
    depth: 0,
  );
  return results;
}

Map<String, dynamic> _deriveContextMeta({
  required String label,
  required List<_RefRow> mapRefs,
  required List<_RefRow> unitRefs,
  required Map<String, String> missionTitles,
}) {
  String? mapKey;
  String? mapName;
  String mode = 'generic';
  String? sourceKind;
  String? sourceFile;

  if (mapRefs.isNotEmpty) {
    final ref = mapRefs.first;
    sourceFile = ref.sourceFile;
    final stem = _fileStem(ref.sourceFile);
    final numericMission = int.tryParse(stem);
    if (numericMission != null) {
      mapKey = 'MISSION_$stem';
      mapName = missionTitles[stem] ?? 'Mission $stem';
      mode = 'campaign';
      sourceKind = 'mission_map';
    } else {
      final meta = mapMissionMetaByFileStem[stem.toLowerCase()];
      if (meta != null) {
        mapKey = meta.key;
        mapName = meta.displayName;
        mode = meta.mode;
        sourceKind = 'map';
      }
    }
  }

  if (mapKey == null) {
    for (final entry in mapMissionMetaByFileStem.values) {
      if (label.startsWith(entry.key)) {
        mapKey = entry.key;
        mapName = entry.displayName;
        mode = entry.mode;
        sourceKind = 'table_label';
        break;
      }
    }
  }

  final lower = label.toLowerCase();
  if (lower.contains('pvp')) {
    mode = 'pvp';
    sourceKind ??= 'mode';
  } else if (lower.contains('mission rewards')) {
    mode = 'mission_rewards';
    sourceKind ??= 'mode';
  } else if (lower.contains('common dungeon')) {
    mode = 'dungeon_generic';
    sourceKind ??= 'generic_table';
  } else if (lower.contains('common hard boss') ||
      lower.contains('common low boss') ||
      lower == 'common boss') {
    mode = 'boss_generic';
    sourceKind ??= 'generic_table';
  }

  final bossOrUnit = unitRefs.isNotEmpty ? unitRefs.first.unitOrContext : null;

  return {
    'mode': mode,
    'sourceKind': sourceKind,
    'mapKey': mapKey,
    'mapName': mapName,
    'sourceFile': sourceFile,
    'unitOrContext': bossOrUnit,
  };
}

String _fileStem(String path) {
  final slash = path.replaceAll(r'\', '/');
  final fileName = slash.split('/').last;
  final dot = fileName.lastIndexOf('.');
  return dot == -1 ? fileName : fileName.substring(0, dot);
}

String _readText(File file) {
  final bytes = file.readAsBytesSync();
  return utf8.decode(bytes, allowMalformed: true).replaceFirst('\ufeff', '');
}

Map<int, _ItemDefinition> _parseItemDefinitions(File file) {
  final raw = _readText(file);
  final lines = raw.split(RegExp(r'\r?\n'));
  final records = <String>[];
  String? current;
  for (final line in lines) {
    if (RegExp(r'^\d+\t').hasMatch(line)) {
      if (current != null) {
        records.add(current);
      }
      current = line;
    } else if (current != null) {
      current = '$current\v$line';
    }
  }
  if (current != null) {
    records.add(current);
  }

  final result = <int, _ItemDefinition>{};
  for (final record in records) {
    final fields = record.split('\t');
    if (fields.length < 7) {
      continue;
    }
    final itemId = int.tryParse(fields[0].trim());
    if (itemId == null) {
      continue;
    }

    final affectedUnits = _splitVerticalField(fields[5]);
    final rawAttributeLines = _splitVerticalField(fields[6]);
    result[itemId] = _ItemDefinition(
      id: itemId,
      rarity: fields[1].trim(),
      race: fields[2].trim(),
      slot: fields[3].trim(),
      name: fields[4].trim(),
      affectedUnits: affectedUnits,
      attributes: _parseAttributes(rawAttributeLines),
      rawAttributeLines: rawAttributeLines,
      flavorText: fields.length > 7 && fields[7].trim().isNotEmpty
          ? fields[7].trim()
          : null,
      notes: fields.length > 8 && fields[8].trim().isNotEmpty
          ? fields[8].trim()
          : null,
    );
  }
  return result;
}

Map<String, Map<String, String>> _parseAttributes(List<String> lines) {
  final result = <String, Map<String, String>>{};
  final regex = RegExp(r'^([A-Za-z0-9_]+)\s+([A-Za-z0-9_]+)\s*=\s*(.+)$');
  for (final line in lines) {
    final match = regex.firstMatch(line.trim());
    if (match == null) {
      continue;
    }
    final unit = match.group(1)!.trim();
    final key = match.group(2)!.trim();
    final value = match.group(3)!.trim();
    result.putIfAbsent(unit, () => {})[key] = value;
  }
  return result;
}

List<String> _splitVerticalField(String field) {
  return field
      .split('\v')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}

List<_LootRow> _parseLootRows(File file) {
  final raw = _readText(file);
  final rows = <_LootRow>[];
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    if (line.trim().isEmpty) {
      continue;
    }
    final fields = line.split('\t');
    if (fields.length != 6) {
      continue;
    }
    final tableId = int.tryParse(fields[0].trim());
    final itemId = int.tryParse(fields[2].trim());
    if (tableId == null || itemId == null) {
      continue;
    }
    rows.add(
      _LootRow(
        tableId: tableId,
        locationLabel: fields[1].trim(),
        itemId: itemId,
        itemName: fields[5].trim(),
      ),
    );
  }
  return rows;
}

List<_LootIndexRow> _parseLootIndexRows(File file) {
  final raw = _readText(file);
  final rows = <_LootIndexRow>[];
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    if (line.trim().isEmpty) {
      continue;
    }
    final fields = line.split('\t');
    if (fields.length != 7) {
      continue;
    }
    final tableId = int.tryParse(fields[0].trim());
    if (tableId == null) {
      continue;
    }
    rows.add(
      _LootIndexRow(
        tableId: tableId,
        label: fields[1].trim(),
        rarityWeights: fields
            .skip(2)
            .map((field) => int.tryParse(field.trim()) ?? 0)
            .toList(),
      ),
    );
  }
  return rows;
}

List<_DropRow> _parseDropRows(File file) {
  final raw = _readText(file);
  final rows = <_DropRow>[];
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    if (line.trim().isEmpty) {
      continue;
    }
    final fields = line.split('\t');
    if (fields.length < 4) {
      continue;
    }
    final fromId = int.tryParse(fields[0].trim());
    final toId = int.tryParse(fields[2].trim());
    if (fromId == null || toId == null) {
      continue;
    }
    rows.add(
      _DropRow(
        fromId: fromId,
        fromLabel: fields[1].trim(),
        toId: toId,
        toLabel: fields[3].trim(),
        rawFields: fields.map((field) => field.trim()).toList(),
      ),
    );
  }
  return rows;
}

List<_RefRow> _parseRefs(File file, {required bool hasContextColumn}) {
  final raw = _readText(file);
  final lines = raw.split(RegExp(r'\r?\n'));
  final rows = <_RefRow>[];
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) {
      continue;
    }
    final fields = line.split('\t');
    if (hasContextColumn) {
      if (fields.length < 4) {
        continue;
      }
      rows.add(
        _RefRow(
          sourceFile: fields[0].trim(),
          unitOrContext: fields[1].trim(),
          refKind: fields[2].trim(),
          refValue: fields[3].trim(),
        ),
      );
    } else {
      if (fields.length < 3) {
        continue;
      }
      rows.add(
        _RefRow(
          sourceFile: fields[0].trim(),
          unitOrContext: null,
          refKind: fields[1].trim(),
          refValue: fields[2].trim(),
        ),
      );
    }
  }
  return rows;
}

Map<String, String> _parseMissionTitles(File file) {
  final raw = _readText(file);
  final titles = <String, String>{};
  final regex = RegExp(r'^earth_spots\.#(\d+)\.title\t(.+)$', multiLine: true);
  for (final match in regex.allMatches(raw)) {
    titles[match.group(1)!] = match.group(2)!.trim();
  }
  return titles;
}

class _ItemDefinition {
  const _ItemDefinition({
    required this.id,
    required this.rarity,
    required this.race,
    required this.slot,
    required this.name,
    required this.affectedUnits,
    required this.attributes,
    required this.rawAttributeLines,
    required this.flavorText,
    required this.notes,
  });

  final int id;
  final String rarity;
  final String race;
  final String slot;
  final String name;
  final List<String> affectedUnits;
  final Map<String, Map<String, String>> attributes;
  final List<String> rawAttributeLines;
  final String? flavorText;
  final String? notes;
}

class _LootRow {
  const _LootRow({
    required this.tableId,
    required this.locationLabel,
    required this.itemId,
    required this.itemName,
  });

  final int tableId;
  final String locationLabel;
  final int itemId;
  final String itemName;

  Map<String, dynamic> toJson() => {
        'tableId': tableId,
        'locationLabel': locationLabel,
        'itemId': itemId,
        'itemName': itemName,
      };
}

class _LootIndexRow {
  const _LootIndexRow({
    required this.tableId,
    required this.label,
    required this.rarityWeights,
  });

  final int tableId;
  final String label;
  final List<int> rarityWeights;
}

class _DropRow {
  const _DropRow({
    required this.fromId,
    required this.fromLabel,
    required this.toId,
    required this.toLabel,
    required this.rawFields,
  });

  final int fromId;
  final String fromLabel;
  final int toId;
  final String toLabel;
  final List<String> rawFields;

  Map<String, dynamic> toJson() => {
        'fromId': fromId,
        'fromLabel': fromLabel,
        'toId': toId,
        'toLabel': toLabel,
        'rawFields': rawFields,
      };
}

class _RefRow {
  const _RefRow({
    required this.sourceFile,
    required this.unitOrContext,
    required this.refKind,
    required this.refValue,
  });

  final String sourceFile;
  final String? unitOrContext;
  final String refKind;
  final String refValue;

  Map<String, dynamic> toJson() => {
        'sourceFile': sourceFile,
        if (unitOrContext != null) 'unitOrContext': unitOrContext,
        'refKind': refKind,
        'refValue': refValue,
      };
}
