class Item {
  final int id;
  final int lootTable;
  final String location;
  final String name;
  final String rarity;
  final String race;
  final String slot;
  final Map<String, String> attributes; // Cambiado a Map<String, String>

  Item({
    required this.id,
    required this.lootTable,
    required this.location,
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
      'location': location,
      'rarity': rarity,
      'race': race,
      'slot': slot,
      'attributes': attributes, // Ya no se necesita el .toMap()
    };
  }

  // Factory para crear un 'Item' desde un Map (por ejemplo, desde Firestore o JSON)
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      lootTable: json['lootTable'] as int,
      location: json['location'] as String,
      name: json['name'] as String,
      rarity: json['rarity'] as String,
      race: json['race'] as String,
      slot: json['slot'] as String,
      attributes: Map<String, String>.from(json['attributes'] ?? {}),
    );
  }
}
