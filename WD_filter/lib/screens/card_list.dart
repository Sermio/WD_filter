import 'package:adv_basics/data/data.dart';
import 'package:adv_basics/models/item_filters_model.dart';
import 'package:adv_basics/utils/utils.dart';
import 'package:adv_basics/widgets/expandable_card.dart';
import 'package:adv_basics/widgets/multi_chip.dart';
import 'package:adv_basics/widgets/rarity_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchItems();
    _nameController.text =
        Provider.of<FilterProvider>(context, listen: false).nameFilter;
    _attributeController.text =
        Provider.of<FilterProvider>(context, listen: false).attributeFilter;
  }

  Future<List<QueryDocumentSnapshot>> _fetchItems() async {
    final snapshot = await FirebaseFirestore.instance.collection('items').get();
    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () async {
          await saveSpritesAsPngs();
        },
      ),
      appBar: AppBar(
        elevation: 10,
        shadowColor: Colors.black,
        // backgroundColor: Colors.blue.shade800,
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
                'assets/images/banner.png', // Asegúrate de que la ruta de la imagen sea correcta
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
                _isFilterVisible = !_isFilterVisible;
                if (!_isFilterVisible) {
                  Provider.of<FilterProvider>(context, listen: false)
                      .clearFilters();
                  _nameController.clear();
                  _attributeController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isFilterVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    onChanged: (value) {
                      Provider.of<FilterProvider>(context, listen: false)
                          .setNameFilter(value.toLowerCase());
                    },
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  TextField(
                    controller: _attributeController,
                    onChanged: (value) {
                      Provider.of<FilterProvider>(context, listen: false)
                          .setAttributeFilter(value.toLowerCase());
                    },
                    decoration: const InputDecoration(labelText: 'Attribute'),
                  ),
                  const SizedBox(
                    height: 20,
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
                      value: Provider.of<FilterProvider>(context).selectedMap,
                      hint: const Text('Select Map'),
                      onChanged: (newValue) {
                        Provider.of<FilterProvider>(context, listen: false)
                            .setSelectedMap(newValue);
                      },
                      items: maps
                          .map((map) => DropdownMenuItem<String>(
                                value: map['value'],
                                child: Text(map['value']!),
                              ))
                          .toList(),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      alignment: Alignment.centerLeft,
                      menuMaxHeight: 300,
                      value: Provider.of<FilterProvider>(context).selectedSlot,
                      hint: const Text('Select Slot'),
                      onChanged: (newValue) {
                        Provider.of<FilterProvider>(context, listen: false)
                            .setSelectedSlot(newValue);
                      },
                      items: slots
                          .map((slot) => DropdownMenuItem<String>(
                                value: slot['key'],
                                child: Text(slot['value']!),
                              ))
                          .toList(),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      alignment: Alignment.centerLeft,
                      menuMaxHeight: 300,
                      hint: const Text('Select Rarity'),
                      value:
                          Provider.of<FilterProvider>(context).selectedRarity,
                      items: ['1', '2', '3', '4', '5'].map((rarity) {
                        return DropdownMenuItem<String>(
                          value: rarity,
                          child: RarityIndicator(rarity: rarity),
                        );
                      }).toList(),
                      onChanged: (value) {
                        Provider.of<FilterProvider>(context, listen: false)
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
                  const Divider()
                ],
              ),
            ),
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
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var itemData = items[index].data() as Map<String, dynamic>;
                    String name = itemData['name'] ?? '';
                    String rarity = itemData['rarity'] ?? 'unknown';
                    if ((Provider.of<FilterProvider>(context).nameFilter.isNotEmpty && !name.toLowerCase().contains(Provider.of<FilterProvider>(context).nameFilter)) ||
                        (Provider.of<FilterProvider>(context)
                                .attributeFilter
                                .isNotEmpty &&
                            !itemData['attributes']
                                .toString()
                                .toLowerCase()
                                .contains(Provider.of<FilterProvider>(context)
                                    .attributeFilter)) ||
                        (Provider.of<FilterProvider>(context).selectedMap != null &&
                            itemData['map'] !=
                                Provider.of<FilterProvider>(context)
                                    .selectedMap) ||
                        (Provider.of<FilterProvider>(context)
                                .selectedRaces
                                .isNotEmpty &&
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
    super.dispose();
  }
}
