// GENERATED FILE — do not edit by hand.
// Regenerar: dart run tool/generate_skill_tree_data.dart [ruta_Worldshift]

part of '../human_skill_tree_data.dart';

/// Grid row-major: matches tech grid columns 1–5 × rows 1–2 (1-based in game).
const List<List<HumanSpecTreeNode>> humanSpecTreeGrid = [
  [
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECA1',
      title: 'Durability',
      description:
          'All your regular units will have [stats.hp] higher hit points.',
      targets: [
        'Technician',
        'Ripper',
        'Trooper',
        'AssaultBot',
        'Hellfire',
        'Defender',
      ],
      iconRow: 0,
      iconCol: 0,
      rankBonuses: [
        'Hit Points +5%.',
        'Hit Points +10%.',
      ],
      rankStatSnippets: [
        'hp = 5%',
        'hp = 10%',
      ],
    ),
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECA2',
      title: 'Overclocking',
      description:
          'All your cyber units will auto-repair [stats.hp_gen] faster, without recovery time and will also do [stats.damage] additional direct damage.',
      targets: [
        'Constructor',
        'Ripper',
        'AssaultBot',
        'Hellfire',
        'Defender',
      ],
      iconRow: 0,
      iconCol: 1,
      rankBonuses: [
        'HP regen +10%, direct damage +10%, recovery time −100%.',
        'HP regen +20%, direct damage +20%, recovery time −100%.',
      ],
      rankStatSnippets: [
        'hp_gen = 10%, damage = 10%, recovery_time = -100%',
        'hp_gen = 20%, damage = 20%, recovery_time = -100%',
      ],
    ),
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECB1',
      title: 'Elusion',
      description:
          'Your Rippers will have [stats.elusion]% chance to completely ignore direct ranged attacks coming from melee range.',
      targets: ['Ripper'],
      iconRow: 0,
      iconCol: 2,
      rankBonuses: [
        'Ripper: 20% chance to ignore direct ranged attacks from melee range.',
      ],
      rankStatSnippets: [
        'elusion = 20',
      ],
    ),
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECB2',
      title: 'Crushing Fire',
      description:
          'All your units will have [stats.crit_chance]% additionally to inflicting double (critical) damage with their direct attack.',
      targets: [
        'Commander',
        'Assassin',
        'Surgeon',
        'Judge',
        'Constructor',
        'Technician',
        'Ripper',
        'Trooper',
        'AssaultBot',
        'Hellfire',
        'Defender',
      ],
      iconRow: 0,
      iconCol: 3,
      rankBonuses: [
        'Critical chance +2%.',
        'Critical chance +5%.',
        'Critical chance +10%.',
      ],
      rankStatSnippets: [
        'crit_chance = 2%',
        'crit_chance = 5%',
        'crit_chance = 10%',
      ],
    ),
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECB3',
      title: 'Motivation',
      description:
          'Troopers has [stats.motivation]% to become Elite after doing critical attack on their target.',
      targets: ['Trooper'],
      iconRow: 0,
      iconCol: 4,
      rankBonuses: [
        '10% chance to become Elite after a critical hit.',
        '25% chance to become Elite after a critical hit.',
      ],
      rankStatSnippets: [
        'motivation = 10%',
        'motivation = 25%',
      ],
    ),
  ],
  [
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECC1',
      title: 'Precision',
      description: 'All your Troopers will do [stats.damage] additional direct damage.',
      targets: ['Trooper'],
      iconRow: 1,
      iconCol: 0,
      rankBonuses: [
        'Trooper direct damage +1.',
        'Trooper direct damage +2.',
      ],
      rankStatSnippets: [
        'damage = 1',
        'damage = 2',
      ],
    ),
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECD2',
      title: 'First-Aid Mastery',
      description:
          "Surgeons' First-Aid has additional [stats.bandage_crit]% chance to heal for double amount.",
      targets: ['Surgeon'],
      iconRow: 1,
      iconCol: 1,
      rankBonuses: [
        'First-Aid double-heal chance +10%.',
        'First-Aid double-heal chance +20%.',
        'First-Aid double-heal chance +30%.',
      ],
      rankStatSnippets: [
        'bandage_crit = 10%',
        'bandage_crit = 20%',
        'bandage_crit = 30%',
      ],
    ),
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECD1',
      title: 'Barrier Armor',
      description:
          "Lord Commander's has [stats.armor] additional armor and hit points.",
      targets: ['Commander'],
      iconRow: 1,
      iconCol: 2,
      rankBonuses: [
        'Commander: hit points +25%, armor +25%.',
      ],
      rankStatSnippets: [
        'hp = 25%, armor = 25%',
      ],
    ),
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECC2',
      title: 'Overtraining',
      description: 'All your Officers have [stats.hp] more hit points.',
      targets: ['Assassin', 'Surgeon', 'Judge', 'Constructor'],
      iconRow: 1,
      iconCol: 3,
      rankBonuses: [
        'Officer hit points +5%.',
        'Officer hit points +10%.',
        'Officer hit points +25%.',
      ],
      rankStatSnippets: [
        'hp = 5%',
        'hp = 10%',
        'hp = 25%',
      ],
    ),
    HumanSpecTreeNode(
      repo: 'HUMAN_SPECD3',
      title: 'Power Surge',
      description:
          "Your Lord Commander and all your Officers' power will restore [stats.psi_gen] faster.",
      targets: ['Commander', 'Assassin', 'Surgeon', 'Judge', 'Constructor'],
      iconRow: 1,
      iconCol: 4,
      rankBonuses: [
        'Power regeneration +30%.',
      ],
      rankStatSnippets: [
        'psi_gen = 30%',
      ],
    ),
  ],
];

/// Filas visuales 2-3-2-3 (A1–A2 | B1–B3 | C1–C2 | D1–D3).
const List<List<String>> humanSpecTreeVisualRowRepos = [
  ['HUMAN_SPECA1', 'HUMAN_SPECA2'],
  ['HUMAN_SPECB1', 'HUMAN_SPECB2', 'HUMAN_SPECB3'],
  ['HUMAN_SPECC1', 'HUMAN_SPECD2'],
  ['HUMAN_SPECD1', 'HUMAN_SPECC2', 'HUMAN_SPECD3'],
];

final Map<String, HumanSpecTreeNode> humanSpecTreeByRepo =
    Map<String, HumanSpecTreeNode>.unmodifiable({
  for (final row in humanSpecTreeGrid)
    for (final n in row) n.repo: n,
});
