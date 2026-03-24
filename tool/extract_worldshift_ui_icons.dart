import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

const _defaultWorldshiftUiRoot =
    r'C:\Users\sergi\Desktop\Proyectos\Worldshift\data\textures\ui';
const _defaultTexconvPath = r'C:\Tools\texconv\texconv.exe';

const _atlasConfigs = <_AtlasConfig>[
  _AtlasConfig(
    id: 'buttons',
    fileName: 'buttons.dds',
    // In-game action icons are rendered as 38x38 (see ui/actions.lua).
    cellWidth: 38,
    cellHeight: 38,
  ),
  _AtlasConfig(
    id: 'passive_abilities',
    fileName: 'passive_abilities.dds',
    cellWidth: 16,
    cellHeight: 16,
  ),
  _AtlasConfig(
    id: 'buff_icons',
    fileName: 'buff_icons.dds',
    cellWidth: 16,
    cellHeight: 16,
  ),
  _AtlasConfig(
    id: 'spec_tree_icons',
    fileName: 'spec_tree_icons.dds',
    cellWidth: 72,
    cellHeight: 71,
  ),
];

void main(List<String> args) {
  final uiRoot = Directory(
    args.isNotEmpty && args.first.trim().isNotEmpty
        ? args.first
        : _defaultWorldshiftUiRoot,
  );
  final texconvPath =
      args.length > 1 && args[1].trim().isNotEmpty ? args[1] : _defaultTexconvPath;

  if (!uiRoot.existsSync()) {
    stderr.writeln('UI textures directory does not exist: ${uiRoot.path}');
    exitCode = 2;
    return;
  }

  final outputRoot = Directory(
    'assets${Platform.pathSeparator}generated${Platform.pathSeparator}ui_icons',
  );
  outputRoot.createSync(recursive: true);

  final manifest = <Map<String, dynamic>>[];

  for (final config in _atlasConfigs) {
    final atlasFile = File(
      '${uiRoot.path}${Platform.pathSeparator}${config.fileName}',
    );
    if (!atlasFile.existsSync()) {
      stderr.writeln('Atlas not found: ${atlasFile.path}');
      continue;
    }

    final image = _loadAtlasImage(
      atlasFile: atlasFile,
      texconvPath: texconvPath,
    );
    if (image == null) {
      stderr.writeln('Could not decode atlas: ${atlasFile.path}');
      continue;
    }

    final atlasOutDir = Directory(
      '${outputRoot.path}${Platform.pathSeparator}${config.id}',
    );
    if (atlasOutDir.existsSync()) {
      for (final ent in atlasOutDir.listSync(recursive: false)) {
        if (ent is File && ent.path.toLowerCase().endsWith('.png')) {
          ent.deleteSync();
        }
      }
    }
    atlasOutDir.createSync(recursive: true);

    final rows = (image.height / config.cellHeight).ceil();
    final cols = (image.width / config.cellWidth).ceil();
    final cells = <Map<String, dynamic>>[];
    var exported = 0;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final left = col * config.cellWidth;
        final top = row * config.cellHeight;
        final width = _clampSize(config.cellWidth, image.width - left);
        final height = _clampSize(config.cellHeight, image.height - top);
        if (width <= 0 || height <= 0) {
          continue;
        }

        final cropped = img.copyCrop(
          image,
          x: left,
          y: top,
          width: width,
          height: height,
        );

        final fileName = 'r${row}_c$col.png';
        final outFile = File(
          '${atlasOutDir.path}${Platform.pathSeparator}$fileName',
        );
        outFile.writeAsBytesSync(img.encodePng(cropped));
        exported++;

        cells.add({
          'row': row,
          'col': col,
          'x': left,
          'y': top,
          'width': width,
          'height': height,
          'file': 'assets/generated/ui_icons/${config.id}/$fileName',
        });
      }
    }

    final atlasIndex = File(
      '${atlasOutDir.path}${Platform.pathSeparator}atlas_index.json',
    );
    atlasIndex.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(cells));

    manifest.add({
      'id': config.id,
      'sourceFile': atlasFile.path,
      'cellWidth': config.cellWidth,
      'cellHeight': config.cellHeight,
      'imageWidth': image.width,
      'imageHeight': image.height,
      'exportedCells': exported,
      'indexFile': 'assets/generated/ui_icons/${config.id}/atlas_index.json',
    });
  }

  final manifestFile = File(
    '${outputRoot.path}${Platform.pathSeparator}atlas_manifest.json',
  );
  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  stdout.writeln('Generated UI atlas exports in ${outputRoot.path}');
}

class _AtlasConfig {
  final String id;
  final String fileName;
  final int cellWidth;
  final int cellHeight;

  const _AtlasConfig({
    required this.id,
    required this.fileName,
    required this.cellWidth,
    required this.cellHeight,
  });
}

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

  if (!atlasFile.path.toLowerCase().endsWith('.dds')) {
    return null;
  }

  final texconv = File(texconvPath);
  if (!texconv.existsSync()) {
    return null;
  }

  final tempDir = Directory.systemTemp.createTempSync('ui_icons_texconv_');
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

