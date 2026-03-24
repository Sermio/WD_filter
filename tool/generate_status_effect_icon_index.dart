import 'dart:convert';
import 'dart:io';

const _defaultWorldshiftDbRoot =
    r'C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db';
const _outputPath = 'assets/generated/ui_icons/buff_icons/status_effect_icon_index.json';
const _buffIconsDir = 'assets/generated/ui_icons/buff_icons';

void main(List<String> args) {
  final dbRoot = Directory(
    args.isNotEmpty && args.first.trim().isNotEmpty
        ? args.first
        : _defaultWorldshiftDbRoot,
  );
  if (!dbRoot.existsSync()) {
    stderr.writeln('No existe el directorio db: ${dbRoot.path}');
    exitCode = 2;
    return;
  }

  final sources = <File>[
    ..._collectDtFiles(Directory('${dbRoot.path}${Platform.pathSeparator}units')),
    ..._collectDtFiles(Directory('${dbRoot.path}${Platform.pathSeparator}effects')),
  ];

  final byName = <String, _EffectBucket>{};
  for (final f in sources) {
    final raw = latin1.decode(f.readAsBytesSync(), allowInvalid: true);
    final rel = _relativeFromRoot(f.path, dbRoot.path);
    _visitBlocks(raw, (header, body) {
      if (!_isStatusEffectHeader(header)) {
        return;
      }
      final parsed = _parseStatusEffectBody(body);
      if (parsed == null) {
        return;
      }
      final bucket = byName.putIfAbsent(
        parsed.name.toLowerCase(),
        () => _EffectBucket(parsed.name),
      );
      bucket.entries.add(
        _StatusEffectEntry(
          name: parsed.name,
          description: parsed.description,
          isDebuff: parsed.isDebuff,
          rowRaw: parsed.rowRaw,
          colRaw: parsed.colRaw,
          sourceFile: rel,
          sourceHeader: header.trim(),
        ),
      );
    });
  }

  final buffIcons = Directory(_buffIconsDir);
  final out = byName.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  final payload = out.map((bucket) {
    bucket.entries.sort((a, b) {
      final ra = (a.rowRaw ?? -1).compareTo(b.rowRaw ?? -1);
      if (ra != 0) return ra;
      return (a.colRaw ?? -1).compareTo(b.colRaw ?? -1);
    });
    return {
      'name': bucket.name,
      'entries': bucket.entries
          .map((e) => e.toJson(buffIcons: buffIcons))
          .toList(growable: false),
    };
  }).toList(growable: false);

  final outFile = File(_outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  stdout.writeln(
    'Indice de status effects generado: ${outFile.path} (${payload.length} nombres).',
  );
}

List<File> _collectDtFiles(Directory root) {
  if (!root.existsSync()) {
    return const [];
  }
  final files = <File>[];
  for (final e in root.listSync(recursive: true)) {
    if (e is File && e.path.toLowerCase().endsWith('.dt')) {
      files.add(e);
    }
  }
  return files;
}

String _relativeFromRoot(String fullPath, String rootPath) {
  final normFull = fullPath.replaceAll('\\', '/');
  final normRoot = rootPath.replaceAll('\\', '/');
  if (normFull.startsWith('$normRoot/')) {
    return normFull.substring(normRoot.length + 1);
  }
  return normFull;
}

bool _isStatusEffectHeader(String header) {
  final h = header.trim();
  return h.startsWith('CBuffEffect ') ||
      h.startsWith('E_debuff ') ||
      h.startsWith('E_multidebuff ') ||
      h.startsWith('S_stun ') ||
      h.startsWith('S_multistun ') ||
      h.startsWith('dstate ') ||
      RegExp(r'^effect\s*=\s*E_', caseSensitive: false).hasMatch(h) ||
      RegExp(r'^effect\s*=\s*S_', caseSensitive: false).hasMatch(h);
}

_ParsedEffect? _parseStatusEffectBody(String body) {
  final nameMatch = RegExp(
    r'^\s*name\s*=\s*(?:"([^"]*)"|([^\n]+))',
    multiLine: true,
  ).firstMatch(body);
  final name = _clean(nameMatch?.group(1) ?? nameMatch?.group(2));
  if (name == null || name.isEmpty || name.toLowerCase() == 'description') {
    return null;
  }

  final textMatch = RegExp(
    r'^\s*(?:text|descr)\s*=\s*"([^"]*)"',
    multiLine: true,
  ).firstMatch(body);
  final description = _clean(textMatch?.group(1));
  final debuff =
      RegExp(r'^\s*debuff\s*=\s*1\b', multiLine: true).hasMatch(body) ? true : null;
  final iconMatch = RegExp(r'^\s*icon\s*=\s*(\d+)\s*,\s*(\d+)', multiLine: true)
      .firstMatch(body);
  final rowRaw = int.tryParse(iconMatch?.group(1) ?? '');
  final colRaw = int.tryParse(iconMatch?.group(2) ?? '');

  return _ParsedEffect(
    name: name,
    description: description,
    isDebuff: debuff,
    rowRaw: rowRaw,
    colRaw: colRaw,
  );
}

String? _clean(String? raw) {
  if (raw == null) {
    return null;
  }
  final t = raw.trim();
  if (t.isEmpty) {
    return null;
  }
  if ((t.startsWith('"') && t.endsWith('"')) ||
      (t.startsWith("'") && t.endsWith("'"))) {
    return t.substring(1, t.length - 1).trim();
  }
  return t;
}

void _visitBlocks(String source, void Function(String header, String body) onBlock) {
  void visit(String text) {
    for (final b in _extractBlocks(text)) {
      onBlock(b.header, b.body);
      visit(b.body);
    }
  }

  visit(source);
}

List<_DtBlock> _extractBlocks(String source) {
  final blocks = <_DtBlock>[];
  final lines = source.split('\n');
  var depth = 0;
  String? currentHeader;
  final currentBody = <String>[];

  for (final line in lines) {
    final trimmed = line.trim();
    final opens = '{'.allMatches(line).length;
    final closes = '}'.allMatches(line).length;

    if (depth == 0 && trimmed.endsWith('{')) {
      currentHeader = trimmed.substring(0, trimmed.length - 1).trim();
      currentBody.clear();
      depth += opens - closes;
      continue;
    }

    if (currentHeader != null) {
      currentBody.add(line);
    }

    depth += opens - closes;

    if (currentHeader != null && depth == 0) {
      if (currentBody.isNotEmpty && currentBody.last.trim() == '}') {
        currentBody.removeLast();
      }
      blocks.add(_DtBlock(header: currentHeader, body: currentBody.join('\n')));
      currentHeader = null;
      currentBody.clear();
    }
  }

  return blocks;
}

class _DtBlock {
  final String header;
  final String body;

  const _DtBlock({required this.header, required this.body});
}

class _ParsedEffect {
  final String name;
  final String? description;
  final bool? isDebuff;
  final int? rowRaw;
  final int? colRaw;

  const _ParsedEffect({
    required this.name,
    required this.description,
    required this.isDebuff,
    required this.rowRaw,
    required this.colRaw,
  });
}

class _StatusEffectEntry {
  final String name;
  final String? description;
  final bool? isDebuff;
  final int? rowRaw;
  final int? colRaw;
  final String sourceFile;
  final String sourceHeader;

  const _StatusEffectEntry({
    required this.name,
    required this.description,
    required this.isDebuff,
    required this.rowRaw,
    required this.colRaw,
    required this.sourceFile,
    required this.sourceHeader,
  });

  Map<String, dynamic> toJson({required Directory buffIcons}) {
    final candidates = <Map<String, dynamic>>[];

    void addCandidate(String mode, int? row, int? col) {
      if (row == null || col == null || row < 0 || col < 0) {
        return;
      }
      final fileName = 'r${row}_c$col.png';
      final rel = 'assets/generated/ui_icons/buff_icons/$fileName';
      final exists = File('${buffIcons.path}${Platform.pathSeparator}$fileName')
          .existsSync();
      candidates.add({
        'mode': mode,
        'row': row,
        'col': col,
        'file': rel,
        'exists': exists,
      });
    }

    final r = rowRaw;
    final c = colRaw;

    // Basado en UI original: icon = row,col y ambos 1-based.
    if (r != null && c != null && r > 0 && c > 0) {
      addCandidate('one_based_to_zero_row_col', r - 1, c - 1);
    }
    addCandidate('raw_row_col', r, c);
    // Respaldo por datos invertidos.
    addCandidate('raw_col_row', c, r);
    if (r != null && c != null && r > 0 && c > 0) {
      addCandidate('one_based_to_zero_col_row', c - 1, r - 1);
    }

    Map<String, dynamic>? resolved;
    for (final cnd in candidates) {
      if (cnd['exists'] == true) {
        resolved = cnd;
        break;
      }
    }

    return {
      'name': name,
      'description': description,
      'isDebuff': isDebuff,
      'iconRowRaw': rowRaw,
      'iconColRaw': colRaw,
      'sourceFile': sourceFile,
      'sourceHeader': sourceHeader,
      'resolved': resolved,
      'candidates': candidates,
    };
  }
}

class _EffectBucket {
  final String name;
  final List<_StatusEffectEntry> entries = [];

  _EffectBucket(this.name);
}
