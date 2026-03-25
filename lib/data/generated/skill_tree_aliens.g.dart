// GENERATED FILE — do not edit by hand.
// Regenerar: dart run tool/generate_skill_tree_data.dart [ruta_Worldshift]

part of '../alien_skill_tree_data.dart';

/// Grid filas = patrón visual en app (ver alien_skill_tree_data.dart).
const List<List<AlienSpecTreeNode>> alienSpecTreeGrid = [
  [
    AlienSpecTreeNode(
      repo: "ALIEN_SPECA1",
      title: "Terrify",
      description: "Your Trisat's Frenzy will last [stats.frenzy_duration] additional seconds after they stop doing damage.",
      targets: const ["Trisat"],
      iconRow: 4,
      iconCol: 0,
      rankBonuses: const ["frenzy_duration = 5", "frenzy_duration = 10"],
      rankStatSnippets: const ["frenzy_duration = 5", "frenzy_duration = 10"],
    ),
    AlienSpecTreeNode(
      repo: "ALIEN_SPECA2",
      title: "Overpower",
      description: "All your regular units will do [stats.damage] more direct damage.",
      targets: const ["Trisat", "Tritech", "Shifter", "Overseer", "AttackDrone", "PsiDetonator"],
      iconRow: 4,
      iconCol: 1,
      rankBonuses: const ["damage = 5%", "damage = 10%"],
      rankStatSnippets: const ["damage = 5%", "damage = 10%"],
    )
  ],
  [
    AlienSpecTreeNode(
      repo: "ALIEN_SPECB1",
      title: "Prophesy",
      description: "Your Master will regenerate power [stats.psi_gen] faster.",
      targets: const ["Master"],
      iconRow: 4,
      iconCol: 2,
      rankBonuses: const ["psi_gen = 20%", "psi_gen = 50%"],
      rankStatSnippets: const ["psi_gen = 20%", "psi_gen = 50%"],
    ),
    AlienSpecTreeNode(
      repo: "ALIEN_SPECB2",
      title: "Fire Focus",
      description: "Your Tritech's will have additional [stats.crit_chance]% chance to do double damage on their target.",
      targets: const ["Tritech"],
      iconRow: 4,
      iconCol: 3,
      rankBonuses: const ["crit_chance = 5", "crit_chance = 10", "crit_chance = 20"],
      rankStatSnippets: const ["crit_chance = 5", "crit_chance = 10", "crit_chance = 20"],
    ),
    AlienSpecTreeNode(
      repo: "ALIEN_SPECB3",
      title: "Bio-Split",
      description: "When a Tritech is killed there is [stats.bio_split_chance]% chance for 2-3 Hatchlings to spawn from its corpse.",
      targets: const ["Tritech"],
      iconRow: 4,
      iconCol: 4,
      rankBonuses: const ["bio_split_chance = 25"],
      rankStatSnippets: const ["bio_split_chance = 25"],
    )
  ],
  [
    AlienSpecTreeNode(
      repo: "ALIEN_SPECC1",
      title: "Demonic Hunger",
      description: "Your Masters'  feed action will add additional [stats.feed_add_heal] healing every tick and for each affected target.",
      targets: const ["Master"],
      iconRow: 5,
      iconCol: 0,
      rankBonuses: const ["feed_add_heal = 1", "feed_add_heal = 2", "feed_add_heal = 5"],
      rankStatSnippets: const ["feed_add_heal = 1", "feed_add_heal = 2", "feed_add_heal = 5"],
    ),
    AlienSpecTreeNode(
      repo: "ALIEN_SPECC2",
      title: "Imminence",
      description: "Harvester will have [stats.confuse_chance]% chance on every strike to stress his target forcing it to focus attacks on the Harvester.",
      targets: const ["Harvester"],
      iconRow: 5,
      iconCol: 1,
      rankBonuses: const ["confuse_chance = 5", "confuse_chance = 15"],
      rankStatSnippets: const ["confuse_chance = 5", "confuse_chance = 15"],
    )
  ],
  [
    AlienSpecTreeNode(
      repo: "ALIEN_SPECD1",
      title: "Barrier Cure",
      description: "All your units will regenerate hit points [stats.hp_gen] faster without recovering.",
      targets: const ["Master", "Harvester", "Arbiter", "Manipulator", "Dominator", "Shifter", "Overseer", "Tritech", "Trisat", "Hatchling", "AttackDrone", "PsiDetonator"],
      iconRow: 5,
      iconCol: 2,
      rankBonuses: const ["hp_gen = 50%, recovery_time = -100%"],
      rankStatSnippets: const ["hp_gen = 50%, recovery_time = -100%"],
    ),
    AlienSpecTreeNode(
      repo: "ALIEN_SPECD2",
      title: "Charged Armor",
      description: "Your Master and all your Wardens will get [stats.hp] additional hit points.",
      targets: const ["Master", "Harvester", "Arbiter", "Manipulator", "Dominator", "Defiler"],
      iconRow: 5,
      iconCol: 3,
      rankBonuses: const ["hp = 5%", "hp = 10%", "hp = 20%"],
      rankStatSnippets: const ["hp = 5%", "hp = 10%", "hp = 20%"],
    ),
    AlienSpecTreeNode(
      repo: "ALIEN_SPECD3",
      title: "Bio-Cycle",
      description: "When Trisat dies in the sight of the Master, there is [stats.bio_cycle_chance]% chance for the Master to recycle it near him with 25% hit points. Recycled Trisats will loose all their beneficial effects they might had before they were killed.",
      targets: const ["Trisat"],
      iconRow: 5,
      iconCol: 4,
      rankBonuses: const ["bio_cycle_chance = 25"],
      rankStatSnippets: const ["bio_cycle_chance = 25"],
    )
  ]
];

const List<List<String>> alienSpecTreeVisualRowRepos = const [const ["ALIEN_SPECA1", "ALIEN_SPECA2"], const ["ALIEN_SPECB1", "ALIEN_SPECB2", "ALIEN_SPECB3"], const ["ALIEN_SPECC1", "ALIEN_SPECC2"], const ["ALIEN_SPECD1", "ALIEN_SPECD2", "ALIEN_SPECD3"]];

final Map<String, AlienSpecTreeNode> alienSpecTreeByRepo = Map<String, AlienSpecTreeNode>.unmodifiable({
  for (final row in alienSpecTreeGrid)
    for (final n in row) n.repo: n,
});
