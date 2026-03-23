import 'dart:convert';
import 'dart:io';

const _generatedRoot = r'assets\generated\unit_icons';

void main() {
  final namedRoot = Directory('$_generatedRoot${Platform.pathSeparator}named');
  final sharedUnitsDir =
      Directory('${namedRoot.path}${Platform.pathSeparator}units');
  final officersDir =
      Directory('${namedRoot.path}${Platform.pathSeparator}officers');

  final playableIndexFile = File(
      '${namedRoot.path}${Platform.pathSeparator}unit_icon_name_index.json');

  if (!playableIndexFile.existsSync()) {
    stderr.writeln('No existe ${playableIndexFile.path}');
    exitCode = 2;
    return;
  }
  sharedUnitsDir.createSync(recursive: true);
  for (final file
      in sharedUnitsDir.listSync(recursive: false).whereType<File>()) {
    if (file.path.toLowerCase().endsWith('.png') ||
        file.path.toLowerCase().endsWith('.json')) {
      file.deleteSync();
    }
  }

  final combined = <Map<String, dynamic>>[];
  final usedIds = <String>{};

  final playable =
      (jsonDecode(playableIndexFile.readAsStringSync()) as List<dynamic>)
          .cast<Map<String, dynamic>>();
  for (final entry in playable) {
    final id = '${entry['id'] ?? ''}'.trim();
    final sourceFile = File('${entry['sourceFile'] ?? ''}');
    if (id.isEmpty || !sourceFile.existsSync()) {
      continue;
    }
    final outPath = '${sharedUnitsDir.path}${Platform.pathSeparator}$id.png';
    sourceFile.copySync(outPath);
    combined.add({
      ...entry,
      'bucket': 'playable',
      'sharedNamedFile': outPath.replaceAll(r'\', '/'),
    });
    usedIds.add(id);
  }

  if (officersDir.existsSync()) {
    for (final file
        in officersDir.listSync(recursive: false).whereType<File>()) {
      if (!file.path.toLowerCase().endsWith('.png')) {
        continue;
      }
      final id = file.uri.pathSegments.last.replaceAll('.png', '');
      final outPath = '${sharedUnitsDir.path}${Platform.pathSeparator}$id.png';
      file.copySync(outPath);
      combined.add({
        'id': id,
        'bucket': 'officer',
        'sourceFile': file.path.replaceAll(r'\', '/'),
        'sharedNamedFile': outPath.replaceAll(r'\', '/'),
      });
      usedIds.add(id);
    }
  }

  final indexFile = File(
      '${sharedUnitsDir.path}${Platform.pathSeparator}unit_icon_name_index.json');
  indexFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(combined),
  );

  stdout.writeln(
    'Reconstruida carpeta compartida ${sharedUnitsDir.path}\n'
    'Total iconos: ${combined.length}\n'
    'Indice: ${indexFile.path}',
  );
}
