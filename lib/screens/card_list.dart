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
      backgroundColor: Colors.white,
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.refresh),
      //   onPressed: () async {
      //     await _uploadItems(context);
      //   },
      // ),
      appBar: AppBar(
        elevation: 10,
        shadowColor: Colors.black,
        title: const Center(
          child: Text(
            'Items',
            style: TextStyle(color: Colors.white),
          ),
        ),
        flexibleSpace: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/banner.png',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isFilterVisible ? Icons.close : Icons.filter_list),
            color: Colors.white,
            onPressed: () {
              setState(() {
                // Limpiar los filtros
                // Provider.of<FilterProvider>(context, listen: false)
                //     .clearFilters();

                // _nameController.clear();
                // _attributeController.clear();
                // _unitController.clear(); // Limpiar el filtro de unidades

                // Cambiar visibilidad del filtro
                _isFilterVisible = !_isFilterVisible;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isFilterVisible)
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
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
                        const SizedBox(height: 5),
                        TypeAheadField<String>(
                          controller: _attributeController,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: false,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Attribute',
                                suffixIcon: _attributeController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          filterProvider.resetAttributeFilter();
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
                            return ListTile(
                              title: Text(suggestion),
                            );
                          },
                          onSelected: (suggestion) {
                            filterProvider
                                .setAttributeFilter(suggestion.toLowerCase());
                            _attributeController.text = suggestion;
                          },
                        ),
                        const SizedBox(height: 5),
                        TypeAheadField<String>(
                          controller: _unitController,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: false,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Unit',
                                suffixIcon: _unitController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close),
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
                            return ListTile(
                              title: Text(suggestion),
                            );
                          },
                          onSelected: (suggestion) {
                            filterProvider
                                .setUnitFilter(suggestion.toLowerCase());
                            _unitController.text = suggestion;
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        MultiSelectChip(
                          labels: races,
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            alignment: Alignment.centerLeft,
                            menuMaxHeight: 300,
                            value: Provider.of<FilterProvider>(context)
                                .selectedMap,
                            hint: const Text('Select Map'),
                            onChanged: (newValue) {
                              Provider.of<FilterProvider>(context,
                                      listen: false)
                                  .setSelectedMap(newValue);
                            },
                            items: [
                              const DropdownMenuItem<String>(
                                value:
                                    null, // O usa '' si prefieres una cadena vacía
                                child: Text(
                                    'All Maps'), // Texto para indicar que no hay filtro
                              ),
                              ...maps.map((map) => DropdownMenuItem<String>(
                                    value: map['value'],
                                    child: Text(map['value']!),
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            alignment: Alignment.centerLeft,
                            menuMaxHeight: 300,
                            value: Provider.of<FilterProvider>(context)
                                .selectedSlot,
                            hint: const Text('Select Slot'),
                            onChanged: (newValue) {
                              Provider.of<FilterProvider>(context,
                                      listen: false)
                                  .setSelectedSlot(newValue);
                            },
                            items: [
                              const DropdownMenuItem<String>(
                                value:
                                    null, // O usa '' si prefieres una cadena vacía
                                child: Text(
                                    'All Slots'), // Indica que no se aplica filtro
                              ),
                              ...slots.map((slot) => DropdownMenuItem<String>(
                                    value: slot['key'],
                                    child: Text(slot['value']!),
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            alignment: Alignment.centerLeft,
                            menuMaxHeight: 300,
                            hint: const Text('Select Rarity'),
                            value: Provider.of<FilterProvider>(context)
                                .selectedRarity,
                            items: [
                              const DropdownMenuItem<String>(
                                value:
                                    null, // O usa '' si prefieres una cadena vacía
                                child: Text(
                                    'All Rarities'), // Indica que no se aplica filtro
                              ),
                              ...['1', '2', '3', '4', '5'].map((rarity) {
                                return DropdownMenuItem<String>(
                                  value: rarity,
                                  child: RarityIndicator(rarity: rarity),
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
                        ElevatedButton(
                          onPressed: () {
                            Provider.of<FilterProvider>(context, listen: false)
                                .clearFilters();
                          },
                          child: const Text('Clear Filters'),
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
                  child: ListView.builder(
                    itemCount: items.length,
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
