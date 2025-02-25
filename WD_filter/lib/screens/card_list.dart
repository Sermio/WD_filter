import 'package:adv_basics/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardListScreen extends StatelessWidget {
  const CardListScreen({super.key});

  Future<String> loadFileFromAssets(String path) async {
    final data =
        await rootBundle.load(path); // Cargar el archivo desde los assets
    final bytes = data.buffer.asUint8List();
    return String.fromCharCodes(bytes); // Convertir los bytes en un string
  }

  // Esta es la función que se llama cuando el botón es presionado
  Future<void> _uploadItems(BuildContext context) async {
    try {
      // Llamar a la función para procesar el archivo y subir a Firestore
      // await processFileAndUpload();
      await processAndUploadItems(
        'assets/tsvFiles/loot.txt',
        'assets/tsvFiles/items_extra_data.txt',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos subidos correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh),
          onPressed: () => _uploadItems(context)),
      appBar: AppBar(title: const Text('Card List')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .snapshots(), // Escucha los cambios en la colección
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var itemData = items[index].data() as Map<String, dynamic>;
              int id = itemData['id'] ?? 'No ID';
              String location = itemData['location'] ?? 'No location';
              String name = itemData['name'] ?? 'No name';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(location),
                  leading: const Icon(Icons.label),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    // Acción al hacer clic en la tarjeta
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Clicked on $name')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
