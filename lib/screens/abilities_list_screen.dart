import 'package:flutter/material.dart';
import 'package:worldshift_assistant/models/catalog_ability.dart';
import 'package:worldshift_assistant/screens/ability_detail_screen.dart';
import 'package:worldshift_assistant/services/abilities_catalog.dart';
import 'package:worldshift_assistant/services/units_catalog.dart';
import 'package:worldshift_assistant/data/ability_icon_fallbacks.dart';
import 'package:worldshift_assistant/utils/unit_icon_candidates.dart';
import 'package:worldshift_assistant/widgets/ability_icon_preview.dart';
import 'package:worldshift_assistant/widgets/catalog_filter_widgets.dart';
import 'package:worldshift_assistant/widgets/game_description_highlights.dart';
import 'package:worldshift_assistant/widgets/resolved_mini_asset_image.dart';

class AbilitiesListScreen extends StatefulWidget {
  const AbilitiesListScreen({super.key});

  @override
  State<AbilitiesListScreen> createState() => _AbilitiesListScreenState();
}

class _AbilitiesListScreenState extends State<AbilitiesListScreen> {
  Future<({UnitsCatalog units, AbilitiesCatalog abilities})>? _future;
  bool _isFilterVisible = false;
  final _search = TextEditingController();
  List<String> _selectedKinds = [];
  List<String> _selectedRaceLabels = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({UnitsCatalog units, AbilitiesCatalog abilities})> _load() async {
    final units = await UnitsCatalog.load();
    final abilities = AbilitiesCatalog.fromUnits(units.units);
    return (units: units, abilities: abilities);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _selectedKinds = [];
      _selectedRaceLabels = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CatalogListAppBar(
        title: 'Abilities',
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
      body: FutureBuilder<({UnitsCatalog units, AbilitiesCatalog abilities})>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load catalog.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snap.data!;
          final folders =
              RaceFilterToggleButtons.raceFoldersFromLabels(_selectedRaceLabels);
          final filtered = data.abilities.filter(
            kinds: _selectedKinds,
            raceFolders: folders.isEmpty ? null : folders,
            search: _search.text,
          );

          return Column(
            children: [
              if (_isFilterVisible) ...[
                CatalogFilterPanel(
                  maxHeight: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CatalogSearchBar(
                        controller: _search,
                        hintText:
                            'Search by name, description, or unit…',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      AbilityKindToggleButtons(
                        selectedKinds: _selectedKinds,
                        onChanged: (v) => setState(() => _selectedKinds = v),
                      ),
                      const SizedBox(height: 8),
                      RaceFilterToggleButtons(
                        selectedRaces: _selectedRaceLabels,
                        onChanged: (v) =>
                            setState(() => _selectedRaceLabels = v),
                      ),
                      const SizedBox(height: 10),
                      CatalogClearFiltersButton(onPressed: _clearFilters),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          '${filtered.length} ${filtered.length == 1 ? 'ability' : 'abilities'}',
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
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No abilities match these filters.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final a = filtered[i];
                          return _AbilityCard(
                            ability: a,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => AbilityDetailScreen(
                                    ability: a,
                                    allUnits: data.units.units,
                                  ),
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

class _AbilityCard extends StatelessWidget {
  const _AbilityCard({
    required this.ability,
    required this.onTap,
  });

  final CatalogAbility ability;
  final VoidCallback onTap;

  Color _typeColor() {
    if (ability.isStatusEffect) {
      return ability.isDebuff == true
          ? const Color(0xFFB91C1C)
          : const Color(0xFF0F766E);
    }
    return ability.isActive ? const Color(0xFF7C3AED) : const Color(0xFF0D9488);
  }

  IconData _typeIcon() {
    if (ability.isStatusEffect) {
      return ability.isDebuff == true
          ? Icons.health_and_safety_outlined
          : Icons.auto_awesome_outlined;
    }
    return ability.isActive ? Icons.flash_on_rounded : Icons.shield_outlined;
  }

  AbilityIconFallbackKind? _fallbackKind() {
    if (ability.isStatusEffect) {
      return null;
    }
    return ability.isActive
        ? AbilityIconFallbackKind.active
        : AbilityIconFallbackKind.passive;
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor();
    final desc = ability.description?.trim();

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
                  AbilityIconPreview(
                    candidatePaths: ability.iconAssetPathCandidates,
                    assetPath: ability.iconAssetPath,
                    fallbackKind: _fallbackKind(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ability.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniChip(
                              label: ability.typeLabel,
                              color: typeColor,
                              icon: _typeIcon(),
                            ),
                            _MiniChip(
                              label:
                                  '${ability.usedByUnits.length} ${ability.usedByUnits.length == 1 ? 'unit' : 'units'}',
                              color: const Color(0xFF5E6678),
                              icon: ability.usedByUnits.length == 1
                                  ? null
                                  : Icons.groups_outlined,
                              leadingAssetCandidates:
                                  ability.usedByUnits.length == 1
                                      ? unitIconAssetCandidates(
                                          ability.usedByUnits.first.unitId,
                                        )
                                      : null,
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
              if (desc != null && desc.isNotEmpty) ...[
                const SizedBox(height: 12),
                GameDescriptionText(
                  desc,
                  compact: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  baseStyle: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.35,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    this.icon,
    this.leadingAssetCandidates,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final List<String>? leadingAssetCandidates;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingAssetCandidates != null &&
              leadingAssetCandidates!.isNotEmpty) ...[
            ResolvedMiniAssetImage(
              candidates: leadingAssetCandidates!,
              size: 16,
              fallbackIcon: Icons.groups_outlined,
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
