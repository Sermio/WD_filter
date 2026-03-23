import 'package:flutter/services.dart' show rootBundle;

import 'package:worldshift_assistant/data/loot_drop_models.dart';
import 'package:worldshift_assistant/data/worldshift_assets.dart';

/// Carga y cruza loot + drop desde assets (sincronizados con Worldshift).
class LootDropRepository {
  LootDropRepository._({
    required this.lootRows,
    required this.dropRows,
  });

  final List<LootTableRow> lootRows;
  final List<DropTableRow> dropRows;

  /// lootTableId -> filas de ítems
  final Map<int, List<LootTableRow>> _lootByTable = {};

  /// itemId -> mesas donde aparece
  final Map<int, Set<int>> _tablesByItem = {};

  /// fromId -> hijos en drop.tsv
  final Map<int, List<DropTableRow>> _dropChildren = {};

  static Future<LootDropRepository> loadFromAssets() async {
    final lootRaw =
        await rootBundle.loadString(WorldshiftAssets.lootTableFile);
    final dropRaw = await rootBundle.loadString(WorldshiftAssets.dropFile);

    final lootRows = _parseLoot(lootRaw);
    final dropRows = _parseDrop(dropRaw);
    final repo = LootDropRepository._(
      lootRows: lootRows,
      dropRows: dropRows,
    );
    repo._buildIndexes();
    return repo;
  }

  void _buildIndexes() {
    for (final r in lootRows) {
      _lootByTable.putIfAbsent(r.lootTableId, () => []).add(r);
      _tablesByItem.putIfAbsent(r.itemId, () => {}).add(r.lootTableId);
    }
    for (final d in dropRows) {
      _dropChildren.putIfAbsent(d.fromId, () => []).add(d);
    }
  }

  static List<LootTableRow> _parseLoot(String content) {
    final out = <LootTableRow>[];
    final regex = RegExp(r'^(\d+)\s+(.+?)\s+(\d{4,})\s+(.+?)$');
    for (final line in content.split(RegExp(r'\r?\n'))) {
      if (line.trim().isEmpty) continue;
      final m = regex.firstMatch(line.trim());
      if (m == null) continue;
      final tableId = int.tryParse(m.group(1) ?? '') ?? 0;
      final loc = (m.group(2) ?? '').trim();
      final itemId = int.tryParse(m.group(3) ?? '') ?? 0;
      var name = (m.group(4) ?? '').trim();
      name = name.replaceAll(RegExp(r'\s+'), ' ');
      out.add(LootTableRow(
        lootTableId: tableId,
        locationLabel: loc,
        itemId: itemId,
        itemName: name,
      ));
    }
    return out;
  }

  static List<DropTableRow> _parseDrop(String content) {
    final out = <DropTableRow>[];
    for (final line in content.split(RegExp(r'\r?\n'))) {
      if (line.trim().isEmpty) continue;
      final fields = line.split('\t');
      if (fields.length < 4) continue;
      final fromId = int.tryParse(fields[0].trim());
      final toId = int.tryParse(fields[2].trim());
      if (fromId == null || toId == null) continue;
      out.add(DropTableRow(
        fromId: fromId,
        fromLabel: fields[1].trim(),
        toId: toId,
        toLabel: fields[3].trim(),
        rawFields: fields,
      ));
    }
    return out;
  }

  /// Encuentros únicos (primera aparición de cada mesa origen).
  List<DropTableRow> get uniqueRootEncounters {
    final seen = <int>{};
    final list = <DropTableRow>[];
    for (final d in dropRows) {
      if (seen.add(d.fromId)) {
        list.add(d);
      }
    }
    list.sort((a, b) => a.fromId.compareTo(b.fromId));
    return list;
  }

  List<DropTableRow> childrenOf(int lootTableId) =>
      List.unmodifiable(_dropChildren[lootTableId] ?? const []);

  List<LootTableRow> itemsOnTable(int lootTableId) =>
      List.unmodifiable(_lootByTable[lootTableId] ?? const []);

  Set<int> tablesContainingItem(int itemId) =>
      Set.unmodifiable(_tablesByItem[itemId] ?? const {});

  List<LootTableRow> searchItemsByName(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    return lootRows
        .where((r) => r.itemName.toLowerCase().contains(q))
        .toList();
  }
}
