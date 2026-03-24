import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/models/game_unit.dart';
import 'package:worldshift_assistant/screens/unit_detail_screen.dart';
import 'package:worldshift_assistant/services/units_catalog.dart';
import 'package:worldshift_assistant/utils/catalog_card_stripe.dart';
import 'package:worldshift_assistant/widgets/catalog_filter_widgets.dart';

class UnitsListScreen extends StatefulWidget {
  const UnitsListScreen({super.key});

  @override
  State<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends State<UnitsListScreen> {
  Future<UnitsCatalog>? _catalogFuture;
  bool _isFilterVisible = false;
  final _search = TextEditingController();
  /// Humans, Tribes, Aliens, Bosses (vacío = todo el catálogo).
  List<String> _selectedRaceLabels = [];

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

  void _clearFilters() {
    _search.clear();
    setState(() => _selectedRaceLabels = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CatalogListAppBar(
        title: 'Units',
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isFilterVisible ? Icons.close : Icons.tune,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                setState(() => _isFilterVisible = !_isFilterVisible);
              },
            ),
          ),
        ],
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
                  'Could not load units catalog.\n'
                  'Run: dart run tool/generate_worldshift_assets.dart\n'
                  'and: dart run tool/extract_units_70_atlas.dart\n'
                  'and: dart run tool/generate_unit_icon_lookup.dart\n'
                  '${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final catalog = snap.data!;
          final folders =
              RaceFilterToggleButtons.raceFoldersFromLabels(_selectedRaceLabels);
          final filtered = catalog.filter(
            raceFolders: folders.isEmpty ? null : folders,
            search: _search.text,
          );

          return Column(
            children: [
              if (_isFilterVisible) ...[
                CatalogFilterPanel(
                  maxHeight: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CatalogSearchBar(
                        controller: _search,
                        hintText: 'Search by name or id…',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      RaceFilterToggleButtons(
                        selectedRaces: _selectedRaceLabels,
                        onChanged: (v) =>
                            setState(() => _selectedRaceLabels = v),
                        includeBosses: true,
                      ),
                      const SizedBox(height: 10),
                      CatalogClearFiltersButton(onPressed: _clearFilters),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          '${filtered.length} ${filtered.length == 1 ? 'unit' : 'units'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final u = filtered[i];
                    return _UnitPreviewCard(
                      unit: u,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => UnitDetailScreen(unit: u),
                          ),
                        );
                      },
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

class _UnitPreviewCard extends StatelessWidget {
  const _UnitPreviewCard({
    required this.unit,
    required this.onTap,
  });

  final GameUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statsCount = unit.stats.length;
    final primaryStats = _selectPrimaryStats(unit.stats);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CatalogCardStripe.forRaceLabel(unit.raceLabel),
            Expanded(
              child: Material(
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _ResolvedUnitAssetImage(
                        candidates: unit.detailIconAssetCandidates,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.displayName ?? unit.id,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _UnitInfoChip(
                              label: unit.raceLabel,
                              icon: Icons.public,
                            ),
                            _UnitInfoChip(
                              label: _formatIconClass(unit.unitIconClass),
                              icon: Icons.badge_outlined,
                            ),
                            if (unit.movementType != null)
                              _UnitInfoChip(
                                label: unit.movementType!,
                                icon: Icons.directions_run,
                              ),
                            _UnitInfoChip(
                              label: '$statsCount stats',
                              icon: Icons.auto_awesome_motion_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
              if (primaryStats.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: primaryStats
                      .map(
                        (entry) => _StatBadge(
                          label: _statLabel(entry.key),
                          value: entry.value,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statLabel(String key) {
    for (final m in attributeList) {
      if (m['key'] == key) {
        return m['value'] ?? key;
      }
    }
    return key.replaceAll('_', ' ');
  }

  static List<MapEntry<String, String>> _selectPrimaryStats(
    Map<String, String> stats,
  ) {
    final selected = <MapEntry<String, String>>[];
    final seen = <String>{};
    const preferredGroups = [
      ['damage'],
      ['hit_points', 'hp'],
      ['armor'],
    ];

    for (final group in preferredGroups) {
      for (final key in group) {
        final value = stats[key];
        if (value != null && seen.add(key)) {
          selected.add(MapEntry(key, value));
          break;
        }
      }
    }

    for (final entry in stats.entries) {
      if (selected.length >= 3) {
        break;
      }
      if (seen.add(entry.key)) {
        selected.add(entry);
      }
    }

    return selected;
  }

  static String _formatIconClass(String value) {
    switch (value) {
      case 'officer':
        return 'Officer';
      case 'commander':
        return 'Commander';
      case 'unit':
        return 'Unit';
      default:
        return value;
    }
  }
}

class _UnitInfoChip extends StatelessWidget {
  const _UnitInfoChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7DDFC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF667eea)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4D5FBD),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedUnitAssetImage extends StatelessWidget {
  const _ResolvedUnitAssetImage({required this.candidates});

  final List<String> candidates;

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
          return const CircleAvatar(
            backgroundColor: Color(0xFFF8FAFC),
            child: Icon(
              Icons.person,
              size: 40,
              color: Color(0xFF64748B),
            ),
          );
        }
        return ClipOval(
          child: SizedBox.expand(
            child: Image.asset(
              path,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
