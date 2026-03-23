import 'dart:convert';
import 'dart:io';

const _unitsJsonPath = r'assets\data\units.json';
const _atlasIndexPath = r'assets\generated\unit_icons\units_70\atlas_index.json';
const _outputPath = r'assets\generated\unit_icons\units_70\units_70_lookup.json';
const _mappedOutputPath = r'assets\generated\unit_icons\units_70\units_70_mapped.json';
const _unmappedOutputPath = r'assets\generated\unit_icons\units_70\units_70_unmapped.json';

void main() {
  final unitsFile = File(_unitsJsonPath);
  final atlasIndexFile = File(_atlasIndexPath);

  if (!unitsFile.existsSync()) {
    stderr.writeln('No existe $_unitsJsonPath');
    exitCode = 2;
    return;
  }
  if (!atlasIndexFile.existsSync()) {
    stderr.writeln('No existe $_atlasIndexPath');
    exitCode = 3;
    return;
  }

  final units = (jsonDecode(unitsFile.readAsStringSync()) as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final atlasEntries = (jsonDecode(atlasIndexFile.readAsStringSync()) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  final byCell = <String, List<Map<String, dynamic>>>{};
  for (final unit in units) {
    final row = unit['mainIconRow'];
    final col = unit['mainIconCol'];
    if (row is! int || col is! int) {
      continue;
    }
    if ('${unit['unitIconClass'] ?? ''}' != 'unit') {
      continue;
    }
    final key = '$row:$col';
    byCell.putIfAbsent(key, () => []);
    byCell[key]!.add({
      'id': unit['id'],
      'displayName': unit['displayName'],
      'raceFolder': unit['raceFolder'],
      'unitIconClass': unit['unitIconClass'],
    });
  }

  final lookup = atlasEntries.map((entry) {
    final row = entry['row'];
    final col = entry['col'];
    final key = '$row:$col';
    final matches = byCell[key] ?? const [];
    return {
      'row': row,
      'col': col,
      'file': entry['file'],
      'sourceFile': 'assets/generated/unit_icons/units_70/${entry['file']}',
      'matches': matches,
      'mapped': matches.isNotEmpty,
    };
  }).toList();

  File(_outputPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(lookup),
  );
  File(_mappedOutputPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert(lookup.where((entry) => entry['mapped'] == true).toList()),
  );
  File(_unmappedOutputPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert(lookup.where((entry) => entry['mapped'] == false).toList()),
  );

  final mapped = lookup.where((e) => e['mapped'] == true).length;
  final unmapped = lookup.length - mapped;
  stdout.writeln(
    'Lookup generado en $_outputPath\n'
    'Listado mapeado en $_mappedOutputPath\n'
    'Listado sin mapear en $_unmappedOutputPath\n'
    'Celdas mapeadas: $mapped\n'
    'Celdas sin correspondencia en units.json: $unmapped',
  );
}
