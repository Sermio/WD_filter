import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/data/item.dart';
import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/utils/unit_icon_candidates.dart';
import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/catalog_filter_widgets.dart';
import 'package:worldshift_assistant/widgets/expandable_card.dart';
import 'package:worldshift_assistant/widgets/resolved_mini_asset_image.dart';

/// Distinct from [null] so closing the sheet without choosing does not unequip.
final Object _builderPickerUnequip = Object();

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  static const _races = ['Humans', 'Tribes', 'Aliens'];
  static const _racePrefix = {
    'Humans': 'HUMAN_',
    'Tribes': 'MUTANT_',
    'Aliens': 'ALIEN_',
  };

  late final Future<List<Item>> _itemsFuture;
  String _selectedRace = 'Humans';
  final Map<String, Item> _equippedBySlot = {};

  @override
  void initState() {
    super.initState();
    _itemsFuture = combineLootData(
      WorldshiftAssets.lootTableFile,
      WorldshiftAssets.itemsDefinitionFile,
    );
  }

  List<Map<String, String>> _slotsForRace(String race) {
    final prefix = _racePrefix[race]!;
    return slots.where((s) => (s['key'] ?? '').startsWith(prefix)).toList();
  }

  Future<void> _openItemPicker({
    required String slotKey,
    required String slotLabel,
    required List<Item> allItems,
  }) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF8F9FA),
      builder: (context) => _BuilderEquipItemPicker(
        slotKey: slotKey,
        slotLabel: slotLabel,
        allItems: allItems,
        canUnequip: _equippedBySlot[slotKey] != null,
        unequipToken: _builderPickerUnequip,
      ),
    );

    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }
    if (identical(result, _builderPickerUnequip)) {
      setState(() => _equippedBySlot.remove(slotKey));
      return;
    }
    if (result is Item) {
      setState(() => _equippedBySlot[slotKey] = result);
    }
  }

  _BuildSummary _buildSummary() {
    final unitMap = <String, _UnitAggBuilder>{};

    for (final equip in _equippedBySlot.entries) {
      final slotKey = equip.key;
      final item = equip.value;
      for (final unitEntry in item.attributes.entries) {
        final unitKey = unitEntry.key;
        final rawAttrs = unitEntry.value;
        final agg = unitMap.putIfAbsent(
          unitKey,
          () => _UnitAggBuilder(unitKey),
        );
        final slotNums = <String, double>{};
        for (final ae in rawAttrs.entries) {
          final v = _parseNumber(ae.value);
          if (v == null) {
            continue;
          }
          agg.totals[ae.key] = (agg.totals[ae.key] ?? 0) + v;
          slotNums[ae.key] = (slotNums[ae.key] ?? 0) + v;
        }
        if (slotNums.isNotEmpty) {
          agg.slots.add(
            _SlotStatContribution(
              slotKey: slotKey,
              itemName: item.name,
              attrs: Map<String, double>.from(slotNums),
            ),
          );
        }
      }
    }

    final perUnit = unitMap.values
        .map(
          (b) => _PerUnitBuildSummary(
            unitKey: b.unitKey,
            displayLabel: _formatBuilderUnitLabel(b.unitKey),
            attributeTotals: Map<String, double>.from(b.totals),
            slotContributions: List<_SlotStatContribution>.from(b.slots),
          ),
        )
        .toList()
      ..sort(
        (a, b) => a.displayLabel.toLowerCase().compareTo(
              b.displayLabel.toLowerCase(),
            ),
      );

    return _BuildSummary(
      itemCount: _equippedBySlot.length,
      perUnit: perUnit,
    );
  }

  static String _formatBuilderUnitLabel(String unitKey) {
    final rawLabel = getUnitValue(unitKey).replaceAll('_', ' ').trim();
    return rawLabel.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  double? _parseNumber(String raw) {
    final m = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(raw);
    if (m == null) {
      return null;
    }
    return double.tryParse(m.group(0)!.replaceAll(',', '.'));
  }

  String _formatValue(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Builder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFFf093fb),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load items.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allItems = snap.data ?? const <Item>[];
          final slotsForRace = _slotsForRace(_selectedRace);
          final summary = _buildSummary();

          return LayoutBuilder(
            builder: (context, constraints) {
              final panelLeft = _EquipmentPanel(
                selectedRace: _selectedRace,
                races: _races,
                onRaceChanged: (race) => setState(() => _selectedRace = race),
                slotsForRace: slotsForRace,
                equippedBySlot: _equippedBySlot,
                onPickItem: (slotKey, slotLabel) => _openItemPicker(
                  slotKey: slotKey,
                  slotLabel: slotLabel,
                  allItems: allItems,
                ),
              );
              final panelRight = _SummaryPanel(
                summary: summary,
                formatValue: _formatValue,
                scrollUnitsInternally: constraints.maxWidth >= 1050,
              );

              if (constraints.maxWidth >= 1050) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(flex: 7, child: panelLeft),
                      const SizedBox(width: 12),
                      Expanded(flex: 5, child: panelRight),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  panelLeft,
                  const SizedBox(height: 12),
                  panelRight,
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BuilderEquipItemPicker extends StatefulWidget {
  const _BuilderEquipItemPicker({
    required this.slotKey,
    required this.slotLabel,
    required this.allItems,
    required this.canUnequip,
    required this.unequipToken,
  });

  final String slotKey;
  final String slotLabel;
  final List<Item> allItems;
  final bool canUnequip;
  final Object unequipToken;

  @override
  State<_BuilderEquipItemPicker> createState() => _BuilderEquipItemPickerState();
}

class _BuilderEquipItemPickerState extends State<_BuilderEquipItemPicker> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> _filteredSorted() {
    final q = _searchController.text.trim().toLowerCase();
    final result = widget.allItems.where((i) {
      if (i.slot != widget.slotKey) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
      if (i.name.toLowerCase().contains(q)) {
        return true;
      }
      return i.attributes.keys.any(
        (u) => getUnitValue(u).toLowerCase().contains(q),
      );
    }).toList();
    result.sort((a, b) {
      final rarityCmp = b.rarity.compareTo(a.rarity);
      if (rarityCmp != 0) {
        return rarityCmp;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredSorted();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: bottomInset + 12,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Equip in ${widget.slotLabel}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (widget.canUnequip)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(widget.unequipToken),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Unequip'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              CatalogSearchBar(
                controller: _searchController,
                hintText: 'Search item by name…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '${items.length} items',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 42,
                                color: Color(0xFF8A90A0),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No items for this slot',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF313846),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try another search or pick a different slot.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final itemData = item.toMap();
                          final rarity =
                              item.rarity.isEmpty ? 'unknown' : item.rarity;
                          return ExpandableCard(
                            name: item.name,
                            map: item.map,
                            rarity: rarity,
                            obtainedFrom: item.obtainedFrom,
                            itemData: itemData,
                            onSelect: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipmentPanel extends StatelessWidget {
  const _EquipmentPanel({
    required this.selectedRace,
    required this.races,
    required this.onRaceChanged,
    required this.slotsForRace,
    required this.equippedBySlot,
    required this.onPickItem,
  });

  static const List<String> _humanCenterKeys = [
    'HUMAN_IMPLANTS',
    'HUMAN_NEUROSCIENCE',
    'HUMAN_ENGINEER',
    'HUMAN_COMMANDER',
  ];
  static const List<String> _humanSideKeys = [
    'HUMAN_DEFENCE',
    'HUMAN_CONSTRUCTOR',
    'HUMAN_SURGEON',
  ];
  static const List<String> _humanRightKeys = [
    'HUMAN_WEAPONS',
    'HUMAN_ASSASSIN',
    'HUMAN_JUDGE',
  ];

  final String selectedRace;
  final List<String> races;
  final ValueChanged<String> onRaceChanged;
  final List<Map<String, String>> slotsForRace;
  final Map<String, Item> equippedBySlot;
  final void Function(String slotKey, String slotLabel) onPickItem;

  Map<String, Map<String, String>> _slotsByKey() {
    return {
      for (final s in slotsForRace) s['key'] ?? '': s,
    };
  }

  @override
  Widget build(BuildContext context) {
    final humanHud = selectedRace == 'Humans';
    final titleColor =
        humanHud ? const Color(0xFFE8EDF5) : const Color(0xFF1F2937);
    final hintColor =
        humanHud ? const Color(0xFF8B95A8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: humanHud ? const Color(0xFF0C0F14) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: humanHud ? const Color(0xFF2A313C) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Equipment Builder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: races.map((race) {
              final sel = race == selectedRace;
              return ChoiceChip(
                selected: sel,
                label: Text(race),
                selectedColor:
                    humanHud ? const Color(0xFF3D4F6A) : const Color(0xFFE0E7FF),
                backgroundColor: humanHud
                    ? const Color(0xFF1A1F28)
                    : const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  color: sel
                      ? (humanHud ? Colors.white : const Color(0xFF3730A3))
                      : (humanHud
                          ? const Color(0xFFB8C0D0)
                          : const Color(0xFF475569)),
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: humanHud
                      ? const Color(0xFF343C4A)
                      : const Color(0xFFE2E8F0),
                ),
                onSelected: (_) => onRaceChanged(race),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap a slot to equip an item.',
            style: TextStyle(
              color: hintColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (humanHud)
            _HumanEquipmentZigzag(
              slotsByKey: _slotsByKey(),
              equippedBySlot: equippedBySlot,
              onPickItem: onPickItem,
              centerKeys: _humanCenterKeys,
              leftKeys: _humanSideKeys,
              rightKeys: _humanRightKeys,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slotsForRace.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.65,
              ),
              itemBuilder: (context, index) {
                final slot = slotsForRace[index];
                final slotKey = slot['key'] ?? '';
                final slotLabel = slot['value'] ?? slotKey;
                final equipped = equippedBySlot[slotKey];

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onPickItem(slotKey, slotLabel),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: equipped == null
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF8B5CF6),
                        width: equipped == null ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        _ResolvedAssetImage(
                          candidates: [
                            'assets/generated/item_icons/named/icons/$slotKey.png',
                          ],
                          size: 42,
                          borderRadius: 10,
                          fallbackIcon: Icons.inventory_2_outlined,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slotLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                equipped?.name ?? 'Empty slot',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: equipped == null
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF334155),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HumanEquipmentZigzag extends StatelessWidget {
  const _HumanEquipmentZigzag({
    required this.slotsByKey,
    required this.equippedBySlot,
    required this.onPickItem,
    required this.centerKeys,
    required this.leftKeys,
    required this.rightKeys,
  });

  final Map<String, Map<String, String>> slotsByKey;
  final Map<String, Item> equippedBySlot;
  final void Function(String slotKey, String slotLabel) onPickItem;
  final List<String> centerKeys;
  final List<String> leftKeys;
  final List<String> rightKeys;

  static const double _colGap = 6;
  static const double _rowGap = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final frameSize = (maxW / 3.2).clamp(64.0, 88.0);

        Widget columnSlot(String key) {
          final meta = slotsByKey[key];
          if (meta == null) {
            return const SizedBox.shrink();
          }
          final slotKey = meta['key'] ?? key;
          final slotLabel = meta['value'] ?? slotKey;
          final equipped = equippedBySlot[slotKey];
          final rarity = equipped?.rarity ?? '1';

          return _BuilderHumanSlotCell(
            slotKey: slotKey,
            slotLabel: slotLabel,
            equippedName: equipped?.name,
            rarity: rarity,
            frameSize: frameSize,
            onTap: () => onPickItem(slotKey, slotLabel),
          );
        }

        Widget gapHalf() => SizedBox(height: _rowGap / 2 + frameSize * 0.12);
        Widget gapFull() => SizedBox(height: _rowGap + frameSize * 0.08);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  gapHalf(),
                  columnSlot(leftKeys[0]),
                  gapFull(),
                  columnSlot(leftKeys[1]),
                  gapFull(),
                  columnSlot(leftKeys[2]),
                ],
              ),
            ),
            const SizedBox(width: _colGap),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  columnSlot(centerKeys[0]),
                  gapFull(),
                  columnSlot(centerKeys[1]),
                  gapFull(),
                  columnSlot(centerKeys[2]),
                  gapFull(),
                  columnSlot(centerKeys[3]),
                ],
              ),
            ),
            const SizedBox(width: _colGap),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  gapHalf(),
                  columnSlot(rightKeys[0]),
                  gapFull(),
                  columnSlot(rightKeys[1]),
                  gapFull(),
                  columnSlot(rightKeys[2]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BuilderHumanSlotCell extends StatelessWidget {
  const _BuilderHumanSlotCell({
    required this.slotKey,
    required this.slotLabel,
    required this.equippedName,
    required this.rarity,
    required this.frameSize,
    required this.onTap,
  });

  final String slotKey;
  final String slotLabel;
  final String? equippedName;
  final String rarity;
  final double frameSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ItemCompleteFrame(
                  slot: slotKey,
                  rarity: rarity,
                  size: frameSize,
                  darkInterior: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                slotLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF2F5FA),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              if (equippedName != null) ...[
                const SizedBox(height: 2),
                Text(
                  equippedName!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D8696),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.summary,
    required this.formatValue,
    required this.scrollUnitsInternally,
  });

  final _BuildSummary summary;
  final String Function(double) formatValue;
  final bool scrollUnitsInternally;

  static const Color _accent = Color(0xFF667eea);

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Build Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          summary.itemCount == 0
              ? 'No items equipped'
              : '${summary.itemCount} equipped items · '
                    '${summary.perUnit.length} units affected',
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Totals by unit',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );

    final skillPlaceholder = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Tree',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Coming next: skill tree integration using existing icons.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );

    Widget unitSection() {
      if (summary.perUnit.isEmpty) {
        return Text(
          'Equip items to see aggregated attributes by unit.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < summary.perUnit.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _UnitTotalsCard(
              unit: summary.perUnit[i],
              formatValue: formatValue,
              accent: _accent,
              onInfoTap: () => _showUnitSlotSourcesSheet(
                context,
                unit: summary.perUnit[i],
                formatValue: formatValue,
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: scrollUnitsInternally
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      unitSection(),
                      const SizedBox(height: 14),
                      skillPlaceholder,
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                unitSection(),
                const SizedBox(height: 14),
                skillPlaceholder,
              ],
            ),
    );
  }
}

void _showUnitSlotSourcesSheet(
  BuildContext context, {
  required _PerUnitBuildSummary unit,
  required String Function(double) formatValue,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFFF8F9FA),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Stat sources · ${unit.displayLabel}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Equipment slots contributing numeric bonuses to this unit.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: unit.slotContributions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = unit.slotContributions[index];
                      final slotTitle =
                          getSlotValueOrDescription(c.slotKey);
                      final lines = c.attrs.entries.toList()
                        ..sort(
                          (a, b) => b.value.abs().compareTo(a.value.abs()),
                        );
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slotTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.itemName,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...lines.map((e) {
                              final v = e.value;
                              final sign = v >= 0 ? '+' : '';
                              final isNeg = v < 0;
                              final amtColor = isNeg
                                  ? const Color(0xFFC75A5A)
                                  : const Color(0xFF2E9B62);
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$sign${formatValue(v)}',
                                      style: TextStyle(
                                        color: amtColor,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        getAttributeValue(e.key),
                                        style: const TextStyle(
                                          color: Color(0xFF3D4452),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _UnitTotalsCard extends StatelessWidget {
  const _UnitTotalsCard({
    required this.unit,
    required this.formatValue,
    required this.accent,
    required this.onInfoTap,
  });

  final _PerUnitBuildSummary unit;
  final String Function(double) formatValue;
  final Color accent;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final sortedAttrs = unit.attributeTotals.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final readableAccent = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.42),
      accent,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: accent.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: const Color(0xFFF1F3F7),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ResolvedMiniAssetImage(
                        candidates: unitIconAssetCandidates(unit.unitKey),
                        size: 28,
                        borderRadius: 6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.displayLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: readableAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.1,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sortedAttrs.length} stacked attributes',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Slots contributing to this unit',
                onPressed: onInfoTap,
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: accent.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          if (sortedAttrs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedAttrs.asMap().entries.map((me) {
                  final v = me.value.value;
                  final sign = v >= 0 ? '+' : '';
                  final isNeg = v < 0;
                  return Padding(
                    padding: EdgeInsets.only(top: me.key == 0 ? 0 : 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$sign${formatValue(v)}',
                          style: TextStyle(
                            color: isNeg
                                ? const Color(0xFFC75A5A)
                                : const Color(0xFF2E9B62),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            getAttributeValue(me.value.key),
                            style: const TextStyle(
                              color: Color(0xFF3D4452),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotStatContribution {
  const _SlotStatContribution({
    required this.slotKey,
    required this.itemName,
    required this.attrs,
  });

  final String slotKey;
  final String itemName;
  final Map<String, double> attrs;
}

class _UnitAggBuilder {
  _UnitAggBuilder(this.unitKey);

  final String unitKey;
  final Map<String, double> totals = {};
  final List<_SlotStatContribution> slots = [];
}

class _PerUnitBuildSummary {
  const _PerUnitBuildSummary({
    required this.unitKey,
    required this.displayLabel,
    required this.attributeTotals,
    required this.slotContributions,
  });

  final String unitKey;
  final String displayLabel;
  final Map<String, double> attributeTotals;
  final List<_SlotStatContribution> slotContributions;
}

class _BuildSummary {
  const _BuildSummary({
    required this.itemCount,
    required this.perUnit,
  });

  final int itemCount;
  final List<_PerUnitBuildSummary> perUnit;
}

class _ResolvedAssetImage extends StatelessWidget {
  const _ResolvedAssetImage({
    required this.candidates,
    required this.size,
    required this.borderRadius,
    required this.fallbackIcon,
  });

  final List<String> candidates;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;

  Future<String?> _resolve() async {
    for (final path in candidates) {
      try {
        await rootBundle.load(path);
        return path;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolve(),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(
              fallbackIcon,
              size: size * 0.6,
              color: const Color(0xFF64748B),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.asset(
            path,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
