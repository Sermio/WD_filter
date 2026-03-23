import 'dart:convert';
import 'dart:io';

const _unitsJsonPath = 'assets/data/units.json';
const _outRoot = 'assets/generated/ui_icons';
const _worldshiftDbRoot = r'C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db';

void main() {
  final outDir = Directory(_outRoot);
  outDir.createSync(recursive: true);

  final units = _loadUnits();
  final byAtlas = <String, Map<String, _IconNameBucket>>{
    'buttons': {},
    'passive_abilities': {},
    'buff_icons': {},
    'spec_tree_icons': {},
  };

  _collectFromUnits(units, byAtlas);
  _collectSpecTreeNames(byAtlas['spec_tree_icons']!);
  _collectBuffCandidates(byAtlas['buff_icons']!, byAtlas);

  for (final entry in byAtlas.entries) {
    _writeAtlasNameIndex(entry.key, entry.value);
  }

  stdout.writeln('Indices de nombre generados en $_outRoot');
}

List<Map<String, dynamic>> _loadUnits() {
  final f = File(_unitsJsonPath);
  if (!f.existsSync()) {
    throw StateError('No existe $_unitsJsonPath');
  }
  final decoded = jsonDecode(f.readAsStringSync());
  if (decoded is! List) {
    throw StateError('Formato invalido en $_unitsJsonPath');
  }
  return decoded.whereType<Map<String, dynamic>>().toList();
}

void _collectFromUnits(
  List<Map<String, dynamic>> units,
  Map<String, Map<String, _IconNameBucket>> byAtlas,
) {
  for (final unit in units) {
    final unitId = '${unit['id'] ?? ''}'.trim();
    final displayName = '${unit['displayName'] ?? unitId}'.trim();
    _collectAbilityList(
      unit['activeAbilities'],
      fallbackAtlas: 'buttons',
      unitId: unitId,
      unitName: displayName,
      bucket: byAtlas['buttons']!,
    );
    _collectAbilityList(
      unit['passiveAbilities'],
      fallbackAtlas: 'passive_abilities',
      unitId: unitId,
      unitName: displayName,
      bucket: byAtlas['passive_abilities']!,
    );
  }
}

void _collectAbilityList(
  dynamic rawList, {
  required String fallbackAtlas,
  required String unitId,
  required String unitName,
  required Map<String, _IconNameBucket> bucket,
}) {
  if (rawList is! List) {
    return;
  }
  for (final raw in rawList.whereType<Map<String, dynamic>>()) {
    final atlas = (raw['iconAtlas'] as String?) ?? fallbackAtlas;
    if (atlas != fallbackAtlas) {
      continue;
    }
    final col = raw['iconCol'];
    final row = raw['iconRow'];
    final abilityName = '${raw['name'] ?? ''}'.trim();
    if (col is! int || row is! int || abilityName.isEmpty) {
      continue;
    }
    _addName(
      bucket,
      row: row,
      col: col,
      name: abilityName,
      source: 'unit:$unitId',
      context: unitName,
    );
  }
}

void _collectSpecTreeNames(Map<String, _IconNameBucket> bucket) {
  final techgrid = File('$_worldshiftDbRoot${Platform.pathSeparator}ui${Platform.pathSeparator}techgrid.lua');
  if (!techgrid.existsSync()) {
    return;
  }

  final repoToName = <String, String>{};
  for (final nameFile in [
    '$_worldshiftDbRoot${Platform.pathSeparator}items${Platform.pathSeparator}humansspecs.dt',
    '$_worldshiftDbRoot${Platform.pathSeparator}items${Platform.pathSeparator}mutantsspecs.dt',
    '$_worldshiftDbRoot${Platform.pathSeparator}items${Platform.pathSeparator}aliensspecs.dt',
  ]) {
    final f = File(nameFile);
    if (!f.existsSync()) {
      continue;
    }
    final text = latin1.decode(f.readAsBytesSync(), allowInvalid: true);
    final itemPattern = RegExp(
      r'item\s+\w+\s*:\s*\w+\s*\{([\s\S]*?)\n\}',
      multiLine: true,
    );
    for (final m in itemPattern.allMatches(text)) {
      final body = m.group(1) ?? '';
      final repo = RegExp(r'^\s*repo\s*=\s*([A-Z0-9_]+)', multiLine: true)
          .firstMatch(body)
          ?.group(1);
      final name = RegExp(r'^\s*name\s*=\s*"([^"]+)"', multiLine: true)
          .firstMatch(body)
          ?.group(1);
      if (repo != null && name != null && name.trim().isNotEmpty) {
        repoToName[repo] = name.trim();
      }
    }
  }

  final lua = techgrid.readAsStringSync();
  final specSlotPattern = RegExp(
    r'SpecSlot_[A-D]\d\s*=\s*DefSpecSlot\s*\{\s*row\s*=\s*(\d+)\s*,\s*col\s*=\s*(\d+)\s*,\s*repo\s*=\s*"([A-Z0-9_]+)"',
  );
  for (final m in specSlotPattern.allMatches(lua)) {
    final row1 = int.tryParse(m.group(1) ?? '');
    final col1 = int.tryParse(m.group(2) ?? '');
    final repo = m.group(3) ?? '';
    if (row1 == null || col1 == null || repo.isEmpty) {
      continue;
    }
    // techgrid.lua indexes are 1-based.
    final row = row1 - 1;
    final col = col1 - 1;
    final name = repoToName[repo] ?? repo;
    _addName(
      bucket,
      row: row,
      col: col,
      name: name,
      source: 'techgrid:$repo',
      context: 'spec',
    );
  }
}

void _collectBuffCandidates(
  Map<String, _IconNameBucket> buffBucket,
  Map<String, Map<String, _IconNameBucket>> byAtlas,
) {
  final unitsDir = Directory('$_worldshiftDbRoot${Platform.pathSeparator}units');
  if (!unitsDir.existsSync()) {
    return;
  }

  final knownPassiveKeys = byAtlas['passive_abilities']!.keys.toSet();
  final knownButtonKeys = byAtlas['buttons']!.keys.toSet();

  final filePattern = RegExp(r'\.dt$', caseSensitive: false);
  for (final ent in unitsDir.listSync(recursive: true)) {
    if (ent is! File || !filePattern.hasMatch(ent.path)) {
      continue;
    }
    final text = latin1.decode(ent.readAsBytesSync(), allowInvalid: true);
    final lines = text.split('\n');
    String? currentName;
    for (final line in lines) {
      final nameMatch = RegExp(r'^\s*name\s*=\s*"([^"]+)"').firstMatch(line);
      if (nameMatch != null) {
        currentName = nameMatch.group(1)?.trim();
      }
      final iconMatch = RegExp(r'^\s*icon\s*=\s*(\d+)\s*,\s*(\d+)').firstMatch(line);
      if (iconMatch == null || currentName == null || currentName.isEmpty) {
        continue;
      }
      final col = int.tryParse(iconMatch.group(1)!);
      final row = int.tryParse(iconMatch.group(2)!);
      if (col == null || row == null) {
        continue;
      }
      // buff_icons atlas is 16x16 over 256x64 => col 0..15, row 0..3.
      if (col < 0 || col > 15 || row < 0 || row > 3) {
        continue;
      }
      final key = '$row:$col';
      if (knownPassiveKeys.contains(key) || knownButtonKeys.contains(key)) {
        continue;
      }
      _addName(
        buffBucket,
        row: row,
        col: col,
        name: currentName,
        source: 'units-dt',
        context: ent.uri.pathSegments.last,
      );
    }
  }
}

void _addName(
  Map<String, _IconNameBucket> bucket, {
  required int row,
  required int col,
  required String name,
  required String source,
  required String context,
}) {
  final clean = name.trim();
  if (clean.isEmpty) {
    return;
  }
  final key = '$row:$col';
  final cell = bucket.putIfAbsent(key, () => _IconNameBucket(row: row, col: col));
  cell.names.add(clean);
  cell.sources.add({'source': source, 'context': context, 'name': clean});
}

void _writeAtlasNameIndex(String atlasId, Map<String, _IconNameBucket> map) {
  final out = map.values.toList()
    ..sort((a, b) {
      final rc = a.row.compareTo(b.row);
      if (rc != 0) return rc;
      return a.col.compareTo(b.col);
    });

  final jsonOut = out
      .map(
        (e) => {
          'row': e.row,
          'col': e.col,
          'key': '${e.row}:${e.col}',
          'file': 'assets/generated/ui_icons/$atlasId/r${e.row}_c${e.col}.png',
          'names': e.names.toList()..sort(),
          'sources': e.sources,
        },
      )
      .toList();

  final file = File(
    '$_outRoot${Platform.pathSeparator}$atlasId${Platform.pathSeparator}icon_name_index.json',
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonOut));
}

class _IconNameBucket {
  _IconNameBucket({
    required this.row,
    required this.col,
  });

  final int row;
  final int col;
  final Set<String> names = <String>{};
  final List<Map<String, String>> sources = <Map<String, String>>[];
}
