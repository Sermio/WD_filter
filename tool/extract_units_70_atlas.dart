// Corta los atlas DDS de iconos de unidad en PNG por celda (solo nomenclatura r{row}_c{col}.png).
//
// - units-70x70.dds → assets/generated/unit_icons/units_70/
// - officers-70x70.dds → assets/generated/unit_icons/officers_70/
// - conversation_icons.dds (49×49) → assets/generated/unit_icons/conversation_49/  [retratos commander]
//
// Filas/columnas 1-based (como en los .dt).
//
// Uso (desde la raíz del proyecto):
//   dart run tool/extract_units_70_atlas.dart [ruta_texconv.exe]
//
// Si el paquete `image` no decodifica el DDS, hace falta DirectX Texconv en la ruta indicada
// (por defecto C:\Tools\texconv\texconv.exe).
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

const _defaultTexconvPath = r'C:\Tools\texconv\texconv.exe';

void main(List<String> args) {
  final texconvPath = args.isNotEmpty ? args.first : _defaultTexconvPath;
  final root = Directory.current;

  final jobs = <_ExtractJob>[
    _ExtractJob(
      label: 'units',
      cellW: 70,
      cellH: 70,
      atlasFile: File('${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}ddsFiles${Platform.pathSeparator}units-70x70.dds'),
      outputDir: Directory(
        '${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}generated${Platform.pathSeparator}unit_icons${Platform.pathSeparator}units_70',
      ),
    ),
    _ExtractJob(
      label: 'officers',
      cellW: 70,
      cellH: 70,
      atlasFile: File('${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}ddsFiles${Platform.pathSeparator}officers-70x70.dds'),
      outputDir: Directory(
        '${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}generated${Platform.pathSeparator}unit_icons${Platform.pathSeparator}officers_70',
      ),
    ),
    _ExtractJob(
      label: 'conversation',
      cellW: 49,
      cellH: 49,
      atlasFile: File('${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}ddsFiles${Platform.pathSeparator}conversation_icons.dds'),
      outputDir: Directory(
        '${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}generated${Platform.pathSeparator}unit_icons${Platform.pathSeparator}conversation_49',
      ),
    ),
  ];

  var anyFailed = false;
  for (final job in jobs) {
    if (!job.atlasFile.existsSync()) {
      stderr.writeln('Omitido (${job.label}): no existe ${job.atlasFile.path}');
      continue;
    }
    final ok = _extractAtlas(
      job: job,
      texconvPath: texconvPath,
    );
    if (!ok) {
      anyFailed = true;
    }
  }

  if (anyFailed) {
    exitCode = 3;
  }
}

class _ExtractJob {
  _ExtractJob({
    required this.label,
    required this.cellW,
    required this.cellH,
    required this.atlasFile,
    required this.outputDir,
  });

  final String label;
  final int cellW;
  final int cellH;
  final File atlasFile;
  final Directory outputDir;
}

bool _extractAtlas({
  required _ExtractJob job,
  required String texconvPath,
}) {
  final image = _loadAtlasImage(
    atlasFile: job.atlasFile,
    texconvPath: texconvPath,
  );
  if (image == null) {
    stderr.writeln(
      'No se pudo decodificar ${job.atlasFile.path} (prueba con texconv: $texconvPath)',
    );
    return false;
  }

  job.outputDir.createSync(recursive: true);

  final cw = job.cellW;
  final ch = job.cellH;
  final rows = (image.height / ch).ceil();
  final cols = (image.width / cw).ceil();
  final metadata = <Map<String, dynamic>>[];
  var exported = 0;

  for (var row = 1; row <= rows; row++) {
    for (var col = 1; col <= cols; col++) {
      final left = (col - 1) * cw;
      final top = (row - 1) * ch;
      final width = _clampSize(cw, image.width - left);
      final height = _clampSize(ch, image.height - top);
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

      // Exportamos todas las celdas: las coordenadas del juego deben existir aunque la celda parezca vacía.
      final outName = 'r${row}_c$col.png';
      final outFile =
          File('${job.outputDir.path}${Platform.pathSeparator}$outName');
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

  final metadataFile = File(
    '${job.outputDir.path}${Platform.pathSeparator}atlas_index.json',
  );
  metadataFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(metadata),
  );

  stdout.writeln(
    '[${job.label}] Exportadas $exported celdas → ${job.outputDir.path}\n'
    '  metadata: ${metadataFile.path}',
  );
  return true;
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

  final ext = atlasFile.path.toLowerCase();
  if (!ext.endsWith('.dds')) {
    return null;
  }

  final texconv = File(texconvPath);
  if (!texconv.existsSync()) {
    return null;
  }

  final tempDir = Directory.systemTemp.createTempSync('units70_texconv_');
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
