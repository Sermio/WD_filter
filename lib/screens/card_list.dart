import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:worldshift_assistant/data/itemList.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/expandable_card.dart';
import 'package:worldshift_assistant/widgets/multi_chip.dart';
import 'package:worldshift_assistant/widgets/rarity_indicator.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  late Future<List<QueryDocumentSnapshot>> _itemsFuture;
  bool _isFilterVisible = false;

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
    _unitController.text =
        Provider.of<FilterProvider>(context, listen: false).unitFilter;
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
      // Sin filtro por raza: devolver todas las unidades existentes
      return units
          .map((u) => u['value'] ?? '')
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

  Future<List<QueryDocumentSnapshot>> _fetchItems() async {
    final snapshot = await FirebaseFirestore.instance.collection('items').get();
    return snapshot.docs;
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
      body: Column(
        children: [
          if (_isFilterVisible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 280,
              child: Container(
                margin: const EdgeInsets.all(16),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Consumer<FilterProvider>(
                      builder: (context, filterProvider, child) {
                    _nameController.text = filterProvider.nameFilter;
                    _attributeController.text = filterProvider.attributeFilter;
                    _unitController.text = filterProvider.unitFilter;

                    return Column(
                      children: [
                        // TypeAheadField<String>(
                        //   controller: _nameController,
                        //   builder: (context, controller, focusNode) {
                        //     return TextField(
                        //         controller: controller,
                        //         focusNode: focusNode,
                        //         autofocus: false,
                        //         decoration: const InputDecoration(
                        //           border: OutlineInputBorder(),
                        //           labelText: 'Name',
                        //         ));
                        //   },
                        //   // textFieldConfiguration: TextFieldConfiguration(
                        //   //   controller: _nameController,
                        //   //   decoration:
                        //   //       const InputDecoration(labelText: 'Item Name'),
                        //   // ),
                        //   suggestionsCallback: (pattern) async {
                        //     return getSuggestions(pattern, 'name');
                        //   },
                        //   itemBuilder: (context, suggestion) {
                        //     return ListTile(
                        //       title: Text(suggestion),
                        //     );
                        //   },
                        //   onSelected: (suggestion) {
                        //     filterProvider.setNameFilter(suggestion.toLowerCase());
                        //     _nameController.text =
                        //         suggestion; // Sincronizar el valor
                        //   },
                        // ),
                        const SizedBox(height: 12),
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
                              filterProvider
                                  .setAttributeFilter(suggestion.toLowerCase());
                              _attributeController.text = suggestion;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
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
                            builder: (context, fp, _) => TypeAheadField<String>(
                              key: ValueKey(fp.selectedRaces.join(',')),
                              controller: _unitController,
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
                                    prefixIcon: Icon(
                                      Icons.category,
                                      color: Colors.grey.shade600,
                                    ),
                                    suffixIcon: _unitController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.grey.shade600,
                                            ),
                                            onPressed: () {
                                              filterProvider.resetUnitFilter();
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
                                        (v) => v.toLowerCase().contains(lower))
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
                                fp.setUnitFilter(suggestion.toLowerCase());
                                _unitController.text = suggestion;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        MultiSelectChip(
                          labels: races,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
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
                                    value: Provider.of<FilterProvider>(context)
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
                                      ...maps.map(
                                          (map) => DropdownMenuItem<String>(
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
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
                                    value: Provider.of<FilterProvider>(context)
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
                                                child: Text(
                                                  slot['value']!,
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
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
                                    value: Provider.of<FilterProvider>(context)
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
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667eea)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Provider.of<FilterProvider>(context,
                                            listen: false)
                                        .clearFilters();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.clear_all,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Clear Filters',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          if (_isFilterVisible) const Divider(),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? [];
                final filterProvider = Provider.of<FilterProvider>(context);

                // Filtrar la lista antes de mostrarla
                final filteredItems = items.where((item) {
                  final itemData = item.data() as Map<String, dynamic>;
                  final name = itemData['name'] ?? '';
                  final rarity = itemData['rarity'] ?? 'unknown';
                  return _matchesFilters(
                      itemData, name, rarity, filterProvider);
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                  color: Color(0xFF5F6677),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${filteredItems.length} items',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF3F4655),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Vista previa rapida con icono, overlay de rareza y marco original.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredItems.isEmpty
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
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
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
                                      'No hay items con esos filtros',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF313846),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Prueba a cambiar la rareza, el slot o el mapa para ampliar los resultados.',
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
                                top: 4,
                                bottom: 20,
                              ),
                              itemCount: filteredItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final itemData = filteredItems[index].data()
                                    as Map<String, dynamic>;
                                final name = itemData['name'] ?? '';
                                final rarity = itemData['rarity'] ?? 'unknown';

                                return ExpandableCard(
                                  name: name,
                                  map: itemData['map'] ?? '',
                                  rarity: rarity,
                                  obtainedFrom: itemData['obtainedFrom'],
                                  itemData: itemData,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
    if (filterProvider.unitFilter.isNotEmpty &&
        !itemData['attributes']
            .toString()
            .toLowerCase()
            .contains(filterProvider.unitFilter.toLowerCase())) {
      return false;
    }

    // Filtro por mapa
    if (filterProvider.selectedMap != null &&
        itemData['map'] != filterProvider.selectedMap) {
      return false;
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
