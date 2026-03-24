import 'package:worldshift_assistant/data/unit_icon_lookup_generated.dart';

/// Rutas PNG de iconos de unidad: **solo atlas por coordenadas** (sin `named/units/*.png`).
///
/// En el juego, los **personajes jugables de campaña** (oficiales, commanders, héroes de historia)
/// viven en **`officers-70x70.dds`** → `officers_70/r{row}_c{col}.png`.
/// Tropas genéricas, criaturas y la mayoría de NPC usan **`units-70x70.dds`** → `units_70/...`.
///
/// - `unit` → `units_70/...` ([mainIconRow] / [mainIconCol])
/// - `officer` → `officers_70/...`
/// - `commander` → `officers_70/...` (Lord Commander, Denkar, High Priest, Master, etc.).
///   Si no hay main, se intenta `conversation_49` con conv_icon.
///
/// Si faltan coordenadas, se intenta [kUnitIconAssetPathsByLookupKey] por `id`.

List<String> buildUnitIconAssetCandidates({
  required String id,
  String unitIconClass = 'unit',
  int? mainIconRow,
  int? mainIconCol,
  int? conversationIconRow,
  int? conversationIconCol,
}) {
  final norm = id.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toLowerCase();

  List<String> lookupFallback() {
    final a = kUnitIconAssetPathsByLookupKey[id];
    if (a != null && a.isNotEmpty) {
      return List<String>.from(a);
    }
    if (norm.isNotEmpty) {
      final b = kUnitIconAssetPathsByLookupKey[norm];
      if (b != null && b.isNotEmpty) {
        return List<String>.from(b);
      }
    }
    return const [];
  }

  if (unitIconClass == 'commander') {
    final mr = mainIconRow;
    final mc = mainIconCol;
    if (mr != null && mc != null) {
      return [
        'assets/generated/unit_icons/officers_70/r${mr}_c$mc.png',
      ];
    }
    final cr = conversationIconRow;
    final cc = conversationIconCol;
    if (cr != null && cc != null) {
      return [
        'assets/generated/unit_icons/conversation_49/r${cr}_c$cc.png',
      ];
    }
    return lookupFallback();
  }

  final r = mainIconRow;
  final c = mainIconCol;
  if (r == null || c == null) {
    return lookupFallback();
  }

  if (unitIconClass == 'officer') {
    return [
      'assets/generated/unit_icons/officers_70/r${r}_c$c.png',
    ];
  }

  return [
    'assets/generated/unit_icons/units_70/r${r}_c$c.png',
  ];
}
