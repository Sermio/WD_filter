import 'package:flutter_test/flutter_test.dart';
import 'package:worldshift_assistant/services/units_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UnitsCatalog fusiona units_manual (ganthu, tharksh, kuna, arna)', () async {
    final c = await UnitsCatalog.load();
    final ids = c.units.map((u) => u.id).toSet();
    expect(ids.contains('ganthu'), true, reason: 'Ganthu manual');
    expect(ids.contains('tharksh'), true, reason: 'Tharksh solo en manual');
    expect(ids.contains('kuna'), true, reason: 'Kuna solo en manual');
    expect(ids.contains('arna'), true, reason: 'Arna solo en manual');
    expect(ids.contains('kuna'), true);
    final denkar = c.units.firstWhere((u) => u.id == 'denkar');
    expect(denkar.displayName, 'Denkar ni\'Varra');
  });
}
