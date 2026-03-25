import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:worldshift_assistant/utils/unit_icon_candidates.dart';
import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/catalog_filter_widgets.dart';
import 'package:worldshift_assistant/widgets/multi_chip.dart';
import 'package:worldshift_assistant/widgets/rarity_indicator.dart';

/// Panel de filtros avanzados (mismo bloque que la pantalla de ítems).
class ItemCatalogFiltersPanel extends StatelessWidget {
  const ItemCatalogFiltersPanel({
    super.key,
    required this.nameController,
    required this.attributeController,
    required this.unitController,
    required this.onFiltersChanged,
    this.footer,
    this.maxHeight = 520,
    this.hideSlotDropdown = false,
    /// Oculta el selector de raza y limita unidades/slots sugeridos a esta raza (p. ej. Builder).
    this.lockedRace,
  });

  final TextEditingController nameController;
  final TextEditingController attributeController;
  final TextEditingController unitController;
  final VoidCallback onFiltersChanged;
  final Widget? footer;
  final double maxHeight;

  /// En el picker de equipar un slot concreto no tiene sentido filtrar por otro slot.
  final bool hideSlotDropdown;

  final String? lockedRace;

  List<String> _effectiveRaces(FilterProvider fp) =>
      lockedRace != null ? <String>[lockedRace!] : fp.selectedRaces;

  static const Map<String, List<String>> _raceToUnits = {
    'Humans': [
      'Commander',
      'Assassin',
      'Constructor',
      'Judge',
      'Surgeon',
      'Trooper',
      'Ripper',
      'AssaultBot',
      'Hellfire',
      'Engineer',
      'Defender',
    ],
    'Tribes': [
      'HighPriest',
      'Guardian',
      'Shaman',
      'Sorcerer',
      'StoneGhost',
      'Warrior',
      'Brute',
      'AncientShade',
      'HowlingHorror',
      'Psychic',
      'EliteKaiRider',
    ],
    'Aliens': [
      'Master',
      'Arbiter',
      'Dominator',
      'Harvester',
      'Manipulator',
      'Trisat',
      'Tritech',
      'Shifter',
      'Overseer',
      'Defiler',
      'PsiDetonator',
    ],
  };

  static List<String> _unitsForRaces(List<String> selectedRaces) {
    if (selectedRaces.isEmpty) {
      return units
          .map((u) => u['key'] ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final result = <String>{};
    for (final race in selectedRaces) {
      final list = _raceToUnits[race];
      if (list != null) {
        result.addAll(list);
      }
    }
    return result.toList();
  }

  static List<String> _sortedUnitKeysForRace(String raceLabel) {
    final list = _raceToUnits[raceLabel];
    if (list == null || list.isEmpty) {
      return const [];
    }
    final copy = List<String>.from(list);
    copy.sort(
      (a, b) => _formatUnitLabel(a)
          .toLowerCase()
          .compareTo(_formatUnitLabel(b).toLowerCase()),
    );
    return copy;
  }

  static String _formatUnitLabel(String unitKey) {
    final rawLabel = getUnitValue(unitKey).replaceAll('_', ' ').trim();
    return rawLabel.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  static String _slotIconPath(String slotKey) =>
      'assets/generated/item_icons/named/icons/$slotKey.png';

  static List<String> _slotIconCandidates(String slotKey) {
    const unitBySlotKey = <String, String>{
      'HUMAN_COMMANDER': 'Commander',
      'HUMAN_ASSASSIN': 'Assassin',
      'HUMAN_CONSTRUCTOR': 'Constructor',
      'HUMAN_JUDGE': 'Judge',
      'HUMAN_SURGEON': 'Surgeon',
      'HUMAN_ENGINEER': 'Engineer',
      'ALIEN_MASTER': 'Master',
      'ALIEN_ARBITER': 'Arbiter',
      'ALIEN_DOMINATOR': 'Dominator',
      'ALIEN_HARVESTER': 'Harvester',
      'ALIEN_MANIPULATOR': 'Manipulator',
      'ALIEN_DEFILER': 'Defiler',
      'MUTANT_PSYCHIC': 'Psychic',
      'MUTANT_HIGHPRIEST': 'HighPriest',
      'MUTANT_ADEPT': 'Sorcerer',
      'MUTANT_GUARDIAN': 'Guardian',
      'MUTANT_SHAMAN': 'Shaman',
      'MUTANT_STONEGHOST': 'StoneGhost',
    };

    final unitKey = unitBySlotKey[slotKey];
    if (unitKey == null) {
      return [_slotIconPath(slotKey)];
    }

    return [
      ...unitIconAssetCandidates(unitKey),
      _slotIconPath(slotKey),
    ];
  }

  static List<Map<String, String>> _slotsForRaces(List<String> selectedRaces) {
    if (selectedRaces.isEmpty) {
      return slots;
    }
    final filtered = <Map<String, String>>[];
    final includeHumans = selectedRaces.contains('Humans');
    final includeTribes = selectedRaces.contains('Tribes');
    final includeAliens = selectedRaces.contains('Aliens');
    for (final slot in slots) {
      final key = slot['key'] ?? '';
      if ((includeHumans && key.startsWith('HUMAN_')) ||
          (includeTribes && key.startsWith('MUTANT_')) ||
          (includeAliens && key.startsWith('ALIEN_'))) {
        filtered.add(slot);
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CatalogSearchBar(
                controller: nameController,
                hintText: 'Search item by name…',
                onChanged: (text) {
                  context.read<FilterProvider>().setNameFilter(text);
                  onFiltersChanged();
                },
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TypeAheadField<String>(
                  controller: attributeController,
                  constraints: const BoxConstraints(maxHeight: 260),
                  autoFlipDirection: true,
                  hideOnUnfocus: true,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: false,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFF667eea),
                            width: 2,
                          ),
                        ),
                        labelText: 'Attribute',
                        labelStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                        ),
                        suffixIcon: attributeController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  context
                                      .read<FilterProvider>()
                                      .resetAttributeFilter();
                                  attributeController.clear();
                                  onFiltersChanged();
                                },
                              )
                            : null,
                      ),
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    final capitalizedPattern =
                        capitalizeFirstLetterOfEachWord(pattern);
                    final q = capitalizedPattern.toLowerCase();
                    return attributeList
                        .map((a) => a['value'] ?? '')
                        .where((v) => v.toLowerCase().contains(q))
                        .toList();
                  },
                  itemBuilder: (context, suggestion) {
                    return Material(
                      color: Colors.white,
                      child: ListTile(
                        title: Text(suggestion),
                      ),
                    );
                  },
                  onSelected: (suggestion) {
                    context.read<FilterProvider>().setAttributeFilter(
                          suggestion.toLowerCase(),
                        );
                    attributeController.text = suggestion;
                    onFiltersChanged();
                  },
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: lockedRace != null
                    ? _RaceLockedUnitDropdown(
                        raceLabel: lockedRace!,
                        unitController: unitController,
                        onFiltersChanged: onFiltersChanged,
                      )
                    : Consumer<FilterProvider>(
                        builder: (context, fp, _) => TypeAheadField<String>(
                          key: ValueKey(_effectiveRaces(fp).join(',')),
                          controller: unitController,
                          constraints: const BoxConstraints(maxHeight: 260),
                          autoFlipDirection: true,
                          hideOnUnfocus: true,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: false,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF667eea),
                                    width: 2,
                                  ),
                                ),
                                labelText: 'Unit',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: unitController.text.isEmpty
                                    ? Icon(
                                        Icons.category,
                                        color: Colors.grey.shade600,
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: _CatalogFilterAssetBadge(
                                          candidates: unitIconAssetCandidates(
                                            fp.unitFilter,
                                          ),
                                          size: 22,
                                          borderRadius: 6,
                                          fallbackIcon: Icons.shield_outlined,
                                        ),
                                      ),
                                suffixIcon: unitController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.grey.shade600,
                                        ),
                                        onPressed: () {
                                          context
                                              .read<FilterProvider>()
                                              .resetUnitFilter();
                                          unitController.clear();
                                          onFiltersChanged();
                                        },
                                      )
                                    : null,
                              ),
                            );
                          },
                          suggestionsCallback: (pattern) async {
                            final candidates =
                                _unitsForRaces(_effectiveRaces(fp));
                            final lower = pattern.toLowerCase();
                            return candidates
                                .where(
                                  (v) =>
                                      v.toLowerCase().contains(lower) ||
                                      _formatUnitLabel(v)
                                          .toLowerCase()
                                          .contains(lower),
                                )
                                .toList();
                          },
                          itemBuilder: (context, suggestion) {
                            return Material(
                              color: Colors.white,
                              child: ListTile(
                                leading: _CatalogFilterAssetBadge(
                                  candidates:
                                      unitIconAssetCandidates(suggestion),
                                  size: 28,
                                  borderRadius: 8,
                                  fallbackIcon: Icons.shield_outlined,
                                ),
                                title: Text(_formatUnitLabel(suggestion)),
                              ),
                            );
                          },
                          onSelected: (suggestion) {
                            fp.setUnitFilter(suggestion);
                            unitController.text =
                                _formatUnitLabel(suggestion);
                            onFiltersChanged();
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              if (lockedRace == null) ...[
                MultiSelectChip(
                  labels: races,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.white,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          alignment: Alignment.centerLeft,
                          menuMaxHeight: 300,
                          dropdownColor: Colors.white,
                          value: context.watch<FilterProvider>().selectedMap,
                          hint: Text(
                            'Select Map',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          underline: const SizedBox(),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                          ),
                          onChanged: (newValue) {
                            context.read<FilterProvider>().setSelectedMap(
                                  newValue,
                                );
                            onFiltersChanged();
                          },
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Maps',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ...maps.map(
                              (map) => DropdownMenuItem<String>(
                                value: map['value'],
                                child: Text(
                                  map['value']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!hideSlotDropdown) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.white,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            alignment: Alignment.centerLeft,
                            menuMaxHeight: 300,
                            dropdownColor: Colors.white,
                            value: context.watch<FilterProvider>().selectedSlot,
                            hint: Text(
                              'Select Slot',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600,
                            ),
                            onChanged: (newValue) {
                              context.read<FilterProvider>().setSelectedSlot(
                                    newValue,
                                  );
                              onFiltersChanged();
                            },
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Slots',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              ..._slotsForRaces(
                                _effectiveRaces(
                                  context.watch<FilterProvider>(),
                                ),
                              ).map(
                                (slot) => DropdownMenuItem<String>(
                                  value: slot['key'],
                                  child: Row(
                                    children: [
                                      _CatalogFilterAssetBadge(
                                        candidates: _slotIconCandidates(
                                          slot['key']!,
                                        ),
                                        size: 24,
                                        borderRadius: 6,
                                        fallbackIcon:
                                            Icons.inventory_2_outlined,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          slot['value']!,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.white,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          alignment: Alignment.centerLeft,
                          menuMaxHeight: 300,
                          dropdownColor: Colors.white,
                          hint: Text(
                            'Select Rarity',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: context.watch<FilterProvider>().selectedRarity,
                          underline: const SizedBox(),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Rarities',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ...['1', '2', '3', '4', '5'].map((rarity) {
                              return DropdownMenuItem<String>(
                                value: rarity,
                                child: RarityIndicator(rarity: rarity),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            context.read<FilterProvider>().setSelectedRarity(
                                  value,
                                );
                            onFiltersChanged();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CatalogClearFiltersButton(
                      label: 'Clear Filters',
                      onPressed: () {
                        context.read<FilterProvider>().clearFilters();
                        nameController.clear();
                        attributeController.clear();
                        unitController.clear();
                        onFiltersChanged();
                      },
                    ),
                  ),
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: 6),
                footer!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Desplegable de unidad acotado a [raceLabel] (p. ej. Builder con [ItemCatalogFiltersPanel.lockedRace]).
class _RaceLockedUnitDropdown extends StatelessWidget {
  const _RaceLockedUnitDropdown({
    required this.raceLabel,
    required this.unitController,
    required this.onFiltersChanged,
  });

  final String raceLabel;
  final TextEditingController unitController;
  final VoidCallback onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, fp, _) {
        final keys = ItemCatalogFiltersPanel._sortedUnitKeysForRace(raceLabel);
        final current = fp.unitFilter;
        final value = current.isNotEmpty && keys.contains(current) ? current : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: DropdownButtonFormField<String?>(
            value: value,
            isExpanded: true,
            menuMaxHeight: 280,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF667eea),
                  width: 2,
                ),
              ),
              labelText: 'Unit',
              labelStyle: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              // Sin icono aquí si hay selección: el [DropdownMenuItem.child] ya es Row(badge, texto).
              // Un prefixIcon duplicaría el mismo asset que muestra el ítem cerrado.
              prefixIcon: value == null
                  ? Icon(
                      Icons.category,
                      color: Colors.grey.shade600,
                    )
                  : null,
            ),
            hint: Text(
              'All units',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey.shade600,
            ),
            dropdownColor: Colors.white,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'All units',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ...keys.map(
                (k) => DropdownMenuItem<String?>(
                  value: k,
                  child: Row(
                    children: [
                      _CatalogFilterAssetBadge(
                        candidates: unitIconAssetCandidates(k),
                        size: 24,
                        borderRadius: 6,
                        fallbackIcon: Icons.shield_outlined,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ItemCatalogFiltersPanel._formatUnitLabel(k),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (selected) {
              final provider = context.read<FilterProvider>();
              if (selected == null) {
                provider.resetUnitFilter();
                unitController.clear();
              } else {
                provider.setUnitFilter(selected);
                unitController.text =
                    ItemCatalogFiltersPanel._formatUnitLabel(selected);
              }
              onFiltersChanged();
            },
          ),
        );
      },
    );
  }
}

class _CatalogFilterAssetBadge extends StatelessWidget {
  const _CatalogFilterAssetBadge({
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
              color: const Color(0xFFF2F4F8),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(
              fallbackIcon,
              size: size * 0.6,
              color: const Color(0xFF7A8395),
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
