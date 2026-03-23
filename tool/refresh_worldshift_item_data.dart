import 'dart:convert';
import 'dart:io';

const _defaultWorldshiftRoot = r'C:\Users\sergi\Desktop\Proyectos\Worldshift';

const _sourceGameItemsDir = r'assets\loot\source_game\items';
const _sourceGameTextsDir = r'assets\loot\source_game\texts';
const _sourceGameRefsDir = r'assets\loot\source_game\refs';
const _legacyTsvDir = r'assets\tsvFiles';

void main(List<String> args) {
  final worldshiftRoot = Directory(
    args.isNotEmpty ? args.first : _defaultWorldshiftRoot,
  );
  if (!worldshiftRoot.existsSync()) {
    stderr.writeln('No existe el directorio: ${worldshiftRoot.path}');
    stderr.writeln(
      'Uso: dart run tool/refresh_worldshift_item_data.dart [ruta_a_Worldshift]',
    );
    exitCode = 1;
    return;
  }

  final itemsDir = Directory(
    '${worldshiftRoot.path}${Platform.pathSeparator}data${Platform.pathSeparator}db${Platform.pathSeparator}items',
  );
  final textsEnDir = Directory(
    '${worldshiftRoot.path}${Platform.pathSeparator}data${Platform.pathSeparator}texts${Platform.pathSeparator}en',
  );
  final missionsDir = Directory(
    '${worldshiftRoot.path}${Platform.pathSeparator}data${Platform.pathSeparator}maps${Platform.pathSeparator}missions',
  );
  final unitsDir = Directory(
    '${worldshiftRoot.path}${Platform.pathSeparator}data${Platform.pathSeparator}db${Platform.pathSeparator}units',
  );

  if (!itemsDir.existsSync() ||
      !textsEnDir.existsSync() ||
      !missionsDir.existsSync() ||
      !unitsDir.existsSync()) {
    stderr.writeln(
      'Faltan carpetas esperadas dentro del proyecto Worldshift. Revisa la ruta base.',
    );
    exitCode = 2;
    return;
  }

  for (final dirPath in [
    _sourceGameItemsDir,
    _sourceGameTextsDir,
    _sourceGameRefsDir,
    _legacyTsvDir,
  ]) {
    Directory(dirPath).createSync(recursive: true);
  }

  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}items.tsv',
    '$_sourceGameItemsDir${Platform.pathSeparator}items.tsv',
  );
  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}loot.tsv',
    '$_sourceGameItemsDir${Platform.pathSeparator}loot.tsv',
  );
  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}loot index.tsv',
    '$_sourceGameItemsDir${Platform.pathSeparator}loot index.tsv',
  );
  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}drop.tsv',
    '$_sourceGameItemsDir${Platform.pathSeparator}drop.tsv',
  );
  _copyFile(
    '${textsEnDir.path}${Platform.pathSeparator}missions.tsv',
    '$_sourceGameTextsDir${Platform.pathSeparator}missions.tsv',
  );

  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}items.tsv',
    '$_legacyTsvDir${Platform.pathSeparator}items_extra_data_complete.txt',
  );
  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}items.tsv',
    '$_legacyTsvDir${Platform.pathSeparator}copy of items.tsv',
  );
  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}loot.tsv',
    '$_legacyTsvDir${Platform.pathSeparator}loot_complete.txt',
  );
  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}loot.tsv',
    '$_legacyTsvDir${Platform.pathSeparator}loot.tsv',
  );
  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}loot index.tsv',
    '$_legacyTsvDir${Platform.pathSeparator}loot index.tsv',
  );
  _copyFile(
    '${itemsDir.path}${Platform.pathSeparator}drop.tsv',
    '$_legacyTsvDir${Platform.pathSeparator}drop.tsv',
  );

  _writeMapRefs(missionsDir);
  _writeUnitRefs(unitsDir);

  _runDartScript('tool/generate_item_origin_index.dart');
  _runDartScript('tool/generate_item_list.dart');
  _runDartScript('tool/rebuild_attribute_list.dart', [worldshiftRoot.path]);

  stdout.writeln(
    'Sincronización de items Worldshift completada.\n'
    'Ruta base: ${worldshiftRoot.path}',
  );
}

void _copyFile(String sourcePath, String targetPath) {
  final source = File(sourcePath);
  if (!source.existsSync()) {
    stderr.writeln('No existe $sourcePath');
    exitCode = 3;
    throw FileSystemException('Falta archivo requerido', sourcePath);
  }
  final target = File(targetPath);
  target.parent.createSync(recursive: true);
  target.writeAsBytesSync(source.readAsBytesSync());
  stdout.writeln('Copiado: $targetPath');
}

void _writeMapRefs(Directory missionsDir) {
  final out =
      File('$_sourceGameRefsDir${Platform.pathSeparator}map_drop_refs.tsv');
  final rows = <String>[
    'source_file\tref_kind\tref_value',
  ];

  final files =
      missionsDir.listSync(recursive: false).whereType<File>().where((file) {
    final lower = file.path.toLowerCase();
    return lower.endsWith('.map') || lower.endsWith('.lua');
  }).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final mapRefPattern = RegExp(
    r'drop_(id|item)\s*=\s*(?:int|str):\s*([^\r\n]+)',
    caseSensitive: false,
  );
  final giveItemPattern = RegExp(r'GiveItem\(([^)]+)\)', caseSensitive: false);

  for (final file in files) {
    final relative = 'missions/${file.uri.pathSegments.last}';
    final raw = _readText(file);

    for (final match in mapRefPattern.allMatches(raw)) {
      rows.add(
        '$relative\tdrop_${match.group(1)!.toLowerCase()}\t${match.group(2)!.trim()}',
      );
    }
    for (final match in giveItemPattern.allMatches(raw)) {
      rows.add('$relative\truntime_give_item\t${match.group(1)!.trim()}');
    }
  }

  out.writeAsStringSync('${rows.join('\n')}\n');
  stdout.writeln('Generado: ${out.path}');
}

void _writeUnitRefs(Directory unitsDir) {
  final out = File(
    '$_sourceGameRefsDir${Platform.pathSeparator}unit_drop_refs.tsv',
  );
  final rows = <String>[
    'source_file\tunit_or_context\tref_kind\tref_value',
  ];

  final files = unitsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.dt'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final pattern = RegExp(r'\b(drop_id|drop_item)\s*=\s*([^\r\n;]+)');

  for (final file in files) {
    final raw = _readText(file);
    final relative = file.path
        .replaceAll(unitsDir.path.replaceAll(r'\', '/'), '')
        .replaceAll(r'\', '/')
        .replaceFirst('/', '');
    final unitId = file.uri.pathSegments.last.replaceAll('.dt', '');

    for (final match in pattern.allMatches(raw)) {
      rows.add(
        'data/db/units/$relative\t$unitId\t${match.group(1)}\t${match.group(2)!.trim()}',
      );
    }
  }

  out.writeAsStringSync('${rows.join('\n')}\n');
  stdout.writeln('Generado: ${out.path}');
}

String _readText(File file) {
  return utf8
      .decode(file.readAsBytesSync(), allowMalformed: true)
      .replaceFirst('\ufeff', '');
}

void _runDartScript(String scriptPath, [List<String> args = const []]) {
  final commandArgs = ['run', scriptPath, ...args];
  final result = Process.runSync('dart', commandArgs);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    throw ProcessException(
      'dart',
      commandArgs,
      'El script falló: $scriptPath',
      result.exitCode,
    );
  }
}
