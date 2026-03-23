/// Rutas candidatas para el icono de unidad (mismo criterio que ítems / lista de unidades).
List<String> unitIconAssetCandidates(String unitId) {
  const extraFileIds = <String, List<String>>{
    'engineer': ['technician2'],
    'psychic': ['eji2'],
    'commander': ['lancelot'],
  };

  final seen = <String>{};
  final out = <String>[];

  void add(String id) {
    final clean = id.replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '').toLowerCase();
    if (clean.isEmpty || !seen.add(clean)) {
      return;
    }
    out.add('assets/generated/unit_icons/named/units/$clean.png');
    out.add('assets/generated/unit_icons/named/officers/$clean.png');
  }

  final lower = unitId.trim().toLowerCase();
  for (final alt in extraFileIds[lower] ?? const <String>[]) {
    add(alt);
  }
  add(unitId);
  return out;
}
