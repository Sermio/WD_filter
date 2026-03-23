import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:worldshift_assistant/data/itemList.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/data/item.dart';
import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:provider/provider.dart';
import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/catalog_filter_widgets.dart';
import 'package:worldshift_assistant/widgets/expandable_card.dart';
import 'package:worldshift_assistant/widgets/multi_chip.dart';
import 'package:worldshift_assistant/widgets/rarity_indicator.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  late Future<List<Item>> _itemsFuture;
  bool _isFilterVisible = false;
  final Map<int, Set<String>> _resolvedMapNamesByItem = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _attributeController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchItems();
    _nameController.text =
        Provider.of<FilterProvider>(context, listen: false).nameFilter;
    _attributeController.text =
        Provider.of<FilterProvider>(context, listen: false).attributeFilter;
    final initialUnitFilter =
        Provider.of<FilterProvider>(context, listen: false).unitFilter;
    _unitController.text =
        initialUnitFilter.isEmpty ? '' : _formatUnitLabel(initialUnitFilter);
  }

  // Unidades por raza para filtrar sugerencias de "Unit"
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

  List<String> _getUnitsByRaces(List<String> selectedRaces) {
    if (selectedRaces.isEmpty) {
      return units
          .map((u) => u['key'] ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final Set<String> result = {};
    for (final race in selectedRaces) {
      final items = _raceToUnits[race];
      if (items != null) {
        result.addAll(items);
      }
    }
    return result.toList();
  }

  String _formatUnitLabel(String unitKey) {
    final rawLabel = getUnitValue(unitKey).replaceAll('_', ' ').trim();
    return rawLabel.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
  }

  String _normalizeFilterValue(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toLowerCase();
  }

  List<String> _buildUnitIconCandidates(String unitKey) {
    const aliasByUnitKey = <String, List<String>>{
      'Engineer': ['technician2'],
      'Psychic': ['eji2'],
      'Commander': ['commander', 'lancelot'],
      'HighPriest': ['highpriest'],
      'Defiler': ['dave', 'defiler'],
    };

    final normalized =
        unitKey.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toLowerCase();
    final aliases = <String>[
      ...?aliasByUnitKey[unitKey],
      normalized,
    ];
    final seen = <String>{};
    final candidates = <String>[];

    for (final id in aliases) {
      if (!seen.add(id) || id.isEmpty) {
        continue;
      }
      candidates.add('assets/generated/unit_icons/named/units/$id.png');
      candidates.add('assets/generated/unit_icons/named/officers/$id.png');
    }

    return candidates;
  }

  String _slotIconPath(String slotKey) =>
      'assets/generated/item_icons/named/icons/$slotKey.png';

  List<String> _buildSlotIconCandidates(String slotKey) {
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
      ..._buildUnitIconCandidates(unitKey),
      _slotIconPath(slotKey),
    ];
  }

  List<Map<String, String>> _getSlotsByRaces(List<String> selectedRaces) {
    if (selectedRaces.isEmpty) {
      return slots;
    }
    final List<Map<String, String>> filtered = [];
    final bool includeHumans = selectedRaces.contains('Humans');
    final bool includeTribes = selectedRaces.contains('Tribes');
    final bool includeAliens = selectedRaces.contains('Aliens');
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

  Future<List<Item>> _fetchItems() async {
    await _loadResolvedMapNamesByItem();
    final items = await combineLootData(
      WorldshiftAssets.lootTableFile,
      WorldshiftAssets.itemsDefinitionFile,
    );
    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }

  Future<void> _loadResolvedMapNamesByItem() async {
    _resolvedMapNamesByItem.clear();
    final raw =
        await rootBundle.loadString(WorldshiftAssets.itemOriginIndexFile);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final items = decoded['items'];
    if (items is! List) {
      return;
    }

    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final itemId = item['id'];
      final resolvedOrigins = item['resolvedOrigins'];
      if (itemId is! int || resolvedOrigins is! List) {
        continue;
      }

      final mapNames = <String>{};
      for (final origin in resolvedOrigins) {
        if (origin is! Map<String, dynamic>) {
          continue;
        }
        final mapName = '${origin['mapName'] ?? ''}'.trim();
        if (mapName.isNotEmpty) {
          mapNames.add(mapName);
        }
      }
      if (mapNames.isNotEmpty) {
        _resolvedMapNamesByItem[itemId] = mapNames;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.refresh),
      //   onPressed: () async {
      //     await _uploadItems(context);
      //   },
      // ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Center(
          child: Text(
            'WorldShift Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667eea),
                const Color(0xFF764ba2),
                const Color(0xFFf093fb),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            image: const DecorationImage(
              image: AssetImage('assets/images/banner.png'),
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isFilterVisible ? Icons.close : Icons.tune,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _isFilterVisible = !_isFilterVisible;
                });
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: FutureBuilder<List<Item>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final items = snapshot.data ?? const <Item>[];
            return Consumer<FilterProvider>(
              builder: (context, filterProvider, _) {
                _attributeController.text = filterProvider.attributeFilter;
                _unitController.text = filterProvider.unitFilter.isEmpty
                    ? ''
                    : _formatUnitLabel(filterProvider.unitFilter);
                final filteredItems = _filterItems(items, filterProvider);
                return Column(
                  children: [
            if (_isFilterVisible)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                            controller: _nameController,
                            hintText: 'Search item by name…',
                            onChanged: (text) {
                              filterProvider.setNameFilter(text);
                              setState(() {});
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
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TypeAheadField<String>(
                              controller: _attributeController,
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
                                    suffixIcon:
                                        _attributeController.text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color: Colors.grey.shade600,
                                                ),
                                                onPressed: () {
                                                  filterProvider
                                                      .resetAttributeFilter();
                                                  _attributeController.clear();
                                                },
                                              )
                                            : null,
                                  ),
                                );
                              },
                              suggestionsCallback: (pattern) async {
                                // Capitalizar la primera letra de cada palabra y manejar múltiples palabras
                                String capitalizedPattern =
                                    capitalizeFirstLetterOfEachWord(pattern);
                                return getSuggestions(
                                    capitalizedPattern, 'attribute');
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
                                filterProvider.setAttributeFilter(
                                    suggestion.toLowerCase());
                                _attributeController.text = suggestion;
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
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Consumer<FilterProvider>(
                              builder: (context, fp, _) =>
                                  TypeAheadField<String>(
                                key: ValueKey(fp.selectedRaces.join(',')),
                                controller: _unitController,
                                constraints:
                                    const BoxConstraints(maxHeight: 260),
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
                                      prefixIcon: _unitController.text.isEmpty
                                          ? Icon(
                                              Icons.category,
                                              color: Colors.grey.shade600,
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: _ResolvedAssetBadge(
                                                candidates:
                                                    _buildUnitIconCandidates(
                                                  fp.unitFilter,
                                                ),
                                                size: 22,
                                                borderRadius: 6,
                                                fallbackIcon:
                                                    Icons.shield_outlined,
                                              ),
                                            ),
                                      suffixIcon:
                                          _unitController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  onPressed: () {
                                                    filterProvider
                                                        .resetUnitFilter();
                                                    _unitController.clear();
                                                  },
                                                )
                                              : null,
                                    ),
                                  );
                                },
                                suggestionsCallback: (pattern) async {
                                  final candidates =
                                      _getUnitsByRaces(fp.selectedRaces);
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
                                      leading: _ResolvedAssetBadge(
                                        candidates: _buildUnitIconCandidates(
                                            suggestion),
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
                                  _unitController.text =
                                      _formatUnitLabel(suggestion);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          MultiSelectChip(
                            labels: races,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                      value:
                                          Provider.of<FilterProvider>(context)
                                              .selectedMap,
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
                                        Provider.of<FilterProvider>(context,
                                                listen: false)
                                            .setSelectedMap(newValue);
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
                                        ...maps.map((map) =>
                                            DropdownMenuItem<String>(
                                              value: map['value'],
                                              child: Text(
                                                map['value']!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                      value:
                                          Provider.of<FilterProvider>(context)
                                              .selectedSlot,
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
                                        Provider.of<FilterProvider>(context,
                                                listen: false)
                                            .setSelectedSlot(newValue);
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
                                        ..._getSlotsByRaces(
                                                Provider.of<FilterProvider>(
                                                        context)
                                                    .selectedRaces)
                                            .map((slot) =>
                                                DropdownMenuItem<String>(
                                                  value: slot['key'],
                                                  child: Row(
                                                    children: [
                                                      _ResolvedAssetBadge(
                                                        candidates:
                                                            _buildSlotIconCandidates(
                                                          slot['key']!,
                                                        ),
                                                        size: 24,
                                                        borderRadius: 6,
                                                        fallbackIcon: Icons
                                                            .inventory_2_outlined,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          slot['value']!,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                      value:
                                          Provider.of<FilterProvider>(context)
                                              .selectedRarity,
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
                                        ...['1', '2', '3', '4', '5']
                                            .map((rarity) {
                                          return DropdownMenuItem<String>(
                                            value: rarity,
                                            child:
                                                RarityIndicator(rarity: rarity),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) {
                                        Provider.of<FilterProvider>(context,
                                                listen: false)
                                            .setSelectedRarity(value);
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
                                    Provider.of<FilterProvider>(context,
                                            listen: false)
                                        .clearFilters();
                                    _nameController.clear();
                                    _attributeController.clear();
                                    _unitController.clear();
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              '${filteredItems.length} items',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                    ),
                  ],
                ),
              ),
            if (_isFilterVisible) const Divider(),
            Expanded(
              child: filteredItems.isEmpty
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
                                  'No items match these filters',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF313846),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try changing rarity, slot, or map to broaden results.',
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
                          padding: const EdgeInsets.only(
                            top: 10,
                            bottom: 20,
                          ),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final itemData = item.toMap();
                            final name = item.name;
                            final rarity =
                                item.rarity.isEmpty ? 'unknown' : item.rarity;

                            return ExpandableCard(
                              name: name,
                              map: item.map,
                              rarity: rarity,
                              obtainedFrom: item.obtainedFrom,
                              itemData: itemData,
                            );
                          },
                        ),
            ),
          ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _attributeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  List<Item> _filterItems(List<Item> items, FilterProvider filterProvider) {
    return items.where((item) {
      final itemData = item.toMap();
      final name = item.name;
      final rarity = item.rarity;
      return _matchesFilters(itemData, name, rarity, filterProvider);
    }).toList();
  }

  // Método optimizado para verificar filtros
  bool _matchesFilters(Map<String, dynamic> itemData, String name,
      String rarity, FilterProvider filterProvider) {
    // Filtro por nombre
    if (filterProvider.nameFilter.isNotEmpty &&
        !name.toLowerCase().contains(filterProvider.nameFilter.toLowerCase())) {
      return false;
    }

    // Filtro por atributo
    if (filterProvider.attributeFilter.isNotEmpty) {
      final attributes = itemData['attributes'];
      if (attributes is Map) {
        final hasAttribute = attributes.values.any((unitMap) {
          if (unitMap is Map<String, dynamic>) {
            return unitMap.keys.any((attributeKey) {
              final filterValue = filterProvider.attributeFilter.toLowerCase();
              final attributeMatch = attributeList.firstWhere(
                (attribute) => attribute['value']?.toLowerCase() == filterValue,
                orElse: () => <String, String>{},
              );
              return attributeMatch.isNotEmpty &&
                  attributeMatch['key']?.toLowerCase() ==
                      attributeKey.toLowerCase();
            });
          }
          return false;
        });
        if (!hasAttribute) return false;
      }
    }

    // Filtro por unidad
    if (filterProvider.unitFilter.isNotEmpty) {
      final normalizedAttributes =
          _normalizeFilterValue(itemData['attributes'].toString());
      final normalizedUnitFilter =
          _normalizeFilterValue(filterProvider.unitFilter);
      if (!normalizedAttributes.contains(normalizedUnitFilter)) {
        return false;
      }
    }

    // Filtro por mapa
    if (filterProvider.selectedMap != null) {
      final selectedMap = filterProvider.selectedMap!;
      final directMap = '${itemData['map'] ?? ''}'.trim();
      final itemId = itemData['id'];
      final resolvedMaps = itemId is int
          ? (_resolvedMapNamesByItem[itemId] ?? const <String>{})
          : const <String>{};
      if (directMap != selectedMap && !resolvedMaps.contains(selectedMap)) {
        return false;
      }
    }

    // Filtro por raza
    if (filterProvider.selectedRaces.isNotEmpty &&
        !filterProvider.selectedRaces.contains(itemData['race'])) {
      return false;
    }

    // Filtro por slot
    if (filterProvider.selectedSlot != null &&
        itemData['slot'] != filterProvider.selectedSlot) {
      return false;
    }

    // Filtro por rareza
    if (filterProvider.selectedRarity != null &&
        rarity != filterProvider.selectedRarity) {
      return false;
    }

    return true;
  }

  Future<List<String>> getSuggestions(String query, String filterType) async {
    query = query.toLowerCase();
    if (filterType == 'name') {
      return itemList;
    } else if (filterType == 'attribute') {
      return attributeList
          .map((attribute) => attribute['value'] ?? '')
          .where((value) => value.toLowerCase().contains(query))
          .toList();
    } else if (filterType == 'unit') {
      final selectedRaces =
          Provider.of<FilterProvider>(context, listen: false).selectedRaces;
      final candidates = _getUnitsByRaces(selectedRaces);
      return candidates
          .where((value) => value.toLowerCase().contains(query))
          .toList();
    } else {
      return [];
    }
  }
}

class _ResolvedAssetBadge extends StatelessWidget {
  const _ResolvedAssetBadge({
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
