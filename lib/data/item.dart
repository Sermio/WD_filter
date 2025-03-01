class Item {
  final int id;
  final int lootTable;
  final String map;
  final String obtainedFrom;
  final String name;
  final String rarity;
  final String race;
  final String slot;
  final Map<String, Map<String, String>> attributes;

  Item({
    required this.id,
    required this.lootTable,
    required this.map,
    required this.obtainedFrom,
    required this.name,
    required this.rarity,
    required this.race,
    required this.slot,
    required this.attributes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lootTable': lootTable,
      'name': name,
      'map': map,
      'obtainedFrom': obtainedFrom,
      'rarity': rarity,
      'race': race,
      'slot': slot,
      'attributes': attributes,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      lootTable: json['lootTable'] as int,
      map: json['map'] as String,
      obtainedFrom: json['obtainedFrom'] as String,
      name: json['name'] as String,
      rarity: json['rarity'] as String,
      race: json['race'] as String,
      slot: json['slot'] as String,
      attributes:
          Map<String, Map<String, String>>.from(json['attributes'] ?? {}),
    );
  }
}

final List<String> unitsFlat = [
  'Commander',
  'Assassin',
  'Constructor',
  'Judge',
  'Surgeon',
  'Trooper',
  'Ripper',
  'AssaultBot',
  'Hellfire',
  'HighPriest',
  'Guardian',
  'Shaman',
  'Sorcerer',
  'StoneGhost',
  'Warrior',
  'Brute',
  'AncientShade',
  'HowlingHorror',
  'Master',
  'Arbiter',
  'Dominator',
  'Harvester',
  'Manipulator',
  'Trisat',
  'Tritech',
  'Shifter',
  'Overseer',
];
