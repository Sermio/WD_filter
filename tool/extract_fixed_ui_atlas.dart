import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Uso:\n'
      '  dart run tool/extract_fixed_ui_atlas.dart <atlas.dds|png> <outputDir> '
      '[cellWidth] [cellHeight] [texconvPath]\n\n'
      'Ejemplo para iconos de conversación de unidades:\n'
      '  dart run tool/extract_fixed_ui_atlas.dart '
      '"C:\\ruta\\conversation_icons.dds" '
      '"assets\\generated\\conversation_icons" 49 49 '
      '"C:\\Tools\\texconv\\texconv.exe"',
    );
    exitCode = 64;
    return;
  }

  final atlasPath = args[0];
  final outputDir = Directory(args[1]);
  final cellWidth = args.length > 2 ? int.parse(args[2]) : 49;
  final cellHeight = args.length > 3 ? int.parse(args[3]) : 49;
  final texconvPath = args.length > 4 ? args[4] : _defaultTexconvPath;

  final atlasFile = File(atlasPath);
  if (!atlasFile.existsSync()) {
    stderr.writeln('No existe el atlas: $atlasPath');
    exitCode = 2;
    return;
  }

  final image = _loadAtlasImage(
    atlasFile: atlasFile,
    texconvPath: texconvPath,
  );
  if (image == null) {
    stderr.writeln(
      'No se pudo decodificar el archivo ni convertirlo con texconv.\n'
      'Ruta texconv probada: $texconvPath',
    );
    exitCode = 3;
    return;
  }

  outputDir.createSync(recursive: true);

  final rows = (image.height / cellHeight).ceil();
  final cols = (image.width / cellWidth).ceil();
  final metadata = <Map<String, dynamic>>[];
  var exported = 0;

  for (var row = 1; row <= rows; row++) {
    for (var col = 1; col <= cols; col++) {
      final left = (col - 1) * cellWidth;
      final top = (row - 1) * cellHeight;
      final width = _clampSize(cellWidth, image.width - left);
      final height = _clampSize(cellHeight, image.height - top);
      if (width <= 0 || height <= 0) continue;

      final cropped = img.copyCrop(
        image,
        x: left,
        y: top,
        width: width,
        height: height,
      );

      if (_isEmptyCell(cropped)) {
        continue;
      }

      final outName = 'r${row}_c${col}.png';
      final outFile = File('${outputDir.path}${Platform.pathSeparator}$outName');
      outFile.writeAsBytesSync(img.encodePng(cropped));

      metadata.add({
        'row': row,
        'col': col,
        'x': left,
        'y': top,
        'width': width,
        'height': height,
        'file': outName,
      });
      exported++;
    }
  }

  final metadataFile =
      File('${outputDir.path}${Platform.pathSeparator}atlas_index.json');
  metadataFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(metadata),
  );

  stdout.writeln(
    'Exportados $exported iconos a ${outputDir.path}\n'
    'Metadata: ${metadataFile.path}',
  );
}

const _defaultTexconvPath = r'C:\Tools\texconv\texconv.exe';

img.Image? _loadAtlasImage({
  required File atlasFile,
  required String texconvPath,
}) {
  final bytes = atlasFile.readAsBytesSync();
  final direct =
      img.decodeNamedImage(atlasFile.path, bytes) ?? img.decodeImage(bytes);
  if (direct != null) {
    return direct;
  }

  final ext = atlasFile.path.toLowerCase();
  if (!ext.endsWith('.dds')) {
    return null;
  }

  final texconv = File(texconvPath);
  if (!texconv.existsSync()) {
    return null;
  }

  final tempDir = Directory.systemTemp.createTempSync('atlas_texconv_');
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

int _clampSize(int size, int remaining) => remaining < size ? remaining : size;

bool _isEmptyCell(img.Image image) {
  final bg = image.getPixel(0, 0);
  final bgA = bg.a.toInt();
  final bgR = bg.r.toInt();
  final bgG = bg.g.toInt();
  final bgB = bg.b.toInt();

  var visiblePixels = 0;
  for (final pixel in image) {
    final a = pixel.a.toInt();
    final delta = (pixel.r.toInt() - bgR).abs() +
        (pixel.g.toInt() - bgG).abs() +
        (pixel.b.toInt() - bgB).abs() +
        (a - bgA).abs();
    if (a > 8 || delta > 32) {
      visiblePixels++;
      if (visiblePixels > 20) {
        return false;
      }
    }
  }
  return true;
}
