// Genera `lib/data/unit_icon_lookup_generated.dart`: mapa de claves (id .dt, claves del builder, etc.)
// → rutas únicas a PNG solo por coordenada en atlas.
//
// Reglas (Worldshift): personajes jugables de campaña → officers-70x70; tropas/NPC habituales → units-70x70;
// conv_icon suelto → conversation_icons (49×49) si no hay main.
//
// Ejecutar tras:
//   dart run tool/extract_units_70_atlas.dart
//   dart run tool/generate_worldshift_assets.dart   (si cambió units.json)
//
// Uso:
//   dart run tool/generate_unit_icon_lookup.dart
import 'dart:convert';
import 'dart:io';

const _unitsJsonPath = r'assets\data\units.json';
const _unitsManualJsonPath = r'assets\data\units_manual.json';
const _outputDartPath = r'lib\data\unit_icon_lookup_generated.dart';

/// Coincide con claves de `lib/data/data.dart` → `units`.
const _builderDisplayKeys = <String>[
  'Commander',
  'Assassin',
  'Constructor',
  'Judge',
  'Surgeon',
  'Trooper',
  'Ripper',
  'AssaultBot',
  'Hellfire',
  'Engineer',
  'Defender',
  'HighPriest',
  'Guardian',
  'Shaman',
  'Sorcerer',
  'StoneGhost',
  'Warrior',
  'Brute',
  'AncientShade',
  'HowlingHorror',
  'Psychic',
  'EliteKaiRider',
  'Master',
  'Arbiter',
  'Dominator',
  'Harvester',
  'Manipulator',
  'Trisat',
  'Tritech',
  'Shifter',
  'Overseer',
  'Defiler',
  'PsiDetonator',
];

/// Sustituye id .dt cuando no coincide con la clave PascalCase compacta.
const _dtIdAliasByBuilderKey = <String, String>{
  'Engineer': 'technician2',
  'Psychic': 'eji2',
  'HighPriest': 'highpriest',
  'Defiler': 'dave',
};

/// Variantes adicionales (mismo chip / alternativa de retrato).
const _extraDtIdsByBuilderKey = <String, List<String>>{
  'Commander': ['lancelot'],
};

/// Retratos solo por nombre (búsquedas / UI que no usan id .dt). El resto de campaña va en [units_manual.json].
const _manualPortraitPathsByName = <String, List<String>>{};

String? _iconPathForUnit(Map<String, dynamic> u) {
  final cls = '${u['unitIconClass'] ?? 'unit'}'.trim();
  final mainR = u['mainIconRow'];
  final mainC = u['mainIconCol'];

  if (cls == 'commander') {
    if (mainR is int && mainC is int) {
      return 'assets/generated/unit_icons/officers_70/r${mainR}_c$mainC.png';
    }
    final cr = u['conversationIconRow'];
    final cc = u['conversationIconCol'];
    if (cr is int && cc is int) {
      return 'assets/generated/unit_icons/conversation_49/r${cr}_c$cc.png';
    }
    return null;
  }

  if (mainR is! int || mainC is! int) {
    return null;
  }
  if (cls == 'officer') {
    return 'assets/generated/unit_icons/officers_70/r${mainR}_c$mainC.png';
  }
  return 'assets/generated/unit_icons/units_70/r${mainR}_c$mainC.png';
}

String _defaultDtIdForBuilderKey(String key) =>
    key.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();

void main() {
  final unitsFile = File(_unitsJsonPath);
  if (!unitsFile.existsSync()) {
    stderr.writeln('No existe $_unitsJsonPath');
    exitCode = 2;
    return;
  }

  final baseList = (jsonDecode(unitsFile.readAsStringSync()) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final byId = <String, Map<String, dynamic>>{};
  for (final u in baseList) {
    final id = '${u['id'] ?? ''}'.trim();
    if (id.isNotEmpty) {
      byId[id] = u;
    }
  }

  final manualFile = File(_unitsManualJsonPath);
  if (manualFile.existsSync()) {
    final manualList =
        (jsonDecode(manualFile.readAsStringSync()) as List<dynamic>)
            .cast<Map<String, dynamic>>();
    for (final u in manualList) {
      final id = '${u['id'] ?? ''}'.trim();
      if (id.isNotEmpty) {
        byId[id] = u;
      }
    }
  }

  final units = byId.values.toList();

  /// lookupKey → orden estable de rutas
  final merged = <String, List<String>>{};

  void addPath(String lookupKey, String path) {
    if (lookupKey.isEmpty) {
      return;
    }
    final list = merged.putIfAbsent(lookupKey, () => []);
    if (!list.contains(path)) {
      list.add(path);
    }
  }

  for (final u in units) {
    final id = '${u['id'] ?? ''}'.trim();
    final p = _iconPathForUnit(u);
    if (id.isEmpty || p == null) {
      continue;
    }
    addPath(id, p);
    final norm = id.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toLowerCase();
    if (norm.isNotEmpty && norm != id) {
      addPath(norm, p);
    }
  }

  for (final key in _builderDisplayKeys) {
    final dtId = _dtIdAliasByBuilderKey[key] ?? _defaultDtIdForBuilderKey(key);
    final u = byId[dtId];
    if (u == null) {
      stderr.writeln('Aviso: sin units.json para builder key "$key" → id "$dtId"');
      continue;
    }
    final p = _iconPathForUnit(u);
    if (p == null) {
      stderr.writeln('Aviso: sin icono para "$key" (id $dtId)');
      continue;
    }
    addPath(key, p);
    for (final x in _extraDtIdsByBuilderKey[key] ?? const <String>[]) {
      final u2 = byId[x];
      final p2 = u2 == null ? null : _iconPathForUnit(u2);
      if (p2 != null) {
        addPath(key, p2);
      }
    }
  }

  for (final e in _manualPortraitPathsByName.entries) {
    for (final p in e.value) {
      addPath(e.key, p);
      final norm =
          e.key.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toLowerCase();
      if (norm.isNotEmpty && norm != e.key) {
        addPath(norm, p);
      }
    }
  }

  final sortedKeys = merged.keys.toList()..sort();

  final buf = StringBuffer()
    ..writeln('// GENERATED FILE — no editar.')
    ..writeln('// Generado por: dart run tool/generate_unit_icon_lookup.dart')
    ..writeln('//')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln('/// Clave → rutas candidatas (orden = preferencia).')
    ..writeln('/// Campaña jugable → officers_70; tropas/NPC → units_70; conv sin main → conversation_49.')
    ..writeln(
      'const Map<String, List<String>> kUnitIconAssetPathsByLookupKey = {',
    );

  for (final k in sortedKeys) {
    final paths = merged[k]!;
    final pathList = paths.map(json.encode).join(', ');
    buf.writeln('  ${json.encode(k)}: <String>[$pathList],');
  }

  buf.writeln('};');

  final outFile = File(_outputDartPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(buf.toString());
  stdout.writeln('Escrito ${outFile.path} (${merged.length} claves)');
}
