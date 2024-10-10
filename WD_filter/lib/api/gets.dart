import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:adv_basics/data/monster.dart';
import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:adv_basics/data/items.dart';
import 'package:flutter/services.dart' show rootBundle;

class MonsterApi {
  static Future<List<Monster>> fetchMonsters() async {
    final url = Uri.parse('https://mhw-db.com/monsters');

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<Monster> monsters =
          data.map((json) => Monster.fromJson(json)).toList();

      // Ordenar la lista de monstruos por nombre
      monsters.sort((a, b) => a.name.compareTo(b.name));

      return monsters;
    } else {
      throw Exception('Failed to load monsters');
    }
  }
}

class ExcelReader {
  final String fileName;

  ExcelReader(this.fileName);

  Future<List<WorldshiftItem>> readItems() async {
    try {
      // Leer el archivo desde assets
      final byteData = await rootBundle.load('assets/csvFiles/$fileName');
      final bytes = byteData.buffer.asUint8List();

      // Decodificar el archivo Excel
      var excel = Excel.decodeBytes(bytes);

      return _parseItems(excel);
    } catch (e) {
      print('Error al cargar el archivo Excel: $e');
      throw e; // Lanzar la excepción después de imprimir el error
    }
  }

  bool _parseBis(dynamic value) {
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  List<WorldshiftItem> _parseItems(Excel excel) {
    List<WorldshiftItem> items = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];

      if (sheet != null) {
        var headers = sheet.rows.first
            .map((cell) => cell?.value.toString() ?? '')
            .toList();
        for (var row in sheet.rows.skip(1)) {
          if (row.isNotEmpty) {
            try {
              // Asumiendo que las columnas son: img, name, description, rarity, location, type, race
              WorldshiftItem item = WorldshiftItem(
                img: row[headers.indexOf('img')]?.value.toString() ?? '0',
                name: row[headers.indexOf('name')]?.value.toString() ?? '',
                description:
                    row[headers.indexOf('description')]?.value.toString() ?? '',
                rarity: row[headers.indexOf('rarity')]?.value.toString() ?? '0',
                location:
                    row[headers.indexOf('location')]?.value.toString() ?? '0',
                race: row[headers.indexOf('race')]?.value.toString() ?? '0',
                type: row[headers.indexOf('type')]?.value.toString() ?? '0',
                bis: _parseBis(row[headers.indexOf('bis')]?.value.toString()),
              );
              items.add(item);
            } catch (e) {
              print('Error al parsear la fila: $e');
            }
          }
        }
      }
    }

    return items;
  }
}
