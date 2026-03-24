import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worldshift_assistant/data/item.dart';
import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:provider/provider.dart';
import 'package:worldshift_assistant/utils/catalog_item_filter.dart';
import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/expandable_card.dart';
import 'package:worldshift_assistant/widgets/item_catalog_filters_panel.dart';

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

  String _formatUnitLabel(String unitKey) {
    final rawLabel = getUnitValue(unitKey).replaceAll('_', ' ').trim();
    return rawLabel.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: ItemCatalogFiltersPanel(
                  nameController: _nameController,
                  attributeController: _attributeController,
                  unitController: _unitController,
                  onFiltersChanged: () => setState(() {}),
                  footer: Center(
                    child: Text(
                      '${filteredItems.length} items',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
    return items
        .where(
          (item) => catalogItemMatchesFilters(
            item: item,
            filterProvider: filterProvider,
            resolvedMapNamesByItem: _resolvedMapNamesByItem,
          ),
        )
        .toList();
  }
}
