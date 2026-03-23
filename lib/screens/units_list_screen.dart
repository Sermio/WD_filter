import 'package:flutter/material.dart';
import 'package:worldshift_assistant/screens/unit_detail_screen.dart';
import 'package:worldshift_assistant/services/units_catalog.dart';

class UnitsListScreen extends StatefulWidget {
  const UnitsListScreen({super.key});

  @override
  State<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends State<UnitsListScreen> {
  Future<UnitsCatalog>? _catalogFuture;
  String _raceFilter = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _catalogFuture = UnitsCatalog.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UnitsCatalog>(
        future: _catalogFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar el catálogo de unidades.\n'
                  'Ejecuta: dart run tool/generate_worldshift_assets.dart\n'
                  '${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final catalog = snap.data!;
          final filtered = catalog.filter(
            raceFolder: _raceFilter.isEmpty ? null : _raceFilter,
            search: _search.text,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o id…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todas'),
                      selected: _raceFilter.isEmpty,
                      onSelected: (_) =>
                          setState(() => _raceFilter = ''),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Humans'),
                      selected: _raceFilter == 'humans',
                      onSelected: (_) =>
                          setState(() => _raceFilter = 'humans'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Tribes'),
                      selected: _raceFilter == 'mutants',
                      onSelected: (_) =>
                          setState(() => _raceFilter = 'mutants'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Aliens'),
                      selected: _raceFilter == 'aliens',
                      onSelected: (_) =>
                          setState(() => _raceFilter = 'aliens'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final u = filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(u.displayName ?? u.id),
                        subtitle: Text(
                          '${u.raceLabel} · ${u.id}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => UnitDetailScreen(unit: u),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
