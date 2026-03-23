import 'dart:convert';
import 'dart:io';

const _defaultWorldshiftRoot = r'C:\Users\sergi\Desktop\Proyectos\Worldshift';
const _dataFilePath = r'lib\data\data.dart';
const _preservedNonGameplayKeys = <String>{
  'additive',
  'material_alpha',
  'diffuse',
  'ambient',
  'emissive',
};
const _labelOverrides = <String, String>{
  'power': 'Machine Power',
  'power_gen': 'Machine Power Generation',
};

void main(List<String> args) {
  final worldshiftRoot = Directory(
    args.isNotEmpty ? args.first : _defaultWorldshiftRoot,
  );
  if (!worldshiftRoot.existsSync()) {
    stderr.writeln('No existe el directorio: ${worldshiftRoot.path}');
    stderr.writeln(
      'Uso: dart run tool/rebuild_attribute_list.dart [ruta_a_Worldshift]',
    );
    exitCode = 1;
    return;
  }

  final dataFile = File(_dataFilePath);
  if (!dataFile.existsSync()) {
    stderr.writeln('No existe el archivo: ${dataFile.path}');
    exitCode = 2;
    return;
  }

  final gameplayKeySet = _collectGameplayKeys(worldshiftRoot);
  final gameplayKeys = gameplayKeySet.toList()..sort();
  final labelByKey = _collectStatLabels(worldshiftRoot);
  final dataSource = dataFile.readAsStringSync();
  final currentKeys = _parseCurrentAttributeKeys(dataSource);
  final currentAttributeEntries = _parseCurrentAttributeEntries(dataSource);

  final orderedGameplayKeys = <String>[];
  final orderedExtras = <String>[];
  final seen = <String>{};

  for (final key in currentKeys) {
    if (!seen.add(key)) {
      continue;
    }
    if (gameplayKeySet.contains(key)) {
      orderedGameplayKeys.add(key);
    } else if (_preservedNonGameplayKeys.contains(key)) {
      orderedExtras.add(key);
    }
  }

  final missingGameplayKeys =
      gameplayKeys.where((key) => !orderedGameplayKeys.contains(key)).toList();

  final finalKeys = <String>[
    ...orderedGameplayKeys,
    ...missingGameplayKeys,
    ...orderedExtras,
  ];
  final finalAttributeEntries = _buildAttributeEntries(
    finalKeys,
    currentAttributeEntries,
    labelByKey,
  );

  var updatedSource = dataSource.replaceFirst(
    RegExp(
      r'List<String>\s+attributesList\s*=\s*\[[\s\S]*?\];',
      multiLine: true,
    ),
    _buildAttributeKeyListSource(finalKeys),
  );
  updatedSource = updatedSource.replaceFirst(
    RegExp(
      r'List<Map<String,\s*String>>\s+attributeList\s*=\s*\[[\s\S]*?\];',
      multiLine: true,
    ),
    _buildAttributeEntryListSource(finalAttributeEntries),
  );
  updatedSource = updatedSource.replaceFirst(
    RegExp(
      r'Map<String,\s*String>\s+attributeFilter\s*=\s*\{[\s\S]*?\};',
      multiLine: true,
    ),
    _buildAttributeFilterSource(finalAttributeEntries),
  );

  if (updatedSource == dataSource) {
    stderr
        .writeln('No se pudo localizar `attributesList` en ${dataFile.path}.');
    exitCode = 3;
    return;
  }

  dataFile.writeAsStringSync(updatedSource);

  stdout.writeln(
    'attributesList actualizada con ${finalKeys.length} claves '
    '(${missingGameplayKeys.length} nuevas de gameplay).',
  );
  if (missingGameplayKeys.isNotEmpty) {
    stdout.writeln('\nClaves nuevas detectadas:');
    for (final key in missingGameplayKeys) {
      stdout.writeln('- $key');
    }
  }
}

Set<String> _collectGameplayKeys(Directory worldshiftRoot) {
  final itemDbDir = Directory(
    '${worldshiftRoot.path}${Platform.pathSeparator}data${Platform.pathSeparator}db${Platform.pathSeparator}items',
  );
  final unitsDir = Directory(
    '${worldshiftRoot.path}${Platform.pathSeparator}data${Platform.pathSeparator}db${Platform.pathSeparator}units',
  );
  final itemTextsFile = File(
    '${worldshiftRoot.path}${Platform.pathSeparator}data${Platform.pathSeparator}texts${Platform.pathSeparator}en${Platform.pathSeparator}items.tsv',
  );
  final itemBonusesFile = File(
    '${itemDbDir.path}${Platform.pathSeparator}items.tsv',
  );

  final missingPaths = <String>[
    if (!itemDbDir.existsSync()) itemDbDir.path,
    if (!unitsDir.existsSync()) unitsDir.path,
    if (!itemTextsFile.existsSync()) itemTextsFile.path,
    if (!itemBonusesFile.existsSync()) itemBonusesFile.path,
  ];
  if (missingPaths.isNotEmpty) {
    throw FileSystemException(
      'Faltan archivos o carpetas necesarios para reconstruir attributesList',
      missingPaths.join(', '),
    );
  }

  final keys = <String>{};
  keys.addAll(_parseItemBonusKeys(itemBonusesFile));
  keys.addAll(_parseTextStatKeys(itemTextsFile));

  final dtFiles = <File>[
    ...unitsDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.dt')),
    ...itemDbDir
        .listSync(recursive: false)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('specs.dt')),
  ]..sort((a, b) => a.path.compareTo(b.path));

  for (final file in dtFiles) {
    final raw = _readText(file);
    keys.addAll(_parseStatReferences(raw));
    keys.addAll(_parseStatsBlockKeys(raw));
  }

  return keys.where(_looksLikeStatKey).toSet();
}

List<String> _parseCurrentAttributeKeys(String source) {
  final match = RegExp(
    r'List<String>\s+attributesList\s*=\s*\[([\s\S]*?)\];',
    multiLine: true,
  ).firstMatch(source);
  if (match == null) {
    return const [];
  }
  return RegExp(r'"([A-Za-z0-9_]+)"')
      .allMatches(match.group(1)!)
      .map((match) => match.group(1)!)
      .toList();
}

Map<String, String> _parseCurrentAttributeEntries(String source) {
  final match = RegExp(
    r'List<Map<String,\s*String>>\s+attributeList\s*=\s*\[([\s\S]*?)\];',
    multiLine: true,
  ).firstMatch(source);
  if (match == null) {
    return const {};
  }

  final result = <String, String>{};
  final entryPattern = RegExp(
    r"'key'\s*:\s*'([^']+)'\s*,\s*'value'\s*:\s*'([^']+)'",
    multiLine: true,
  );
  for (final entry in entryPattern.allMatches(match.group(1)!)) {
    result[entry.group(1)!] = entry.group(2)!;
  }
  return result;
}

Iterable<String> _parseItemBonusKeys(File file) sync* {
  final raw = _readText(file);
  final records = <String>[];
  var current = '';

  for (final line in const LineSplitter().convert(raw)) {
    if (RegExp(r'^\d+\t').hasMatch(line)) {
      if (current.isNotEmpty) {
        records.add(current);
      }
      current = line;
      continue;
    }
    current = current.isEmpty ? line : '$current\v$line';
  }
  if (current.isNotEmpty) {
    records.add(current);
  }

  final pattern = RegExp(
    r'[A-Za-z0-9_]+\s+([A-Za-z0-9_]+)\s*=\s*[^\v\t]+',
  );

  for (final record in records) {
    final parts = record.split('\t');
    if (parts.length < 7) {
      continue;
    }
    for (final match in pattern.allMatches(parts[6])) {
      yield match.group(1)!;
    }
  }
}

Iterable<String> _parseTextStatKeys(File file) sync* {
  for (final entry in _parseTextStatEntries(file).entries) {
    yield entry.key;
  }
}

Map<String, String> _collectStatLabels(Directory worldshiftRoot) {
  final itemTextsFile = File(
    '${worldshiftRoot.path}${Platform.pathSeparator}data${Platform.pathSeparator}texts${Platform.pathSeparator}en${Platform.pathSeparator}items.tsv',
  );
  if (!itemTextsFile.existsSync()) {
    return const {};
  }
  return _parseTextStatEntries(itemTextsFile);
}

Map<String, String> _parseTextStatEntries(File file) {
  final raw = _readText(file);
  final pattern = RegExp(
    r'^(?:stat|stats)\.([A-Za-z0-9_]+)\t([^\r\n]+)',
    multiLine: true,
  );
  final result = <String, String>{};
  for (final match in pattern.allMatches(raw)) {
    result[match.group(1)!] = _normalizeLabel(match.group(2)!);
  }
  return result;
}

Iterable<String> _parseStatReferences(String raw) sync* {
  final statRefPattern = RegExp(r'stat:([A-Za-z0-9_]+)');
  for (final match in statRefPattern.allMatches(raw)) {
    yield match.group(1)!;
  }
}

Iterable<String> _parseStatsBlockKeys(String raw) sync* {
  final blockStartPattern = RegExp(
    r'^\s*stats\s*(?::\s*[A-Za-z_][A-Za-z0-9_]*)?\s*\{',
    multiLine: true,
  );
  final linePattern = RegExp(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=');

  for (final match in blockStartPattern.allMatches(raw)) {
    final openBraceIndex = raw.indexOf('{', match.start);
    if (openBraceIndex == -1) {
      continue;
    }
    final closeBraceIndex = _findMatchingBrace(raw, openBraceIndex);
    if (closeBraceIndex == -1) {
      continue;
    }
    final block = raw.substring(openBraceIndex + 1, closeBraceIndex);
    for (final line in const LineSplitter().convert(block)) {
      final sanitized = line.split('--').first.trim();
      if (sanitized.isEmpty) {
        continue;
      }
      final lineMatch = linePattern.firstMatch(sanitized);
      if (lineMatch != null) {
        yield lineMatch.group(1)!;
      }
    }
  }
}

int _findMatchingBrace(String source, int openBraceIndex) {
  var depth = 0;
  for (var index = openBraceIndex; index < source.length; index++) {
    final char = source[index];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) {
        return index;
      }
    }
  }
  return -1;
}

String _buildAttributeKeyListSource(List<String> keys) {
  final buffer = StringBuffer('List<String> attributesList = [\n');
  for (final key in keys) {
    buffer.writeln('  "$key",');
  }
  buffer.write('];');
  return buffer.toString();
}

List<MapEntry<String, String>> _buildAttributeEntries(
  List<String> keys,
  Map<String, String> currentEntries,
  Map<String, String> labelByKey,
) {
  final entries = <MapEntry<String, String>>[];
  final seen = <String>{};

  for (final key in keys) {
    if (_preservedNonGameplayKeys.contains(key) || !seen.add(key)) {
      continue;
    }
    final label = _labelOverrides[key] ??
        labelByKey[key] ??
        currentEntries[key] ??
        _humanizeAttributeKey(key);
    entries.add(MapEntry(key, label));
  }

  return entries;
}

String _buildAttributeEntryListSource(List<MapEntry<String, String>> entries) {
  final buffer = StringBuffer('List<Map<String, String>> attributeList = [\n');
  for (final entry in entries) {
    buffer.writeln(
      "  {'key': '${_escapeSingleQuoted(entry.key)}', 'value': '${_escapeSingleQuoted(entry.value)}'},",
    );
  }
  buffer.write('];');
  return buffer.toString();
}

String _buildAttributeFilterSource(List<MapEntry<String, String>> entries) {
  final buffer = StringBuffer('Map<String, String> attributeFilter = {\n');
  for (final entry in entries) {
    buffer.writeln(
      "  '${_escapeSingleQuoted(entry.value)}': '${_escapeSingleQuoted(entry.key)}',",
    );
  }
  buffer.write('};');
  return buffer.toString();
}

String _humanizeAttributeKey(String key) {
  return key
      .split('_')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
      )
      .join(' ');
}

String _normalizeLabel(String label) =>
    label.replaceAll('’', "'").replaceAll(RegExp(r'\s+'), ' ').trim();

String _escapeSingleQuoted(String value) => value.replaceAll("'", "\\'");

bool _looksLikeStatKey(String key) {
  return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(key);
}

String _readText(File file) {
  return utf8
      .decode(file.readAsBytesSync(), allowMalformed: true)
      .replaceFirst('\ufeff', '');
}
