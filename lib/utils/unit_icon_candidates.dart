import 'package:worldshift_assistant/data/unit_icon_lookup_generated.dart';
import 'package:worldshift_assistant/utils/unit_icon_asset_paths.dart';

/// Rutas candidatas para icono de unidad (filtros, builder, habilidades, expandable_card).
///
/// Sin coordenadas: usa [kUnitIconAssetPathsByLookupKey] (claves de id .dt, builder, normalizadas).
/// Con coordenadas: [buildUnitIconAssetCandidates] (commander → conversation; resto → atlas 70×70).
List<String> unitIconAssetCandidates(
  String unitId, {
  int? mainIconRow,
  int? mainIconCol,
  int? conversationIconRow,
  int? conversationIconCol,
  String unitIconClass = 'unit',
}) {
  if (mainIconRow != null ||
      mainIconCol != null ||
      conversationIconRow != null ||
      conversationIconCol != null) {
    return buildUnitIconAssetCandidates(
      id: unitId.trim(),
      unitIconClass: unitIconClass,
      mainIconRow: mainIconRow,
      mainIconCol: mainIconCol,
      conversationIconRow: conversationIconRow,
      conversationIconCol: conversationIconCol,
    );
  }

  const aliasByUnitKey = <String, List<String>>{
    'Engineer': ['technician2'],
    'Psychic': ['eji2'],
    'Commander': ['commander', 'lancelot'],
    'HighPriest': ['highpriest'],
    'Defiler': ['dave', 'defiler'],
  };

  final key = unitId.trim();
  final normalized =
      key.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toLowerCase();
  final aliasKeys = <String>{
    ...?aliasByUnitKey[key],
    key,
    if (normalized.isNotEmpty) normalized,
  };

  final out = <String>[];
  final seen = <String>{};
  for (final k in aliasKeys) {
    final paths = kUnitIconAssetPathsByLookupKey[k];
    if (paths == null) {
      continue;
    }
    for (final p in paths) {
      if (seen.add(p)) {
        out.add(p);
      }
    }
  }
  return out;
}
