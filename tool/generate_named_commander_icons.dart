import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

const _unitsJsonPath = r'assets\data\units.json';
const _conversationAtlasPath = r'assets\ddsFiles\conversation_icons.dds';
const _outputDir = r'assets\generated\unit_icons\named\units';
const _defaultTexconvPath = r'C:\Tools\texconv\texconv.exe';
const _cellSize = 49;

void main(List<String> args) {
  final texconvPath = args.isNotEmpty ? args.first : _defaultTexconvPath;
  final unitsFile = File(_unitsJsonPath);
  if (!unitsFile.existsSync()) {
    stderr.writeln('No existe $_unitsJsonPath');
    exitCode = 2;
    return;
  }

  final atlas = _loadAtlasImage(
    atlasFile: File(_conversationAtlasPath),
    texconvPath: texconvPath,
  );
  if (atlas == null) {
    stderr.writeln('No se pudo cargar $_conversationAtlasPath');
    exitCode = 3;
    return;
  }

  final outDir = Directory(_outputDir);
  outDir.createSync(recursive: true);

  final units = (jsonDecode(unitsFile.readAsStringSync()) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final indexPath =
      '${outDir.path}${Platform.pathSeparator}commander_icon_name_index.json';
  final index = <Map<String, dynamic>>[];
  var generated = 0;

  for (final unit in units) {
    final iconClass = '${unit['unitIconClass'] ?? ''}'.trim();
    if (iconClass != 'commander') {
      continue;
    }

    final id = '${unit['id'] ?? ''}'.trim();
    final row = unit['conversationIconRow'];
    final col = unit['conversationIconCol'];
    if (id.isEmpty || row is! int || col is! int) {
      continue;
    }

    final crop = img.copyCrop(
      atlas,
      x: (col - 1) * _cellSize,
      y: (row - 1) * _cellSize,
      width: _cellSize,
      height: _cellSize,
    );

    final outPath = '${outDir.path}${Platform.pathSeparator}$id.png';
    File(outPath).writeAsBytesSync(img.encodePng(crop));
    generated++;

    index.add({
      'id': id,
      'displayName': unit['displayName'],
      'iconClass': iconClass,
      'row': row,
      'col': col,
      'sourceAtlas': _conversationAtlasPath.replaceAll(r'\', '/'),
      'namedFile': outPath.replaceAll(r'\', '/'),
    });
  }

  File(indexPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(index),
  );

  stdout.writeln(
    'Generados $generated iconos de commander en ${outDir.path}\n'
    'Indice: $indexPath',
  );
}

img.Image? _loadAtlasImage({
  required File atlasFile,
  required String texconvPath,
}) {
  if (!atlasFile.existsSync()) {
    return null;
  }

  final bytes = atlasFile.readAsBytesSync();
  final direct =
      img.decodeNamedImage(atlasFile.path, bytes) ?? img.decodeImage(bytes);
  if (direct != null) {
    return direct;
  }

  final texconv = File(texconvPath);
  if (!texconv.existsSync()) {
    return null;
  }

  final tempDir = Directory.systemTemp.createTempSync('commander_texconv_');
  try {
    final result = Process.runSync(
      texconv.path,
      [
        '-ft',
        'png',
        '-y',
        '-o',
        tempDir.path,
        atlasFile.path,
      ],
      runInShell: false,
    );
    if (result.exitCode != 0) {
      stderr.writeln(result.stdout);
      stderr.writeln(result.stderr);
      return null;
    }

    final pngPath = '${tempDir.path}${Platform.pathSeparator}'
        '${atlasFile.uri.pathSegments.last.replaceAll(RegExp(r'\.dds$', caseSensitive: false), '.png')}';
    final pngFile = File(pngPath);
    if (!pngFile.existsSync()) {
      return null;
    }

    final pngBytes = pngFile.readAsBytesSync();
    return img.decodeNamedImage(pngFile.path, pngBytes) ??
        img.decodeImage(pngBytes);
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
