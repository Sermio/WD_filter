import 'dart:io';
import 'package:adv_basics/data/data.dart';
import 'package:adv_basics/data/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

List<Item> itemsFile1 = [];
List<Item> itemsFile2 = [];
Set<String> attributeKeys = {};
Set<String> mapsSet = {};
Set<String> slotsSet = {};
Set<int> lootTableSet = {};

String getAttributeValue(String key) {
  return attributeList.firstWhere(
    (attribute) => attribute['key'] == key,
    orElse: () => {'value': 'Unknown Attribute'},
  )['value']!;
}

String getSlotValueOrDescription(String key, {bool getDescription = false}) {
  return slots.firstWhere(
    (slot) => slot['key'] == key,
    orElse: () => {'value': 'Unknown', 'description': 'Unknown'},
  )[getDescription ? 'description' : 'value']!;
}

// Limpiar caracteres no válidos
String cleanString(String input) {
  return input.replaceAll(
      RegExp(r'[^\x00-\x7F]'), "'"); // Limpiar caracteres no ASCII
}

// Cargar archivo desde los assets
Future<String> loadFileFromAssets(String path) async {
  final data = await rootBundle.load(path);
  final bytes = data.buffer.asUint8List();
  return String.fromCharCodes(bytes);
}

// Función para leer el primer archivo (formato 1)
Future<void> parseLootFile1(String path) async {
  String fileContent = await loadFileFromAssets(path);
  List<String> lines = fileContent.split(RegExp(r'\r?\n'));

  itemsFile1.clear(); // Limpiar antes de llenarla

  for (var line in lines) {
    if (line.trim().isEmpty) continue; // Ignorar líneas vacías
    print('Línea 1: $line');

    RegExp regex = RegExp(r'^(\d+)\s+(.+?)\s+(\d{5,})\s+(.+?)$');
    Match? match = regex.firstMatch(line);

    if (match != null) {
      try {
        int lootTable = int.parse(match.group(1) ?? '0');
        String location = match.group(2) ?? '';
        int itemId = int.parse(match.group(3) ?? '0');
        String itemName = match.group(4) ?? '';

        List<String> locationParts = location.split(RegExp(r'\s+-\s*'));
        String map = locationParts.isNotEmpty ? locationParts[0] : '';
        mapsSet.add(location);
        lootTableSet.add(lootTable);
        String droppedBy = locationParts.length > 1
            ? locationParts.sublist(1).join(' ')
            : ''; // Para unir las palabras restantes

        itemsFile1.add(Item(
          id: itemId,
          lootTable: lootTable,
          map: map,
          droppedBy: droppedBy,
          name: itemName,
          rarity: '',
          race: '',
          slot: '',
          attributes: {},
        ));

        print('Mapa: $map, DroppedBy: $droppedBy');
      } catch (e) {
        print('Error al procesar la línea: $line');
      }
    }
  }
}

Map<String, Map<String, String>> parseAttributes(String attributeString) {
  Map<String, Map<String, String>> result = {};

  // Dividimos el string en partes usando espacios y saltos de línea
  List<String> parts = attributeString.split(RegExp(r'\s+'));

  String currentUnit = '';

  // Set para almacenar las claves únicas

  for (int i = 0; i < parts.length; i++) {
    String part = parts[i].trim();

    // Si encontramos una unidad válida
    if (unitsFlat.contains(part)) {
      currentUnit = part;
      result.putIfAbsent(currentUnit, () => {});
    }
    // Si encontramos un patrón de atributo "clave = valor"
    else if (i + 2 < parts.length && parts[i + 1] == '=') {
      String key = part;
      String value = parts[i + 2].trim();

      if (currentUnit.isNotEmpty) {
        result[currentUnit]![key] = value;
        attributeKeys.add(key); // Almacenamos la clave en el set
      }

      i += 2;
    }
  }

  // Escribir las claves únicas en un archivo .txt
  // print(attributeKeys.join('\n'));
  // File file = File('attribute_keys.txt');
  // file.writeAsStringSync(attributeKeys.join('\n'));

  return result;
}

Future<void> parseLootFile2(String path) async {
  String fileContent = await loadFileFromAssets(path);
  List<String> lines = fileContent.split(RegExp(r'\r?\n'));

  itemsFile2.clear();

  for (var line in lines) {
    print('Línea 2: $line');

    // Expresión regular para capturar ID, rareza, raza, slot, name y atributos
    RegExp regex = RegExp(r'^(\d+)\s+(\d+)\s+(.+?)\s+(\S+)\s+(.*)$');
    Match? match = regex.firstMatch(line);

    if (match != null) {
      int itemId = int.parse(match.group(1) ?? '0');
      String rarity = match.group(2) ?? '';
      String race = match.group(3) ?? '';
      String slot = match.group(4) ?? '';
      String attributes = match.group(5)?.trim() ?? '';
      slotsSet.add(slot);

      // Empezamos a buscar el nombre después del slot
      int startIndex = line.indexOf(slot) + slot.length;
      String name = '';
      String attributeString = '';

      // Buscamos las palabras entre el slot y el primer unit
      List<String> words = line
          .substring(startIndex)
          .split(RegExp(r'\s+')); // Divide las palabras por espacios
      bool foundUnit = false;

      for (var word in words) {
        if (unitsFlat.contains(word)) {
          // Si encontramos un unit, terminamos de capturar el nombre
          foundUnit = true;
          break;
        }
        name += '$word '; // Añadimos la palabra al nombre
      }

      name = name.trim(); // Limpiamos los posibles espacios adicionales

      // El resto es el atributo
      if (foundUnit) {
        // A partir de donde terminamos con el nombre, el resto es el atributo
        int nameEndIndex = line.indexOf(name) + name.length;
        attributeString = line.substring(nameEndIndex).trim();

        // Ahora eliminamos la primera palabra (el nombre de la unidad) de attributeString
        List<String> attributeParts = attributeString.split(RegExp(r'\s+'));
        if (attributeParts.isNotEmpty) {
          attributeParts.removeAt(0); // Elimina la primera palabra
          attributeString = attributeParts
              .join(' '); // Reconstruye el string sin la primera palabra
        }
      } else {
        // Si no encontramos un unit, todo lo que queda es el atributo
        attributeString = line.substring(startIndex).trim();
      }

      // Procesamos los atributos de la misma manera que antes
      itemsFile2.add(Item(
        id: itemId,
        lootTable: 0,
        map: '',
        droppedBy: '',
        name: name, // Nombre capturado
        rarity: rarity,
        race: race,
        slot: slot,
        attributes: parseAttributes(
            attributeString), // Procesamos los atributos correctamente
      ));
    } else {
      print('No se pudo parsear la línea: $line');
    }
  }
}

// Función para combinar la información de ambos archivos
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
        droppedBy: item1.droppedBy,
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
        droppedBy: item1.droppedBy,
        name: item1.name,
        rarity: '',
        race: '',
        slot: '',
        attributes: {},
      ));
    }
  }

  return combinedItems;
}

// Subir items a Firebase
Future<void> uploadItemsToFirebase(List<Item> items) async {
  try {
    final firestore = FirebaseFirestore.instance;

    for (var item in items) {
      Map<String, dynamic> itemData = {
        'id': item.id,
        'lootTable': item.lootTable,
        'map': item.map,
        'droppedBy': item.droppedBy,
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

// Procesar archivos y subir items a Firebase
Future<void> processAndUploadItems(String pathFile1, String pathFile2) async {
  try {
    await Firebase.initializeApp();

    List<Item> combinedItems = await combineLootData(pathFile1, pathFile2);

    if (combinedItems.isNotEmpty) {
      print(attributeKeys);
      print(mapsSet);
      print(slotsSet);
      print(lootTableSet);
      // await uploadItemsToFirebase(combinedItems);
      print('Todos los items han sido subidos correctamente.');
    } else {
      print('No se encontraron items para subir.');
    }
  } catch (e) {
    print('Error procesando y subiendo los items: $e');
  }
}
