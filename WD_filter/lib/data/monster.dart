const String imagePlaceholder =
    'https://imgs.search.brave.com/0pPNMnJms3MKXS7Ak8s4BJzk95qHhrP2ePTdPQSsLBA/rs:fit:860:0:0/g:ce/aHR0cHM6Ly9hc3Nl/dHNpby5nbndjZG4u/Y29tL3BhbGljby5q/cGc_d2lkdGg9Njkw/JnF1YWxpdHk9NzUm/Zm9ybWF0PWpwZyZh/dXRvPXdlYnA';

class Monster {
  final int id;
  final String name;
  final String type;
  final String species;
  final String description;
  final List<Weakness> weaknesses;
  final List<Reward> rewards;
  final String img;

  Monster({
    required this.id,
    required this.name,
    required this.type,
    required this.species,
    required this.description,
    required this.weaknesses,
    required this.rewards,
    required this.img,
  });

  factory Monster.fromJson(Map<String, dynamic> json) {
    return Monster(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        species: json['species'],
        description: json['description'],
        weaknesses: (json['weaknesses'] as List<dynamic>)
            .map((weaknessJson) => Weakness.fromJson(weaknessJson))
            .toList(),
        rewards: (json['rewards'] as List<dynamic>)
            .map((rewardJson) => Reward.fromJson(rewardJson))
            .toList(),
        img:
            'https://monsterhunterworld.wiki.fextralife.com/file/Monster-Hunter-World/mhw-${json['name'].toString().toLowerCase().replaceAll(' ', '_')}_render_001.png' // Proporcionar una URL de marcador de posición si no hay URL
        );
  }
}

class Weakness {
  final String element;
  final int stars;
  final String? condition;

  Weakness({
    required this.element,
    required this.stars,
    this.condition,
  });

  factory Weakness.fromJson(Map<String, dynamic> json) {
    return Weakness(
      element: json['element'],
      stars: json['stars'],
      condition: json['condition'],
    );
  }
}

class Reward {
  final int id;
  final Item item;
  final List<Condition> conditions;

  Reward({
    required this.id,
    required this.item,
    required this.conditions,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      item: Item.fromJson(json['item']),
      conditions: (json['conditions'] as List<dynamic>)
          .map((conditionJson) => Condition.fromJson(conditionJson))
          .toList(),
    );
  }
}

class Item {
  final int id;
  final String name;
  final String description;
  final int rarity;
  final int carryLimit;
  final int value;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.carryLimit,
    required this.value,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      rarity: json['rarity'],
      carryLimit: json['carryLimit'],
      value: json['value'],
    );
  }
}

class Condition {
  final String type;
  final String? subtype;
  final String rank;
  final int quantity;
  final int chance;

  Condition({
    required this.type,
    this.subtype,
    required this.rank,
    required this.quantity,
    required this.chance,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      type: json['type'],
      subtype: json['subtype'],
      rank: json['rank'],
      quantity: json['quantity'],
      chance: json['chance'],
    );
  }
}
