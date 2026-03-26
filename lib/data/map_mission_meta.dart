/// Metadatos de mapas PvE: stems de `missions/*.map` (véase `map_drop_refs.tsv`)
/// y el generador `tool/generate_item_origin_index.dart`.
/// Las claves (`key`) son las siglas usadas en loot/drop (p. ej. `DTB`, `CF`).
///
/// [hasHardMode]: mapas con variante Hard en el juego (no aplica a BSA, ROM, RH, BRD).
/// "Retribution" es título de misión de campaña (`missions/14.map`), no un mapa PvE.
class MapMissionMeta {
  const MapMissionMeta({
    required this.key,
    required this.displayName,
    required this.mode,
    required this.hasHardMode,
  });

  final String key;
  final String displayName;
  final String mode;

  /// Si el mapa tiene modo Hard (Safari, Dunetown, AC, Junkyard, Kharum, CF).
  final bool hasHardMode;
}

/// Por nombre de archivo de misión sin extensión (minúsculas).
const Map<String, MapMissionMeta> mapMissionMetaByFileStem = {
  'safari': MapMissionMeta(
    key: 'Safari',
    displayName: 'Deadly safari',
    mode: 'pve',
    hasHardMode: true,
  ),
  'dtb': MapMissionMeta(
    key: 'DTB',
    displayName: 'Dunetown base',
    mode: 'pve',
    hasHardMode: true,
  ),
  'bsa': MapMissionMeta(
    key: 'BSA',
    displayName: 'Bloodsport Arena',
    mode: 'pve',
    hasHardMode: false,
  ),
  'rom': MapMissionMeta(
    key: 'ROM',
    displayName: 'ROM base',
    mode: 'pve',
    hasHardMode: false,
  ),
  'esperanza': MapMissionMeta(
    key: 'AC',
    displayName: 'Ancient corridors',
    mode: 'pve',
    hasHardMode: true,
  ),
  'kharum': MapMissionMeta(
    key: 'Kharum',
    displayName: 'Kharum',
    mode: 'pve',
    hasHardMode: true,
  ),
  'junkyard': MapMissionMeta(
    key: 'JY',
    displayName: 'Junkyard',
    mode: 'pve',
    hasHardMode: true,
  ),
  'cf': MapMissionMeta(
    key: 'CF',
    displayName: 'Corrupted fields',
    mode: 'pve',
    hasHardMode: true,
  ),
  'rh': MapMissionMeta(
    key: 'RH',
    displayName: "The renegades' hideout",
    mode: 'pve',
    hasHardMode: false,
  ),
  'bt': MapMissionMeta(
    key: 'BRD',
    displayName: 'Bridge of trial',
    mode: 'pve',
    hasHardMode: false,
  ),
};

/// Normaliza el nombre mostrado para comparar con [mapMissionMetaByFileStem]
/// y con [maps] en `data.dart`.
String normalizeMapDisplayNameForLookup(String s) {
  return s
      .trim()
      .toLowerCase()
      .replaceAll('\u2019', "'")
      .replaceAll('\u2018', "'");
}

/// Sigla del juego para un nombre de mapa PvE, si está en la tabla de misiones.
String? mapMissionKeyForDisplayName(String fullName) {
  final n = fullName.trim();
  if (n.isEmpty) {
    return null;
  }
  final normalized = normalizeMapDisplayNameForLookup(n);
  for (final m in mapMissionMetaByFileStem.values) {
    if (normalizeMapDisplayNameForLookup(m.displayName) == normalized) {
      return m.key;
    }
  }
  return null;
}

/// Si el nombre mostrado es un mapa PvE con variante Hard en el juego.
bool mapDisplayNameSupportsHardMode(String displayName) {
  final normalized = normalizeMapDisplayNameForLookup(displayName);
  for (final m in mapMissionMetaByFileStem.values) {
    if (normalizeMapDisplayNameForLookup(m.displayName) == normalized) {
      return m.hasHardMode;
    }
  }
  return false;
}
