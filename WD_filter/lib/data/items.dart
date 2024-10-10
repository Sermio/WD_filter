class WorldshiftItem {
  final String img;
  final String name;
  final String rarity;
  final String description;
  final String location;
  final String type;
  final String race;
  final bool bis;

  WorldshiftItem({
    required this.img,
    required this.name,
    required this.rarity,
    required this.description,
    required this.location,
    required this.type,
    required this.race,
    required this.bis,
  });

  factory WorldshiftItem.fromMap(Map<String, dynamic> map) {
    return WorldshiftItem(
      img: map['img'],
      name: map['name'],
      rarity: map['rarity'],
      description: map['description'],
      location: map['location'],
      type: map['type'],
      race: map['race'],
      bis: map['bis'],
    );
  }
}
