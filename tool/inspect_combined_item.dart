import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/utils/utils.dart';

Future<void> main(List<String> args) async {
  final targetId = args.isNotEmpty ? int.parse(args.first) : 40000;
  final items = await combineLootData(
    WorldshiftAssets.lootTableFile,
    WorldshiftAssets.itemsDefinitionFile,
  );
  final item = items.firstWhere((entry) => entry.id == targetId);
  print('id=${item.id}');
  print('name=${item.name}');
  print('rarity=${item.rarity}');
  print('race=${item.race}');
  print('slot=${item.slot}');
  print('map=${item.map}');
  print('obtainedFrom=${item.obtainedFrom}');
  print('attributes=${item.attributes}');
}
