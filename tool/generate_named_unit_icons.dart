import 'dart:convert';
import 'dart:io';

const _unitsJsonPath = r'assets\data\units.json';
const _generatedRoot = r'assets\generated\unit_icons';

void main() {
  final unitsFile = File(_unitsJsonPath);
  if (!unitsFile.existsSync()) {
    stderr.writeln('No existe $_unitsJsonPath');
    exitCode = 2;
    return;
  }

  final namedDir = Directory('$_generatedRoot${Platform.pathSeparator}named');
  final namedUnitsDir =
      Directory('${namedDir.path}${Platform.pathSeparator}units');
  final namedOfficersDir =
      Directory('${namedDir.path}${Platform.pathSeparator}officers');
  if (!namedDir.existsSync()) {
    namedDir.createSync(recursive: true);
  }
  if (!namedUnitsDir.existsSync()) {
    namedUnitsDir.createSync(recursive: true);
  }
  if (!namedOfficersDir.existsSync()) {
    namedOfficersDir.createSync(recursive: true);
  }

  final units = (jsonDecode(unitsFile.readAsStringSync()) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final index = <Map<String, dynamic>>[];
  var copied = 0;

  for (final unit in units) {
    final id = '${unit['id'] ?? ''}'.trim();
    final displayName = '${unit['displayName'] ?? id}'.trim();
    final iconClass = '${unit['unitIconClass'] ?? 'unit'}'.trim();
    final row = unit['mainIconRow'];
    final col = unit['mainIconCol'];

    if (id.isEmpty || row is! int || col is! int) {
      continue;
    }

    final sourcePath = _resolveAtlasIconPath(
      iconClass: iconClass,
      row: row,
      col: col,
    );
    if (sourcePath == null) {
      continue;
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      continue;
    }

    final outPath = _resolveNamedOutputPath(
      namedRoot: namedDir.path,
      iconClass: iconClass,
      id: id,
    );
    final sharedOutPath =
        '${namedUnitsDir.path}${Platform.pathSeparator}$id.png';
    sourceFile.copySync(outPath);
    if (outPath != sharedOutPath) {
      sourceFile.copySync(sharedOutPath);
    }

    index.add({
      'id': id,
      'displayName': displayName,
      'raceFolder': unit['raceFolder'],
      'iconClass': iconClass,
      'row': row,
      'col': col,
      'sourceFile': sourcePath.replaceAll(r'\', '/'),
      'namedFile': outPath.replaceAll(r'\', '/'),
      'sharedNamedFile': sharedOutPath.replaceAll(r'\', '/'),
    });
    copied++;
  }

  final indexFile = File(
      '${namedDir.path}${Platform.pathSeparator}unit_icon_name_index.json');
  indexFile
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(index));

  stdout.writeln(
    'Generados $copied iconos nombrados en ${namedDir.path}\n'
    'Índice: ${indexFile.path}',
  );
}

String? _resolveAtlasIconPath({
  required String iconClass,
  required int row,
  required int col,
}) {
  switch (iconClass) {
    case 'officer':
      return '$_generatedRoot${Platform.pathSeparator}officers_70'
          '${Platform.pathSeparator}r${row}_c${col}.png';
    case 'unit':
      return '$_generatedRoot${Platform.pathSeparator}units_70'
          '${Platform.pathSeparator}r${row}_c${col}.png';
    default:
      return null;
  }
}

String _resolveNamedOutputPath({
  required String namedRoot,
  required String iconClass,
  required String id,
}) {
  switch (iconClass) {
    case 'officer':
      return '$namedRoot${Platform.pathSeparator}officers'
          '${Platform.pathSeparator}$id.png';
    case 'unit':
      return '$namedRoot${Platform.pathSeparator}units'
          '${Platform.pathSeparator}$id.png';
    default:
      return '$namedRoot${Platform.pathSeparator}$id.png';
  }
}
