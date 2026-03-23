import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

const _globalsPath = r'C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db\items\globals.dt';
const _inventoryUiPath = r'C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db\ui\inventory.lua';
const _itemsAtlasPath = r'assets\ddsFiles\items.dds';
const _framesAtlasPath = r'assets\ddsFiles\item_frames.dds';
const _generatedRoot = r'assets\generated\item_icons';
const _defaultTexconvPath = r'C:\Tools\texconv\texconv.exe';

const _itemsCell = 64;
const _frameCell = 81;

const _frameTopByRace = <String, int>{
  'aliens': 0,
  'humans': 324,
  'mutants': 648,
};

const _overlayTopByRace = <String, int>{
  'aliens': 243,
  'humans': 567,
  'mutants': 891,
};

const _frameFallbackByRepo = <String, int>{
  'HUMAN_ENGINEER': 7,
  'HUMAN_NEUROSCIENCE': 8,
  'MUTANT_PSYCHIC': 7,
  'MUTANT_SPIRIT': 8,
  'ALIEN_DEFILER': 7,
  'ALIEN_ENIGMA': 8,
};

const _iconOverrideByRepo = <String, ({int row, int col})>{
  'HUMAN_ENGINEER': (row: 5, col: 2),
  'MUTANT_SPIRIT': (row: 6, col: 2),
  'MUTANT_PSYCHIC': (row: 6, col: 5),
  'ALIEN_DEFILER': (row: 4, col: 7),
};

void main(List<String> args) {
  final texconvPath = args.isNotEmpty ? args.first : _defaultTexconvPath;

  final itemsAtlas = _loadAtlasImage(
    atlasFile: File(_itemsAtlasPath),
    texconvPath: texconvPath,
  );
  final framesAtlas = _loadAtlasImage(
    atlasFile: File(_framesAtlasPath),
    texconvPath: texconvPath,
  );

  if (itemsAtlas == null) {
    stderr.writeln('No se pudo cargar $_itemsAtlasPath');
    exitCode = 2;
    return;
  }
  if (framesAtlas == null) {
    stderr.writeln('No se pudo cargar $_framesAtlasPath');
    exitCode = 3;
    return;
  }

  final globalsFile = File(_globalsPath);
  final inventoryFile = File(_inventoryUiPath);
  if (!globalsFile.existsSync()) {
    stderr.writeln('No existe $_globalsPath');
    exitCode = 4;
    return;
  }
  if (!inventoryFile.existsSync()) {
    stderr.writeln('No existe $_inventoryUiPath');
    exitCode = 5;
    return;
  }

  final slots = _parseItemSlots(globalsFile.readAsStringSync());
  final frameByRepo = _parseFrameByRepo(inventoryFile.readAsStringSync());

  final rootDir = Directory(_generatedRoot);
  final rawItemsDir = Directory('${rootDir.path}${Platform.pathSeparator}raw_items');
  final rawFramesDir = Directory('${rootDir.path}${Platform.pathSeparator}raw_frames');
  final rawOverlaysDir =
      Directory('${rootDir.path}${Platform.pathSeparator}raw_overlays');
  final namedIconsDir =
      Directory('${rootDir.path}${Platform.pathSeparator}named${Platform.pathSeparator}icons');
  final namedFramesDir =
      Directory('${rootDir.path}${Platform.pathSeparator}named${Platform.pathSeparator}frames');
  final namedOverlaysDir =
      Directory('${rootDir.path}${Platform.pathSeparator}named${Platform.pathSeparator}overlays');
  for (final dir in [
    rootDir,
    rawItemsDir,
    rawFramesDir,
    rawOverlaysDir,
    namedIconsDir,
    namedFramesDir,
    namedOverlaysDir,
  ]) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }
  _cleanDirectory(rawItemsDir);
  _cleanDirectory(rawFramesDir);
  _cleanDirectory(rawOverlaysDir);
  _cleanDirectory(namedIconsDir);
  _cleanDirectory(namedFramesDir);
  _cleanDirectory(namedOverlaysDir);

  final rawItemsIndex = _exportRawAtlas(
    atlas: itemsAtlas,
    cellWidth: _itemsCell,
    cellHeight: _itemsCell,
    outDir: rawItemsDir,
  );
  final rawFramesIndex = _exportRawAtlas(
    atlas: framesAtlas,
    cellWidth: _frameCell,
    cellHeight: _frameCell,
    outDir: rawFramesDir,
  );
  final rawOverlaysIndex = _exportRawOverlayBands(
    atlas: framesAtlas,
    cellWidth: _frameCell,
    cellHeight: _frameCell,
    outDir: rawOverlaysDir,
  );

  final namedIndex = <Map<String, dynamic>>[];
  var namedIcons = 0;
  var namedFrames = 0;
  var namedOverlays = 0;
  final missingIcons = <String>[];
  final missingFrames = <String>[];
  final missingOverlays = <String>[];

  for (final slot in slots) {
    final repo = slot.repo;
    final frameIdx = frameByRepo[repo];
    final frameTop = _frameTopByRace[slot.race];
    final overlayTop = _overlayTopByRace[slot.race];
    if (frameIdx == null || frameTop == null || overlayTop == null) {
      continue;
    }
    final iconOverride = _iconOverrideByRepo[repo];
    final iconRow = iconOverride?.row ?? slot.iconRow;
    final iconCol = iconOverride?.col ?? slot.iconCol;

    final iconCrop = img.copyCrop(
      itemsAtlas,
      x: (iconCol - 1) * _itemsCell,
      y: (iconRow - 1) * _itemsCell,
      width: _itemsCell,
      height: _itemsCell,
    );
    final frameCrop = img.copyCrop(
      framesAtlas,
      x: (frameIdx - 1) * _frameCell,
      y: frameTop,
      width: _frameCell,
      height: _frameCell,
    );
    final fallbackFrameIdx = _frameFallbackByRepo[repo];
    final fallbackFrameCrop = fallbackFrameIdx == null
        ? null
        : img.copyCrop(
            framesAtlas,
            x: (fallbackFrameIdx - 1) * _frameCell,
            y: frameTop,
            width: _frameCell,
            height: _frameCell,
          );
    final overlayCrop = img.copyCrop(
      framesAtlas,
      x: (frameIdx - 1) * _frameCell,
      y: overlayTop,
      width: _frameCell,
      height: _frameCell,
    );
    final fallbackOverlayCrop = fallbackFrameIdx == null
        ? null
        : img.copyCrop(
            framesAtlas,
            x: (fallbackFrameIdx - 1) * _frameCell,
            y: overlayTop,
            width: _frameCell,
            height: _frameCell,
          );

    String? iconOut;
    if (!_isEmptyCell(iconCrop)) {
      iconOut = '${namedIconsDir.path}${Platform.pathSeparator}${slot.repo}.png';
      File(iconOut).writeAsBytesSync(img.encodePng(iconCrop));
      namedIcons++;
    } else {
      missingIcons.add(slot.repo);
    }

    String? frameOut;
    var frameSourceIdx = frameIdx;
    if (_hasMeaningfulContent(frameCrop)) {
      frameOut =
          '${namedFramesDir.path}${Platform.pathSeparator}${slot.repo}_frame.png';
      File(frameOut).writeAsBytesSync(img.encodePng(frameCrop));
      namedFrames++;
    } else if (fallbackFrameCrop != null && _hasMeaningfulContent(fallbackFrameCrop)) {
      frameOut =
          '${namedFramesDir.path}${Platform.pathSeparator}${slot.repo}_frame.png';
      File(frameOut).writeAsBytesSync(img.encodePng(fallbackFrameCrop));
      frameSourceIdx = fallbackFrameIdx!;
      namedFrames++;
    } else {
      missingFrames.add(slot.repo);
    }

    String? overlayOut;
    var overlaySourceIdx = frameIdx;
    if (_hasMeaningfulContent(overlayCrop)) {
      overlayOut =
          '${namedOverlaysDir.path}${Platform.pathSeparator}${slot.repo}_overlay.png';
      File(overlayOut).writeAsBytesSync(img.encodePng(overlayCrop));
      namedOverlays++;
    } else if (fallbackOverlayCrop != null &&
        _hasMeaningfulContent(fallbackOverlayCrop)) {
      overlayOut =
          '${namedOverlaysDir.path}${Platform.pathSeparator}${slot.repo}_overlay.png';
      File(overlayOut).writeAsBytesSync(img.encodePng(fallbackOverlayCrop));
      overlaySourceIdx = fallbackFrameIdx!;
      namedOverlays++;
    } else {
      missingOverlays.add(slot.repo);
    }

    namedIndex.add({
      'repo': repo,
      'race': slot.race,
      'icon': {
        'col': iconCol,
        'row': iconRow,
        'present': iconOut != null,
        'file': iconOut?.replaceAll(r'\', '/'),
      },
      'frame': {
        'frameIdx': frameIdx,
        'sourceFrameIdx': frameOut == null ? null : frameSourceIdx,
        'top': frameTop,
        'present': frameOut != null,
        'file': frameOut?.replaceAll(r'\', '/'),
      },
      'overlay': {
        'frameIdx': frameIdx,
        'sourceFrameIdx': overlayOut == null ? null : overlaySourceIdx,
        'top': overlayTop,
        'present': overlayOut != null,
        'file': overlayOut?.replaceAll(r'\', '/'),
      },
    });
  }

  final rawItemsIndexFile =
      File('${rawItemsDir.path}${Platform.pathSeparator}atlas_index.json');
  rawItemsIndexFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(rawItemsIndex),
  );

  final rawFramesIndexFile =
      File('${rawFramesDir.path}${Platform.pathSeparator}atlas_index.json');
  rawFramesIndexFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(rawFramesIndex),
  );
  final rawOverlaysIndexFile =
      File('${rawOverlaysDir.path}${Platform.pathSeparator}atlas_index.json');
  rawOverlaysIndexFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(rawOverlaysIndex),
  );

  final namedIndexFile =
      File('${rootDir.path}${Platform.pathSeparator}named${Platform.pathSeparator}item_icon_name_index.json');
  namedIndexFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(namedIndex),
  );

  stdout.writeln(
    'Generados $namedIcons iconos nombrados, $namedFrames marcos nombrados y '
    '$namedOverlays overlays nombrados en ${rootDir.path}\n'
    'Raw items: ${rawItemsDir.path}\n'
    'Raw frames: ${rawFramesDir.path}\n'
    'Raw overlays: ${rawOverlaysDir.path}\n'
    'Indice: ${namedIndexFile.path}\n'
    'Slots sin icono visible: ${missingIcons.join(', ')}\n'
    'Slots sin marco visible: ${missingFrames.join(', ')}\n'
    'Slots sin overlay visible: ${missingOverlays.join(', ')}',
  );
}

List<_ItemSlot> _parseItemSlots(String source) {
  final matches = RegExp(
    r'^\s*((?:ALIEN|HUMAN|MUTANT)_[A-Z_]+)\s*\{\s*count\s*=\s*\d+;\s*race\s*=\s*(aliens|humans|mutants);\s*icon\s*=\s*(\d+)\s*,\s*(\d+)\s*;',
    multiLine: true,
  ).allMatches(source);

  return matches
      .map(
        (match) => _ItemSlot(
          repo: match.group(1)!,
          race: match.group(2)!,
          iconCol: int.parse(match.group(3)!),
          iconRow: int.parse(match.group(4)!),
        ),
      )
      .toList();
}

Map<String, int> _parseFrameByRepo(String source) {
  final block = RegExp(
    r'local\s+FrameByRepo\s*=\s*\{([\s\S]*?)\n\}',
    multiLine: true,
  ).firstMatch(source);
  if (block == null) {
    return const {};
  }

  final result = <String, int>{};
  for (final match in RegExp(
    r'^\s*([A-Z_]+)\s*=\s*(\d+),',
    multiLine: true,
  ).allMatches(block.group(1)!)) {
    result[match.group(1)!] = int.parse(match.group(2)!);
  }
  return result;
}

List<Map<String, dynamic>> _exportRawAtlas({
  required img.Image atlas,
  required int cellWidth,
  required int cellHeight,
  required Directory outDir,
}) {
  final rows = atlas.height ~/ cellHeight;
  final cols = atlas.width ~/ cellWidth;
  final index = <Map<String, dynamic>>[];

  for (var row = 1; row <= rows; row++) {
    for (var col = 1; col <= cols; col++) {
      final x = (col - 1) * cellWidth;
      final y = (row - 1) * cellHeight;
      final crop = img.copyCrop(
        atlas,
        x: x,
        y: y,
        width: cellWidth,
        height: cellHeight,
      );
      if (_isEmptyCell(crop)) {
        continue;
      }
      final fileName = 'r${row}_c${col}.png';
      final file = File('${outDir.path}${Platform.pathSeparator}$fileName');
      file.writeAsBytesSync(img.encodePng(crop));
      index.add({
        'row': row,
        'col': col,
        'x': x,
        'y': y,
        'width': cellWidth,
        'height': cellHeight,
        'file': file.path.replaceAll(r'\', '/'),
      });
    }
  }

  return index;
}

List<Map<String, dynamic>> _exportRawOverlayBands({
  required img.Image atlas,
  required int cellWidth,
  required int cellHeight,
  required Directory outDir,
}) {
  final index = <Map<String, dynamic>>[];

  for (final entry in _overlayTopByRace.entries) {
    final race = entry.key;
    final top = entry.value;
    final cols = atlas.width ~/ cellWidth;
    for (var col = 1; col <= cols; col++) {
      final x = (col - 1) * cellWidth;
      final crop = img.copyCrop(
        atlas,
        x: x,
        y: top,
        width: cellWidth,
        height: cellHeight,
      );
      if (_isEmptyCell(crop)) {
        continue;
      }
      final fileName = '${race}_c$col.png';
      final file = File('${outDir.path}${Platform.pathSeparator}$fileName');
      file.writeAsBytesSync(img.encodePng(crop));
      index.add({
        'race': race,
        'col': col,
        'x': x,
        'y': top,
        'width': cellWidth,
        'height': cellHeight,
        'file': file.path.replaceAll(r'\', '/'),
      });
    }
  }

  return index;
}

void _cleanDirectory(Directory dir) {
  if (!dir.existsSync()) {
    return;
  }
  for (final entity in dir.listSync(recursive: false)) {
    if (entity is File) {
      entity.deleteSync();
      continue;
    }
    if (entity is Directory) {
      entity.deleteSync(recursive: true);
    }
  }
}

img.Image? _loadAtlasImage({
  required File atlasFile,
  required String texconvPath,
}) {
  if (!atlasFile.existsSync()) {
    final pngFallback = File(
      atlasFile.path.replaceAll(RegExp(r'\.dds$', caseSensitive: false), '.png'),
    );
    if (pngFallback.existsSync()) {
      return _decodeImage(pngFallback);
    }
    return null;
  }

  final direct = _decodeImage(atlasFile);
  if (direct != null) {
    return direct;
  }

  if (!atlasFile.path.toLowerCase().endsWith('.dds')) {
    return null;
  }

  final texconv = File(texconvPath);
  if (!texconv.existsSync()) {
    final pngFallback = File(
      atlasFile.path.replaceAll(RegExp(r'\.dds$', caseSensitive: false), '.png'),
    );
    return _decodeImage(pngFallback);
  }

  final tempDir = Directory.systemTemp.createTempSync('item_icons_texconv_');
  try {
    final result = Process.runSync(
      texconv.path,
      ['-ft', 'png', '-y', '-o', tempDir.path, atlasFile.path],
      runInShell: false,
    );
    if (result.exitCode != 0) {
      stderr.writeln(result.stdout);
      stderr.writeln(result.stderr);
      return null;
    }
    final pngPath = '${tempDir.path}${Platform.pathSeparator}'
        '${atlasFile.uri.pathSegments.last.replaceAll(RegExp(r'\.dds$', caseSensitive: false), '.png')}';
    return _decodeImage(File(pngPath));
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

img.Image? _decodeImage(File file) {
  if (!file.existsSync()) {
    return null;
  }
  final bytes = file.readAsBytesSync();
  return img.decodeNamedImage(file.path, bytes) ?? img.decodeImage(bytes);
}

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

bool _hasMeaningfulContent(img.Image image) {
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
      if (visiblePixels > 150) {
        return true;
      }
    }
  }
  return false;
}

class _ItemSlot {
  const _ItemSlot({
    required this.repo,
    required this.race,
    required this.iconCol,
    required this.iconRow,
  });

  final String repo;
  final String race;
  final int iconCol;
  final int iconRow;
}
