// Obsoleto: la app ya no usa PNG en `named/units/*.png` (solo atlas r{row}_c{col}).
//
// Flujo actual:
//   1. dart run tool/extract_units_70_atlas.dart
//   2. dart run tool/generate_worldshift_assets.dart   (si cambió el mod)
//   3. dart run tool/generate_unit_icon_lookup.dart
import 'dart:io';

void main() {
  stderr.writeln(
    'generate_named_unit_icons ya no genera PNG duplicados.\n'
    'Usa:\n'
    '  dart run tool/extract_units_70_atlas.dart\n'
    '  dart run tool/generate_unit_icon_lookup.dart',
  );
}
