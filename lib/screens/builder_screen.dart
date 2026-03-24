import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/data/item.dart';
import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:worldshift_assistant/utils/catalog_card_stripe.dart';
import 'package:worldshift_assistant/utils/catalog_item_filter.dart';
import 'package:worldshift_assistant/utils/unit_icon_candidates.dart';
import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/expandable_card.dart';
import 'package:worldshift_assistant/widgets/item_catalog_filters_panel.dart';
import 'package:worldshift_assistant/widgets/rarity_indicator.dart';
import 'package:worldshift_assistant/widgets/resolved_mini_asset_image.dart';

/// Distinct from [null] so closing the sheet without choosing does not unequip.
final Object _builderPickerUnequip = Object();

enum _BuilderPanelTab { items, skillTree }

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

  /// Legacy flat map (slot → item id). Migrated to [_prefsEquipKeyV2] on load/save.
  static const _prefsEquipKeyV1 = 'builder_equipped_slots_v1';
  /// One equipment set per race (Humans / Tribes / Aliens). Skill tree can use the same split later.
  static const _prefsEquipKeyV2 = 'builder_equipped_by_race_v2';
  static const _prefsRaceKey = 'builder_selected_race_v1';

  late final Future<List<Item>> _itemsFuture;
  String _selectedRace = 'Humans';
  _BuilderPanelTab _panelTab = _BuilderPanelTab.items;
  final Map<String, Map<String, Item>> _equippedByRace = {
    for (final r in _races) r: <String, Item>{},
  };

  Map<String, Item> get _equipForSelectedRace => _equippedByRace[_selectedRace]!;

  static String? _raceForSlotKey(String slotKey) {
    for (final e in _racePrefix.entries) {
      if (slotKey.startsWith(e.value)) {
        return e.key;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItemsAndRestorePrefs();
  }

  Future<List<Item>> _loadItemsAndRestorePrefs() async {
    final items = await combineLootData(
      WorldshiftAssets.lootTableFile,
      WorldshiftAssets.itemsDefinitionFile,
    );
    await _restoreFromPrefs(items);
    return items;
  }

  Future<void> _restoreFromPrefs(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    final byId = {for (final i in items) i.id: i};

    final nextByRace = {
      for (final r in _races) r: <String, Item>{},
    };

    void putIfValid(String race, String slotKey, int id) {
      final item = byId[id];
      if (item == null || item.slot != slotKey) {
        return;
      }
      if (_raceForSlotKey(slotKey) != race) {
        return;
      }
      nextByRace[race]![slotKey] = item;
    }

    try {
      final rawV2 = prefs.getString(_prefsEquipKeyV2);
      if (rawV2 != null && rawV2.isNotEmpty) {
        final decoded = jsonDecode(rawV2);
        if (decoded is Map) {
          for (final race in _races) {
            final inner = decoded[race];
            if (inner is! Map) {
              continue;
            }
            for (final e in inner.entries) {
              final slotKey = '${e.key}';
              final idVal = e.value;
              final id = idVal is int
                  ? idVal
                  : idVal is num
                      ? idVal.toInt()
                      : int.tryParse('$idVal');
              if (id == null) {
                continue;
              }
              putIfValid(race, slotKey, id);
            }
          }
        }
      } else {
        final rawV1 = prefs.getString(_prefsEquipKeyV1);
        if (rawV1 != null && rawV1.isNotEmpty) {
          final decoded = jsonDecode(rawV1);
          if (decoded is Map) {
            for (final e in decoded.entries) {
              final slotKey = '${e.key}';
              final race = _raceForSlotKey(slotKey);
              if (race == null) {
                continue;
              }
              final idVal = e.value;
              final id = idVal is int
                  ? idVal
                  : idVal is num
                      ? idVal.toInt()
                      : int.tryParse('$idVal');
              if (id == null) {
                continue;
              }
              putIfValid(race, slotKey, id);
            }
          }
        }
      }
    } catch (_) {
      // ignore corrupt prefs
    }

    final savedRace = prefs.getString(_prefsRaceKey);
    final race = savedRace != null && _races.contains(savedRace)
        ? savedRace
        : _selectedRace;

    if (!mounted) {
      return;
    }
    setState(() {
      for (final r in _races) {
        _equippedByRace[r]!
          ..clear()
          ..addAll(nextByRace[r]!);
      }
      _selectedRace = race;
    });
  }

  Future<void> _persistBuilderState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      for (final r in _races)
        r: {
          for (final e in _equippedByRace[r]!.entries) e.key: e.value.id,
        },
    };
    await prefs.setString(_prefsEquipKeyV2, jsonEncode(payload));
    await prefs.remove(_prefsEquipKeyV1);
    await prefs.setString(_prefsRaceKey, _selectedRace);
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
        lockedRace: _selectedRace,
        allItems: allItems,
        canUnequip: _equipForSelectedRace[slotKey] != null,
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
      setState(() => _equipForSelectedRace.remove(slotKey));
      unawaited(_persistBuilderState());
      return;
    }
    if (result is Item) {
      setState(() => _equipForSelectedRace[slotKey] = result);
      unawaited(_persistBuilderState());
    }
  }

  Future<void> _confirmResetCurrentRaceLoadout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset loadout'),
        content: Text(
          'Remove all equipped items for $_selectedRace? Other races are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(_equipForSelectedRace.clear);
    unawaited(_persistBuilderState());
  }

  _BuildSummary _buildSummary() {
    final unitMap = <String, _UnitAggBuilder>{};

    for (final equip in _equipForSelectedRace.entries) {
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
              itemRarity: item.rarity,
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
      itemCount: _equipForSelectedRace.length,
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
                onRaceChanged: (race) {
                  setState(() => _selectedRace = race);
                  unawaited(_persistBuilderState());
                },
                panelTab: _panelTab,
                onPanelTabChanged: (tab) => setState(() => _panelTab = tab),
                slotsForRace: slotsForRace,
                equippedBySlot: _equipForSelectedRace,
                onPickItem: (slotKey, slotLabel) => _openItemPicker(
                  slotKey: slotKey,
                  slotLabel: slotLabel,
                  allItems: allItems,
                ),
                onResetLoadout: () =>
                    unawaited(_confirmResetCurrentRaceLoadout()),
              );
              final panelRight = _SummaryPanel(
                selectedRace: _selectedRace,
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
    required this.lockedRace,
    required this.allItems,
    required this.canUnequip,
    required this.unequipToken,
  });

  final String slotKey;
  final String slotLabel;
  final String lockedRace;
  final List<Item> allItems;
  final bool canUnequip;
  final Object unequipToken;

  @override
  State<_BuilderEquipItemPicker> createState() => _BuilderEquipItemPickerState();
}

class _BuilderEquipItemPickerState extends State<_BuilderEquipItemPicker> {
  late final TextEditingController _nameController;
  late final TextEditingController _attributeController;
  late final TextEditingController _unitController;
  bool _filtersVisible = false;

  static String _formatUnitLabel(String unitKey) {
    final rawLabel = getUnitValue(unitKey).replaceAll('_', ' ').trim();
    return rawLabel.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  @override
  void initState() {
    super.initState();
    final fp = context.read<FilterProvider>();
    _nameController = TextEditingController(text: fp.nameFilter);
    _attributeController = TextEditingController(text: fp.attributeFilter);
    _unitController = TextEditingController(
      text: fp.unitFilter.isEmpty ? '' : _formatUnitLabel(fp.unitFilter),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _attributeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  List<Item> _filteredSorted(FilterProvider fp) {
    final result = widget.allItems
        .where(
          (item) => catalogItemMatchesFilters(
            item: item,
            filterProvider: fp,
            lockedSlotKey: widget.slotKey,
            lockedRaceKey: widget.lockedRace,
          ),
        )
        .toList();
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
          child: Consumer<FilterProvider>(
            builder: (context, fp, _) {
              final items = _filteredSorted(fp);
              return Column(
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
                      IconButton(
                        tooltip: 'Filters',
                        onPressed: () => setState(
                          () => _filtersVisible = !_filtersVisible,
                        ),
                        icon: Icon(
                          _filtersVisible ? Icons.close : Icons.tune,
                          color: const Color(0xFF475569),
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
                  if (_filtersVisible) ...[
                    const SizedBox(height: 8),
                    ItemCatalogFiltersPanel(
                      nameController: _nameController,
                      attributeController: _attributeController,
                      unitController: _unitController,
                      hideSlotDropdown: true,
                      lockedRace: widget.lockedRace,
                      maxHeight: 260,
                      onFiltersChanged: () => setState(() {}),
                      footer: Center(
                        child: Text(
                          '${items.length} items',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_filtersVisible) const Divider(height: 1),
                  if (!_filtersVisible) const SizedBox(height: 10),
                  if (!_filtersVisible)
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
                  if (!_filtersVisible) const SizedBox(height: 8),
                  if (_filtersVisible) const SizedBox(height: 6),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
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
                                    'Try filters, search, or clear criteria.',
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
                            padding:
                                const EdgeInsets.only(top: 10, bottom: 20),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final itemData = item.toMap();
                              final rarity = item.rarity.isEmpty
                                  ? 'unknown'
                                  : item.rarity;
                              return ExpandableCard(
                                name: item.name,
                                map: item.map,
                                rarity: rarity,
                                obtainedFrom: item.obtainedFrom,
                                itemData: itemData,
                                onSelect: () =>
                                    Navigator.of(context).pop(item),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BuilderRaceHudTheme {
  const _BuilderRaceHudTheme({
    required this.isDarkPanel,
    required this.panelBg,
    required this.panelBorder,
    required this.titleColor,
    required this.hintColor,
    required this.chipSelected,
    required this.chipBackground,
    required this.chipLabelSelected,
    required this.chipLabelUnselected,
    required this.chipSide,
    required this.footerDivider,
    required this.resetStyle,
    required this.hudInterior,
    required this.slotLabelPrimary,
    required this.slotLabelSecondary,
    required this.inkSplash,
    required this.inkHighlight,
    required this.frameShadow,
    required this.summaryUnitCardAccent,
    required this.summaryUnitCardGradientEndAlpha,
  });

  final bool isDarkPanel;
  final Color panelBg;
  final Color panelBorder;
  final Color titleColor;
  final Color hintColor;
  final Color chipSelected;
  final Color chipBackground;
  final Color chipLabelSelected;
  final Color chipLabelUnselected;
  final Color chipSide;
  final Color footerDivider;
  final ButtonStyle resetStyle;
  final BuilderHudInterior hudInterior;
  final Color slotLabelPrimary;
  final Color slotLabelSecondary;
  final Color inkSplash;
  final Color inkHighlight;
  final Color frameShadow;
  /// Tinte suave en cards de stats por unidad del resumen (Humans mantiene el violeta del listado).
  final Color summaryUnitCardAccent;
  /// Opacidad del segundo color del gradiente en esas cards (Humans ≈ listado original).
  final double summaryUnitCardGradientEndAlpha;

  static _BuilderRaceHudTheme forRace(String race) {
    switch (race) {
      case 'Humans':
        return _BuilderRaceHudTheme(
          isDarkPanel: true,
          panelBg: const Color(0xFF0C0F14),
          panelBorder: const Color(0xFF2A313C),
          titleColor: const Color(0xFFE8EDF5),
          hintColor: const Color(0xFF8B95A8),
          chipSelected: const Color(0xFF3D4F6A),
          chipBackground: const Color(0xFF1A1F28),
          chipLabelSelected: Colors.white,
          chipLabelUnselected: const Color(0xFFB8C0D0),
          chipSide: const Color(0xFF343C4A),
          footerDivider: const Color(0xFF2A313C),
          resetStyle: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEEF2F7),
            disabledForegroundColor: const Color(0xFF5C6570),
            side: const BorderSide(color: Color(0xFF4A5568)),
            backgroundColor: const Color(0xFF1A1F28),
          ),
          hudInterior: BuilderHudInterior.human,
          slotLabelPrimary: const Color(0xFFF2F5FA),
          slotLabelSecondary: const Color(0xFF7D8696),
          inkSplash: Colors.white24,
          inkHighlight: Colors.white10,
          frameShadow: const Color(0x73000000),
          summaryUnitCardAccent: const Color(0xFF667eea),
          summaryUnitCardGradientEndAlpha: 0.04,
        );
      case 'Tribes':
        return _BuilderRaceHudTheme(
          isDarkPanel: true,
          panelBg: const Color(0xFF100E0C),
          panelBorder: const Color(0xFF3D3428),
          titleColor: const Color(0xFFF2E8DC),
          hintColor: const Color(0xFF9A8B78),
          chipSelected: const Color(0xFF5C4A32),
          chipBackground: const Color(0xFF1C1612),
          chipLabelSelected: const Color(0xFFFFFBF5),
          chipLabelUnselected: const Color(0xFFBDA892),
          chipSide: const Color(0xFF4A3F32),
          footerDivider: const Color(0xFF3D3428),
          resetStyle: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE8DED0),
            disabledForegroundColor: const Color(0xFF5C534A),
            side: const BorderSide(color: Color(0xFF5A4E42)),
            backgroundColor: const Color(0xFF161310),
          ),
          hudInterior: BuilderHudInterior.mutant,
          slotLabelPrimary: const Color(0xFFF5EDE0),
          slotLabelSecondary: const Color(0xFF8F7D6B),
          inkSplash: const Color(0x33D4A574),
          inkHighlight: const Color(0x18D4A574),
          frameShadow: const Color(0x80000000),
          summaryUnitCardAccent: const Color(0xFFC4A57B),
          summaryUnitCardGradientEndAlpha: 0.09,
        );
      case 'Aliens':
        return _BuilderRaceHudTheme(
          isDarkPanel: true,
          panelBg: const Color(0xFF050806),
          panelBorder: const Color(0xFF143220),
          titleColor: const Color(0xFFE5F2EA),
          hintColor: const Color(0xFF6B8878),
          chipSelected: const Color(0xFF1E4D32),
          chipBackground: const Color(0xFF0A120E),
          chipLabelSelected: const Color(0xFFB8FFD4),
          chipLabelUnselected: const Color(0xFF7DA892),
          chipSide: const Color(0xFF1A3024),
          footerDivider: const Color(0xFF143220),
          resetStyle: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC8EDD8),
            disabledForegroundColor: const Color(0xFF3D5248),
            side: const BorderSide(color: Color(0xFF255238)),
            backgroundColor: const Color(0xFF0A100C),
          ),
          hudInterior: BuilderHudInterior.alien,
          slotLabelPrimary: const Color(0xFFE8F7EE),
          slotLabelSecondary: const Color(0xFF5E806E),
          inkSplash: const Color(0x4040FF88),
          inkHighlight: const Color(0x2040FF88),
          frameShadow: const Color(0xAA003020),
          summaryUnitCardAccent: const Color(0xFF3CB878),
          summaryUnitCardGradientEndAlpha: 0.09,
        );
      default:
        return _BuilderRaceHudTheme(
          isDarkPanel: false,
          panelBg: Colors.white,
          panelBorder: const Color(0xFFE2E8F0),
          titleColor: const Color(0xFF1F2937),
          hintColor: const Color(0xFF64748B),
          chipSelected: const Color(0xFFE0E7FF),
          chipBackground: const Color(0xFFF1F5F9),
          chipLabelSelected: const Color(0xFF3730A3),
          chipLabelUnselected: const Color(0xFF475569),
          chipSide: const Color(0xFFE2E8F0),
          footerDivider: const Color(0xFFE2E8F0),
          resetStyle: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF475569),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          hudInterior: BuilderHudInterior.human,
          slotLabelPrimary: const Color(0xFFF2F5FA),
          slotLabelSecondary: const Color(0xFF7D8696),
          inkSplash: Colors.black12,
          inkHighlight: Colors.black12,
          frameShadow: const Color(0x73000000),
          summaryUnitCardAccent: const Color(0xFF667eea),
          summaryUnitCardGradientEndAlpha: 0.04,
        );
    }
  }
}

({List<String> center, List<String> left, List<String> right})? _zigzagKeysForRace(
    String race) {
  switch (race) {
    case 'Humans':
      return (
        center: _EquipmentPanel._humanCenterKeys,
        left: _EquipmentPanel._humanSideKeys,
        right: _EquipmentPanel._humanRightKeys,
      );
    case 'Tribes':
      return (
        center: _EquipmentPanel._mutantCenterKeys,
        left: _EquipmentPanel._mutantLeftKeys,
        right: _EquipmentPanel._mutantRightKeys,
      );
    case 'Aliens':
      return (
        center: _EquipmentPanel._alienCenterKeys,
        left: _EquipmentPanel._alienLeftKeys,
        right: _EquipmentPanel._alienRightKeys,
      );
    default:
      return null;
  }
}

class _EquipmentPanel extends StatelessWidget {
  const _EquipmentPanel({
    required this.selectedRace,
    required this.races,
    required this.onRaceChanged,
    required this.panelTab,
    required this.onPanelTabChanged,
    required this.slotsForRace,
    required this.equippedBySlot,
    required this.onPickItem,
    required this.onResetLoadout,
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

  /// Orden zigzag como UI de referencia (columna central 4, lados 3 desfasados).
  static const List<String> _mutantCenterKeys = [
    'MUTANT_NATURE',
    'MUTANT_SPIRIT',
    'MUTANT_PSYCHIC',
    'MUTANT_HIGHPRIEST',
  ];
  static const List<String> _mutantLeftKeys = [
    'MUTANT_BLOOD',
    'MUTANT_STONEGHOST',
    'MUTANT_SHAMAN',
  ];
  static const List<String> _mutantRightKeys = [
    'MUTANT_MIND',
    'MUTANT_ADEPT',
    'MUTANT_GUARDIAN',
  ];

  static const List<String> _alienCenterKeys = [
    'ALIEN_CORRUPTION',
    'ALIEN_ENIGMA',
    'ALIEN_DEFILER',
    'ALIEN_MASTER',
  ];
  static const List<String> _alienLeftKeys = [
    'ALIEN_POWER',
    'ALIEN_HARVESTER',
    'ALIEN_DOMINATOR',
  ];
  static const List<String> _alienRightKeys = [
    'ALIEN_DOGMA',
    'ALIEN_MANIPULATOR',
    'ALIEN_ARBITER',
  ];

  final String selectedRace;
  final List<String> races;
  final ValueChanged<String> onRaceChanged;
  final _BuilderPanelTab panelTab;
  final ValueChanged<_BuilderPanelTab> onPanelTabChanged;
  final List<Map<String, String>> slotsForRace;
  final Map<String, Item> equippedBySlot;
  final void Function(String slotKey, String slotLabel) onPickItem;
  final VoidCallback onResetLoadout;

  Map<String, Map<String, String>> _slotsByKey() {
    return {
      for (final s in slotsForRace) s['key'] ?? '': s,
    };
  }

  /// Selector unido; cada segmento usa el HUD de su raza (oscuro + tinte).
  static Widget _darkRaceSegmentedBar({
    required List<String> races,
    required String selectedRace,
    required ValueChanged<String> onRaceChanged,
    required Color dividerAndOutlineColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: dividerAndOutlineColor, width: 1),
        ),
        child: Row(
          children: List.generate(races.length, (i) {
            final rh = _BuilderRaceHudTheme.forRace(races[i]);
            final sel = races[i] == selectedRace;
            return Expanded(
              child: Material(
                color: sel ? rh.chipSelected : rh.chipBackground,
                child: InkWell(
                  onTap: () => onRaceChanged(races[i]),
                  splashColor: rh.inkSplash,
                  highlightColor: rh.inkHighlight,
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        right: i < races.length - 1
                            ? BorderSide(
                                color: dividerAndOutlineColor,
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        races[i],
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: sel
                              ? rh.chipLabelSelected
                              : rh.chipLabelUnselected,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Items / Skill tree con el HUD de la raza activa.
  static Widget _panelModeSegmentedBar({
    required _BuilderPanelTab tab,
    required ValueChanged<_BuilderPanelTab> onChanged,
    required _BuilderRaceHudTheme hud,
    required Color dividerAndOutlineColor,
  }) {
    const modes = _BuilderPanelTab.values;
    String label(_BuilderPanelTab m) {
      switch (m) {
        case _BuilderPanelTab.items:
          return 'Items';
        case _BuilderPanelTab.skillTree:
          return 'Skill tree';
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: dividerAndOutlineColor, width: 1),
        ),
        child: Row(
          children: List.generate(modes.length, (i) {
            final m = modes[i];
            final sel = tab == m;
            return Expanded(
              child: Material(
                color: sel ? hud.chipSelected : hud.chipBackground,
                child: InkWell(
                  onTap: () => onChanged(m),
                  splashColor: hud.inkSplash,
                  highlightColor: hud.inkHighlight,
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        right: i < modes.length - 1
                            ? BorderSide(
                                color: dividerAndOutlineColor,
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label(m),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: sel
                              ? hud.chipLabelSelected
                              : hud.chipLabelUnselected,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  static Widget _skillTreePlaceholder(_BuilderRaceHudTheme hud) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Center(
        child: Text(
          'Coming next: per-race skill tree using existing icons.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: hud.hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hud = _BuilderRaceHudTheme.forRace(selectedRace);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hud.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hud.panelBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelHasBoundedHeight = constraints.maxHeight.isFinite;
          final barOutline = hud.panelBorder;

          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Equipment Builder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: hud.titleColor,
                ),
              ),
              const SizedBox(height: 8),
              _EquipmentPanel._darkRaceSegmentedBar(
                races: races,
                selectedRace: selectedRace,
                onRaceChanged: onRaceChanged,
                dividerAndOutlineColor: barOutline,
              ),
              const SizedBox(height: 8),
              _EquipmentPanel._panelModeSegmentedBar(
                tab: panelTab,
                onChanged: onPanelTabChanged,
                hud: hud,
                dividerAndOutlineColor: barOutline,
              ),
              const SizedBox(height: 12),
              Text(
                panelTab == _BuilderPanelTab.items
                    ? 'Tap a slot to equip an item.'
                    : 'Skill tree for this race — work in progress.',
                style: TextStyle(
                  color: hud.hintColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],
          );

          final zig = _zigzagKeysForRace(selectedRace);
          final equipmentBody = zig != null
              ? _BuilderEquipmentZigzag(
                  hud: hud,
                  slotsByKey: _slotsByKey(),
                  equippedBySlot: equippedBySlot,
                  onPickItem: onPickItem,
                  centerKeys: zig.center,
                  leftKeys: zig.left,
                  rightKeys: zig.right,
                )
              : GridView.builder(
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

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: equipped == null
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF8B5CF6),
                            width: equipped == null ? 1 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onPickItem(slotKey, slotLabel),
                          child: Container(
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ItemCompleteFrame(
                                  slot: slotKey,
                                  rarity: equipped?.rarity ?? '1',
                                  size: 42,
                                  showInteriorIcon: equipped != null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                        ),
                      ),
                    );
                  },
                );

          final slotBody = panelTab == _BuilderPanelTab.items
              ? equipmentBody
              : _EquipmentPanel._skillTreePlaceholder(hud);

          final footer = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: panelHasBoundedHeight ? 8 : 10),
              if (panelHasBoundedHeight)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: hud.footerDivider,
                ),
              if (panelHasBoundedHeight) const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  style: hud.resetStyle,
                  onPressed:
                      equippedBySlot.isEmpty ? null : onResetLoadout,
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  label: const Text(
                    'Reset loadout',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );

          if (panelHasBoundedHeight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(
                  child: SingleChildScrollView(
                    clipBehavior: Clip.hardEdge,
                    child: slotBody,
                  ),
                ),
                footer,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              slotBody,
              footer,
            ],
          );
        },
      ),
    );
  }
}

class _BuilderEquipmentZigzag extends StatelessWidget {
  const _BuilderEquipmentZigzag({
    required this.hud,
    required this.slotsByKey,
    required this.equippedBySlot,
    required this.onPickItem,
    required this.centerKeys,
    required this.leftKeys,
    required this.rightKeys,
  });

  final _BuilderRaceHudTheme hud;
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

          return _BuilderHudSlotCell(
            hud: hud,
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

class _BuilderHudSlotCell extends StatelessWidget {
  const _BuilderHudSlotCell({
    required this.hud,
    required this.slotKey,
    required this.slotLabel,
    required this.equippedName,
    required this.rarity,
    required this.frameSize,
    required this.onTap,
  });

  final _BuilderRaceHudTheme hud;
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
        splashColor: hud.inkSplash,
        highlightColor: hud.inkHighlight,
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
                      color: hud.frameShadow,
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
                  builderHudInterior: hud.hudInterior,
                  showInteriorIcon: equippedName != null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                slotLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hud.slotLabelPrimary,
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
                  style: TextStyle(
                    color: hud.slotLabelSecondary,
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
    required this.selectedRace,
    required this.summary,
    required this.formatValue,
    required this.scrollUnitsInternally,
  });

  final String selectedRace;
  final _BuildSummary summary;
  final String Function(double) formatValue;
  final bool scrollUnitsInternally;

  @override
  Widget build(BuildContext context) {
    final summaryHud = _BuilderRaceHudTheme.forRace(selectedRace);

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
              ? 'No items equipped for this race'
              : '${summary.itemCount} equipped items · '
                    '${summary.perUnit.length} units affected',
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Stats',
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
            'Coming next: per-race skill tree using existing icons.',
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
              accent: summaryHud.summaryUnitCardAccent,
              gradientEndAlpha: summaryHud.summaryUnitCardGradientEndAlpha,
              stripeRaceLabel: selectedRace,
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
                      final rarityColor = getRarityColor(c.itemRarity);
                      final lines = c.attrs.entries.toList()
                        ..sort(
                          (a, b) => b.value.abs().compareTo(a.value.abs()),
                        );
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: rarityColor.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CatalogCardStripe.forRarityColor(rarityColor),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        rarityColor.withValues(alpha: 0.06),
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _ResolvedAssetImage(
                                            candidates: [
                                              'assets/generated/item_icons/named/icons/${c.slotKey}.png',
                                            ],
                                            size: 44,
                                            borderRadius: 10,
                                            fallbackIcon: Icons
                                                .inventory_2_outlined,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  slotTitle,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  c.itemName,
                                                  style: TextStyle(
                                                    color: Colors
                                                        .grey.shade800,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                RarityIndicator(
                                                  rarity: c.itemRarity,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ...lines.asMap().entries.map((me) {
                                        final e = me.value;
                                        final v = e.value;
                                        final sign = v >= 0 ? '+' : '';
                                        final isNeg = v < 0;
                                        final amtColor = isNeg
                                            ? const Color(0xFFC75A5A)
                                            : const Color(0xFF2E9B62);
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            top: me.key == 0 ? 0 : 4,
                                          ),
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
                                ),
                              ),
                            ],
                          ),
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
    required this.gradientEndAlpha,
    required this.stripeRaceLabel,
    required this.onInfoTap,
  });

  final _PerUnitBuildSummary unit;
  final String Function(double) formatValue;
  final Color accent;
  final double gradientEndAlpha;
  final String stripeRaceLabel;
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
      decoration: BoxDecoration(
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
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CatalogCardStripe.forRaceLabel(stripeRaceLabel),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      accent.withValues(alpha: gradientEndAlpha),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
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
                                  candidates:
                                      unitIconAssetCandidates(unit.unitKey),
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
                          color: Color.alphaBlend(
                            accent.withValues(alpha: 0.045),
                            const Color(0xFFF6F7FB),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color.alphaBlend(
                              accent.withValues(alpha: 0.12),
                              Colors.grey.shade200,
                            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotStatContribution {
  const _SlotStatContribution({
    required this.slotKey,
    required this.itemName,
    required this.itemRarity,
    required this.attrs,
  });

  final String slotKey;
  final String itemName;
  final String itemRarity;
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
