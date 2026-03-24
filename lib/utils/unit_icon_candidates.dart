/// Rutas candidatas para el icono de unidad (mismo criterio que filtros de ítems / lista).
List<String> unitIconAssetCandidates(String unitId) {
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
  final aliases = <String>[
    ...?aliasByUnitKey[key],
    normalized,
  ];
  final seen = <String>{};
  final out = <String>[];

  for (final id in aliases) {
    if (!seen.add(id) || id.isEmpty) {
      continue;
    }
    out.add('assets/generated/unit_icons/named/units/$id.png');
    out.add('assets/generated/unit_icons/named/officers/$id.png');
  }

  return out;
}
