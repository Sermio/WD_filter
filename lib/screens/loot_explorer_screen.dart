import 'package:flutter/material.dart';
import 'package:worldshift_assistant/data/loot_drop_models.dart';
import 'package:worldshift_assistant/data/loot_drop_repository.dart';

class LootExplorerScreen extends StatefulWidget {
  const LootExplorerScreen({super.key});

  @override
  State<LootExplorerScreen> createState() => _LootExplorerScreenState();
}

class _LootExplorerScreenState extends State<LootExplorerScreen> {
  Future<LootDropRepository>? _repoFuture;
  final _itemSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repoFuture = LootDropRepository.loadFromAssets();
  }

  @override
  void dispose() {
    _itemSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loot y mesas'),
        backgroundColor: const Color(0xFF764ba2),
        foregroundColor: Colors.white,
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

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Encuentros (drop.tsv)'),
                    Tab(text: 'Buscar ítem'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _EncountersTab(repo: repo),
                      _ItemSearchTab(
                        repo: repo,
                        controller: _itemSearch,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            subtitle: Text('Mesa ${d.fromId}'),
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
      appBar: AppBar(
        title: Text(root.fromLabel),
        backgroundColor: const Color(0xFF764ba2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Mesa ${root.fromId}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Sub-tablas (drop.tsv)',
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
                  'Mesa ${c.toId}${c.weightOrChance != null ? ' · ${c.weightOrChance}' : ''}',
                ),
              ),
            ),
          const Divider(height: 32),
          Text(
            'Ítems en loot (mesa ${root.fromId})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (items.isEmpty)
            Text(
              'Ninguna fila en loot para esta mesa (puede delegar solo en sub-tablas).',
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
    required this.onChanged,
  });

  final LootDropRepository repo;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final results = repo.searchItemsByName(controller.text);
    final limited = results.length > 200 ? results.sublist(0, 200) : results;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Nombre de ítem…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
        if (results.length > 200)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Mostrando 200 de ${results.length} coincidencias.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
        Expanded(
          child: ListView.builder(
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
                        title: Text('Sin mesas indexadas'),
                      )
                    else
                      ...tables.map(
                        (tid) => ListTile(
                          dense: true,
                          title: Text('Mesa $tid'),
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
