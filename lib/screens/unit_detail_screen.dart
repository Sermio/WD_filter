import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/models/game_unit.dart';

class UnitDetailScreen extends StatelessWidget {
  const UnitDetailScreen({super.key, required this.unit});

  final GameUnit unit;

  String _statLabel(String key) {
    for (final m in attributeList) {
      if (m['key'] == key) return m['value'] ?? key;
    }
    return key.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final statsEntries = unit.stats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(unit.displayName ?? unit.id),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Resumen',
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(unit.raceLabel, Icons.public),
                  _buildChip(unit.unitIconClass, Icons.image_outlined),
                  if (unit.movementType != null)
                    _buildChip(unit.movementType!, Icons.directions_run),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow('Id', unit.id),
              _infoRow('Carpeta', unit.raceFolder),
              _infoRow('Fuente icono', unit.detailIconSourceLabel),
              if (unit.mainIconCol != null && unit.mainIconRow != null)
                _infoRow('Atlas icon', '${unit.mainIconCol}, ${unit.mainIconRow}'),
              if (unit.conversationIconCol != null &&
                  unit.conversationIconRow != null)
                _infoRow(
                  'Atlas conv',
                  '${unit.conversationIconCol}, ${unit.conversationIconRow}',
                ),
              if (unit.tags != null) _infoRow('Tags', unit.tags!),
              if (unit.auraNames.isNotEmpty)
                _infoRow('Auras', unit.auraNames.join(', ')),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Estadísticas',
            trailing: _buildStatsCount(statsEntries.length),
            children: [
              if (statsEntries.isEmpty)
                Text(
                  'Sin bloque `stats` parseable en el .dt.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                ...statsEntries.map(
                  (e) => Container(
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
                            _statLabel(e.key),
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
                  ),
                ),
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
          Container(
            width: 124,
            height: 124,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: _ResolvedAssetImage(
              candidates: unit.detailIconAssetCandidates,
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
          const SizedBox(height: 6),
          Text(
            unit.id,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
            ),
          ),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
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

  Widget _buildStatsCount(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Color(0xFF4D5FBD),
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _infoRow(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                k,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildChip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD7DDFC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF667eea)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4D5FBD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
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
          return const Icon(Icons.person, size: 56);
        }
        return Image.asset(path, fit: BoxFit.contain);
      },
    );
  }
}
