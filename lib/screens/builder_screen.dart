import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/data/alien_skill_tree_data.dart';
import 'package:worldshift_assistant/data/human_skill_tree_data.dart';
import 'package:worldshift_assistant/data/mutant_skill_tree_data.dart';
import 'package:worldshift_assistant/data/spec_tree_node.dart';
import 'package:worldshift_assistant/data/item.dart';
import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:worldshift_assistant/utils/catalog_card_stripe.dart';
import 'package:worldshift_assistant/utils/catalog_item_filter.dart';
import 'package:worldshift_assistant/utils/item_origin_maps.dart'
    show loadItemOriginDerived;
import 'package:worldshift_assistant/utils/human_spec_build_summary.dart';
import 'package:worldshift_assistant/utils/unit_icon_candidates.dart';
import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/catalog_info_eye_button.dart';
import 'package:worldshift_assistant/widgets/expandable_card.dart';
import 'package:worldshift_assistant/widgets/item_catalog_filters_panel.dart';
import 'package:worldshift_assistant/models/spec_star_allocation.dart';
import 'package:worldshift_assistant/widgets/race_spec_tree_panel.dart';
import 'package:worldshift_assistant/widgets/resolved_mini_asset_image.dart';

/// Sufijo en mapas de totales del builder: mismo stat en plano vs % no se suman en una sola línea.
const _builderTotalsPctSuffix = '__pct';

/// Escala visual (~−20%) para frames de equipo (zigzag + rejilla) en el panel del builder.
const double _kBuilderItemFrameScale = 0.8;

String _builderTotalsStorageKey(String baseKey, bool isPercent) {
  final k = baseKey.trim().toLowerCase();
  return isPercent ? '$k$_builderTotalsPctSuffix' : k;
}

String _builderTotalsBaseAttrKey(String storageKey) {
  if (storageKey.endsWith(_builderTotalsPctSuffix)) {
    return storageKey.substring(
      0,
      storageKey.length - _builderTotalsPctSuffix.length,
    );
  }
  return storageKey;
}

String _builderTotalsAttrDisplayLabel(String storageKey) {
  return getAttributeValue(_builderTotalsBaseAttrKey(storageKey));
}

/// Distinct from [null] so closing the sheet without choosing does not unequip.
final Object _builderPickerUnequip = Object();

SpecTreeNode? _specTreeNodeForBuilderRace(String uiRace, String repo) {
  switch (uiRace) {
    case 'Humans':
      return humanSpecTreeByRepo[repo];
    case 'Tribes':
      return mutantSpecTreeByRepo[repo];
    case 'Aliens':
      return alienSpecTreeByRepo[repo];
  }
  return null;
}

enum _BuilderPanelTab { items, skillTree }

enum _BuildSummaryViewTab { all, items, skills }

/// Max length for loadout names (saved + text field). Change if you need another cap.
const int _kMaxLoadoutNameChars = 30;

String _clampLoadoutName(String value) {
  final t = value.trim();
  if (t.length <= _kMaxLoadoutNameChars) {
    return t;
  }
  return t.substring(0, _kMaxLoadoutNameChars);
}

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

  /// Stars per repo (Humans / Tribes / Aliens); same persistence as equipment.
  static const _prefsSpecStarsKey = 'builder_spec_stars_by_race_v1';

  /// Named snapshots: equipment + skill tree (all races) + selected race tab.
  static const _prefsSavedBuildsKey = 'builder_saved_builds_v1';

  late final Future<List<Item>> _itemsFuture;
  String _selectedRace = 'Humans';
  _BuilderPanelTab _panelTab = _BuilderPanelTab.items;
  _BuildSummaryViewTab _summaryViewTab = _BuildSummaryViewTab.all;
  final Map<String, Map<String, Item>> _equippedByRace = {
    for (final r in _races) r: <String, Item>{},
  };

  /// Specialization stars per race (`repo` → invested points). Max 10 per race total.
  final Map<String, Map<String, int>> _specStarsByRace = {
    for (final r in _races) r: <String, int>{},
  };

  /// Orígenes por mapa desde `item_origin_index.json` (mismo criterio que el catálogo).
  final Map<int, Set<String>> _resolvedMapNamesByItem = {};

  Map<String, Item> get _equipForSelectedRace =>
      _equippedByRace[_selectedRace]!;

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
    final lootFuture = combineLootData(
      WorldshiftAssets.lootTableFile,
      WorldshiftAssets.itemsDefinitionFile,
    );
    final derivedFuture = loadItemOriginDerived();
    final items = await lootFuture;
    final derived = await derivedFuture;
    _resolvedMapNamesByItem
      ..clear()
      ..addAll(derived.mapNamesByItemId);
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

    try {
      final rawSpec = prefs.getString(_prefsSpecStarsKey);
      if (rawSpec != null && rawSpec.isNotEmpty) {
        final decoded = jsonDecode(rawSpec);
        if (decoded is Map) {
          for (final raceName in _races) {
            final inner = decoded[raceName];
            if (inner is! Map) {
              continue;
            }
            final m = _specStarsByRace[raceName]!;
            m.clear();
            for (final e in inner.entries) {
              final k = '${e.key}';
              final v = e.value;
              final n = v is int
                  ? v
                  : v is num
                      ? v.toInt()
                      : int.tryParse('$v');
              if (n != null && n > 0) {
                m[k] = n;
              }
            }
          }
        }
      }
    } catch (_) {
      // ignore corrupt spec stars
    }

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
    final specPayload = {
      for (final r in _races) r: {..._specStarsByRace[r]!},
    };
    await prefs.setString(_prefsSpecStarsKey, jsonEncode(specPayload));
  }

  Map<String, dynamic> _captureBuildSnapshot() {
    return {
      'equip': {
        for (final r in _races)
          r: {
            for (final e in _equippedByRace[r]!.entries) e.key: e.value.id,
          },
      },
      'specStars': {
        for (final r in _races) r: {..._specStarsByRace[r]!},
      },
      'selectedRace': _selectedRace,
    };
  }

  Future<List<Map<String, dynamic>>> _readSavedBuildsList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsSavedBuildsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeSavedBuildsList(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsSavedBuildsKey, jsonEncode(list));
  }

  /// Aplica un snapshot guardado (misma validación que al leer prefs del builder).
  void _applyBuildSnapshot(List<Item> items, Map<String, dynamic> snap) {
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

    final equip = snap['equip'];
    if (equip is Map) {
      for (final race in _races) {
        final inner = equip[race];
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

    for (final raceName in _races) {
      _specStarsByRace[raceName]!.clear();
    }
    final spec = snap['specStars'];
    if (spec is Map) {
      for (final raceName in _races) {
        final inner = spec[raceName];
        if (inner is! Map) {
          continue;
        }
        final m = _specStarsByRace[raceName]!;
        for (final e in inner.entries) {
          final k = '${e.key}';
          final v = e.value;
          final n = v is int
              ? v
              : v is num
                  ? v.toInt()
                  : int.tryParse('$v');
          if (n != null && n > 0) {
            m[k] = n;
          }
        }
      }
    }

    final sr = snap['selectedRace'];
    final race = sr is String && _races.contains(sr) ? sr : _selectedRace;

    setState(() {
      for (final r in _races) {
        _equippedByRace[r]!
          ..clear()
          ..addAll(nextByRace[r]!);
      }
      _selectedRace = race;
      _summaryViewTab = _BuildSummaryViewTab.all;
    });
  }

  /// Localiza la fila a sustituir tras re-leer prefs (orden puede cambiar).
  int? _findSavedBuildToOverwrite(
    List<Map<String, dynamic>> fresh,
    Map<String, dynamic> marker,
    int preferredIndex,
  ) {
    final mid = marker['id'];
    if (mid != null && '$mid'.isNotEmpty) {
      final i = fresh.indexWhere((e) => '${e['id']}' == '$mid');
      if (i >= 0) {
        return i;
      }
    }
    final name = '${marker['name']}';
    final at = '${marker['savedAt']}';
    final i = fresh.indexWhere(
      (e) => '${e['name']}' == name && '${e['savedAt']}' == at,
    );
    if (i >= 0) {
      return i;
    }
    if (preferredIndex >= 0 && preferredIndex < fresh.length) {
      return preferredIndex;
    }
    return null;
  }

  Future<void> _persistSaveOutcome(
    List<Map<String, dynamic>> snapshotAtDialogOpen,
    _SaveBuilderConfigOutcome outcome,
  ) async {
    final name = _clampLoadoutName(outcome.name);
    if (name.isEmpty) {
      return;
    }
    final snap = _captureBuildSnapshot();
    final list = await _readSavedBuildsList();
    if (outcome.createNew) {
      final entry = <String, dynamic>{
        'schema': 1,
        'id': '${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'savedAt': DateTime.now().toIso8601String(),
        ...snap,
      };
      list.insert(0, entry);
    } else {
      final idx = outcome.overwriteSnapshotIndex;
      if (idx == null ||
          idx < 0 ||
          idx >= snapshotAtDialogOpen.length) {
        return;
      }
      final marker = snapshotAtDialogOpen[idx];
      final target = _findSavedBuildToOverwrite(list, marker, idx);
      if (target == null) {
        return;
      }
      final preservedId =
          list[target]['id'] ?? '${DateTime.now().millisecondsSinceEpoch}';
      list[target] = <String, dynamic>{
        'schema': 1,
        'id': '$preservedId',
        'name': name,
        'savedAt': DateTime.now().toIso8601String(),
        ...snap,
      };
    }
    await _writeSavedBuildsList(list);
  }

  Future<void> _openSaveBuildDialog() async {
    final existing = await _readSavedBuildsList();
    if (!mounted) {
      return;
    }
    final snapshot = List<Map<String, dynamic>>.from(existing);
    final outcome = await showDialog<_SaveBuilderConfigOutcome>(
      context: context,
      builder: (ctx) => _SaveBuilderConfigDialog(
        initialText: '',
        existingSaved: snapshot,
      ),
    );
    if (outcome == null || outcome.name.trim().isEmpty || !mounted) {
      return;
    }
    await _persistSaveOutcome(snapshot, outcome);
    if (!mounted) {
      return;
    }
    final label = outcome.name.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.createNew
              ? 'New loadout saved: $label'
              : 'Loadout updated: $label',
        ),
      ),
    );
  }

  Future<void> _openLoadBuildWhenReady() async {
    final items = await _itemsFuture;
    if (!mounted) {
      return;
    }
    await _openLoadBuildSheet(items);
  }

  Future<void> _openLoadBuildSheet(List<Item> allItems) async {
    final list = await _readSavedBuildsList();
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF8F9FA),
      builder: (ctx) {
        final h = (MediaQuery.sizeOf(ctx).height * 0.55).clamp(240.0, 520.0);
        final localList = List<Map<String, dynamic>>.from(list);
        return SizedBox(
          height: h,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final body = localList.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No saved loadouts yet.\n'
                          'Use Save Loadout above the build summary.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: localList.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, i) {
                        final e = localList[i];
                        final label = _savedLoadoutDisplayName(e);
                        return ListTile(
                          title: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Delete',
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error,
                                ),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: ctx,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Delete loadout'),
                                      content: Text(
                                        'Delete “$label”? This cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dCtx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(dCtx)
                                                .colorScheme
                                                .error,
                                            foregroundColor: Theme.of(dCtx)
                                                .colorScheme
                                                .onError,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(dCtx).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) {
                                    return;
                                  }
                                  localList.remove(e);
                                  await _writeSavedBuildsList(localList);
                                  if (!mounted) {
                                    return;
                                  }
                                  setModalState(() {});
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Deleted: $label')),
                                  );
                                },
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => Navigator.of(ctx).pop(e),
                        );
                      },
                    );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Saved loadouts',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(child: body),
                ],
              );
            },
          ),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    final displayName = '${picked['name'] ?? 'Loadout'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load loadout'),
        content: Text(
          'Load “$displayName”?\n\n'
          'Equipped items and specialization trees for all races will be '
          'replaced with this loadout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    _applyBuildSnapshot(allItems, picked);
    await _persistBuilderState();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded: $displayName')),
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
        lockedRace: _selectedRace,
        allItems: allItems,
        resolvedMapNamesByItem: _resolvedMapNamesByItem,
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

  Widget _buildSkillTreeForHud(_BuilderRaceHudTheme hud) {
    final m = _specStarsByRace[_selectedRace]!;
    void commit(Map<String, int> next) {
      setState(() {
        m.clear();
        m.addAll(next);
      });
      unawaited(_persistBuilderState());
    }
    final allocated = Map<String, int>.from(m);
    switch (_selectedRace) {
      case 'Humans':
        return RaceSpecTreePanel.humans(
          hudTitleColor: hud.titleColor,
          hudHintColor: hud.hintColor,
          hudChipBg: hud.chipBackground,
          hudInkSplash: hud.inkSplash,
          hudInkHighlight: hud.inkHighlight,
          hudPanelBg: hud.panelBg,
          hudPanelBorder: hud.panelBorder,
          allocatedByRepo: allocated,
          onSpecAllocationChanged: commit,
        );
      case 'Tribes':
        return RaceSpecTreePanel.mutants(
          hudTitleColor: hud.titleColor,
          hudHintColor: hud.hintColor,
          hudChipBg: hud.chipBackground,
          hudInkSplash: hud.inkSplash,
          hudInkHighlight: hud.inkHighlight,
          hudPanelBg: hud.panelBg,
          hudPanelBorder: hud.panelBorder,
          allocatedByRepo: allocated,
          onSpecAllocationChanged: commit,
        );
      case 'Aliens':
        return RaceSpecTreePanel.aliens(
          hudTitleColor: hud.titleColor,
          hudHintColor: hud.hintColor,
          hudChipBg: hud.chipBackground,
          hudInkSplash: hud.inkSplash,
          hudInkHighlight: hud.inkHighlight,
          hudPanelBg: hud.panelBg,
          hudPanelBorder: hud.panelBorder,
          allocatedByRepo: allocated,
          onSpecAllocationChanged: commit,
        );
      default:
        return _EquipmentPanel.skillTreePlaceholder(hud);
    }
  }

  Future<void> _confirmResetCurrentRaceItems() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset items'),
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

  Future<void> _confirmResetCurrentRaceSpecStars() async {
    final m = _specStarsByRace[_selectedRace]!;
    if (totalSpecStarsAllocated(m) == 0) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset skills'),
        content: Text(
          'Clear all specialization skills (stars) for $_selectedRace? Other races are not affected.',
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
    setState(() => m.clear());
    unawaited(_persistBuilderState());
  }

  _BuildSummary _buildSummary() {
    final byUnit = <String, _UnitSummaryScratch>{};

    for (final equip in _equipForSelectedRace.entries) {
      final slotKey = equip.key;
      final item = equip.value;
      for (final unitEntry in item.attributes.entries) {
        final unitKey = unitEntry.key;
        final rawAttrs = unitEntry.value;
        final sc = byUnit.putIfAbsent(
          unitKey,
          () => _UnitSummaryScratch(unitKey),
        );
        final slotAttrs = <String, NumericAttrValue>{};
        for (final ae in rawAttrs.entries) {
          final parsed = _parseNumericAttr(ae.value);
          if (parsed == null) {
            continue;
          }
          final tk = _builderTotalsStorageKey(ae.key, parsed.isPercent);
          sc.totalsItems[tk] = (sc.totalsItems[tk] ?? 0) + parsed.value;
          sc.itemPercentHints
              .putIfAbsent(tk, _PercentHintAgg.new)
              .add(parsed.isPercent);
          slotAttrs.update(
            ae.key,
            (prev) => NumericAttrValue(
              value: prev.value + parsed.value,
              isPercent: prev.isPercent && parsed.isPercent,
            ),
            ifAbsent: () => parsed,
          );
        }
        if (slotAttrs.isNotEmpty) {
          sc.itemSources.add(
            _BuildStatSource.item(
              slotKey: slotKey,
              itemName: item.name,
              itemRarity: item.rarity,
              attrs: Map<String, NumericAttrValue>.from(slotAttrs),
            ),
          );
        }
      }
    }

    final specStarsUsed =
        totalSpecStarsAllocated(_specStarsByRace[_selectedRace]!);
    final specAppliesToSummary =
        _selectedRace == 'Humans' ||
            _selectedRace == 'Tribes' ||
            _selectedRace == 'Aliens';
    if (specAppliesToSummary) {
      final detailed = specTreeContributionsDetailed(
        _specStarsByRace[_selectedRace]!,
        (repo) => _specTreeNodeForBuilderRace(_selectedRace, repo),
      );
      for (final ue in detailed.entries) {
        final sc = byUnit.putIfAbsent(
          ue.key,
          () => _UnitSummaryScratch(ue.key),
        );
        for (final row in ue.value) {
          sc.skillSources.add(
            _BuildStatSource.spec(
              specRepo: row.repo,
              nodeTitle: row.nodeTitle,
              attrs: Map<String, NumericAttrValue>.from(row.attrs),
              specInvestedRanks: row.investedRanks,
              specMaxRanks: row.maxRanks,
            ),
          );
          for (final ae in row.attrs.entries) {
            final tk =
                _builderTotalsStorageKey(ae.key, ae.value.isPercent);
            sc.totalsSkills[tk] =
                (sc.totalsSkills[tk] ?? 0) + ae.value.value;
            sc.skillPercentHints
                .putIfAbsent(tk, _PercentHintAgg.new)
                .add(ae.value.isPercent);
          }
        }
      }
    }

    final perUnit = byUnit.values
        .map(
          (b) => _PerUnitBuildSummary(
            unitKey: b.unitKey,
            displayLabel: _formatBuilderUnitLabel(b.unitKey),
            totalsItems: Map<String, double>.from(b.totalsItems),
            totalsSkills: Map<String, double>.from(b.totalsSkills),
            totalsAll: _mergeAttrTotals(b.totalsItems, b.totalsSkills),
            percentItems: {
              for (final e in b.itemPercentHints.entries)
                e.key: e.value.uniformPercent,
            },
            percentSkills: {
              for (final e in b.skillPercentHints.entries)
                e.key: e.value.uniformPercent,
            },
            percentAll: _percentFlagsMerged(
              b.itemPercentHints,
              b.skillPercentHints,
              _mergeAttrTotals(b.totalsItems, b.totalsSkills),
            ),
            itemSources: List<_BuildStatSource>.from(b.itemSources),
            skillSources: List<_BuildStatSource>.from(b.skillSources),
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
      specStarsUsed: specStarsUsed,
      specAppliesToSummary: specAppliesToSummary,
    );
  }

  static Map<String, double> _mergeAttrTotals(
    Map<String, double> a,
    Map<String, double> b,
  ) {
    final out = Map<String, double>.from(a);
    for (final e in b.entries) {
      out[e.key] = (out[e.key] ?? 0) + e.value;
    }
    return out;
  }

  static Map<String, bool> _percentFlagsMerged(
    Map<String, _PercentHintAgg> itemHints,
    Map<String, _PercentHintAgg> skillHints,
    Map<String, double> totalsAll,
  ) {
    return {
      for (final k in totalsAll.keys)
        k: _uniformPercentAcross(itemHints[k], skillHints[k]),
    };
  }

  static bool _uniformPercentAcross(
    _PercentHintAgg? item,
    _PercentHintAgg? skill,
  ) {
    final ti = item?.total ?? 0;
    final pi = item?.percentCount ?? 0;
    final ts = skill?.total ?? 0;
    final ps = skill?.percentCount ?? 0;
    final t = ti + ts;
    final p = pi + ps;
    return t > 0 && p == t;
  }

  static String _formatBuilderUnitLabel(String unitKey) {
    final rawLabel = getUnitValue(unitKey).replaceAll('_', ' ').trim();
    return rawLabel.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  NumericAttrValue? _parseNumericAttr(String raw) {
    final m = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(raw);
    if (m == null) {
      return null;
    }
    final v = double.tryParse(m.group(0)!.replaceAll(',', '.'));
    if (v == null) {
      return null;
    }
    return NumericAttrValue(value: v, isPercent: raw.contains('%'));
  }

  String _formatValue(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatAttrDisplay(double value, bool isPercent) {
    final core = _formatValue(value);
    return isPercent ? '$core%' : core;
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
                resolvedMapNamesByItem: _resolvedMapNamesByItem,
                selectedRace: _selectedRace,
                races: _races,
                onRaceChanged: (race) {
                  setState(() {
                    _selectedRace = race;
                    _summaryViewTab = _BuildSummaryViewTab.all;
                  });
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
                onFooterReset: () {
                  if (_panelTab == _BuilderPanelTab.items) {
                    unawaited(_confirmResetCurrentRaceItems());
                  } else {
                    unawaited(_confirmResetCurrentRaceSpecStars());
                  }
                },
                footerResetLabel: _panelTab == _BuilderPanelTab.items
                    ? 'Reset items'
                    : 'Reset skills',
                footerResetEnabled: _panelTab == _BuilderPanelTab.items
                    ? _equipForSelectedRace.isNotEmpty
                    : totalSpecStarsAllocated(
                          _specStarsByRace[_selectedRace]!,
                        ) >
                        0,
                skillTreeForHud: _buildSkillTreeForHud,
              );
              final panelRight = _SummaryPanel(
                selectedRace: _selectedRace,
                summary: summary,
                formatAttrDisplay: _formatAttrDisplay,
                scrollUnitsInternally: constraints.maxWidth >= 1050,
                summaryViewTab: _summaryViewTab,
                onSummaryViewTabChanged: (t) =>
                    setState(() => _summaryViewTab = t),
              );

              final loadoutActions = Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => unawaited(_openSaveBuildDialog()),
                        icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                        label: const Text('Save Loadout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4338CA),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => unawaited(_openLoadBuildWhenReady()),
                        icon: const Icon(Icons.folder_open_outlined, size: 20),
                        label: const Text('Load Loadout'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (constraints.maxWidth >= 1050) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: panelLeft),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            loadoutActions,
                            Expanded(child: panelRight),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  panelLeft,
                  const SizedBox(height: 12),
                  loadoutActions,
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

/// Loadout name only (no date), for dropdowns and lists.
String _savedLoadoutDisplayName(Map<String, dynamic> e) {
  return _clampLoadoutName('${e['name'] ?? 'Unnamed'}');
}

class _SaveBuilderConfigOutcome {
  const _SaveBuilderConfigOutcome({
    required this.createNew,
    this.overwriteSnapshotIndex,
    required this.name,
  });

  final bool createNew;
  final int? overwriteSnapshotIndex;
  final String name;
}

class _SaveBuilderConfigDialog extends StatefulWidget {
  const _SaveBuilderConfigDialog({
    required this.initialText,
    required this.existingSaved,
  });

  final String initialText;
  final List<Map<String, dynamic>> existingSaved;

  @override
  State<_SaveBuilderConfigDialog> createState() =>
      _SaveBuilderConfigDialogState();
}

class _SaveBuilderConfigDialogState extends State<_SaveBuilderConfigDialog> {
  late final TextEditingController _controller;
  late bool _createNew;
  late int _overwriteIdx;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _clampLoadoutName(widget.initialText),
    );
    _createNew = true;
    _overwriteIdx = 0;
  }

  void _syncNameFromOverwriteSelection() {
    if (widget.existingSaved.isEmpty) {
      return;
    }
    final i = _overwriteIdx.clamp(0, widget.existingSaved.length - 1);
    final n = _clampLoadoutName('${widget.existingSaved[i]['name'] ?? ''}');
    if (n.isNotEmpty) {
      _controller.text = n;
    }
  }

  void _onLoadoutSaveModeChanged(bool? v) {
    if (v == null) {
      return;
    }
    setState(() {
      _createNew = v;
      if (!v) {
        _syncNameFromOverwriteSelection();
      }
    });
  }

  void _submit() {
    final name = _clampLoadoutName(_controller.text);
    if (name.isEmpty) {
      return;
    }
    final canOverwrite = widget.existingSaved.isNotEmpty;
    final createNew = _createNew || !canOverwrite;
    Navigator.of(context).pop(
      _SaveBuilderConfigOutcome(
        createNew: createNew,
        overwriteSnapshotIndex: createNew ? null : _overwriteIdx,
        name: name,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canOverwrite = widget.existingSaved.isNotEmpty;
    return AlertDialog(
      title: const Text('Save loadout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canOverwrite) ...[
              RadioListTile<bool>(
                title: const Text('New loadout'),
                subtitle: const Text('Adds another entry to the list'),
                value: true,
                groupValue: _createNew,
                onChanged: _onLoadoutSaveModeChanged,
              ),
              RadioListTile<bool>(
                title: const Text('Overwrite existing'),
                subtitle: const Text(
                  'Updates items and skill tree on a saved loadout',
                ),
                value: false,
                groupValue: _createNew,
                onChanged: _onLoadoutSaveModeChanged,
              ),
              if (!_createNew) ...[
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _overwriteIdx.clamp(
                    0,
                    widget.existingSaved.length - 1,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Loadout to update',
                  ),
                  selectedItemBuilder: (context) => [
                    for (var i = 0; i < widget.existingSaved.length; i++)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _savedLoadoutDisplayName(widget.existingSaved[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  items: [
                    for (var i = 0; i < widget.existingSaved.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          _savedLoadoutDisplayName(widget.existingSaved[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) {
                      return;
                    }
                    setState(() {
                      _overwriteIdx = v;
                      _syncNameFromOverwriteSelection();
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Mutant tank PvE',
              ),
              autofocus: !canOverwrite,
              maxLength: _kMaxLoadoutNameChars,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _BuilderEquipItemPicker extends StatefulWidget {
  const _BuilderEquipItemPicker({
    required this.slotKey,
    required this.slotLabel,
    required this.lockedRace,
    required this.allItems,
    required this.resolvedMapNamesByItem,
    required this.canUnequip,
    required this.unequipToken,
  });

  final String slotKey;
  final String slotLabel;
  final String lockedRace;
  final List<Item> allItems;
  final Map<int, Set<String>> resolvedMapNamesByItem;
  final bool canUnequip;
  final Object unequipToken;

  @override
  State<_BuilderEquipItemPicker> createState() =>
      _BuilderEquipItemPickerState();
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
            resolvedMapNamesByItem: widget.resolvedMapNamesByItem,
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
                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
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
                                resolvedMapNames:
                                    widget.resolvedMapNamesByItem[item.id],
                                onSelect: () => Navigator.of(context).pop(item),
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
  final Color slotLabelPrimary;
  final Color slotLabelSecondary;
  final Color inkSplash;
  final Color inkHighlight;
  final Color frameShadow;

  /// Soft tint on per-unit summary stat cards (Humans keeps the list violet).
  final Color summaryUnitCardAccent;

  /// Second gradient color opacity on those cards (Humans ≈ original list).
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

({List<String> center, List<String> left, List<String> right})?
    _zigzagKeysForRace(String race) {
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
    required this.resolvedMapNamesByItem,
    required this.selectedRace,
    required this.races,
    required this.onRaceChanged,
    required this.panelTab,
    required this.onPanelTabChanged,
    required this.slotsForRace,
    required this.equippedBySlot,
    required this.onPickItem,
    required this.onFooterReset,
    required this.footerResetLabel,
    required this.footerResetEnabled,
    required this.skillTreeForHud,
  });

  final Map<int, Set<String>> resolvedMapNamesByItem;
  final String selectedRace;
  final List<String> races;
  final ValueChanged<String> onRaceChanged;
  final _BuilderPanelTab panelTab;
  final ValueChanged<_BuilderPanelTab> onPanelTabChanged;
  final List<Map<String, String>> slotsForRace;
  final Map<String, Item> equippedBySlot;
  final void Function(String slotKey, String slotLabel) onPickItem;
  final VoidCallback onFooterReset;
  final String footerResetLabel;
  final bool footerResetEnabled;
  final Widget Function(_BuilderRaceHudTheme hud) skillTreeForHud;

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

  /// Items / Skill tree with the active race HUD.
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

  static Widget skillTreePlaceholder(_BuilderRaceHudTheme hud) {
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

  Map<String, Map<String, String>> _slotsByKey() {
    return {
      for (final s in slotsForRace) s['key'] ?? '': s,
    };
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
          const gridItemFrameSize = 42 * _kBuilderItemFrameScale;
          const gridCellPadding = 10 * _kBuilderItemFrameScale;
          const gridCellGap = 10 * _kBuilderItemFrameScale;

          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (panelTab == _BuilderPanelTab.items) ...[
                const SizedBox(height: 12),
                Text(
                  'Tap a slot to equip an item.',
                  style: TextStyle(
                    color: hud.hintColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (panelTab == _BuilderPanelTab.skillTree) ...[
                if (selectedRace != 'Humans') ...[
                  const SizedBox(height: 12),
                  Text(
                    'Skill tree for this race — work in progress.',
                    style: TextStyle(
                      color: hud.hintColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    'Tap a skill to add a star.',
                    style: TextStyle(
                      color: hud.hintColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          );

          final zig = _zigzagKeysForRace(selectedRace);
          final equipmentBody = zig != null
              ? _BuilderEquipmentZigzag(
                  hud: hud,
                  slotsByKey: _slotsByKey(),
                  equippedBySlot: equippedBySlot,
                  resolvedMapNamesByItem: resolvedMapNamesByItem,
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
                    crossAxisSpacing: gridCellGap,
                    mainAxisSpacing: gridCellGap,
                    childAspectRatio: 1.4,
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
                            padding: const EdgeInsets.all(gridCellPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: gridItemFrameSize,
                                      height: gridItemFrameSize,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              ItemCompleteFrame.cornerRadiusFor(
                                                gridItemFrameSize,
                                              ),
                                            ),
                                            clipBehavior: Clip.hardEdge,
                                            child: ItemCompleteFrame(
                                              slot: slotKey,
                                              rarity: equipped?.rarity ?? '1',
                                              size: gridItemFrameSize,
                                              showInteriorIcon: equipped != null,
                                              lightInteriorFill:
                                                  Colors.transparent,
                                            ),
                                          ),
                                          if (equipped != null)
                                            Positioned(
                                              top: gridCellPadding * 0.3,
                                              right: gridCellPadding * 0.3,
                                              child: CatalogInfoEyeButton(
                                                frameSize: gridItemFrameSize,
                                                tooltip: 'View item details',
                                                onPressed: () {
                                                  final e =
                                                      equippedBySlot[slotKey];
                                                  if (e == null) {
                                                    return;
                                                  }
                                                  showItemCatalogDetailSheet(
                                                    context,
                                                    name: e.name,
                                                    map: e.map,
                                                    rarity: e.rarity.isEmpty
                                                        ? 'unknown'
                                                        : e.rarity,
                                                    obtainedFrom: e.obtainedFrom,
                                                    itemData: e.toMap(),
                                                    resolvedMapNames:
                                                        resolvedMapNamesByItem[
                                                            e.id],
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: equipped == null
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  slotLabel,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Empty slot',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  equipped.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF334155),
                                                    height: 1.15,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  slotLabel,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B),
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );

          final skillsBody = skillTreeForHud(hud);
          final animatedBody = _BuilderTabLateralSlide(
            tab: panelTab,
            items: equipmentBody,
            skills: skillsBody,
          );

          final slotWithSwipe = _BuilderTabHorizontalSwipe(
            panelTab: panelTab,
            onSwitchTab: onPanelTabChanged,
            child: animatedBody,
          );

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
                  onPressed: footerResetEnabled ? onFooterReset : null,
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  label: Text(
                    footerResetLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
                  child: _BuilderTabHorizontalSwipe(
                    panelTab: panelTab,
                    onSwitchTab: onPanelTabChanged,
                    child: SingleChildScrollView(
                      clipBehavior: Clip.hardEdge,
                      child: animatedBody,
                    ),
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
              slotWithSwipe,
              footer,
            ],
          );
        },
      ),
    );
  }
}

/// Simula el cierre de un [PageView]: la vista anterior se desliza fuera y la nueva entra
/// desde el lateral (animación al soltar / al pulsar chip; no sigue el dedo en tiempo real).
class _BuilderTabLateralSlide extends StatefulWidget {
  const _BuilderTabLateralSlide({
    required this.tab,
    required this.items,
    required this.skills,
  });

  final _BuilderPanelTab tab;
  final Widget items;
  final Widget skills;

  @override
  State<_BuilderTabLateralSlide> createState() => _BuilderTabLateralSlideState();
}

class _BuilderTabLateralSlideState extends State<_BuilderTabLateralSlide>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 300);

  late final AnimationController _controller;
  _BuilderPanelTab _idleTab = _BuilderPanelTab.items;
  _BuilderPanelTab? _fromTab;
  _BuilderPanelTab? _toTab;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    _idleTab = widget.tab;
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener(_onAnimStatus);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    setState(() {
      _idleTab = _toTab!;
      _fromTab = null;
      _toTab = null;
    });
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BuilderTabLateralSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != _idleTab && _fromTab == null && _toTab == null) {
      setState(() {
        _fromTab = _idleTab;
        _toTab = widget.tab;
        _forward = widget.tab.index > _idleTab.index;
      });
      _controller.forward();
    }
  }

  /// Orden fijo: [items], [skills]. Así el [Stack] siempre tiene altura
  /// max(items, skills) y no hay salto al empezar/terminar la animación.
  static double _itemsOffsetX({
    required bool animating,
    required bool forward,
    required double t,
    required double w,
    required _BuilderPanelTab idleTab,
  }) {
    if (!animating) {
      return idleTab == _BuilderPanelTab.items ? 0.0 : -w;
    }
    if (forward) {
      return -w * t;
    }
    return -w * (1 - t);
  }

  static double _skillsOffsetX({
    required bool animating,
    required bool forward,
    required double t,
    required double w,
    required _BuilderPanelTab idleTab,
  }) {
    if (!animating) {
      return idleTab == _BuilderPanelTab.items ? w : 0.0;
    }
    if (forward) {
      return w * (1 - t);
    }
    return w * t;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.clamp(1.0, double.infinity);
        final animating = _fromTab != null && _toTab != null;

        Widget layer(double Function(double t) offsetX, Widget child) {
          if (!animating) {
            return Transform.translate(
              offset: Offset(
                offsetX(
                  Curves.easeOutCubic.transform(_controller.value),
                ),
                0,
              ),
              child: SizedBox(width: w, child: child),
            );
          }
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final tAnim =
                  Curves.easeOutCubic.transform(_controller.value);
              return Transform.translate(
                offset: Offset(offsetX(tAnim), 0),
                child: SizedBox(width: w, child: child),
              );
            },
          );
        }

        double itemsT(double t) => _itemsOffsetX(
              animating: animating,
              forward: _forward,
              t: t,
              w: w,
              idleTab: _idleTab,
            );

        double skillsT(double t) => _skillsOffsetX(
              animating: animating,
              forward: _forward,
              t: t,
              w: w,
              idleTab: _idleTab,
            );

        return ClipRect(
          clipBehavior: Clip.hardEdge,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            children: [
              layer(itemsT, widget.items),
              layer(skillsT, widget.skills),
            ],
          ),
        );
      },
    );
  }
}

/// Cambio de pestaña Items ↔ Skill tree con desliz horizontal (sin PageView ni altura fija).
class _BuilderTabHorizontalSwipe extends StatelessWidget {
  const _BuilderTabHorizontalSwipe({
    required this.panelTab,
    required this.onSwitchTab,
    required this.child,
  });

  final _BuilderPanelTab panelTab;
  final ValueChanged<_BuilderPanelTab> onSwitchTab;
  final Widget child;

  static const double _velocityThreshold = 240;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final vx = details.velocity.pixelsPerSecond.dx;
        if (vx < -_velocityThreshold && panelTab == _BuilderPanelTab.items) {
          onSwitchTab(_BuilderPanelTab.skillTree);
        } else if (vx > _velocityThreshold &&
            panelTab == _BuilderPanelTab.skillTree) {
          onSwitchTab(_BuilderPanelTab.items);
        }
      },
      child: child,
    );
  }
}

class _BuilderEquipmentZigzag extends StatelessWidget {
  const _BuilderEquipmentZigzag({
    required this.hud,
    required this.slotsByKey,
    required this.equippedBySlot,
    required this.resolvedMapNamesByItem,
    required this.onPickItem,
    required this.centerKeys,
    required this.leftKeys,
    required this.rightKeys,
  });

  final _BuilderRaceHudTheme hud;
  final Map<String, Map<String, String>> slotsByKey;
  final Map<String, Item> equippedBySlot;
  final Map<int, Set<String>> resolvedMapNamesByItem;
  final void Function(String slotKey, String slotLabel) onPickItem;
  final List<String> centerKeys;
  final List<String> leftKeys;
  final List<String> rightKeys;

  static const double _colGap = 4.8;
  static const double _rowGap = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final frameSize =
            ((maxW / 3.2).clamp(64.0, 88.0)) * _kBuilderItemFrameScale;

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
            equipped: equipped,
            rarity: rarity,
            frameSize: frameSize,
            resolvedMapNamesByItem: resolvedMapNamesByItem,
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
    required this.equipped,
    required this.rarity,
    required this.frameSize,
    required this.resolvedMapNamesByItem,
    required this.onTap,
  });

  final _BuilderRaceHudTheme hud;
  final String slotKey;
  final String slotLabel;
  final Item? equipped;
  final String rarity;
  final double frameSize;
  final Map<int, Set<String>> resolvedMapNamesByItem;
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
              Material(
                color: Colors.transparent,
                elevation: 3,
                shadowColor: hud.frameShadow,
                surfaceTintColor: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  ItemCompleteFrame.cornerRadiusFor(frameSize),
                ),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: frameSize,
                  height: frameSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          ItemCompleteFrame.cornerRadiusFor(frameSize),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: ItemCompleteFrame(
                          slot: slotKey,
                          rarity: rarity,
                          size: frameSize,
                          showInteriorIcon: equipped != null,
                          lightInteriorFill: Colors.transparent,
                        ),
                      ),
                      if (equipped != null)
                        Positioned(
                          top: (frameSize * 0.06).clamp(3.0, 8.0),
                          right: (frameSize * 0.06).clamp(3.0, 8.0),
                          child: CatalogInfoEyeButton(
                            frameSize: frameSize,
                            tooltip: 'View item details',
                            onPressed: () {
                              final e = equipped;
                              if (e == null) {
                                return;
                              }
                              showItemCatalogDetailSheet(
                                context,
                                name: e.name,
                                map: e.map,
                                rarity: e.rarity.isEmpty ? 'unknown' : e.rarity,
                                obtainedFrom: e.obtainedFrom,
                                itemData: e.toMap(),
                                resolvedMapNames:
                                    resolvedMapNamesByItem[e.id],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (equipped == null) ...[
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
              ] else ...[
                Text(
                  equipped!.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hud.slotLabelPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slotLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hud.slotLabelSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
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

Map<String, double> _summaryDisplayTotals(
  _PerUnitBuildSummary u,
  _BuildSummaryViewTab tab,
) {
  switch (tab) {
    case _BuildSummaryViewTab.all:
      return u.totalsAll;
    case _BuildSummaryViewTab.items:
      return u.totalsItems;
    case _BuildSummaryViewTab.skills:
      return u.totalsSkills;
  }
}

Map<String, bool> _summaryPercentFlags(
  _PerUnitBuildSummary u,
  _BuildSummaryViewTab tab,
) {
  switch (tab) {
    case _BuildSummaryViewTab.all:
      return u.percentAll;
    case _BuildSummaryViewTab.items:
      return u.percentItems;
    case _BuildSummaryViewTab.skills:
      return u.percentSkills;
  }
}

String _summaryInfoTooltip(_BuildSummaryViewTab tab) {
  switch (tab) {
    case _BuildSummaryViewTab.all:
      return 'Sources: items and specialization nodes';
    case _BuildSummaryViewTab.items:
      return 'Slots that grant stats to this unit';
    case _BuildSummaryViewTab.skills:
      return 'Specialization nodes that grant stats';
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.selectedRace,
    required this.summary,
    required this.formatAttrDisplay,
    required this.scrollUnitsInternally,
    required this.summaryViewTab,
    required this.onSummaryViewTabChanged,
  });

  final String selectedRace;
  final _BuildSummary summary;
  final String Function(double value, bool isPercent) formatAttrDisplay;
  final bool scrollUnitsInternally;
  final _BuildSummaryViewTab summaryViewTab;
  final ValueChanged<_BuildSummaryViewTab> onSummaryViewTabChanged;

  static const _tabLabels = ['All', 'Items', 'Skills'];

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
          () {
            if (summary.specAppliesToSummary) {
              final equip = summary.itemCount == 0
                  ? 'No items equipped'
                  : '${summary.itemCount} equipped items';
              final units =
                  '${summary.perUnit.length} units in summary · ${summary.specStarsUsed}/10 spec stars';
              return '$equip · $units';
            }
            if (summary.itemCount == 0) {
              return 'No items equipped for this race';
            }
            return '${summary.itemCount} equipped items · '
                '${summary.perUnit.length} units affected';
          }(),
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: List.generate(_BuildSummaryViewTab.values.length, (i) {
                final tab = _BuildSummaryViewTab.values[i];
                final sel = summaryViewTab == tab;
                return Expanded(
                  child: Material(
                    color:
                        sel ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                    child: InkWell(
                      onTap: () => onSummaryViewTabChanged(tab),
                      splashColor: Colors.black12,
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            right: i < _BuildSummaryViewTab.values.length - 1
                                ? const BorderSide(color: Color(0xFFE2E8F0))
                                : BorderSide.none,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _tabLabels[i],
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight:
                                  sel ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                              color: sel
                                  ? const Color(0xFF4338CA)
                                  : const Color(0xFF64748B),
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

    Widget unitSection() {
      final visible = summary.perUnit
          .where((u) => _summaryDisplayTotals(u, summaryViewTab).isNotEmpty)
          .toList();

      if (visible.isEmpty) {
        final msg = switch (summaryViewTab) {
          _BuildSummaryViewTab.all =>
            'Nothing to show. Equip items or assign specialization (Humans).',
          _BuildSummaryViewTab.items =>
            'No numeric bonuses from items for the units in this summary.',
          _BuildSummaryViewTab.skills => summary.specAppliesToSummary
              ? 'No numeric bonuses from the specialization tree.'
              : 'The specialization tree is not included in the summary for this race yet.',
        };
        return Text(
          msg,
          style: TextStyle(
              color: Colors.grey.shade600, fontSize: 13, height: 1.35),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _UnitTotalsCard(
              unit: visible[i],
              displayTotals: _summaryDisplayTotals(visible[i], summaryViewTab),
              percentByAttrKey:
                  _summaryPercentFlags(visible[i], summaryViewTab),
              infoTooltip: _summaryInfoTooltip(summaryViewTab),
              formatAttrDisplay: formatAttrDisplay,
              accent: summaryHud.summaryUnitCardAccent,
              gradientEndAlpha: summaryHud.summaryUnitCardGradientEndAlpha,
              stripeRaceLabel: selectedRace,
              onInfoTap: () => _showUnitStatSourcesSheet(
                context,
                unit: visible[i],
                tab: summaryViewTab,
                raceLabel: selectedRace,
                formatAttrDisplay: formatAttrDisplay,
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
                    children: [unitSection()],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                unitSection(),
              ],
            ),
    );
  }
}

/// Estrellas de rango en el sheet de fuentes (fondo claro).
class _SheetSpecRankStars extends StatelessWidget {
  const _SheetSpecRankStars({
    required this.invested,
    required this.maxRanks,
  });

  final int invested;
  final int maxRanks;

  /// Readable gold on the card’s light gradient.
  static const Color _active = Color(0xFFFBBF24);

  /// Solid slate gray (high contrast); very light gray was lost on the background.
  static const Color _inactive = Color(0xFF57534E);

  @override
  Widget build(BuildContext context) {
    final max = maxRanks.clamp(1, 10);
    final n = invested.clamp(0, max);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < n;
        return Padding(
          padding: EdgeInsets.only(right: i < max - 1 ? 3 : 0),
          child: Icon(
            Icons.star_rounded,
            size: 20,
            color: filled ? _active : _inactive,
            shadows: filled
                ? const [
                    Shadow(
                      color: Color(0x66CA8A04),
                      blurRadius: 5,
                      offset: Offset(0, 0.5),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/// Título del ítem en cards alineado al estilo catálogo ([ExpandableCard]).
Color _statSourceItemTitleAccent(Color rarityColor) {
  final darkness = rarityColor.computeLuminance() > 0.6 ? 0.72 : 0.42;
  return Color.alphaBlend(
    Colors.black.withValues(alpha: darkness),
    rarityColor,
  );
}

String _statSourcesSheetSubtitle(_BuildSummaryViewTab tab) {
  switch (tab) {
    case _BuildSummaryViewTab.all:
      return 'Equipment slots and specialization nodes (current rank) contributing numeric bonuses.';
    case _BuildSummaryViewTab.items:
      return 'Equipment slots contributing numeric bonuses to this unit.';
    case _BuildSummaryViewTab.skills:
      return 'Specialization nodes (current rank) contributing numeric bonuses to this unit.';
  }
}

Widget _buildStatSourceDetailCard({
  required _BuildStatSource c,
  required String sheetRaceLabel,
  required String Function(double value, bool isPercent) formatAttrDisplay,
}) {
  final lines = c.attrs.entries.toList()
    ..sort((a, b) => b.value.value.abs().compareTo(a.value.value.abs()));

  if (c.kind == _BuildStatSourceKind.item) {
    final slotLabel = getSlotValueOrDescription(c.slotKey!);
    final rarityColor = getRarityColor(c.itemRarity!);
    final titleAccent = _statSourceItemTitleAccent(rarityColor);
    final rarityStr =
        c.itemRarity!.isEmpty ? 'unknown' : c.itemRarity!;
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
          color: rarityColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      clipBehavior: Clip.hardEdge,
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
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            ItemCompleteFrame.cornerRadiusFor(62),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: ItemCompleteFrame(
                            slot: c.slotKey!,
                            rarity: rarityStr,
                            lightInteriorFill: Colors.transparent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.itemName!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: titleAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  height: 1.1,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                slotLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (lines.isNotEmpty) ...[
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
                          children: _statValueRowsFromNumeric(
                            lines,
                            formatAttrDisplay,
                          ),
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

  final node = _specTreeNodeForBuilderRace(sheetRaceLabel, c.specRepo!);
  final iconPath = node?.iconAsset;
  final accent = CatalogCardStripe.accentForRaceLabel(sheetRaceLabel);
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: accent.withValues(alpha: 0.12),
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
          CatalogCardStripe.forRaceLabel(sheetRaceLabel),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    accent.withValues(alpha: 0.06),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: iconPath != null
                              ? Image.asset(
                                  iconPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => ColoredBox(
                                    color: const Color(0xFFE2E8F0),
                                    child: Icon(
                                      Icons.auto_graph_rounded,
                                      color: Colors.grey.shade600,
                                      size: 26,
                                    ),
                                  ),
                                )
                              : ColoredBox(
                                  color: const Color(0xFFE2E8F0),
                                  child: Icon(
                                    Icons.auto_graph_rounded,
                                    color: Colors.grey.shade600,
                                    size: 26,
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
                              c.nodeTitle!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF334155),
                              ),
                            ),
                            if (c.specInvestedRanks != null &&
                                c.specMaxRanks != null) ...[
                              const SizedBox(height: 8),
                              _SheetSpecRankStars(
                                invested: c.specInvestedRanks!,
                                maxRanks: c.specMaxRanks!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._statValueRowsFromNumeric(lines, formatAttrDisplay),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

List<Widget> _statValueRowsFromNumeric(
  List<MapEntry<String, NumericAttrValue>> lines,
  String Function(double value, bool isPercent) formatAttrDisplay,
) {
  return lines.asMap().entries.map((me) {
    final e = me.value;
    final v = e.value.value;
    final pct = e.value.isPercent;
    final sign = v >= 0 ? '+' : '';
    final isNeg = v < 0;
    final amtColor = isNeg ? const Color(0xFFC75A5A) : const Color(0xFF2E9B62);
    return Padding(
      padding: EdgeInsets.only(top: me.key == 0 ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$sign${formatAttrDisplay(v, pct)}',
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
  }).toList();
}

void _showUnitStatSourcesSheet(
  BuildContext context, {
  required _PerUnitBuildSummary unit,
  required _BuildSummaryViewTab tab,
  required String raceLabel,
  required String Function(double value, bool isPercent) formatAttrDisplay,
}) {
  final itemBlock =
      tab == _BuildSummaryViewTab.all || tab == _BuildSummaryViewTab.items
          ? unit.itemSources
          : const <_BuildStatSource>[];
  final skillBlock =
      tab == _BuildSummaryViewTab.all || tab == _BuildSummaryViewTab.skills
          ? unit.skillSources
          : const <_BuildStatSource>[];

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
          final children = <Widget>[];
          final showSplitHeaders = tab == _BuildSummaryViewTab.all &&
              itemBlock.isNotEmpty &&
              skillBlock.isNotEmpty;
          if (showSplitHeaders) {
            children.add(
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Equipped items',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            );
          }
          for (final c in itemBlock) {
            children.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildStatSourceDetailCard(
                  c: c,
                  sheetRaceLabel: raceLabel,
                  formatAttrDisplay: formatAttrDisplay,
                ),
              ),
            );
          }
          if (showSplitHeaders) {
            children.add(const SizedBox(height: 8));
            children.add(
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Skill tree',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            );
          }
          for (final c in skillBlock) {
            children.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildStatSourceDetailCard(
                  c: c,
                  sheetRaceLabel: raceLabel,
                  formatAttrDisplay: formatAttrDisplay,
                ),
              ),
            );
          }

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
                  _statSourcesSheetSubtitle(tab),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: children.isEmpty
                      ? Center(
                          child: Text(
                            'No sources for this view.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView(
                          controller: scrollController,
                          children: children,
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
    required this.displayTotals,
    required this.percentByAttrKey,
    required this.infoTooltip,
    required this.formatAttrDisplay,
    required this.accent,
    required this.gradientEndAlpha,
    required this.stripeRaceLabel,
    required this.onInfoTap,
  });

  final _PerUnitBuildSummary unit;
  final Map<String, double> displayTotals;
  final Map<String, bool> percentByAttrKey;
  final String infoTooltip;
  final String Function(double value, bool isPercent) formatAttrDisplay;
  final Color accent;
  final double gradientEndAlpha;
  final String stripeRaceLabel;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final sortedAttrs = displayTotals.entries.toList()
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
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                            ],
                          ),
                        ),
                        Tooltip(
                          message: infoTooltip,
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: onInfoTap,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 22,
                                  color: accent.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (sortedAttrs.isNotEmpty) ...[
                      const SizedBox(height: 8),
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
                            final e = me.value;
                            final v = e.value;
                            final isPct = percentByAttrKey[e.key] ?? false;
                            final sign = v >= 0 ? '+' : '';
                            final isNeg = v < 0;
                            return Padding(
                              padding:
                                  EdgeInsets.only(top: me.key == 0 ? 0 : 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$sign${formatAttrDisplay(v, isPct)}',
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
                                      _builderTotalsAttrDisplayLabel(e.key),
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

enum _BuildStatSourceKind { item, spec }

class _BuildStatSource {
  const _BuildStatSource._({
    required this.kind,
    this.slotKey,
    this.itemName,
    this.itemRarity,
    this.specRepo,
    this.nodeTitle,
    this.specInvestedRanks,
    this.specMaxRanks,
    required this.attrs,
  });

  factory _BuildStatSource.item({
    required String slotKey,
    required String itemName,
    required String itemRarity,
    required Map<String, NumericAttrValue> attrs,
  }) =>
      _BuildStatSource._(
        kind: _BuildStatSourceKind.item,
        slotKey: slotKey,
        itemName: itemName,
        itemRarity: itemRarity,
        attrs: attrs,
      );

  factory _BuildStatSource.spec({
    required String specRepo,
    required String nodeTitle,
    required Map<String, NumericAttrValue> attrs,
    required int specInvestedRanks,
    required int specMaxRanks,
  }) =>
      _BuildStatSource._(
        kind: _BuildStatSourceKind.spec,
        specRepo: specRepo,
        nodeTitle: nodeTitle,
        specInvestedRanks: specInvestedRanks,
        specMaxRanks: specMaxRanks,
        attrs: attrs,
      );

  final _BuildStatSourceKind kind;
  final String? slotKey;
  final String? itemName;
  final String? itemRarity;
  final String? specRepo;
  final String? nodeTitle;
  final int? specInvestedRanks;
  final int? specMaxRanks;
  final Map<String, NumericAttrValue> attrs;
}

class _PercentHintAgg {
  int total = 0;
  int percentCount = 0;

  void add(bool isPercent) {
    total++;
    if (isPercent) {
      percentCount++;
    }
  }

  bool get uniformPercent => total > 0 && percentCount == total;
}

class _UnitSummaryScratch {
  _UnitSummaryScratch(this.unitKey);

  final String unitKey;
  final Map<String, double> totalsItems = {};
  final Map<String, double> totalsSkills = {};
  final Map<String, _PercentHintAgg> itemPercentHints = {};
  final Map<String, _PercentHintAgg> skillPercentHints = {};
  final List<_BuildStatSource> itemSources = [];
  final List<_BuildStatSource> skillSources = [];
}

class _PerUnitBuildSummary {
  const _PerUnitBuildSummary({
    required this.unitKey,
    required this.displayLabel,
    required this.totalsItems,
    required this.totalsSkills,
    required this.totalsAll,
    required this.percentItems,
    required this.percentSkills,
    required this.percentAll,
    required this.itemSources,
    required this.skillSources,
  });

  final String unitKey;
  final String displayLabel;
  final Map<String, double> totalsItems;
  final Map<String, double> totalsSkills;
  final Map<String, double> totalsAll;
  final Map<String, bool> percentItems;
  final Map<String, bool> percentSkills;
  final Map<String, bool> percentAll;
  final List<_BuildStatSource> itemSources;
  final List<_BuildStatSource> skillSources;
}

class _BuildSummary {
  const _BuildSummary({
    required this.itemCount,
    required this.perUnit,
    this.specStarsUsed = 0,
    this.specAppliesToSummary = false,
  });

  final int itemCount;
  final List<_PerUnitBuildSummary> perUnit;
  final int specStarsUsed;
  final bool specAppliesToSummary;
}
