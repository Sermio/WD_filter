/// Rutas de datos copiados o sincronizados desde el proyecto Worldshift.
/// Mantén estos archivos al día con `data/db/items/` del mod cuando cambie el juego.
class WorldshiftAssets {
  WorldshiftAssets._();

  static const String lootTableFile = 'assets/tsvFiles/loot_complete.txt';
  static const String itemsDefinitionFile =
      'assets/tsvFiles/items_extra_data_complete.txt';
  static const String dropFile = 'assets/tsvFiles/drop.tsv';
  static const String unitsCatalogFile = 'assets/data/units.json';
  /// Unidades añadidas a mano y fusionadas con [unitsCatalogFile] por `id`.
  ///
  /// Incluye héroes de campaña sin `.dt` propio o con overrides en `mapdata.lua` (Ganthu → High
  /// Priest; Denkar/Kuna → comandante; Arna → Engineer/technician2; Tharksh → clase tipo Master
  /// alien con icono officers), más stats/retratos alineados a partida cuando difieren del `.dt`.
  static const String unitsManualFile = 'assets/data/units_manual.json';
  static const String itemOriginIndexFile =
      'assets/data/item_origin_index.json';
}
