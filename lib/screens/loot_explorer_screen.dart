import 'package:flutter/material.dart';
import 'package:worldshift_assistant/data/loot_drop_models.dart';
import 'package:worldshift_assistant/data/loot_drop_repository.dart';
import 'package:worldshift_assistant/widgets/catalog_filter_widgets.dart';

class LootExplorerScreen extends StatefulWidget {
  const LootExplorerScreen({super.key});

  @override
  State<LootExplorerScreen> createState() => _LootExplorerScreenState();
}

class _LootExplorerScreenState extends State<LootExplorerScreen>
    with SingleTickerProviderStateMixin {
  Future<LootDropRepository>? _repoFuture;
  final _itemSearch = TextEditingController();
  late final TabController _tabController;
  bool _itemSearchFiltersOpen = false;

  @override
  void initState() {
    super.initState();
    _repoFuture = LootDropRepository.loadFromAssets();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {
      if (_tabController.index != 1) {
        _itemSearchFiltersOpen = false;
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _itemSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSearchTab = _tabController.index == 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CatalogListAppBar(
        title: 'Loot & tables',
        centerTitle: true,
        actions: onSearchTab
            ? [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _itemSearchFiltersOpen ? Icons.close : Icons.tune,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _itemSearchFiltersOpen = !_itemSearchFiltersOpen;
                      });
                    },
                  ),
                ),
              ]
            : null,
      ),
      body: FutureBuilder<LootDropRepository>(
        future: _repoFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final repo = snap.data!;

          return Column(
            children: [
              Material(
                color: const Color(0xFF764ba2),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Encounters (drop.tsv)'),
                    Tab(text: 'Find item'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _EncountersTab(repo: repo),
                    _ItemSearchTab(
                      repo: repo,
                      controller: _itemSearch,
                      filtersVisible: _itemSearchFiltersOpen,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EncountersTab extends StatelessWidget {
  const _EncountersTab({required this.repo});

  final LootDropRepository repo;

  @override
  Widget build(BuildContext context) {
    final roots = repo.uniqueRootEncounters;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: roots.length,
      itemBuilder: (context, i) {
        final d = roots[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(d.fromLabel),
            subtitle: Text('Table ${d.fromId}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _EncounterDetailPage(repo: repo, root: d),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EncounterDetailPage extends StatelessWidget {
  const _EncounterDetailPage({required this.repo, required this.root});

  final LootDropRepository repo;
  final DropTableRow root;

  @override
  Widget build(BuildContext context) {
    final children = repo.childrenOf(root.fromId);
    final items = repo.itemsOnTable(root.fromId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CatalogListAppBar(
        title: root.fromLabel,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Table ${root.fromId}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Sub-tables (drop.tsv)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (children.isEmpty)
            Text(
              'Sin enlaces salientes.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...children.map(
              (c) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('→ ${c.toLabel}'),
                subtitle: Text(
                  'Table ${c.toId}${c.weightOrChance != null ? ' · ${c.weightOrChance}' : ''}',
                ),
              ),
            ),
          const Divider(height: 32),
          Text(
            'Items on loot (table ${root.fromId})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (items.isEmpty)
            Text(
              'No loot rows for this table (may delegate only to sub-tables).',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...items.map(
              (r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(r.itemName),
                subtitle: Text('${r.itemId} · ${r.locationLabel}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemSearchTab extends StatelessWidget {
  const _ItemSearchTab({
    required this.repo,
    required this.controller,
    required this.filtersVisible,
    required this.onChanged,
  });

  final LootDropRepository repo;
  final TextEditingController controller;
  final bool filtersVisible;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final results = repo.searchItemsByName(controller.text);
    final limited = results.length > 200 ? results.sublist(0, 200) : results;
    final queryEmpty = controller.text.trim().isEmpty;

    return Column(
      children: [
        if (filtersVisible) ...[
          CatalogFilterPanel(
            maxHeight: queryEmpty && results.length <= 200 ? 140 : 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CatalogSearchBar(
                  controller: controller,
                  hintText: 'Item name…',
                  onChanged: (_) => onChanged(),
                ),
                if (results.length > 200) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Showing 200 of ${results.length} matches.',
                    style:
                        TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: limited.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      queryEmpty
                          ? 'Tap the filter icon (top right) to search by item name.'
                          : 'No matches for that search.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: limited.length,
                  itemBuilder: (context, i) {
                    final r = limited[i];
                    final tables = repo.tablesContainingItem(r.itemId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(r.itemName),
                        subtitle: Text('ID ${r.itemId}'),
                        children: [
                          if (tables.isEmpty)
                            const ListTile(
                              title: Text('No indexed tables'),
                            )
                          else
                            ...tables.map(
                              (tid) => ListTile(
                                dense: true,
                                title: Text('Table $tid'),
                                subtitle: Text(
                                  repo
                                      .itemsOnTable(tid)
                                      .firstWhere(
                                        (x) => x.itemId == r.itemId,
                                        orElse: () => r,
                                      )
                                      .locationLabel,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
