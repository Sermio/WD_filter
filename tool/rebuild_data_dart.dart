import 'dart:convert';
import 'dart:io';

const _dataFilePath = r'lib\data\data.dart';
const _itemFilePath = r'lib\data\item.dart';
const _sourceItemsDir = r'assets\loot\source_game\items';
const _sourceTextsDir = r'assets\loot\source_game\texts';
const _unitsJsonPath = r'assets\data\units.json';

const _mapDisplayOverrides = <String, String>{
  'Safari': 'Deadly safari',
  'DTB': 'Dunetown base',
  'BSA': 'Bloodsport Arena',
  'ROM': 'ROM base',
  'Kharum': 'Kharum',
  'JY': 'Junkyard',
  'CF': 'Corrupted fields',
  'AC': 'Ancient corridors',
  'RH': "The renegades' hideout",
  'BRD': 'Bridge of trial',
};

const _raceOrder = <String>['Humans', 'Tribes', 'Aliens'];
const _alwaysIncludeUnits = <String>{
  'Defender',
  'EliteKaiRider',
  'PsiDetonator',
};

void main() {
  final dataFile = File(_dataFilePath);
  final itemFile = File(_itemFilePath);
  final itemsFile = File('$_sourceItemsDir${Platform.pathSeparator}items.tsv');
  final lootIndexFile =
      File('$_sourceItemsDir${Platform.pathSeparator}loot index.tsv');
  final itemTextsFile =
      File('$_sourceTextsDir${Platform.pathSeparator}items.tsv');
  final missionsFile =
      File('$_sourceTextsDir${Platform.pathSeparator}missions.tsv');
  final unitsJsonFile = File(_unitsJsonPath);

  final missingPaths = <String>[
    if (!dataFile.existsSync()) dataFile.path,
    if (!itemFile.existsSync()) itemFile.path,
    if (!itemsFile.existsSync()) itemsFile.path,
    if (!lootIndexFile.existsSync()) lootIndexFile.path,
    if (!itemTextsFile.existsSync()) itemTextsFile.path,
    if (!missionsFile.existsSync()) missionsFile.path,
    if (!unitsJsonFile.existsSync()) unitsJsonFile.path,
  ];

  if (missingPaths.isNotEmpty) {
    stderr.writeln('Faltan archivos requeridos para reconstruir data.dart:');
    for (final path in missingPaths) {
      stderr.writeln('- $path');
    }
    stderr.writeln(
      '\nEjecuta antes `dart run tool/refresh_worldshift_item_data.dart`.',
    );
    exitCode = 1;
    return;
  }

  final dataSource = dataFile.readAsStringSync();
  final itemSource = itemFile.readAsStringSync();
  final itemRecords = _parseItemRecords(itemsFile);
  final lootRows = _parseLootIndexRows(lootIndexFile);
  final genericSlots = _parseGenericItemEntries(itemTextsFile);
  final missionTitles = _parseMissionTitles(missionsFile);
  final unitsCatalog = _parseUnitsCatalog(unitsJsonFile);

  final currentUnits = _parseCurrentKeyValueList(dataSource, 'units');
  final currentMaps = _parseCurrentKeyValueList(dataSource, 'maps');
  final currentSlots = _parseCurrentSlotEntries(dataSource);
  final currentRaces = _parseCurrentStringList(dataSource, 'races');
  final currentLootTables = _parseCurrentIntList(dataSource, 'lootTable');

  final rebuiltUnits = _rebuildUnits(
    currentUnits: currentUnits,
    itemRecords: itemRecords,
    unitsCatalog: unitsCatalog,
  );
  final rebuiltRaces = _rebuildRaces(
    currentRaces: currentRaces,
    itemRecords: itemRecords,
    unitsCatalog: unitsCatalog,
  );
  final rebuiltMaps = _rebuildMaps(
    currentMaps: currentMaps,
    lootRows: lootRows,
    missionTitles: missionTitles,
  );
  final rebuiltLootTables = _rebuildLootTables(
    currentLootTables: currentLootTables,
    lootRows: lootRows,
  );
  final rebuiltSlots = _rebuildSlots(
    currentSlots: currentSlots,
    itemRecords: itemRecords,
    genericSlots: genericSlots,
  );
  final rebuiltUnitsFlat = rebuiltUnits.map((entry) => entry.key).toList();

  var updatedDataSource = dataSource;
  updatedDataSource = _replaceDeclaration(
    updatedDataSource,
    'units',
    _buildKeyValueListSource('units', rebuiltUnits),
  );
  updatedDataSource = _replaceDeclaration(
    updatedDataSource,
    'races',
    _buildStringListSource('races', rebuiltRaces),
  );
  updatedDataSource = _replaceDeclaration(
    updatedDataSource,
    'maps',
    _buildKeyValueListSource('maps', rebuiltMaps),
  );
  updatedDataSource = _replaceDeclaration(
    updatedDataSource,
    'lootTable',
    _buildIntListSource('lootTable', rebuiltLootTables),
  );
  updatedDataSource = _replaceDeclaration(
    updatedDataSource,
    'slots',
    _buildSlotListSource('slots', rebuiltSlots),
  );

  var updatedItemSource = _replaceDeclaration(
    itemSource,
    'unitsFlat',
    _buildStringListSource('unitsFlat', rebuiltUnitsFlat, isFinal: true),
  );

  if (updatedDataSource == dataSource && updatedItemSource == itemSource) {
    stdout.writeln(
      'Sin cambios en data.dart e item.dart (ya estaban al día).',
    );
    return;
  }

  dataFile.writeAsStringSync(updatedDataSource);
  itemFile.writeAsStringSync(updatedItemSource);

  stdout.writeln('Regeneradas listas de referencia en data.dart e item.dart.');
  stdout.writeln('- units: ${rebuiltUnits.length}');
  stdout.writeln('- races: ${rebuiltRaces.length}');
  stdout.writeln('- maps: ${rebuiltMaps.length}');
  stdout.writeln('- lootTable: ${rebuiltLootTables.length}');
  stdout.writeln('- slots: ${rebuiltSlots.length}');
}

List<MapEntry<String, String>> _rebuildUnits({
  required Map<String, String> currentUnits,
  required List<_ItemRecord> itemRecords,
  required Map<String, _CatalogUnit> unitsCatalog,
}) {
  final byRace = <String, List<MapEntry<String, String>>>{};
  for (final race in _raceOrder) {
    byRace[race] = <MapEntry<String, String>>[];
  }

  final affectedUnits = <String>{...currentUnits.keys, ..._alwaysIncludeUnits};
  for (final record in itemRecords) {
    affectedUnits.addAll(record.affectedUnits);
  }

  final currentOrder = currentUnits.keys.toList();
  final currentSet = currentUnits.keys.toSet();
  final grouped = <String, List<String>>{};

  for (final unitKey in affectedUnits) {
    final catalogUnit = unitsCatalog[_normalizeKey(unitKey)];
    final race = _catalogRaceToDisplay(
      catalogUnit?.raceLabel ?? _raceFromUnitKey(unitKey),
    );
    grouped.putIfAbsent(race, () => []).add(unitKey);
  }

  for (final race in _raceOrder) {
    final values = grouped[race] ?? const <String>[];
    final existing = currentOrder.where((key) => values.contains(key)).toList();
    final newOnes = values.where((key) => !currentSet.contains(key)).toList()
      ..sort((a, b) {
        final labelA = _resolveUnitValue(a, currentUnits, unitsCatalog);
        final labelB = _resolveUnitValue(b, currentUnits, unitsCatalog);
        return labelA.compareTo(labelB);
      });

    for (final key in [...existing, ...newOnes]) {
      byRace[race]!.add(
        MapEntry(key, _resolveUnitValue(key, currentUnits, unitsCatalog)),
      );
    }
  }

  return [
    ...byRace['Humans'] ?? const [],
    ...byRace['Tribes'] ?? const [],
    ...byRace['Aliens'] ?? const [],
  ];
}

List<String> _rebuildRaces({
  required List<String> currentRaces,
  required List<_ItemRecord> itemRecords,
  required Map<String, _CatalogUnit> unitsCatalog,
}) {
  final discovered = <String>{};
  discovered.addAll(itemRecords.map((record) => record.race));
  discovered.addAll(
    unitsCatalog.values
        .map((unit) => _catalogRaceToDisplay(unit.raceLabel))
        .where((race) => race.isNotEmpty),
  );

  final result = <String>[];
  for (final race in currentRaces) {
    if (discovered.remove(race)) {
      result.add(race);
    }
  }
  final remaining = discovered.toList()..sort();
  result.addAll(remaining);
  return result;
}

List<MapEntry<String, String>> _rebuildMaps({
  required Map<String, String> currentMaps,
  required List<_LootIndexRow> lootRows,
  required Map<String, String> missionTitles,
}) {
  final discovered = <String>{};
  for (final row in lootRows) {
    final mapKey = _extractMapKeyFromLootLabel(row.label);
    if (mapKey != null) {
      discovered.add(mapKey);
    }
  }

  final result = <MapEntry<String, String>>[];
  final currentSet = currentMaps.keys.toSet();
  for (final key in currentMaps.keys) {
    if (!discovered.contains(key)) {
      continue;
    }
    result.add(
      MapEntry(
        key,
        currentMaps[key] ?? _resolveMapValue(key, missionTitles),
      ),
    );
  }

  final remaining =
      discovered.where((key) => !currentSet.contains(key)).toList()..sort();
  for (final key in remaining) {
    result.add(MapEntry(key, _resolveMapValue(key, missionTitles)));
  }
  return result;
}

List<int> _rebuildLootTables({
  required List<int> currentLootTables,
  required List<_LootIndexRow> lootRows,
}) {
  final discovered =
      lootRows.map((row) => row.id).where((id) => id > 0).toSet();
  final result = <int>[];
  for (final id in currentLootTables) {
    if (discovered.remove(id)) {
      result.add(id);
    }
  }
  final remaining = discovered.toList()..sort();
  result.addAll(remaining);
  return result;
}

List<_SlotEntry> _rebuildSlots({
  required Map<String, _SlotEntry> currentSlots,
  required List<_ItemRecord> itemRecords,
  required Map<String, String> genericSlots,
}) {
  final discovered = <String>{};
  discovered.addAll(itemRecords.map((record) => record.slot));
  discovered.addAll(genericSlots.keys);

  final grouped = <String, List<_SlotEntry>>{
    'HUMAN': [],
    'MUTANT': [],
    'ALIEN': [],
  };

  for (final prefix in ['HUMAN', 'MUTANT', 'ALIEN']) {
    final existing = currentSlots.values
        .where((slot) =>
            slot.key.startsWith('${prefix}_') && discovered.contains(slot.key))
        .toList();
    grouped[prefix]!.addAll(existing);
  }

  final used = currentSlots.keys.toSet();
  final remaining = discovered.where((key) => !used.contains(key)).toList()
    ..sort();
  for (final key in remaining) {
    final prefix = key.split('_').first;
    if (!grouped.containsKey(prefix)) {
      continue;
    }
    final description = genericSlots[key] ?? _fallbackSlotDescription(key);
    grouped[prefix]!.add(
      _SlotEntry(
        key: key,
        value: _deriveSlotValue(key, description),
        description: description,
      ),
    );
  }

  return [
    ...grouped['HUMAN'] ?? const [],
    ...grouped['MUTANT'] ?? const [],
    ...grouped['ALIEN'] ?? const [],
  ];
}

List<_ItemRecord> _parseItemRecords(File file) {
  final raw = _readText(file);
  final records = <_ItemRecord>[];
  final logicalRecords = <String>[];
  var current = '';

  for (final line in const LineSplitter().convert(raw)) {
    if (RegExp(r'^\d+\t').hasMatch(line)) {
      if (current.isNotEmpty) {
        logicalRecords.add(current);
      }
      current = line;
    } else {
      current = current.isEmpty ? line : '$current\v$line';
    }
  }
  if (current.isNotEmpty) {
    logicalRecords.add(current);
  }

  final attributePattern = RegExp(
    r'[A-Za-z0-9_]+\s+([A-Za-z0-9_]+)\s*=\s*[^\v\t]+',
  );

  for (final record in logicalRecords) {
    final parts = record.split('\t');
    if (parts.length < 6) {
      continue;
    }
    final affectedUnits = parts[5]
        .split('\v')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final attributeString = parts.length > 6 ? parts[6] : '';
    final attributeKeys = attributePattern
        .allMatches(attributeString)
        .map((match) => match.group(1)!)
        .toSet();

    records.add(
      _ItemRecord(
        race: parts[2].trim(),
        slot: parts[3].trim(),
        affectedUnits: affectedUnits,
        attributeKeys: attributeKeys,
      ),
    );
  }

  return records;
}

List<_LootIndexRow> _parseLootIndexRows(File file) {
  final rows = <_LootIndexRow>[];
  for (final line in const LineSplitter().convert(_readText(file))) {
    if (line.trim().isEmpty) {
      continue;
    }
    final parts = _splitTsvLine(line);
    if (parts.length < 2) {
      continue;
    }
    final id = int.tryParse(parts[0]);
    if (id == null) {
      continue;
    }
    rows.add(_LootIndexRow(id: id, label: parts[1]));
  }
  return rows;
}

Map<String, String> _parseGenericItemEntries(File file) {
  final result = <String, String>{};
  final pattern =
      RegExp(r'^generic_item\.([A-Z_]+)\t([^\r\n]+)', multiLine: true);
  for (final match in pattern.allMatches(_readText(file))) {
    result[match.group(1)!] = _normalizeLabel(match.group(2)!);
  }
  return result;
}

Map<String, String> _parseMissionTitles(File file) {
  final result = <String, String>{};
  final pattern = RegExp(
    r'^earth_spots\.\#\d+\.title\t([^\r\n]+)',
    multiLine: true,
  );
  final titles = pattern
      .allMatches(_readText(file))
      .map((match) => _normalizeLabel(match.group(1)!))
      .toSet();
  for (final title in titles) {
    result[_normalizeKey(title)] = title;
  }
  return result;
}

Map<String, _CatalogUnit> _parseUnitsCatalog(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List) {
    return const {};
  }
  final result = <String, _CatalogUnit>{};
  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) {
      continue;
    }
    final displayName = '${entry['displayName'] ?? ''}'.trim();
    if (displayName.isEmpty) {
      continue;
    }
    final normalizedDisplay = _normalizeKey(displayName);
    final normalizedId = _normalizeKey('${entry['id'] ?? ''}');
    final unit = _CatalogUnit(
      displayName: displayName,
      raceLabel: '${entry['race'] ?? entry['raceFolder'] ?? ''}',
    );
    result[normalizedDisplay] = unit;
    if (normalizedId.isNotEmpty) {
      result.putIfAbsent(normalizedId, () => unit);
    }
  }
  return result;
}

List<String> _parseCurrentStringList(String source, String variableName) {
  final match = RegExp(
    '(?:List<String>|final List<String>)\\s+$variableName\\s*=\\s*\\[([\\s\\S]*?)\\];',
    multiLine: true,
  ).firstMatch(source);
  if (match == null) {
    return const [];
  }
  return RegExp("'([^']+)'|\"([^\"]+)\"")
      .allMatches(match.group(1)!)
      .map((match) => match.group(1) ?? match.group(2) ?? '')
      .where((value) => value.isNotEmpty)
      .toList();
}

List<int> _parseCurrentIntList(String source, String variableName) {
  final match = RegExp(
    'List<int>\\s+$variableName\\s*=\\s*\\[([\\s\\S]*?)\\];',
    multiLine: true,
  ).firstMatch(source);
  if (match == null) {
    return const [];
  }
  return RegExp(r'\b\d+\b')
      .allMatches(match.group(1)!)
      .map((match) => int.parse(match.group(0)!))
      .toList();
}

Map<String, String> _parseCurrentKeyValueList(
    String source, String variableName) {
  final match = RegExp(
    'List<Map<String,\\s*String>>\\s+$variableName\\s*=\\s*\\[([\\s\\S]*?)\\];',
    multiLine: true,
  ).firstMatch(source);
  if (match == null) {
    return const {};
  }
  final result = <String, String>{};
  final pattern = RegExp(
    r"'key'\s*:\s*'([^']+)'\s*,\s*'value'\s*:\s*'((?:\\'|[^'])+)'",
    multiLine: true,
  );
  for (final entry in pattern.allMatches(match.group(1)!)) {
    result[entry.group(1)!] = entry.group(2)!.replaceAll("\\'", "'");
  }
  return result;
}

Map<String, _SlotEntry> _parseCurrentSlotEntries(String source) {
  final match = RegExp(
    r'List<Map<String,\s*String>>\s+slots\s*=\s*\[([\s\S]*?)\];',
    multiLine: true,
  ).firstMatch(source);
  if (match == null) {
    return const {};
  }

  final result = <String, _SlotEntry>{};
  final entryPattern = RegExp(
    r"'key'\s*:\s*'([^']+)'\s*,\s*'value'\s*:\s*'((?:\\'|[^'])+)'\s*,\s*'description'\s*:\s*'((?:\\'|[^'])+)'",
    multiLine: true,
  );

  for (final entry in entryPattern.allMatches(match.group(1)!)) {
    final key = entry.group(1)!;
    result[key] = _SlotEntry(
      key: key,
      value: entry.group(2)!.replaceAll("\\'", "'"),
      description: entry.group(3)!.replaceAll("\\'", "'"),
    );
  }
  return result;
}

String _replaceDeclaration(
    String source, String variableName, String replacement) {
  final patterns = [
    RegExp(
      '^\\s*final List<String>\\s+$variableName\\s*=\\s*\\[[\\s\\S]*?\\];',
      multiLine: true,
    ),
    RegExp(
      '^\\s*List<String>\\s+$variableName\\s*=\\s*\\[[\\s\\S]*?\\];',
      multiLine: true,
    ),
    RegExp(
      '^\\s*List<int>\\s+$variableName\\s*=\\s*\\[[\\s\\S]*?\\];',
      multiLine: true,
    ),
    RegExp(
      '^\\s*List<Map<String,\\s*String>>\\s+$variableName\\s*=\\s*\\[[\\s\\S]*?\\];',
      multiLine: true,
    ),
  ];

  for (final pattern in patterns) {
    final updated = source.replaceFirst(pattern, replacement);
    if (updated != source) {
      return updated;
    }
  }
  return source;
}

String _buildStringListSource(
  String variableName,
  Iterable<String> values, {
  bool isFinal = false,
}) {
  final buffer = StringBuffer(
    '${isFinal ? 'final ' : ''}List<String> $variableName = [\n',
  );
  for (final value in values) {
    buffer.writeln("  '${_escapeSingleQuoted(value)}',");
  }
  buffer.write('];');
  return buffer.toString();
}

String _buildIntListSource(String variableName, Iterable<int> values) {
  final buffer = StringBuffer('List<int> $variableName = [\n');
  for (final value in values) {
    buffer.writeln('  $value,');
  }
  buffer.write('];');
  return buffer.toString();
}

String _buildKeyValueListSource(
  String variableName,
  Iterable<MapEntry<String, String>> entries,
) {
  final buffer = StringBuffer('List<Map<String, String>> $variableName = [\n');
  for (final entry in entries) {
    buffer.writeln(
      "  {'key': '${_escapeSingleQuoted(entry.key)}', 'value': '${_escapeSingleQuoted(entry.value)}'},",
    );
  }
  buffer.write('];');
  return buffer.toString();
}

String _buildSlotListSource(String variableName, Iterable<_SlotEntry> entries) {
  final buffer = StringBuffer('List<Map<String, String>> $variableName = [\n');
  for (final entry in entries) {
    buffer.writeln('  {');
    buffer.writeln("    'key': '${_escapeSingleQuoted(entry.key)}',");
    buffer.writeln("    'value': '${_escapeSingleQuoted(entry.value)}',");
    buffer.writeln(
      "    'description': '${_escapeSingleQuoted(entry.description)}'",
    );
    buffer.writeln('  },');
  }
  buffer.write('];');
  return buffer.toString();
}

String _resolveUnitValue(
  String unitKey,
  Map<String, String> currentUnits,
  Map<String, _CatalogUnit> unitsCatalog,
) {
  return currentUnits[unitKey] ??
      unitsCatalog[_normalizeKey(unitKey)]?.displayName ??
      _humanizeCamelKey(unitKey);
}

String _resolveMapValue(String key, Map<String, String> missionTitles) {
  return _mapDisplayOverrides[key] ??
      missionTitles[_normalizeKey(key)] ??
      _humanizeAttributeKey(key);
}

String _catalogRaceToDisplay(String raw) {
  final normalized = raw.trim().toLowerCase();
  switch (normalized) {
    case 'humans':
      return 'Humans';
    case 'mutants':
    case 'tribes':
      return 'Tribes';
    case 'aliens':
      return 'Aliens';
    default:
      return '';
  }
}

String _raceFromUnitKey(String unitKey) {
  final normalized = unitKey.toLowerCase();
  if ([
    'commander',
    'assassin',
    'constructor',
    'judge',
    'surgeon',
    'trooper',
    'ripper',
    'assaultbot',
    'hellfire',
    'engineer',
    'defender',
  ].contains(normalized)) {
    return 'Humans';
  }
  if ([
    'highpriest',
    'guardian',
    'shaman',
    'sorcerer',
    'stoneghost',
    'warrior',
    'brute',
    'ancientshade',
    'howlinghorror',
    'psychic',
    'elitekairider',
  ].contains(normalized)) {
    return 'Tribes';
  }
  return 'Aliens';
}

String? _extractMapKeyFromLootLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if ([
    'GENERIC',
    'PVP GENERIC',
    'Common Hard Boss',
    'Common Dungeon',
    'PvP Rewards',
    'Common Low Boss',
    'Mission Rewards',
  ].contains(trimmed)) {
    return null;
  }
  if (trimmed.startsWith('JY ')) return 'JY';
  if (trimmed.startsWith('CF ')) return 'CF';
  if (trimmed.startsWith('AC ')) return 'AC';
  if (trimmed.startsWith('RH ')) return 'RH';
  if (trimmed.startsWith('BRD ')) return 'BRD';
  if (trimmed.contains(' - ')) {
    return trimmed.split(' - ').first.trim();
  }
  return trimmed;
}

String _deriveSlotValue(String slotKey, String description) {
  final relatedMatch = RegExp(r'related to ([^,]+),', caseSensitive: false)
      .firstMatch(description);
  if (relatedMatch != null) {
    return relatedMatch.group(1)!.trim();
  }

  final officerMatch = RegExp(
    r'statistics of your ([^.]+)\.',
    caseSensitive: false,
  ).firstMatch(description);
  if (officerMatch != null) {
    return _singularize(officerMatch.group(1)!.trim());
  }

  return _humanizeAttributeKey(slotKey.split('_').skip(1).join('_'));
}

String _fallbackSlotDescription(String slotKey) {
  final slotName = _humanizeAttributeKey(slotKey.split('_').skip(1).join('_'));
  return 'This item is related to $slotName.';
}

String _singularize(String value) {
  if (value.endsWith('s') && !value.endsWith('ss')) {
    return value.substring(0, value.length - 1);
  }
  return value;
}

String _humanizeAttributeKey(String key) {
  return key
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _humanizeCamelKey(String key) {
  return key.replaceAllMapped(
    RegExp(r'(?<=[a-z])(?=[A-Z])'),
    (_) => ' ',
  );
}

String _normalizeLabel(String label) =>
    label.replaceAll('’', "'").replaceAll(RegExp(r'\s+'), ' ').trim();

String _normalizeKey(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toLowerCase();

String _escapeSingleQuoted(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

List<String> _splitTsvLine(String line) =>
    line.split('\t').map((part) => part.trim()).toList();

String _readText(File file) {
  return utf8
      .decode(file.readAsBytesSync(), allowMalformed: true)
      .replaceFirst('\ufeff', '');
}

class _ItemRecord {
  const _ItemRecord({
    required this.race,
    required this.slot,
    required this.affectedUnits,
    required this.attributeKeys,
  });

  final String race;
  final String slot;
  final List<String> affectedUnits;
  final Set<String> attributeKeys;
}

class _LootIndexRow {
  const _LootIndexRow({
    required this.id,
    required this.label,
  });

  final int id;
  final String label;
}

class _CatalogUnit {
  const _CatalogUnit({
    required this.displayName,
    required this.raceLabel,
  });

  final String displayName;
  final String raceLabel;
}

class _SlotEntry {
  const _SlotEntry({
    required this.key,
    required this.value,
    required this.description,
  });

  final String key;
  final String value;
  final String description;
}
