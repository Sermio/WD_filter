// GENERATED FILE — do not edit by hand.
// Regenerar: dart run tool/generate_skill_tree_data.dart [ruta_Worldshift]

part of '../mutant_skill_tree_data.dart';

/// Grid filas = patrón visual en app (ver mutant_skill_tree_data.dart).
const List<List<MutantSpecTreeNode>> mutantSpecTreeGrid = [
  [
    MutantSpecTreeNode(
      repo: "MUTANT_SPECA1",
      title: "Thunder Focus",
      description: "Your High Priest Lightning will do [stats.lightning_damage] more damage.",
      targets: const ["HighPriest"],
      iconRow: 2,
      iconCol: 0,
      rankBonuses: const ["lightning_damage = 20%", "lightning_damage = 50%"],
      rankStatSnippets: const ["lightning_damage = 20%", "lightning_damage = 50%"],
    ),
    MutantSpecTreeNode(
      repo: "MUTANT_SPECA2",
      title: "Freeze Mastery",
      description: "Your High Priest Freeze action will hold for [stats.freeze_duration] seconds longer.",
      targets: const ["HighPriest"],
      iconRow: 2,
      iconCol: 1,
      rankBonuses: const ["freeze_duration = 1", "freeze_duration = 2"],
      rankStatSnippets: const ["freeze_duration = 1", "freeze_duration = 2"],
    )
  ],
  [
    MutantSpecTreeNode(
      repo: "MUTANT_SPECB1",
      title: "Weapons Training",
      description: "Your warriors will have additional [stat.crit_chance]% to critically attack inflicting double damage.",
      targets: const ["Warrior"],
      iconRow: 2,
      iconCol: 2,
      rankBonuses: const ["crit_chance = 5", "crit_chance = 10", "crit_chance = 20"],
      rankStatSnippets: const ["crit_chance = 5", "crit_chance = 10", "crit_chance = 20"],
    ),
    MutantSpecTreeNode(
      repo: "MUTANT_SPECB2",
      title: "Power Mastery",
      description: "Your High Priest and all your Elders' power will regenerate [stats.psi_gen] faster.",
      targets: const ["HighPriest", "Shaman", "Sorcerer", "StoneGhost", "Guardian", "Psychic"],
      iconRow: 2,
      iconCol: 3,
      rankBonuses: const ["psi_gen = 10%", "psi_gen = 30%"],
      rankStatSnippets: const ["psi_gen = 10%", "psi_gen = 30%"],
    ),
    MutantSpecTreeNode(
      repo: "MUTANT_SPECB3",
      title: "Dark Binding",
      description: "All your Underworld units (Ancient Shade, Howling Horror, Stone Ghost and Soul Worm) will regenerate hit points [stats.hp_gen] faster, with no recovery time.",
      targets: const ["StoneGhost", "AncientShade", "HowlingHorror", "Worm"],
      iconRow: 2,
      iconCol: 4,
      rankBonuses: const ["hp_gen = 30%, recovery_time = -100%", "hp_gen = 30%, recovery_time = -100%"],
      rankStatSnippets: const ["hp_gen = 30%, recovery_time = -100%", "hp_gen = 30%, recovery_time = -100%"],
    )
  ],
  [
    MutantSpecTreeNode(
      repo: "MUTANT_SPECC1",
      title: "Natural Protection",
      description: "All your regular units will gain [stats.hp] additional hit points.",
      targets: const ["Warrior", "Worker", "Brute", "AncientShade", "HowlingHorror", "EliteKaiRider"],
      iconRow: 3,
      iconCol: 0,
      rankBonuses: const ["hp = 5%", "hp = 15%"],
      rankStatSnippets: const ["hp = 5%", "hp = 15%"],
    ),
    MutantSpecTreeNode(
      repo: "MUTANT_SPECC2",
      title: "Healing Grace",
      description: "Your High Priest Holy Aura will heal for [stats.holy_aura_heal] more hit points.",
      targets: const ["HighPriest"],
      iconRow: 3,
      iconCol: 1,
      rankBonuses: const ["holy_aura_heal = 10%", "holy_aura_heal = 20%", "holy_aura_heal = 30%"],
      rankStatSnippets: const ["holy_aura_heal = 10%", "holy_aura_heal = 20%", "holy_aura_heal = 30%"],
    )
  ],
  [
    MutantSpecTreeNode(
      repo: "MUTANT_SPECD1",
      title: "Nature Focus",
      description: "Your Shamans' will have [stats.drain_life_chance] higher chance to drain life while attacking enemies. Also, each time Shamans drains life, they will purge one positive effect on their targets.",
      targets: const ["Shaman"],
      iconRow: 3,
      iconCol: 2,
      rankBonuses: const ["drain_life_chance = 25, drain_life_purge = 1"],
      rankStatSnippets: const ["drain_life_chance = 25, drain_life_purge = 1"],
    ),
    MutantSpecTreeNode(
      repo: "MUTANT_SPECD2",
      title: "Elemental Focus",
      description: "Your High Priest, Sorcerer and Shaman will do [stats.damage] more damage with their direct attack.",
      targets: const ["HighPriest", "Shaman", "Sorcerer"],
      iconRow: 3,
      iconCol: 3,
      rankBonuses: const ["damage = 5%", "damage = 15%"],
      rankStatSnippets: const ["damage = 5%", "damage = 15%"],
    ),
    MutantSpecTreeNode(
      repo: "MUTANT_SPECD3",
      title: "Beast Training",
      description: "Your Brutes will get [stats.hp] higher hit points and [stats.armor] additional armor. Also, Brutes will have [stats.ignite_on_strike_chance] chance to Ignite after each attack, instead only after doing killing blow.",
      targets: const ["Brute"],
      iconRow: 3,
      iconCol: 4,
      rankBonuses: const ["hp = 10%, armor = 5, ignite_on_strike_chance = 2", "hp = 20%, armor = 10, ignite_on_strike_chance = 5"],
      rankStatSnippets: const ["hp = 10%, armor = 5, ignite_on_strike_chance = 2", "hp = 20%, armor = 10, ignite_on_strike_chance = 5"],
    )
  ]
];

const List<List<String>> mutantSpecTreeVisualRowRepos = const [const ["MUTANT_SPECA1", "MUTANT_SPECA2"], const ["MUTANT_SPECB1", "MUTANT_SPECB2", "MUTANT_SPECB3"], const ["MUTANT_SPECC1", "MUTANT_SPECC2"], const ["MUTANT_SPECD1", "MUTANT_SPECD2", "MUTANT_SPECD3"]];

final Map<String, MutantSpecTreeNode> mutantSpecTreeByRepo = Map<String, MutantSpecTreeNode>.unmodifiable({
  for (final row in mutantSpecTreeGrid)
    for (final n in row) n.repo: n,
});
