import 'package:worldshift_filters/utils/utils.dart'; // Asegúrate de importar el archivo donde tienes las funciones
import 'package:flutter/material.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  // Esta es la función que se llama cuando el botón es presionado
  Future<void> _uploadItems(BuildContext context) async {
    try {
      // Llamar a la función para procesar el archivo y subir a Firestore
      // await processFileAndUpload();
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
      appBar: AppBar(
        title: const Text('Subir Items'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _uploadItems(
              context), // Corregido para que se ejecute al presionar
          child: const Text('Subir Items a Firestore'),
        ),
      ),
    );
  }
}
