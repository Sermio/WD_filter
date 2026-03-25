/// Specialization tree node (Humans / Tribes / Aliens).
///
/// Gameplay data: `Worldshift/data/db/items/*specs.dt`. Icons: `techgrid.lua`
/// + `spec_tree_icons` atlas.
class SpecTreeNode {
  const SpecTreeNode({
    required this.repo,
    required this.title,
    required this.description,
    required this.targets,
    required this.iconRow,
    required this.iconCol,
    required this.rankBonuses,
    required this.rankStatSnippets,
  });

  final String repo;
  final String title;
  final String description;
  final List<String> targets;
  final int iconRow;
  final int iconCol;

  /// One entry per purchasable rank (slash-separated stats in the `.dt`).
  final List<String> rankBonuses;

  /// Per-rank stat values as in the `.dt` (that rank’s stats).
  final List<String> rankStatSnippets;

  int get maxRanks => rankBonuses.length;

  String get iconAsset =>
      'assets/generated/ui_icons/spec_tree_icons/r${iconRow}_c$iconCol.png';
}
