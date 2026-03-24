import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worldshift_assistant/data/ability_icon_fallbacks.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/models/game_unit.dart';
import 'package:worldshift_assistant/widgets/ability_icon_preview.dart';
import 'package:worldshift_assistant/widgets/game_description_highlights.dart';

class UnitDetailScreen extends StatelessWidget {
  const UnitDetailScreen({super.key, required this.unit});

  final GameUnit unit;

  String _statLabel(String key) {
    const labelOverrides = <String, String>{
      'hp': 'Hit Points',
      'hit_points': 'Hit Points',
      'psi': 'Power',
      'power': 'Power',
    };
    final override = labelOverrides[key];
    if (override != null) {
      return override;
    }
    for (final m in attributeList) {
      if (m['key'] == key) return m['value'] ?? key;
    }
    return key.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final statsEntries = _sortStats(unit.stats);
    final listablePassive = unit.passiveAbilities
        .where((a) => a.isListableAbility)
        .toList();
    final listableActive = unit.activeAbilities
        .where((a) => a.isListableAbility)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          unit.displayName ?? unit.id,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFFf093fb),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          statsEntries.isEmpty
              ? _buildSection(
                  title: 'Stats',
                  children: [
                    Text(
                      'This unit has no stats on record.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                )
              : _buildStatsSection(context, statsEntries),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Abilities',
            children: [
              if (listablePassive.isEmpty && listableActive.isEmpty)
                Text(
                  'This unit has no abilities on record.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else ...[
                if (listablePassive.isNotEmpty)
                  _buildAbilityGroup(
                    'Passive Abilities',
                    listablePassive,
                    fallbackKind: AbilityIconFallbackKind.passive,
                  ),
                if (listablePassive.isNotEmpty && listableActive.isNotEmpty)
                  const SizedBox(height: 16),
                if (listableActive.isNotEmpty)
                  _buildAbilityGroup(
                    'Active Abilities',
                    listableActive,
                    fallbackKind: AbilityIconFallbackKind.active,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Buffs / Debuffs',
            children: [
              if (unit.statusEffects.isEmpty)
                Text(
                  'This unit has no buff or debuff effects listed.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                ...unit.statusEffects.map(_buildStatusEffectCard),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 124,
            height: 124,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _ResolvedAssetImage(
                candidates: unit.detailIconAssetCandidates,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            unit.displayName ?? unit.id,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unit.id,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(unit.raceLabel, Icons.public),
              _buildChip(
                  _unitTypeLabel(unit.unitIconClass), Icons.badge_outlined),
              if (unit.movementType != null)
                _buildChip(unit.movementType!, Icons.directions_run),
            ],
          ),
        ],
      ),
    );
  }

  static const _sectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF667eea),
  );

  static const int _primaryStatCount = 4;

  /// Estadísticas que no están ya en las tarjetas principales (evita duplicar filas).
  List<MapEntry<String, String>> _additionalStatsEntries(
    List<MapEntry<String, String>> statsEntries,
  ) {
    if (statsEntries.length <= _primaryStatCount) {
      return const [];
    }
    return statsEntries.skip(_primaryStatCount).toList();
  }

  Widget _buildStatsSection(
    BuildContext context,
    List<MapEntry<String, String>> statsEntries,
  ) {
    final primary = _selectPrimaryStats(statsEntries);
    final additional = _additionalStatsEntries(statsEntries);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stats', style: _sectionTitleStyle),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: primary
                .map(
                  (e) => _PrimaryStatCard(
                    label: _statLabel(e.key),
                    value: e.value,
                  ),
                )
                .toList(),
          ),
          if (additional.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 4),
                expandedAlignment: Alignment.topLeft,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                iconColor: const Color(0xFF667eea),
                collapsedIconColor: const Color(0xFF667eea),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  'More stats',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  additional.length == 1
                      ? '1 more'
                      : '${additional.length} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                children: [
                  _ExpandableStatList(
                    entries: additional,
                    statLabel: _statLabel,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: _sectionTitleStyle,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x4DFFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildAbilityGroup(
    String title,
    List<GameUnitAbility> abilities, {
    required AbilityIconFallbackKind fallbackKind,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ...abilities.map(
          (a) => _buildAbilityCard(a, fallbackKind: fallbackKind),
        ),
      ],
    );
  }

  Widget _buildAbilityCard(
    GameUnitAbility ability, {
    required AbilityIconFallbackKind fallbackKind,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AbilityIconPreview(
                assetPath: ability.iconAssetPath,
                size: 30,
                fallbackKind: fallbackKind,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ability.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          if (ability.description != null &&
              ability.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            GameDescriptionText(
              ability.description!,
              baseStyle: const TextStyle(
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusEffectCard(GameUnitStatusEffect effect) {
    final badge = effect.isDebuff == true ? 'Debuff' : 'Buff';
    final badgeColor = effect.isDebuff == true
        ? const Color(0xFFB91C1C)
        : const Color(0xFF0F766E);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AbilityIconPreview(
                candidatePaths: effect.iconAssetPathCandidates,
                assetPath: effect.iconAssetPath,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  effect.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          if (effect.description != null && effect.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            GameDescriptionText(
              effect.description!,
              baseStyle: const TextStyle(
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _sortStats(Map<String, String> stats) {
    const priorityGroups = [
      ['damage'],
      ['hit_points', 'hp'],
      ['armor'],
      ['psi', 'power'],
      ['range'],
      ['speed'],
    ];
    final priorityByKey = <String, int>{};
    for (var i = 0; i < priorityGroups.length; i++) {
      for (final key in priorityGroups[i]) {
        priorityByKey[key] = i;
      }
    }

    final entries = stats.entries.toList();
    entries.sort((a, b) {
      final aPriority = priorityByKey[a.key] ?? 999;
      final bPriority = priorityByKey[b.key] ?? 999;
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      return _statLabel(a.key).compareTo(_statLabel(b.key));
    });
    return entries;
  }

  List<MapEntry<String, String>> _selectPrimaryStats(
    List<MapEntry<String, String>> statsEntries,
  ) {
    return statsEntries.take(_primaryStatCount).toList();
  }

  String _unitTypeLabel(String value) {
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

/// Lista de filas de estadísticas: muestra 6 por defecto y permite desplegar el resto.
class _ExpandableStatList extends StatefulWidget {
  const _ExpandableStatList({
    required this.entries,
    required this.statLabel,
  });

  final List<MapEntry<String, String>> entries;
  final String Function(String key) statLabel;

  @override
  State<_ExpandableStatList> createState() => _ExpandableStatListState();
}

class _ExpandableStatListState extends State<_ExpandableStatList> {
  static const int _previewCount = 6;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final total = entries.length;
    final visibleCount =
        _showAll ? total : min(_previewCount, total);
    final hidden = total - _previewCount;
    final canToggle = total > _previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...entries.take(visibleCount).map(_statRow),
        if (canToggle)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                _showAll
                    ? 'Show less'
                    : (hidden == 1
                        ? 'Show 1 more stat'
                        : 'Show $hidden more stats'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statRow(MapEntry<String, String> e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.statLabel(e.key),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              e.value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedAssetImage extends StatelessWidget {
  const _ResolvedAssetImage({required this.candidates});

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
            backgroundColor: Color(0x26FFFFFF),
            child: Icon(Icons.person, size: 56, color: Colors.white),
          );
        }
        return ClipOval(
          child: SizedBox.expand(
            child: Image.asset(path, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _PrimaryStatCard extends StatelessWidget {
  const _PrimaryStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

