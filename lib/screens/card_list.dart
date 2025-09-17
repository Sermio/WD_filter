import 'package:worldshift_filters/data/itemList.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worldshift_filters/data/data.dart';
import 'package:worldshift_filters/models/item_filters_model.dart';
import 'package:worldshift_filters/utils/utils.dart';
import 'package:worldshift_filters/widgets/expandable_card.dart';
import 'package:worldshift_filters/widgets/multi_chip.dart';
import 'package:worldshift_filters/widgets/rarity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  _CardListScreenState createState() => _CardListScreenState();
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

  Future<List<QueryDocumentSnapshot>> _fetchItems() async {
    final snapshot = await FirebaseFirestore.instance.collection('items').get();
    return snapshot.docs;
  }

  Future<void> _uploadItems(BuildContext context) async {
    try {
      await processAndUploadItems(
        'assets/tsvFiles/loot_complete.txt',
        'assets/tsvFiles/items_extra_data_complete.txt',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos subidos correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
            'WorldShift Items',
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
                          child: TypeAheadField<String>(
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
                              return getSuggestions(pattern, 'unit');
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
                                  .setUnitFilter(suggestion.toLowerCase());
                              _unitController.text = suggestion;
                            },
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
                                      ...slots.map(
                                          (slot) => DropdownMenuItem<String>(
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
                return Padding(
                  padding: const EdgeInsets.only(top: 15),
<<<<<<< HEAD
                  child: ListView.builder(
                    itemCount: items.length,
=======
                  child: ListView.separated(
                    itemCount: filteredItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
>>>>>>> 68f8aa2 (updated styles)
                    itemBuilder: (context, index) {
                      var itemData =
                          items[index].data() as Map<String, dynamic>;
                      String name = itemData['name'] ?? '';
                      String rarity = itemData['rarity'] ?? 'unknown';

                      if ((Provider.of<FilterProvider>(context).nameFilter.isNotEmpty &&
                              !name.toLowerCase().contains(
                                  Provider.of<FilterProvider>(context)
                                      .nameFilter)) ||
                          (Provider.of<FilterProvider>(context)
                                  .attributeFilter
                                  .isNotEmpty &&
                              !itemData['attributes'].values.any((unitMap) {
                                // Verificar que 'unitMap' es un Map
                                if (unitMap is Map<String, dynamic>) {
                                  return unitMap.keys.any((attributeKey) {
                                    // Buscamos el 'key' correspondiente al 'value' del filtro
                                    var filterValue =
                                        Provider.of<FilterProvider>(context)
                                            .attributeFilter
                                            .toLowerCase();
                                    var attributeMatch = attributeList.firstWhere(
                                        (attribute) =>
                                            attribute['value']?.toLowerCase() ==
                                            filterValue,
                                        orElse: () =>
                                            {}); // Si no encontramos coincidencia, devolvemos un mapa vacío

                                    return attributeMatch.isNotEmpty &&
                                        attributeMatch['key']?.toLowerCase() ==
                                            attributeKey.toLowerCase();
                                  });
                                }
                                return false;
                              })) ||
                          (Provider.of<FilterProvider>(context).unitFilter.isNotEmpty &&
                              !itemData['attributes']
                                  .toString()
                                  .toLowerCase()
                                  .contains(Provider.of<FilterProvider>(context)
                                      .unitFilter)) ||
                          (Provider.of<FilterProvider>(context).selectedMap != null &&
                              itemData['map'] !=
                                  Provider.of<FilterProvider>(context)
                                      .selectedMap) ||
                          (Provider.of<FilterProvider>(context).selectedRaces.isNotEmpty &&
                              !Provider.of<FilterProvider>(context)
                                  .selectedRaces
                                  .contains(itemData['race'])) ||
                          (Provider.of<FilterProvider>(context).selectedSlot != null &&
                              itemData['slot'] !=
                                  Provider.of<FilterProvider>(context)
                                      .selectedSlot) ||
                          (Provider.of<FilterProvider>(context).selectedRarity != null &&
                              rarity != Provider.of<FilterProvider>(context).selectedRarity)) {
                        return const SizedBox();
                      }

                      return ExpandableCard(
                        name: name,
                        map: itemData['map'] ?? '',
                        rarity: rarity,
                        obtainedFrom: itemData['obtainedFrom'],
                        itemData: itemData,
                      );
                    },
                  ),
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

  Future<List<String>> getSuggestions(String query, String filterType) async {
    query = query.toLowerCase();
    if (filterType == 'name') {
      return itemList;
    } else if (filterType == 'attribute') {
      query = query.toLowerCase();
      return attributeList
          .map((attribute) => attribute['value'] ?? '')
          .where((value) => value.toLowerCase().contains(query))
          .toList();
    } else if (filterType == 'unit') {
      return units
          .map((unit) => unit['value'] ?? '')
          .where((value) => value.toLowerCase().contains(query))
          .toList();
    } else {
      return [];
    }
  }
}
