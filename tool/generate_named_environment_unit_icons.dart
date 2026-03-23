import 'dart:convert';
import 'dart:io';

const _environmentUnitsPath =
    r'C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db\units\environment';
const _generatedRoot = r'assets\generated\unit_icons';

void main() {
  final sourceDir = Directory(_environmentUnitsPath);
  if (!sourceDir.existsSync()) {
    stderr.writeln('No existe $_environmentUnitsPath');
    exitCode = 2;
    return;
  }

  final atlasDir =
      Directory('$_generatedRoot${Platform.pathSeparator}units_70');
  if (!atlasDir.existsSync()) {
    stderr.writeln('No existe ${atlasDir.path}');
    exitCode = 3;
    return;
  }

  final sharedUnitsDir = Directory(
    '$_generatedRoot${Platform.pathSeparator}named${Platform.pathSeparator}units',
  );
  sharedUnitsDir.createSync(recursive: true);

  final index = <Map<String, dynamic>>[];
  final usedIds = <String>{};
  var copied = 0;

  final files = sourceDir
      .listSync(recursive: false)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.dt'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final raw = latin1.decode(file.readAsBytesSync(), allowInvalid: true);
    for (final entry in _parseTopLevelEntries(raw)) {
      if (entry.iconCol == null || entry.iconRow == null) {
        continue;
      }

      final sourcePath = '$_generatedRoot${Platform.pathSeparator}units_70'
          '${Platform.pathSeparator}r${entry.iconRow}_c${entry.iconCol}.png';
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        continue;
      }

      final id = _buildUniqueId(_slugify(entry.objectId), usedIds);
      final outPath = '${sharedUnitsDir.path}${Platform.pathSeparator}$id.png';
      sourceFile.copySync(outPath);

      index.add({
        'id': id,
        'objectId': entry.objectId,
        'displayName': entry.displayName ?? entry.objectId,
        'sourceDt': file.path.replaceAll(r'\', '/'),
        'row': entry.iconRow,
        'col': entry.iconCol,
        'conversationIconRow': entry.convIconRow,
        'conversationIconCol': entry.convIconCol,
        'sourceFile': sourcePath.replaceAll(r'\', '/'),
        'namedFile': outPath.replaceAll(r'\', '/'),
        'sharedNamedFile': outPath.replaceAll(r'\', '/'),
      });
      copied++;
    }
  }

  final indexPath =
      '${sharedUnitsDir.path}${Platform.pathSeparator}environment_icon_name_index.json';
  File(indexPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(index),
  );

  stdout.writeln(
    'Generados $copied iconos de NPC en ${sharedUnitsDir.path}\n'
    'Indice: $indexPath',
  );
}

List<_EnvironmentEntry> _parseTopLevelEntries(String source) {
  final entries = <_EnvironmentEntry>[];
  final lines = const LineSplitter().convert(source);

  var currentName = '';
  var depth = 0;
  final buffer = <String>[];

  for (final line in lines) {
    if (currentName.isEmpty) {
      final start = RegExp(
        r'^\s*(?:[A-Za-z0-9_]+\s+)?([A-Za-z0-9_]+)\s*:\s*[^{]+\{\s*$',
      ).firstMatch(line);
      if (start == null) {
        continue;
      }
      currentName = start.group(1)!;
      depth = _braceDelta(line);
      buffer
        ..clear()
        ..add(line);
      if (depth == 0) {
        final parsed = _parseEntryBlock(currentName, buffer);
        if (parsed != null) {
          entries.add(parsed);
        }
        currentName = '';
      }
      continue;
    }

    buffer.add(line);
    depth += _braceDelta(line);
    if (depth <= 0) {
      final parsed = _parseEntryBlock(currentName, buffer);
      if (parsed != null) {
        entries.add(parsed);
      }
      currentName = '';
      depth = 0;
    }
  }

  return entries;
}

_EnvironmentEntry? _parseEntryBlock(String objectId, List<String> lines) {
  if (objectId.startsWith('Base')) {
    return null;
  }

  String? displayName;
  int? iconCol;
  int? iconRow;
  int? convIconRow;
  int? convIconCol;

  var depth = 0;
  for (final line in lines) {
    final trimmed = line.trim();
    final currentDepth = depth;

    if (currentDepth == 1) {
      final nameMatch = RegExp(
        r'^name\s*[:=]\s*(?:"([^"]+)"|([A-Za-z0-9_.]+))',
      ).firstMatch(trimmed);
      if (nameMatch != null) {
        displayName = (nameMatch.group(1) ?? nameMatch.group(2) ?? '').trim();
      }

      final iconMatch =
          RegExp(r'^icon\s*=\s*(\d+)\s*,\s*(\d+)').firstMatch(trimmed);
      if (iconMatch != null && iconCol == null && iconRow == null) {
        iconCol = int.tryParse(iconMatch.group(1)!);
        iconRow = int.tryParse(iconMatch.group(2)!);
      }

      final convRowMatch =
          RegExp(r'^conv_icon_row\s*=\s*(\d+)').firstMatch(trimmed);
      if (convRowMatch != null) {
        convIconRow = int.tryParse(convRowMatch.group(1)!);
      }

      final convColMatch =
          RegExp(r'^conv_icon_col\s*=\s*(\d+)').firstMatch(trimmed);
      if (convColMatch != null) {
        convIconCol = int.tryParse(convColMatch.group(1)!);
      }
    }

    depth += _braceDelta(line);
  }

  if (iconCol == null || iconRow == null) {
    return null;
  }

  return _EnvironmentEntry(
    objectId: objectId,
    displayName: displayName,
    iconCol: iconCol,
    iconRow: iconRow,
    convIconRow: convIconRow,
    convIconCol: convIconCol,
  );
}

int _braceDelta(String line) {
  var delta = 0;
  for (final rune in line.runes) {
    if (rune == 123) {
      delta++;
    } else if (rune == 125) {
      delta--;
    }
  }
  return delta;
}

String _buildUniqueId(String base, Set<String> usedIds) {
  var candidate = base;
  var suffix = 2;
  while (!usedIds.add(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _slugify(String value) {
  final lower = value.toLowerCase();
  final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
}

class _EnvironmentEntry {
  const _EnvironmentEntry({
    required this.objectId,
    required this.displayName,
    required this.iconCol,
    required this.iconRow,
    required this.convIconRow,
    required this.convIconCol,
  });

  final String objectId;
  final String? displayName;
  final int? iconCol;
  final int? iconRow;
  final int? convIconRow;
  final int? convIconCol;
}
