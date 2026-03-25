// dart run tool/verify_spec_dt.dart
//
// Compara el número de rangos inferido de cada `*specs.dt` con lo esperado
// (máximo de segmentos separados por `/` en el bloque stats, mínimo 1).
// Ajusta la ruta si tu copia de Worldshift está en otro sitio.

import 'dart:convert';
import 'dart:io';

final _worldshiftItems = Directory(
  r'C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db\items',
);

void main() {
  if (!_worldshiftItems.existsSync()) {
    stderr.writeln('No existe ${_worldshiftItems.path}');
    exit(1);
  }
  for (final name in [
    'humansspecs.dt',
    'mutantsspecs.dt',
    'aliensspecs.dt',
  ]) {
    final f = File('${_worldshiftItems.path}${Platform.pathSeparator}$name');
    if (!f.existsSync()) {
      stderr.writeln('Falta $name');
      continue;
    }
    final text = latin1.decode(f.readAsBytesSync(), allowInvalid: true);
    print('=== $name ===');
    for (final block in _itemBlocks(text)) {
      final repo = _firstMatch(block, RegExp(r'^\s*repo\s*=\s*(\w+)', multiLine: true));
      if (repo == null) {
        continue;
      }
      final ranks = _inferRanks(block);
      print('$repo -> $ranks rank(s)');
    }
  }
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

int _inferRanks(String block) {
  var fromLevels = 1;
  final lvPair =
      RegExp(r'levels\s*=\s*(\d+)\s*,\s*(\d+)').firstMatch(block);
  if (lvPair != null) {
    final hi = int.tryParse(lvPair.group(2)!) ?? 1;
    fromLevels = hi.clamp(1, 10);
  } else {
    final lvOne = RegExp(r'levels\s*=\s*(\d+)\s*$', multiLine: true)
        .firstMatch(block);
    if (lvOne != null) {
      fromLevels = 1;
    }
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
