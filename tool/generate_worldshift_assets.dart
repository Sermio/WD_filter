// Genera assets/data/units.json a partir del árbol de unidades del mod Worldshift.
//
// Uso (desde la raíz del proyecto Flutter):
//   dart run tool/generate_worldshift_assets.dart [ruta_a_worldshift/data/db/units]
//
// Por defecto usa la ruta del workspace del usuario si existe.
import 'dart:convert';
import 'dart:io';

import 'package:worldshift_assistant/data/dt_unit_parser.dart';
import 'package:worldshift_assistant/models/game_unit.dart';

const _defaultWorldshiftUnits = r'C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db\units';

Future<void> main(List<String> args) async {
  final root = Directory(args.isNotEmpty ? args.first : _defaultWorldshiftUnits);
  if (!root.existsSync()) {
    stderr.writeln('No existe el directorio: ${root.path}');
    stderr.writeln(
      'Pasa la ruta a data/db/units del clon de Worldshift como argumento.',
    );
    exitCode = 1;
    return;
  }

  final units = <GameUnit>[];
  // `environment`: bosses y unidades de escenario (Queen, Mech0, Adam, Safari, etc.).
  const folders = ['humans', 'mutants', 'aliens', 'environment'];

  for (final folder in folders) {
    final dir = Directory('${root.path}${Platform.pathSeparator}$folder');
    if (!dir.existsSync()) continue;
    for (final ent in dir.listSync(recursive: false)) {
      if (ent is! File || !ent.path.toLowerCase().endsWith('.dt')) continue;
      final id = ent.uri.pathSegments.last.replaceAll('.dt', '');
      final raw =
          latin1.decode(ent.readAsBytesSync(), allowInvalid: true);
      final parsed = DtUnitParser.parse(id, folder, raw);
      if (parsed != null) {
        units.add(parsed);
      }
    }
  }

  units.sort((a, b) {
    final rc = a.raceFolder.compareTo(b.raceFolder);
    if (rc != 0) return rc;
    return (a.displayName ?? a.id).compareTo(b.displayName ?? b.id);
  });

  final outDir = Directory('assets${Platform.pathSeparator}data');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  final outFile = File('assets${Platform.pathSeparator}data${Platform.pathSeparator}units.json');
  final jsonList = units.map((u) => u.toJson()).toList();
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonList));
  stdout.writeln('Escritas ${units.length} unidades en ${outFile.path}');
}
