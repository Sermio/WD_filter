/// Fila de [loot_complete.txt] / loot.tsv: mesa, ubicación, id ítem, nombre.
class LootTableRow {
  final int lootTableId;
  final String locationLabel;
  final int itemId;
  final String itemName;

  const LootTableRow({
    required this.lootTableId,
    required this.locationLabel,
    required this.itemId,
    required this.itemName,
  });
}

/// Fila de drop.tsv: encadenado entre mesas de loot.
class DropTableRow {
  final int fromId;
  final String fromLabel;
  final int toId;
  final String toLabel;
  final List<String> rawFields;

  const DropTableRow({
    required this.fromId,
    required this.fromLabel,
    required this.toId,
    required this.toLabel,
    required this.rawFields,
  });

  /// Peso o probabilidad en la columna típica (índice 4 si existe).
  String? get weightOrChance {
    if (rawFields.length > 4) return rawFields[4];
    return null;
  }
}
