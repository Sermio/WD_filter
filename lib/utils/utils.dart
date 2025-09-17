import 'dart:io';
import 'dart:ui';
import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/data/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Incluye Vector2
import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

List<Item> itemsFile1 = [];
List<Item> itemsFile2 = [];
Set<String> attributeKeys = {};
Set<String> mapsSet = {};
Set<String> slotsSet = {};
Set<String> namesSet = {};
Set<int> lootTableSet = {};

String getAttributeValue(String key) {
  return attributeList.firstWhere(
    (attribute) => attribute['key'] == key,
    orElse: () => {'value': 'Unknown Attribute'},
  )['value']!;
}

String capitalizeFirstLetterOfEachWord(String input) {
  // Si el string contiene 2 o más palabras
  if (input.split(' ').length >= 2) {
    return input.split(' ').map((word) {
      // Cambia la primera letra de cada palabra por mayúscula
      return word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '';
    }).join(' ');
  }
  // Si no contiene 2 o más palabras, retorna el string original
  return input;
}

String getUnitValue(String key) {
  final unit = units.firstWhere(
    (unit) => unit['key'] == key,
    orElse: () => {
      'key': key,
      'value': key
    }, // En caso de que no lo encuentre, devuelve el mismo key.
  );
  return unit['value'] ??
      key; // Si no encuentra el valor, devuelve el mismo key.
}

String getSlotValueOrDescription(String key, {bool getDescription = false}) {
  return slots.firstWhere(
    (slot) => slot['key'] == key,
    orElse: () => {'value': 'Unknown', 'description': 'Unknown'},
  )[getDescription ? 'description' : 'value']!;
}

String cleanString(String input) {
  return input.replaceAll(RegExp(r'[^\x00-\x7F]'), "'");
}

Color getRarityColor(String value) {
  switch (value) {
    case "1":
      return const Color.fromARGB(255, 142, 147, 156);
    case "2":
      return const Color.fromARGB(255, 104, 191, 72);
    case "3":
      return const Color.fromARGB(255, 236, 211, 21);
    case "4":
      return const Color.fromARGB(255, 219, 149, 49);
    case "5":
      return const Color.fromARGB(255, 109, 10, 144);
    default:
      return const Color.fromARGB(255, 120, 122, 128);
  }
}

String rarityToString(String rarity) {
  switch (rarity) {
    case '1':
      return 'Very Common';
    case '2':
      return 'Common';
    case '3':
      return 'Uncommon';
    case '4':
      return 'Rare';
    case '5':
      return 'Legendary';
    default:
      return 'Unknown';
  }
}

String getItemPrice(String rarity) {
  switch (rarity) {
    case '1':
      return '6';
    case '2':
      return '15';
    case '3':
      return '39';
    case '4':
      return '50';
    case '5':
      return '90';
    default:
      return '-';
  }
}

String getImagePath(String race) {
  race = race.toLowerCase();

  if (race.contains('aliens')) {
    return 'aliens';
  } else if (race.contains('humans')) {
    return 'humans';
  } else if (race.contains('tribes')) {
    return 'tribes';
  }
  return 'humans';
}

Future<String> loadFileFromAssets(String path) async {
  final data = await rootBundle.load(path);
  final bytes = data.buffer.asUint8List();
  return String.fromCharCodes(bytes);
}

Future<void> parseLootFile1(String path) async {
  String fileContent = await loadFileFromAssets(path);
  List<String> lines = fileContent.split(RegExp(r'\r?\n'));

  itemsFile1.clear();

  for (var line in lines) {
    if (line.trim().isEmpty) continue;
    print('Línea 1: $line');

    RegExp regex = RegExp(r'^(\d+)\s+(.+?)\s+(\d{5,})\s+(.+?)$');
    Match? match = regex.firstMatch(line);

    if (match != null) {
      try {
        int lootTable = int.parse(match.group(1) ?? '0');
        String location = match.group(2) ?? '';
        int itemId = int.parse(match.group(3) ?? '0');
        String itemName = match.group(4) ?? '';

        String map = '';
        String obtainedFrom = '';

        bool isMapFound = false;
        for (var mapEntry in maps) {
          if (location.startsWith(mapEntry['key']!)) {
            map = mapEntry['key']!;
            obtainedFrom = location
                .substring(map.length)
                .replaceFirst(RegExp(r'^[\s-]+'), '');

            isMapFound = true;
            break;
          }
        }

        if (!isMapFound) {
          map = '';
          obtainedFrom = location.replaceFirst(RegExp(r'^[\s-]+'), '');
        }

        String translatedMap = map;
        for (var mapEntry in maps) {
          if (mapEntry['key'] == map) {
            translatedMap = mapEntry['value'] ?? map;
            break;
          }
        }
        namesSet.add(itemName);

        itemsFile1.add(Item(
          id: itemId,
          lootTable: lootTable,
          map: translatedMap,
          obtainedFrom: obtainedFrom,
          name: itemName,
          rarity: '',
          race: '',
          slot: '',
          attributes: {},
        ));

        print('Mapa: $translatedMap, ObtainedFrom: $obtainedFrom');
      } catch (e) {
        print('Error al procesar la línea: $line');
      }
    }
  }
}

Map<String, Map<String, String>> parseAttributes(String attributeString) {
  Map<String, Map<String, String>> result = {};

  List<String> parts = attributeString.split(RegExp(r'\s+'));

  String currentUnit = '';

  for (int i = 0; i < parts.length; i++) {
    String part = parts[i].trim();

    if (unitsFlat.contains(part)) {
      currentUnit = part;
      result.putIfAbsent(currentUnit, () => {});
    } else if (i + 2 < parts.length && parts[i + 1] == '=') {
      String key = part;
      String value = parts[i + 2].trim();

      if (currentUnit.isNotEmpty) {
        result[currentUnit]![key] = value;
        attributeKeys.add(key);
      }

      i += 2;
    }
  }

  return result;
}

Future<void> parseLootFile2(String path) async {
  String fileContent = await loadFileFromAssets(path);
  List<String> lines = fileContent.split(RegExp(r'\r?\n'));

  itemsFile2.clear();

  for (var line in lines) {
    print('Línea 2: $line');

    RegExp regex = RegExp(r'^(\d+)\s+(\d+)\s+(.+?)\s+(\S+)\s+(.*)$');
    Match? match = regex.firstMatch(line);

    if (match != null) {
      int itemId = int.parse(match.group(1) ?? '0');
      String rarity = match.group(2) ?? '';
      String race = match.group(3) ?? '';
      String slot = match.group(4) ?? '';
      String attributes = match.group(5)?.trim() ?? '';
      slotsSet.add(slot);

      int startIndex = line.indexOf(slot) + slot.length;
      String name = '';
      String attributeString = '';

      List<String> words = line.substring(startIndex).split(RegExp(r'\s+'));
      bool foundUnit = false;

      for (var word in words) {
        if (unitsFlat.contains(word)) {
          foundUnit = true;
          break;
        }
        name += '$word ';
      }

      name = name.trim();

      if (foundUnit) {
        int nameEndIndex = line.indexOf(name) + name.length;
        attributeString = line.substring(nameEndIndex).trim();

        List<String> attributeParts = attributeString.split(RegExp(r'\s+'));
        if (attributeParts.isNotEmpty) {
          attributeParts.removeAt(0);
          attributeString = attributeParts.join(' ');
        }
      } else {
        attributeString = line.substring(startIndex).trim();
      }
      namesSet.add(name);

      itemsFile2.add(Item(
        id: itemId,
        lootTable: 0,
        map: '',
        obtainedFrom: '',
        name: name,
        rarity: rarity,
        race: race,
        slot: slot,
        attributes: parseAttributes(attributeString),
      ));
    } else {
      print('No se pudo parsear la línea: $line');
    }
  }
}

Future<List<Item>> combineLootData(String pathFile1, String pathFile2) async {
  await parseLootFile1(pathFile1);
  await parseLootFile2(pathFile2);

  Map<int, Item> itemMapFile2 = {};
  for (var item in itemsFile2) {
    itemMapFile2[item.id] = item;
  }

  List<Item> combinedItems = [];

  for (var item1 in itemsFile1) {
    var matchingItem = itemMapFile2[item1.id];

    if (matchingItem != null) {
      combinedItems.add(Item(
        id: item1.id,
        lootTable: item1.lootTable,
        map: item1.map,
        obtainedFrom: item1.obtainedFrom,
        name: item1.name,
        rarity: matchingItem.rarity,
        race: matchingItem.race,
        slot: matchingItem.slot,
        attributes: matchingItem.attributes,
      ));
    } else {
      combinedItems.add(Item(
        id: item1.id,
        lootTable: item1.lootTable,
        map: item1.map,
        obtainedFrom: item1.obtainedFrom,
        name: item1.name,
        rarity: '',
        race: '',
        slot: '',
        attributes: {},
      ));
    }
  }

  for (var item2 in itemsFile2) {
    if (!itemsFile1.any((item1) => item1.id == item2.id)) {
      combinedItems.add(Item(
        id: item2.id,
        lootTable: item2.lootTable,
        map: item2.map,
        obtainedFrom: item2.obtainedFrom,
        name: item2.name,
        rarity: item2.rarity,
        race: item2.race,
        slot: item2.slot,
        attributes: item2.attributes,
      ));
    }
  }

  return combinedItems;
}

Future<void> uploadItemsToFirebase(List<Item> items) async {
  try {
    final firestore = FirebaseFirestore.instance;

    for (var item in items) {
      Map<String, dynamic> itemData = {
        'id': item.id,
        'lootTable': item.lootTable,
        'map': item.map,
        'obtainedFrom': item.obtainedFrom,
        'name': item.name,
        'rarity': item.rarity,
        'race': item.race,
        'slot': item.slot,
        'attributes': item.attributes,
      };

      await firestore.collection('items').doc(item.id.toString()).set(itemData);
      print('Item subido correctamente: ${item.id}');
    }
  } catch (e) {
    print('Error subiendo los items: $e');
  }
}

void copySetToClipboard(Set<String> mySet) {
  // Convierte el Set en una cadena, agregando comillas simples alrededor de cada valor,
  // y reemplaza las comillas dobles por comillas simples dentro de cada valor.
  String content = mySet.map((value) {
    // Reemplaza las comillas dobles internas por comillas simples
    String sanitizedValue = value.replaceAll('"', "'");
    return '"$sanitizedValue"';
  }).join(',');

  // Copia al portapapeles
  Clipboard.setData(ClipboardData(text: content)).then((_) {
    print("¡Datos copiados al portapapeles!");
  });
}

Future<void> processAndUploadItems(String pathFile1, String pathFile2) async {
  try {
    await Firebase.initializeApp();

    List<Item> combinedItems = await combineLootData(pathFile1, pathFile2);

    if (combinedItems.isNotEmpty) {
      print(attributeKeys);
      print(mapsSet);
      print(slotsSet);
      print(lootTableSet);
      print(namesSet);
      // copySetToClipboard(namesSet);
      downloadItemsExcel(combinedItems);
      // await uploadItemsToFirebase(combinedItems);
      print(
          'Todos los items han sido subidos correctamente. Cantidad: ${combinedItems.length}');
    } else {
      print('No se encontraron items para subir.');
    }
  } catch (e) {
    print('Error procesando y subiendo los items: $e');
  }
}

Future<void> saveSpritesAsPngs() async {
  // Pedir permisos de almacenamiento (solo necesario para Android)
  if (await Permission.storage.request().isGranted) {
    // Cargar la hoja de sprites
    final image = await Flame.images.load('assets/ddsFiles/items.png');

    // Configurar el tamaño de cada sprite (62.5 x 62.5)
    const spriteWidth = 62.5;
    const spriteHeight = 62.5;

    // Calcular filas y columnas
    final columns = (image.width / spriteWidth).floor();
    final rows = (image.height / spriteHeight).floor();

    // Obtener la ruta de la carpeta de descargas
    final directory = await getExternalStorageDirectory();
    final downloadPath = Directory('${directory?.path}/Download');

    if (!await downloadPath.exists()) {
      await downloadPath.create(recursive: true);
    }

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        // Extraer cada sprite
        final sprite = Sprite(
          image,
          srcPosition: Vector2(x * spriteWidth, y * spriteHeight),
          srcSize: Vector2(spriteWidth, spriteHeight),
        );

        // Convertir el sprite en un Uint8List
        final spriteImage = await sprite.toImage();
        final byteData =
            await spriteImage.toByteData(format: ImageByteFormat.png);

        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();

          // Guardar la imagen en la carpeta de descargas
          final file = File('${downloadPath.path}/sprite_${y}_$x.png');
          await file.writeAsBytes(pngBytes);
          print('Imagen guardada: ${file.path}');
        }
      }
    }
  } else {
    print('Permisos de almacenamiento denegados.');
  }
}

Future<String> downloadItemsExcel(List<Item> items) async {
  var excel = Excel.createExcel();
  Sheet sheet = excel['Sheet1'];

  // Encabezados para las columnas
  sheet.appendRow([TextCellValue('text')]);
  sheet.appendRow([
    TextCellValue('ID'),
    TextCellValue('Loot Table'),
    TextCellValue('Map'),
    TextCellValue('Obtained From'),
    TextCellValue('Name'),
    TextCellValue('Rarity'),
    TextCellValue('Race'),
    TextCellValue('Slot'),
    TextCellValue('Attributes'),
  ]);

  // Llenar las filas con la información de cada item
  for (var item in items) {
    // Aquí se podría personalizar para incluir más detalles de los atributos si es necesario
    String attributes = '';
    item.attributes.forEach((key, value) {
      attributes += '$key: ';
      value.forEach((subKey, subValue) {
        attributes += '$subKey - $subValue; ';
      });
    });

    sheet.appendRow([
      IntCellValue(item.id),
      IntCellValue(item.lootTable),
      TextCellValue(item.map),
      TextCellValue(item.obtainedFrom),
      TextCellValue(item.name),
      TextCellValue(item.rarity),
      TextCellValue(item.race),
      TextCellValue(item.slot),
      TextCellValue(attributes),
    ]);
  }

  var status = await Permission.manageExternalStorage.request();
  if (!status.isGranted) {
    throw Exception('No se otorgaron permisos de almacenamiento.');
  }

  Directory? downloadsDirectory;
  if (Platform.isAndroid) {
    downloadsDirectory = Directory('/storage/emulated/0/Download');
  }

  if (downloadsDirectory == null) {
    throw Exception('No se pudo acceder al directorio de descargas.');
  }

  String fileName = 'items_history.xlsx';
  var file = File('${downloadsDirectory.path}/$fileName');
  await file.writeAsBytes(excel.encode()!);

  // try {
  //   final result = await Share.shareXFiles(
  //     [XFile(file.path)],
  //     text: 'Aquí está la historia de los items.',
  //   );

  //   if (result.status == ShareResultStatus.success) {
  //     print('Archivo compartido con éxito.');
  //   } else if (result.status == ShareResultStatus.dismissed) {
  //     print('El usuario descartó el compartir.');
  //   }
  // } catch (e) {
  //   print('Error al compartir el archivo: $e');
  // }

  return 'items_history.xlsx';
}
