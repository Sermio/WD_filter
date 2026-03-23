import 'dart:convert';
import 'dart:io';

const _unitsPath = 'assets/data/units.json';
const _outPath = 'assets/generated/ui_icons/unit_ability_icon_index.json';

void main() {
  final unitsFile = File(_unitsPath);
  if (!unitsFile.existsSync()) {
    stderr.writeln('No existe $_unitsPath');
    exitCode = 2;
    return;
  }

  final decoded = jsonDecode(unitsFile.readAsStringSync());
  if (decoded is! List) {
    stderr.writeln('Formato inesperado en $_unitsPath');
    exitCode = 3;
    return;
  }

  final out = <Map<String, dynamic>>[];
  var totalPassive = 0;
  var totalActive = 0;

  for (final rawUnit in decoded) {
    if (rawUnit is! Map<String, dynamic>) {
      continue;
    }
    final id = '${rawUnit['id'] ?? ''}'.trim();
    if (id.isEmpty) {
      continue;
    }

    final passive = _extractAbilities(rawUnit['passiveAbilities']);
    final active = _extractAbilities(rawUnit['activeAbilities']);
    totalPassive += passive.length;
    totalActive += active.length;

    out.add({
      'id': id,
      'displayName': rawUnit['displayName'],
      'raceFolder': rawUnit['raceFolder'],
      'passiveAbilities': passive,
      'activeAbilities': active,
    });
  }

  out.sort(
    (a, b) => ('${a['id']}'.toLowerCase()).compareTo('${b['id']}'.toLowerCase()),
  );

  final outFile = File(_outPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));

  stdout.writeln(
    'Indice generado en $_outPath\n'
    'Unidades: ${out.length}\n'
    'Pasivas con icono: $totalPassive\n'
    'Activas con icono: $totalActive',
  );
}

List<Map<String, dynamic>> _extractAbilities(dynamic raw) {
  if (raw is! List) {
    return const [];
  }

  final result = <Map<String, dynamic>>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) {
      continue;
    }
    final atlas = entry['iconAtlas'];
    final row = entry['iconRow'];
    final col = entry['iconCol'];
    if (atlas is! String || row is! int || col is! int) {
      continue;
    }

    result.add({
      'name': entry['name'],
      'description': entry['description'],
      'iconAtlas': atlas,
      'iconRow': row,
      'iconCol': col,
      'iconAssetPath': 'assets/generated/ui_icons/$atlas/r${row}_c${col}.png',
    });
  }

  return result;
}
