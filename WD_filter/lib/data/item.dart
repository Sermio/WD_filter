class Item {
  final int id;
  final int lootTable;
  final String map;
  final String droppedBy;
  final String name;
  final String rarity;
  final String race;
  final String slot;
  final Map<String, Map<String, String>>
      attributes; // Cambiado a Map<String, Map<String, String>>

  Item({
    required this.id,
    required this.lootTable,
    required this.map,
    required this.droppedBy,
    required this.name,
    required this.rarity,
    required this.race,
    required this.slot,
    required this.attributes,
  });

  // Convertir a un mapa para actualizar Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lootTable': lootTable,
      'name': name,
      'map': map,
      'droppedBy': droppedBy,
      'rarity': rarity,
      'race': race,
      'slot': slot,
      'attributes':
          attributes, // Ahora atributos es un Map<String, Map<String, String>>
    };
  }

  // Factory para crear un 'Item' desde un Map (por ejemplo, desde Firestore o JSON)
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      lootTable: json['lootTable'] as int,
      map: json['map'] as String,
      droppedBy: json['droppedBy'] as String,
      name: json['name'] as String,
      rarity: json['rarity'] as String,
      race: json['race'] as String,
      slot: json['slot'] as String,
      attributes: Map<String, Map<String, String>>.from(json['attributes'] ??
          {}), // Adaptado para Map<String, Map<String, String>>
    );
  }
}

// Lista de tropas clasificadas por raza y en lowercase.
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
