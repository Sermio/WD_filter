import 'package:flutter/material.dart';
import 'package:worldshift_assistant/data/alien_skill_tree_data.dart';
import 'package:worldshift_assistant/data/human_skill_tree_data.dart';
import 'package:worldshift_assistant/data/mutant_skill_tree_data.dart';
import 'package:worldshift_assistant/data/spec_tree_node.dart';
import 'package:worldshift_assistant/models/spec_star_allocation.dart';
import 'package:worldshift_assistant/utils/unit_icon_candidates.dart';
import 'package:worldshift_assistant/widgets/catalog_info_eye_button.dart';
import 'package:worldshift_assistant/widgets/resolved_mini_asset_image.dart';
import 'package:worldshift_assistant/widgets/game_description_highlights.dart';
import 'package:worldshift_assistant/widgets/spec_node_effect_tooltip.dart';

/// Specialization tree (visual layout from generated `*VisualRowRepos`). Data: game `*specs.dt`.
class RaceSpecTreePanel extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables — node maps are built in factories, not const.
  RaceSpecTreePanel._({
    super.key,
    required this.visualRowRepos,
    required this.nodesByRepo,
    required this.hudTitleColor,
    required this.hudHintColor,
    required this.hudChipBg,
    required this.hudInkSplash,
    required this.hudInkHighlight,
    required this.hudPanelBorder,
    this.allocatedByRepo = const {},
    this.onSpecAllocationChanged,
    this.starBudget = kSpecStarBudgetPerRace,
  });

  factory RaceSpecTreePanel.humans({
    Key? key,
    required Color hudTitleColor,
    required Color hudHintColor,
    required Color hudChipBg,
    required Color hudInkSplash,
    required Color hudInkHighlight,
    required Color hudPanelBorder,
    Map<String, int> allocatedByRepo = const {},
    void Function(Map<String, int> nextByRepo)? onSpecAllocationChanged,
    int starBudget = kSpecStarBudgetPerRace,
  }) {
    return RaceSpecTreePanel._(
      key: key,
      visualRowRepos: humanSpecTreeVisualRowRepos,
      nodesByRepo: Map<String, SpecTreeNode>.from(humanSpecTreeByRepo),
      hudTitleColor: hudTitleColor,
      hudHintColor: hudHintColor,
      hudChipBg: hudChipBg,
      hudInkSplash: hudInkSplash,
      hudInkHighlight: hudInkHighlight,
      hudPanelBorder: hudPanelBorder,
      allocatedByRepo: allocatedByRepo,
      onSpecAllocationChanged: onSpecAllocationChanged,
      starBudget: starBudget,
    );
  }

  factory RaceSpecTreePanel.mutants({
    Key? key,
    required Color hudTitleColor,
    required Color hudHintColor,
    required Color hudChipBg,
    required Color hudInkSplash,
    required Color hudInkHighlight,
    required Color hudPanelBorder,
    Map<String, int> allocatedByRepo = const {},
    void Function(Map<String, int> nextByRepo)? onSpecAllocationChanged,
    int starBudget = kSpecStarBudgetPerRace,
  }) {
    return RaceSpecTreePanel._(
      key: key,
      visualRowRepos: mutantSpecTreeVisualRowRepos,
      nodesByRepo: Map<String, SpecTreeNode>.from(mutantSpecTreeByRepo),
      hudTitleColor: hudTitleColor,
      hudHintColor: hudHintColor,
      hudChipBg: hudChipBg,
      hudInkSplash: hudInkSplash,
      hudInkHighlight: hudInkHighlight,
      hudPanelBorder: hudPanelBorder,
      allocatedByRepo: allocatedByRepo,
      onSpecAllocationChanged: onSpecAllocationChanged,
      starBudget: starBudget,
    );
  }

  factory RaceSpecTreePanel.aliens({
    Key? key,
    required Color hudTitleColor,
    required Color hudHintColor,
    required Color hudChipBg,
    required Color hudInkSplash,
    required Color hudInkHighlight,
    required Color hudPanelBorder,
    Map<String, int> allocatedByRepo = const {},
    void Function(Map<String, int> nextByRepo)? onSpecAllocationChanged,
    int starBudget = kSpecStarBudgetPerRace,
  }) {
    return RaceSpecTreePanel._(
      key: key,
      visualRowRepos: alienSpecTreeVisualRowRepos,
      nodesByRepo: Map<String, SpecTreeNode>.from(alienSpecTreeByRepo),
      hudTitleColor: hudTitleColor,
      hudHintColor: hudHintColor,
      hudChipBg: hudChipBg,
      hudInkSplash: hudInkSplash,
      hudInkHighlight: hudInkHighlight,
      hudPanelBorder: hudPanelBorder,
      allocatedByRepo: allocatedByRepo,
      onSpecAllocationChanged: onSpecAllocationChanged,
      starBudget: starBudget,
    );
  }

  final List<List<String>> visualRowRepos;
  final Map<String, SpecTreeNode> nodesByRepo;

  final Color hudTitleColor;
  final Color hudHintColor;
  final Color hudChipBg;
  final Color hudInkSplash;
  final Color hudInkHighlight;
  final Color hudPanelBorder;

  /// Stars assigned per `repo` (0 = no entry in the map).
  final Map<String, int> allocatedByRepo;

  /// Replaces the current race map (after +/- on a node). Null = read-only.
  final void Function(Map<String, int> nextByRepo)? onSpecAllocationChanged;

  final int starBudget;

  static const double _hGap = 1;
  static const double _vGap = 9.6;

  /// Misma escala que frames de ítems del builder (~−20%).
  static const double _kSpecTreeFrameScale = 0.8;

  SpecTreeNode _n(String repo) => nodesByRepo[repo]!;

  void _tryQuickAddStar(BuildContext context, SpecTreeNode node) {
    if (onSpecAllocationChanged == null) {
      return;
    }
    final before = allocatedByRepo[node.repo] ?? 0;
    if (before >= node.maxRanks) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('This node already has all its stars.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final m = Map<String, int>.from(allocatedByRepo);
    applySpecStarChange(
      current: m,
      repo: node.repo,
      newValue: before + 1,
      maxRanks: node.maxRanks,
      budget: starBudget,
    );
    final after = m[node.repo] ?? 0;
    if (after <= before) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('No stars left in the pool (10 per race).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    onSpecAllocationChanged!(Map<String, int>.from(m));
  }

  void _openDetail(BuildContext context, SpecTreeNode node) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _SpecDetailSheetTheme.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SpecNodeDetailSheet(
        node: node,
        starBudget: starBudget,
        readOnly: onSpecAllocationChanged == null,
        initialByRepo: Map<String, int>.from(allocatedByRepo),
        onCommit: onSpecAllocationChanged,
      ),
    );
  }

  static double _frameSizeForWidth(double maxW) {
    final w2 = (maxW - _hGap) / 2;
    final w3 = (maxW - 2 * _hGap) / 3;
    final base = (w2 < w3 ? w2 : w3).clamp(52.0, 88.0);
    return base * _kSpecTreeFrameScale;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final frameSize = _frameSizeForWidth(maxW);
        final starsUsedTotal = totalSpecStarsAllocated(allocatedByRepo);
        final remaining = (starBudget - starsUsedTotal).clamp(0, starBudget);
        // Same size as [_SpecStarPlate] on each node.
        final plateStarSize = (frameSize * 0.16).clamp(8.0, 14.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < visualRowRepos.length; i++) ...[
                if (i > 0) const SizedBox(height: _vGap),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var j = 0; j < visualRowRepos[i].length; j++) ...[
                        if (j > 0) const SizedBox(width: _hGap),
                        _SpecTreeCell(
                          node: _n(visualRowRepos[i][j]),
                          frameSize: frameSize,
                          filledStars: allocatedByRepo[visualRowRepos[i][j]] ?? 0,
                          hudHintColor: hudHintColor,
                          hudTitleColor: hudTitleColor,
                          hudInkSplash: hudInkSplash,
                          hudInkHighlight: hudInkHighlight,
                          onShortTap: onSpecAllocationChanged != null
                              ? () => _tryQuickAddStar(
                                    context,
                                    _n(visualRowRepos[i][j]),
                                  )
                              : null,
                          onOpenDetail: () => _openDetail(
                            context,
                            _n(visualRowRepos[i][j]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 11),
              Align(
                alignment: Alignment.center,
                child: _SpecStarPoolRow(
                  remainingInPool: remaining,
                  budget: starBudget,
                  starSize: plateStarSize,
                  labelStyle: TextStyle(
                    color: hudTitleColor,
                    fontSize: (plateStarSize * 1.05).clamp(11.0, 15.0),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Global pool: **gold** stars on the left (still in the pool); **dark** on the right (already on nodes).
class _SpecStarPoolRow extends StatelessWidget {
  const _SpecStarPoolRow({
    required this.remainingInPool,
    required this.budget,
    required this.starSize,
    required this.labelStyle,
  });

  final int remainingInPool;
  final int budget;
  final double starSize;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < budget; i++)
          _SpecStarGlyph(
            active: i < remainingInPool,
            size: starSize,
          ),
        SizedBox(width: (starSize * 0.85).clamp(8.0, 14.0)),
        Text('$remainingInPool/$budget', style: labelStyle),
      ],
    );
  }
}

/// **Active** star: gold with glow. **Inactive**: muted gray-brown (game reference).
class _SpecStarGlyph extends StatelessWidget {
  const _SpecStarGlyph({
    required this.active,
    required this.size,
    this.inactiveColor,
  });

  final bool active;
  final double size;
  /// If non-null, overrides inactive dark gray (e.g. light sheet background).
  final Color? inactiveColor;

  static const Color _activeFill = Color(0xFFFFD85A);
  static const Color _inactiveFill = Color(0xFF4A4038);

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Icon(
        Icons.star_rounded,
        size: size,
        color: inactiveColor ?? _inactiveFill,
      );
    }
    return Icon(
      Icons.star_rounded,
      size: size,
      color: _activeFill,
      shadows: const [
        Shadow(
          color: Color(0xCCFFAA00),
          blurRadius: 6,
          offset: Offset(0, 0),
        ),
        Shadow(
          color: Color(0x99FFF8E1),
          blurRadius: 2,
          offset: Offset(0, -0.5),
        ),
        Shadow(
          color: Color(0xFF6B4A00),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );
  }
}

class _SpecStarPlate extends StatelessWidget {
  const _SpecStarPlate({
    required this.maxRanks,
    required this.filledCount,
    required this.frameSize,
  });

  final int maxRanks;
  final int filledCount;
  final double frameSize;

  @override
  Widget build(BuildContext context) {
    if (maxRanks <= 0) {
      return const SizedBox.shrink();
    }
    final starSize = (frameSize * 0.16).clamp(8.0, 14.0);
    final filled = filledCount.clamp(0, maxRanks);
    return Container(
      padding: const EdgeInsets.only(left: 3, right: 2, top: 1, bottom: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1C22),
            Color(0xFF0A0A0E),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        ),
        border: Border.all(color: const Color(0x55FFFFFF), width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          maxRanks,
          (i) => Padding(
            padding: EdgeInsets.only(left: i > 0 ? 1 : 0),
            child: _SpecStarGlyph(
              active: i < filled,
              size: starSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecStarRowInteractive extends StatelessWidget {
  const _SpecStarRowInteractive({
    required this.maxRanks,
    required this.filledCount,
    required this.starSize,
  });

  final int maxRanks;
  final int filledCount;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    if (maxRanks <= 0) {
      return const SizedBox.shrink();
    }
    final filled = filledCount.clamp(0, maxRanks);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        maxRanks,
        (i) => Padding(
          padding: EdgeInsets.only(right: i < maxRanks - 1 ? 2 : 0),
          child: _SpecStarGlyph(active: i < filled, size: starSize),
        ),
      ),
    );
  }
}

/// Same visual baseline as the builder’s light bottom sheets (`0xFFF8F9FA`, etc.).
abstract final class _SpecDetailSheetTheme {
  static const sheetBackground = Color(0xFFF8F9FA);
  static const titleAccent = Color(0xFFFFB74D);
  static const headline = Color(0xFF1F2937);
  static const body = Color(0xFF374151);
  static const chipBg = Color(0xFFF3F4F6);
  static const border = Color(0xFFE5E7EB);

  static TextStyle get descriptionStyle => const TextStyle(
        color: body,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
      );

  /// Empty stars on light sheets: solid slate gray (better contrast than slate-300).
  static const starInactiveOnSheet = Color(0xFF57534E);
}

/// Shows rank **k** (1…max): **k** gold stars and the rest dimmed.
class _SpecPerRankStarRow extends StatelessWidget {
  const _SpecPerRankStarRow({
    required this.rank,
    required this.maxRanks,
  });

  final int rank;
  final int maxRanks;

  static const double _starSize = 15;

  @override
  Widget build(BuildContext context) {
    if (maxRanks <= 0) {
      return const SizedBox.shrink();
    }
    final k = rank.clamp(1, maxRanks);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        maxRanks,
        (j) => Padding(
          padding: EdgeInsets.only(right: j < maxRanks - 1 ? 2 : 0),
          child: _SpecStarGlyph(
            active: j < k,
            size: _starSize,
            inactiveColor: _SpecDetailSheetTheme.starInactiveOnSheet,
          ),
        ),
      ),
    );
  }
}

class _SpecAffectedUnitChip extends StatelessWidget {
  const _SpecAffectedUnitChip({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _SpecDetailSheetTheme.chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _SpecDetailSheetTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResolvedMiniAssetImage(
            candidates: unitIconAssetCandidates(displayName),
            size: 16,
            borderRadius: 4,
          ),
          const SizedBox(width: 6),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _SpecDetailSheetTheme.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// Typographic `+` / `-` buttons (builder light preview).
class _SpecDeltaButton extends StatelessWidget {
  const _SpecDeltaButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.black12,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1,
              color: enabled
                  ? const Color(0xFF111827)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }
}

/// One rank line: single paragraph, or a vertical list when several stats (`;`-separated).
class _SpecPerRankBonusList extends StatelessWidget {
  const _SpecPerRankBonusList({required this.rawLine});

  final String rawLine;

  @override
  Widget build(BuildContext context) {
    final formatted =
        GameDescriptionText.formatSpecRankBonusLineForDisplay(rawLine);
    final style = _SpecDetailSheetTheme.descriptionStyle;
    final segments = formatted
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }
    if (segments.length == 1) {
      return GameDescriptionText(
        segments.single,
        baseStyle: style,
        compact: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Text(
                  '\u2022',
                  style: style.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              Expanded(
                child: GameDescriptionText(
                  segments[i],
                  baseStyle: style,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SpecNodeDetailSheet extends StatefulWidget {
  const _SpecNodeDetailSheet({
    required this.node,
    required this.starBudget,
    required this.readOnly,
    required this.initialByRepo,
    this.onCommit,
  });

  final SpecTreeNode node;
  final int starBudget;
  final bool readOnly;
  final Map<String, int> initialByRepo;
  final void Function(Map<String, int> nextByRepo)? onCommit;

  @override
  State<_SpecNodeDetailSheet> createState() => _SpecNodeDetailSheetState();
}

class _SpecNodeDetailSheetState extends State<_SpecNodeDetailSheet> {
  late Map<String, int> _byRepo;

  @override
  void initState() {
    super.initState();
    _byRepo = Map<String, int>.from(widget.initialByRepo);
  }

  int get _onNode => _byRepo[widget.node.repo] ?? 0;

  int get _usedTotal => totalSpecStarsAllocated(_byRepo);

  void _tryDelta(int delta) {
    if (widget.readOnly || widget.onCommit == null) {
      return;
    }
    final nextVal = _onNode + delta;
    final m = Map<String, int>.from(_byRepo);
    applySpecStarChange(
      current: m,
      repo: widget.node.repo,
      newValue: nextVal,
      maxRanks: widget.node.maxRanks,
      budget: widget.starBudget,
    );
    setState(() => _byRepo = m);
    widget.onCommit!(Map<String, int>.from(_byRepo));
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final cur = _onNode;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            node.iconAsset,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: _SpecStarPlate(
                              maxRanks: node.maxRanks,
                              filledCount: cur,
                              frameSize: 56,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title,
                          style: const TextStyle(
                            color: _SpecDetailSheetTheme.titleAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!widget.readOnly) ...[
                          Text(
                            'Race stars: $_usedTotal / ${widget.starBudget}',
                            style: const TextStyle(
                              color: _SpecDetailSheetTheme.body,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _SpecDeltaButton(
                                label: '-',
                                onPressed:
                                    cur <= 0 ? null : () => _tryDelta(-1),
                              ),
                              const SizedBox(width: 8),
                              _SpecStarRowInteractive(
                                maxRanks: node.maxRanks,
                                filledCount: cur,
                                starSize: 22,
                              ),
                              const SizedBox(width: 8),
                              _SpecDeltaButton(
                                label: '+',
                                onPressed: cur >= node.maxRanks
                                    ? null
                                    : () => _tryDelta(1),
                              ),
                            ],
                          ),
                        ] else
                          _SpecStarRowInteractive(
                            maxRanks: node.maxRanks,
                            filledCount: cur,
                            starSize: 18,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SpecNodeEffectTooltip(
                node: node,
                investedRanks: cur,
                baseStyle: _SpecDetailSheetTheme.descriptionStyle,
              ),
              const SizedBox(height: 16),
              const Text(
                'Affected units',
                style: TextStyle(
                  color: _SpecDetailSheetTheme.headline,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: node.targets
                    .map((u) => _SpecAffectedUnitChip(displayName: u))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Per rank (bonuses stack when you invest stars)',
                style: TextStyle(
                  color: _SpecDetailSheetTheme.headline,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(node.rankBonuses.length, (i) {
                final rank = i + 1;
                final isCurrentRank = cur > 0 && rank == cur;
                final block = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _SpecPerRankStarRow(
                        rank: rank,
                        maxRanks: node.maxRanks,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SpecPerRankBonusList(
                        rawLine: node.rankBonuses[i],
                      ),
                    ),
                  ],
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: isCurrentRank
                      ? Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4ADE80)
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: block,
                        )
                      : block,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecTreeCell extends StatelessWidget {
  const _SpecTreeCell({
    required this.node,
    required this.frameSize,
    required this.filledStars,
    required this.hudHintColor,
    required this.hudTitleColor,
    required this.hudInkSplash,
    required this.hudInkHighlight,
    this.onShortTap,
    required this.onOpenDetail,
  });

  final SpecTreeNode node;
  final double frameSize;
  final int filledStars;
  final Color hudHintColor;
  final Color hudTitleColor;
  final Color hudInkSplash;
  final Color hudInkHighlight;
  final VoidCallback? onShortTap;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final labelSize = (frameSize / 8.2).clamp(9.0, 10.5);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onShortTap ?? onOpenDetail,
        borderRadius: BorderRadius.circular(12),
        splashColor: hudInkSplash,
        highlightColor: hudInkHighlight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: frameSize,
                height: frameSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: hudHintColor.withValues(alpha: 0.25),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          node.iconAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _SpecStarPlate(
                          maxRanks: node.maxRanks,
                          filledCount: filledStars,
                          frameSize: frameSize,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CatalogInfoEyeButton(
                          frameSize: frameSize,
                          tooltip: 'View effect and ranks',
                          onPressed: onOpenDetail,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: frameSize,
                child: Text(
                  node.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hudTitleColor,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
