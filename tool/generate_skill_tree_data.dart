// dart run tool/generate_skill_tree_data.dart [ruta_Worldshift]
//
// Lee humansspecs/mutantsspecs/aliensspecs.dt + techgrid.lua, fusiona con
// tool/skill_tree_overrides.json y escribe lib/data/generated/skill_tree_*.g.dart

import 'dart:convert';
import 'dart:io';

const _defaultWorldshift = r'C:\Users\sergi\Desktop\Proyectos\Worldshift';
const _overridesPath = 'tool/skill_tree_overrides.json';

const _raceTargets = <_RaceTarget>[
  _RaceTarget(
    jsonKey: 'HUMAN',
    specsFile: 'humansspecs.dt',
    repoPrefix: 'HUMAN_SPEC',
    parentDart: 'human_skill_tree_data.dart',
    partName: 'skill_tree_humans.g.dart',
    typedefName: 'HumanSpecTreeNode',
    gridName: 'humanSpecTreeGrid',
    visualName: 'humanSpecTreeVisualRowRepos',
    mapName: 'humanSpecTreeByRepo',
  ),
  _RaceTarget(
    jsonKey: 'MUTANT',
    specsFile: 'mutantsspecs.dt',
    repoPrefix: 'MUTANT_SPEC',
    parentDart: 'mutant_skill_tree_data.dart',
    partName: 'skill_tree_mutants.g.dart',
    typedefName: 'MutantSpecTreeNode',
    gridName: 'mutantSpecTreeGrid',
    visualName: 'mutantSpecTreeVisualRowRepos',
    mapName: 'mutantSpecTreeByRepo',
  ),
  _RaceTarget(
    jsonKey: 'ALIEN',
    specsFile: 'aliensspecs.dt',
    repoPrefix: 'ALIEN_SPEC',
    parentDart: 'alien_skill_tree_data.dart',
    partName: 'skill_tree_aliens.g.dart',
    typedefName: 'AlienSpecTreeNode',
    gridName: 'alienSpecTreeGrid',
    visualName: 'alienSpecTreeVisualRowRepos',
    mapName: 'alienSpecTreeByRepo',
  ),
];

void main(List<String> args) {
  final wsArg = args.isNotEmpty && !args.first.startsWith('-') ? args.first : null;
  final itemsDir = _resolveItemsDir(wsArg);
  final techgrid = _resolveTechgrid(wsArg);

  if (itemsDir == null || !itemsDir.existsSync()) {
    stderr.writeln(
      'No se encontró carpeta de items (*specs.dt). Pasa la ruta al clon de '
      'Worldshift o copia los .dt a assets/loot/source_game/items/ (tras refresh).',
    );
    exit(1);
  }
  if (techgrid == null || !techgrid.existsSync()) {
    stderr.writeln(
      'No se encontró techgrid.lua. Pasa la ruta a Worldshift o copia el lua a '
      'assets/loot/source_game/refs/techgrid.lua.',
    );
    exit(1);
  }

    final overrides = _OverridesFile.load();
  final lua = techgrid.readAsStringSync();
  final techByRepo = _parseTechgrid(lua);

  final sep = Platform.pathSeparator;
  final outDir = Directory('lib${sep}data${sep}generated');
  outDir.createSync(recursive: true);

  for (final race in _raceTargets) {
    final dt = File('${itemsDir.path}$sep${race.specsFile}');
    if (!dt.existsSync()) {
      stderr.writeln('Aviso: falta ${dt.path}; se omite ${race.jsonKey}.');
      continue;
    }
    var text = _readSpecsDtFile(dt);
    text = _repairSpecApostrophePlaceholders(text);
    final parsedByRepo = <String, _ParsedSpec>{};
    for (final block in _itemBlocks(text)) {
      final repo = _firstMatch(block, RegExp(r'^\s*repo\s*=\s*(\w+)', multiLine: true));
      if (repo == null || !repo.startsWith(race.repoPrefix)) {
        continue;
      }
      final title = _firstMatch(block, RegExp(r'^\s*name\s*=\s*"([^"]*)"', multiLine: true))?.trim();
      final description = _extractDescription(block);
      final targets = _extractTargets(block);
      final rankCount = _inferRanks(block);
      final snippets = _rankStatSnippets(block, rankCount);
      parsedByRepo[repo] = _ParsedSpec(
        repo: repo,
        title: title ?? repo,
        description: description,
        targets: targets,
        rankCount: rankCount,
        rankStatSnippets: snippets,
      );
    }

    if (parsedByRepo.isEmpty) {
      stderr.writeln(
        'Aviso: ningún SpecItem con prefijo ${race.repoPrefix} en ${race.specsFile}; se omite ${race.jsonKey}.',
      );
      continue;
    }

    final ro = overrides.forRace(race.jsonKey);
    final visual = ro.visualRowRepos ??
        _defaultVisualRows(_reposInTechOrder(techByRepo, race.repoPrefix));

    _validateVisual(visual, parsedByRepo.keys.toSet(), race.jsonKey);

    final outPath = '${outDir.path}$sep${race.partName}';
    _writeGeneratedPart(
      path: outPath,
      parentDart: race.parentDart,
      race: race,
      visual: visual,
      parsedByRepo: parsedByRepo,
      techByRepo: techByRepo,
      ro: ro,
    );
    stdout.writeln('Generado: $outPath (${parsedByRepo.length} nodos)');
  }
}

class _RaceTarget {
  const _RaceTarget({
    required this.jsonKey,
    required this.specsFile,
    required this.repoPrefix,
    required this.parentDart,
    required this.partName,
    required this.typedefName,
    required this.gridName,
    required this.visualName,
    required this.mapName,
  });

  final String jsonKey;
  final String specsFile;
  final String repoPrefix;
  final String parentDart;
  final String partName;
  final String typedefName;
  final String gridName;
  final String visualName;
  final String mapName;
}

class _ParsedSpec {
  const _ParsedSpec({
    required this.repo,
    required this.title,
    required this.description,
    required this.targets,
    required this.rankCount,
    required this.rankStatSnippets,
  });

  final String repo;
  final String title;
  final String description;
  /// Unit class ids from `target { ... }` in the `.dt` (overrides JSON replaces when set).
  final List<String> targets;
  final int rankCount;
  final List<String> rankStatSnippets;
}

class _OverridesFile {
  _OverridesFile(this.raw);

  final Map<String, dynamic> raw;

  static _OverridesFile load() {
    final f = File(_overridesPath);
    if (!f.existsSync()) {
      stderr.writeln('Falta $_overridesPath');
      exit(1);
    }
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Overrides: raíz debe ser objeto');
    }
    return _OverridesFile(decoded);
  }

  _RaceOverrides forRace(String key) {
    final m = raw[key];
    if (m is! Map<String, dynamic>) {
      return _RaceOverrides.empty();
    }
    List<List<String>>? visual;
    final vr = m['visualRowRepos'];
    if (vr is List) {
      visual = vr
          .whereType<List>()
          .map((row) => row.whereType<String>().toList())
          .where((row) => row.isNotEmpty)
          .toList();
    }
    final iconCol = <String, int>{};
    final ic = m['iconColOverride'];
    if (ic is Map) {
      for (final e in ic.entries) {
        final k = '${e.key}';
        final v = e.value;
        if (v is int) {
          iconCol[k] = v;
        }
      }
    }
    final iconRow = <String, int>{};
    final ir = m['iconRowOverride'];
    if (ir is Map) {
      for (final e in ir.entries) {
        final k = '${e.key}';
        final v = e.value;
        if (v is int) {
          iconRow[k] = v;
        }
      }
    }
    final nodes = <String, _NodeOverride>{};
    final nm = m['nodes'];
    if (nm is Map) {
      for (final e in nm.entries) {
        final repo = '${e.key}';
        final v = e.value;
        if (v is! Map<String, dynamic>) {
          continue;
        }
        List<String>? targets;
        final t = v['targets'];
        if (t is List) {
          targets = t.whereType<String>().toList();
        }
        List<String>? rankBonuses;
        final rb = v['rankBonuses'];
        if (rb is List) {
          rankBonuses = rb.whereType<String>().toList();
        }
        final desc = v['descriptionOverride'] is String ? v['descriptionOverride'] as String : null;
        final titleOv = v['titleOverride'] is String ? v['titleOverride'] as String : null;
        nodes[repo] = _NodeOverride(
          targets: targets,
          rankBonuses: rankBonuses,
          descriptionOverride: desc,
          titleOverride: titleOv,
        );
      }
    }
    return _RaceOverrides(
      visualRowRepos: visual,
      iconColOverride: iconCol,
      iconRowOverride: iconRow,
      nodes: nodes,
    );
  }
}

class _RaceOverrides {
  _RaceOverrides({
    required this.visualRowRepos,
    required this.iconColOverride,
    required this.iconRowOverride,
    required this.nodes,
  });

  factory _RaceOverrides.empty() => _RaceOverrides(
        visualRowRepos: null,
        iconColOverride: {},
        iconRowOverride: {},
        nodes: {},
      );

  final List<List<String>>? visualRowRepos;
  final Map<String, int> iconColOverride;
  final Map<String, int> iconRowOverride;
  final Map<String, _NodeOverride> nodes;
}

class _NodeOverride {
  const _NodeOverride({
    this.targets,
    this.rankBonuses,
    this.descriptionOverride,
    this.titleOverride,
  });

  final List<String>? targets;
  final List<String>? rankBonuses;
  final String? descriptionOverride;
  final String? titleOverride;
}

class _TechSlot {
  const _TechSlot({required this.row, required this.col});

  final int row;
  final int col;
}

Directory? _resolveItemsDir(String? worldshiftArg) {
  final sep = Platform.pathSeparator;
  final candidates = <String>[
    if (worldshiftArg != null)
      '$worldshiftArg${sep}data${sep}db${sep}items',
    '$_defaultWorldshift${sep}data${sep}db${sep}items',
    'assets${sep}loot${sep}source_game${sep}items',
  ];
  for (final p in candidates) {
    final d = Directory(p);
    if (d.existsSync()) {
      return d;
    }
  }
  return null;
}

File? _resolveTechgrid(String? worldshiftArg) {
  final sep = Platform.pathSeparator;
  final candidates = <String>[
    if (worldshiftArg != null)
      '$worldshiftArg${sep}data${sep}db${sep}ui${sep}techgrid.lua',
    '$_defaultWorldshift${sep}data${sep}db${sep}ui${sep}techgrid.lua',
    'assets${sep}loot${sep}source_game${sep}refs${sep}techgrid.lua',
  ];
  for (final p in candidates) {
    final f = File(p);
    if (f.existsSync()) {
      return f;
    }
  }
  return null;
}

/// *specs.dt are UTF-8 in current Worldshift trees; Latin-1 was wrong and produced `ï¿½` mojibake.
String _readSpecsDtFile(File f) {
  final bytes = f.readAsBytesSync();
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } catch (_) {
    return latin1.decode(bytes, allowInvalid: true);
  }
}

/// U+FFFD in shipped *_specs.dt where a typographic apostrophe was lost.
String _repairSpecApostrophePlaceholders(String s) {
  if (!s.contains('\uFFFD')) {
    return s;
  }
  var o = s.replaceAllMapped(
    RegExp(r'([A-Za-z]+)\uFFFDs(?=[\s\.,;:!?\)\]]|$)'),
    (m) => "${m[1]}'s",
  );
  o = o.replaceAllMapped(
    RegExp(r'([A-Za-z]+)\uFFFD(?=\s)'),
    (m) => "${m[1]}' ",
  );
  return o;
}

Iterable<String> _itemBlocks(String text) sync* {
  final re = RegExp(r'item\s+\w+\s*:\s*\w+SpecItem\s*\{', caseSensitive: false);
  var start = 0;
  Match? m;
  while ((m = re.firstMatch(text.substring(start))) != null) {
    final i = start + m!.start;
    final depthStart = start + m.end - 1;
    final end = _closingBrace(text, depthStart);
    if (end == null) {
      break;
    }
    yield text.substring(i, end + 1);
    start = end + 1;
  }
}

int? _closingBrace(String s, int openBrace) {
  var depth = 0;
  for (var i = openBrace; i < s.length; i++) {
    final c = s[i];
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return null;
}

String? _firstMatch(String block, RegExp re) => re.firstMatch(block)?.group(1);

String _extractDescription(String block) {
  // Worldshift *specs.dt uses `text = "..."` for the player-facing blurb.
  for (final re in [
    RegExp(r'^\s*text\s*=\s*"((?:[^"\\]|\\.)*)"', multiLine: true),
    RegExp(r'^\s*description\s*=\s*"((?:[^"\\]|\\.)*)"', multiLine: true),
    RegExp(r'^\s*desc\s*=\s*"((?:[^"\\]|\\.)*)"', multiLine: true),
    RegExp(r'^\s*info\s*=\s*"((?:[^"\\]|\\.)*)"', multiLine: true),
  ]) {
    final m = re.firstMatch(block);
    if (m != null) {
      return _unescapeLuaString(m.group(1) ?? '');
    }
  }
  return '';
}

/// `target { Technician ... }` blocks in *specs.dt`.
List<String> _extractTargets(String block) {
  final head = RegExp(r'\btarget\s*\{', caseSensitive: false).firstMatch(block);
  if (head == null) {
    return const [];
  }
  final open = block.indexOf('{', head.start);
  if (open < 0) {
    return const [];
  }
  final close = _closingBrace(block, open);
  if (close == null) {
    return const [];
  }
  final body = block.substring(open + 1, close);
  final out = <String>[];
  for (final rawLine in body.split('\n')) {
    var t = rawLine.trim();
    if (t.isEmpty || t.startsWith('--')) {
      continue;
    }
    if (t.endsWith(',')) {
      t = t.substring(0, t.length - 1).trim();
    }
    if (t.isEmpty) {
      continue;
    }
    if (RegExp(r'^\w+$').hasMatch(t)) {
      out.add(t);
    }
  }
  return out;
}

String _unescapeLuaString(String s) =>
    s.replaceAll(r'\"', '"').replaceAll(r'\\', '\\').replaceAll(r'\n', '\n');

int _inferRanks(String block) {
  var fromLevels = 1;
  final lvPair = RegExp(r'levels\s*=\s*(\d+)\s*,\s*(\d+)').firstMatch(block);
  if (lvPair != null) {
    final hi = int.tryParse(lvPair.group(2)!) ?? 1;
    fromLevels = hi.clamp(1, 10);
  }

  final statsM = RegExp(r'\bstats\s*\{').firstMatch(block);
  if (statsM == null) {
    return fromLevels;
  }
  final sub = block.substring(statsM.start);
  final open = sub.indexOf('{');
  if (open < 0) {
    return fromLevels;
  }
  final close = _closingBrace(sub, open);
  if (close == null) {
    return fromLevels;
  }
  final body = sub.substring(open + 1, close);
  var maxSeg = 1;
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('--')) {
      continue;
    }
    final eq = RegExp(r'^\s*(\w+)\s*=\s*(.+)$').firstMatch(trimmed);
    if (eq == null) {
      continue;
    }
    final rhs = eq.group(2)!.trim();
    if (!rhs.contains('/')) {
      continue;
    }
    final parts = rhs.split('/').where((p) => p.trim().isNotEmpty).length;
    if (parts > maxSeg) {
      maxSeg = parts;
    }
  }
  if (maxSeg > 1) {
    return maxSeg;
  }
  return fromLevels;
}

List<String> _rankStatSnippets(String block, int rankCount) {
  final statsM = RegExp(r'\bstats\s*\{').firstMatch(block);
  if (statsM == null) {
    return List.generate(rankCount, (_) => '');
  }
  final sub = block.substring(statsM.start);
  final open = sub.indexOf('{');
  if (open < 0) {
    return List.generate(rankCount, (_) => '');
  }
  final close = _closingBrace(sub, open);
  if (close == null) {
    return List.generate(rankCount, (_) => '');
  }
  final body = sub.substring(open + 1, close);
  final keyToParts = <String, List<String>>{};
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('--')) {
      continue;
    }
    final eq = RegExp(r'^\s*(\w+)\s*=\s*(.+)$').firstMatch(trimmed);
    if (eq == null) {
      continue;
    }
    final key = eq.group(1)!;
    var rhs = eq.group(2)!.trim();
    if (rhs.endsWith(',')) {
      rhs = rhs.substring(0, rhs.length - 1).trim();
    }
    final parts = rhs.contains('/')
        ? rhs.split('/').map((p) => p.trim()).where((p) => p.isNotEmpty).toList()
        : [rhs];
    keyToParts[key] = parts;
  }

  final out = <String>[];
  for (var r = 0; r < rankCount; r++) {
    final bits = <String>[];
    for (final e in keyToParts.entries) {
      final segs = e.value;
      if (segs.isEmpty) {
        continue;
      }
      final idx = r < segs.length ? r : segs.length - 1;
      bits.add('${e.key} = ${segs[idx]}');
    }
    out.add(bits.join(', '));
  }
  return out;
}

Map<String, _TechSlot> _parseTechgrid(String lua) {
  final map = <String, _TechSlot>{};
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
    map[repo] = _TechSlot(row: row1 - 1, col: col1 - 1);
  }
  return map;
}

List<String> _reposInTechOrder(Map<String, _TechSlot> tech, String prefix) {
  final list = tech.entries.where((e) => e.key.startsWith(prefix)).toList()
    ..sort((a, b) {
      final c = a.value.row.compareTo(b.value.row);
      if (c != 0) {
        return c;
      }
      return a.value.col.compareTo(b.value.col);
    });
  return list.map((e) => e.key).toList();
}

List<List<String>> _defaultVisualRows(List<String> orderedRepos) {
  const pattern = [2, 3, 2, 3];
  final out = <List<String>>[];
  var i = 0;
  for (final sz in pattern) {
    if (i >= orderedRepos.length) {
      break;
    }
    final end = (i + sz > orderedRepos.length) ? orderedRepos.length : i + sz;
    out.add(orderedRepos.sublist(i, end));
    i = end;
  }
  if (i < orderedRepos.length) {
    out.add(orderedRepos.sublist(i));
  }
  return out;
}

void _validateVisual(List<List<String>> visual, Set<String> repos, String raceKey) {
  final seen = <String>{};
  for (final row in visual) {
    for (final r in row) {
      if (seen.contains(r)) {
        stderr.writeln('Aviso [$raceKey]: repo duplicado en layout: $r');
      }
      seen.add(r);
      if (!repos.contains(r)) {
        stderr.writeln('Aviso [$raceKey]: layout referencia $r sin entrada en .dt');
      }
    }
  }
  for (final r in repos) {
    if (!seen.contains(r)) {
      stderr.writeln('Aviso [$raceKey]: nodo $r no aparece en visualRowRepos');
    }
  }
}

List<String> _mergeRankBonuses({
  required String title,
  required int rankCount,
  required List<String> snippets,
  required List<String>? override,
}) {
  if (override != null && override.isNotEmpty) {
    if (override.length != rankCount) {
      stderr.writeln(
        'Aviso: rankBonuses (${override.length}) != rankCount ($rankCount) para $title; se recorta o rellena.',
      );
    }
    final out = <String>[];
    for (var i = 0; i < rankCount; i++) {
      if (i < override.length) {
        out.add(override[i]);
      } else if (snippets.length > i && snippets[i].isNotEmpty) {
        out.add(snippets[i]);
      } else {
        out.add(override.last);
      }
    }
    return out;
  }
  return List.generate(rankCount, (i) {
    if (i < snippets.length && snippets[i].isNotEmpty) {
      return snippets[i];
    }
    if (snippets.isNotEmpty) {
      return snippets.last;
    }
    return '$title — rank ${i + 1}';
  });
}

void _writeGeneratedPart({
  required String path,
  required String parentDart,
  required _RaceTarget race,
  required List<List<String>> visual,
  required Map<String, _ParsedSpec> parsedByRepo,
  required Map<String, _TechSlot> techByRepo,
  required _RaceOverrides ro,
}) {
  final buf = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('// Regenerar: dart run tool/generate_skill_tree_data.dart [ruta_Worldshift]')
    ..writeln()
    ..writeln("part of '../$parentDart';")
    ..writeln()
    ..writeln('/// Grid filas = patrón visual en app (ver $parentDart).')
    ..writeln('const List<List<${race.typedefName}>> ${race.gridName} = [');

  for (var ri = 0; ri < visual.length; ri++) {
    final row = visual[ri];
    buf.writeln('  [');
    for (var ci = 0; ci < row.length; ci++) {
      final repo = row[ci];
      final p = parsedByRepo[repo];
      if (p == null) {
        stderr.writeln('Falta parseo para repo $repo (${race.jsonKey})');
        exit(1);
      }
      final node = ro.nodes[repo];
      final targets = node?.targets ?? p.targets;
      final description = node?.descriptionOverride ?? p.description;
      final title = node?.titleOverride ?? p.title;
      final rankBonuses = _mergeRankBonuses(
        title: title,
        rankCount: p.rankCount,
        snippets: p.rankStatSnippets,
        override: node?.rankBonuses,
      );
      final tech = techByRepo[repo];
      var iconRow = tech?.row ?? 0;
      var iconCol = tech?.col ?? 0;
      if (ro.iconRowOverride.containsKey(repo)) {
        iconRow = ro.iconRowOverride[repo]!;
      }
      if (ro.iconColOverride.containsKey(repo)) {
        iconCol = ro.iconColOverride[repo]!;
      }
      if (tech == null) {
        stderr.writeln('Aviso: sin techgrid para $repo (${race.jsonKey})');
      }

      buf.writeln('    ${race.typedefName}(');
      buf.writeln("      repo: ${_dartStr(repo)},");
      buf.writeln("      title: ${_dartStr(title)},");
      buf.writeln('      description: ${_dartStr(description)},');
      buf.writeln('      targets: ${_dartStringList(targets)},');
      buf.writeln('      iconRow: $iconRow,');
      buf.writeln('      iconCol: $iconCol,');
      buf.writeln('      rankBonuses: ${_dartStringList(rankBonuses)},');
      buf.writeln('      rankStatSnippets: ${_dartStringList(p.rankStatSnippets)},');
      buf.writeln('    )${ci < row.length - 1 ? ',' : ''}');
    }
    buf.writeln('  ]${ri < visual.length - 1 ? ',' : ''}');
  }

  buf.writeln('];');
  buf.writeln();
  buf.writeln('const List<List<String>> ${race.visualName} = ${_dartStringGrid(visual)};');
  buf.writeln();
  buf.writeln(
    'final Map<String, ${race.typedefName}> ${race.mapName} = '
    'Map<String, ${race.typedefName}>.unmodifiable({',
  );
  buf.writeln('  for (final row in ${race.gridName})');
  buf.writeln('    for (final n in row) n.repo: n,');
  buf.writeln('});');

  File(path).writeAsStringSync(buf.toString());
}

String _dartStr(String s) => jsonEncode(s);

String _dartStringList(List<String> list) {
  if (list.isEmpty) {
    return 'const []';
  }
  final inner = list.map(_dartStr).join(', ');
  return 'const [$inner]';
}

String _dartStringGrid(List<List<String>> g) {
  final rows = g.map((row) => 'const [${row.map(_dartStr).join(', ')}]').join(', ');
  return 'const [$rows]';
}
