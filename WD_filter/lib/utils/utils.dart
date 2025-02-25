import 'dart:io';
import 'package:adv_basics/data/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

List<Item> itemsFile1 = [];
List<Item> itemsFile2 = [];

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

    // Ajuste del regex para que el tercer grupo (ID) sea solo números con al menos 5 dígitos
    RegExp regex = RegExp(r'^(\d+)\s+(.+?)\s+(\d{5,})\s+(.+?)$');
    Match? match = regex.firstMatch(line);

    if (match != null) {
      try {
        int lootTable = int.parse(match.group(1) ?? '0');
        String itemLocation = match.group(2) ?? '';
        int itemId = int.parse(match.group(3) ?? '0');
        String itemName = match.group(4) ?? '';

        itemsFile1.add(Item(
          id: itemId,
          lootTable: lootTable,
          location: itemLocation,
          name: itemName,
          rarity: '',
          race: '',
          slot: '',
          attributes: {},
        ));
      } catch (e) {
        print('Error al procesar la línea: $line');
      }
    }
  }
}

// Parsear atributos de una cadena
Map<String, String> parseAttributes(String attributes) {
  attributes = cleanString(attributes).trim();
  if (attributes.isEmpty) return {};

  Map<String, String> attributesMap = {};
  List<String> attributePairs = attributes.split(',');

  for (var pair in attributePairs) {
    List<String> parts = pair.split(':');
    if (parts.length == 2) {
      attributesMap[parts[0].trim()] = parts[1].trim();
    }
  }

  return attributesMap;
}

// Función para leer el segundo archivo (formato 2)
Future<void> parseLootFile2(String path) async {
  String fileContent = await loadFileFromAssets(path);
  List<String> lines = fileContent.split(RegExp(r'\r?\n'));

  itemsFile2.clear(); // Limpiar antes de llenarla

  for (var line in lines) {
    print('Línea 2: $line');
    RegExp regex =
        RegExp(r'^(\d+)\s+(\d+)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.*)$');
    Match? match = regex.firstMatch(line);

    if (match != null) {
      int itemId = int.parse(match.group(1) ?? '0');
      String rarity = match.group(3) ?? '';
      String race = match.group(4) ?? '';
      String slot = match.group(5) ?? '';
      String attributes = match.group(7) ?? '';

      itemsFile2.add(Item(
        id: itemId,
        lootTable: 0,
        location: '',
        name: '',
        rarity: rarity,
        race: race,
        slot: slot,
        attributes: parseAttributes(attributes),
      ));
    }
  }
}

// Función para combinar la información de ambos archivos
Future<List<Item>> combineLootData(String pathFile1, String pathFile2) async {
  await parseLootFile1(pathFile1);
  await parseLootFile2(pathFile2);

  // Crear un mapa para mapear los elementos de itemsFile2 por id
  Map<int, Item> itemMapFile2 = {};
  for (var item in itemsFile2) {
    itemMapFile2[item.id] = item;
  }

  List<Item> combinedItems = [];

  for (var item1 in itemsFile1) {
    var matchingItem = itemMapFile2[item1.id]; // Buscar en el mapa por id

    // Si no se encuentra una coincidencia en el segundo archivo, usar valores predeterminados
    if (matchingItem != null) {
      combinedItems.add(Item(
        id: item1.id,
        lootTable: item1.lootTable,
        location: item1.location,
        name: item1.name,
        rarity: matchingItem.rarity,
        race: matchingItem.race,
        slot: matchingItem.slot,
        attributes: matchingItem.attributes,
      ));
    } else {
      // Si no hay coincidencia, agregar un Item con datos del primer archivo
      combinedItems.add(Item(
        id: item1.id,
        lootTable: item1.lootTable,
        location: item1.location,
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
        'location': item.location,
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
      await uploadItemsToFirebase(combinedItems);
      print('Todos los items han sido subidos correctamente.');
    } else {
      print('No se encontraron items para subir.');
    }
  } catch (e) {
    print('Error procesando y subiendo los items: $e');
  }
}
