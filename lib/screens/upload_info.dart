import 'package:flutter/material.dart';
import 'package:worldshift_assistant/data/worldshift_assets.dart';
import 'package:worldshift_assistant/utils/utils.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _uploadFirebase = false;
  bool _writeExcel = true;
  bool _busy = false;
  String? _lastLog;

  Future<void> _runPipeline() async {
    setState(() {
      _busy = true;
      _lastLog = null;
    });
    try {
      final r = await processAndUploadItems(
        pathFile1: WorldshiftAssets.lootTableFile,
        pathFile2: WorldshiftAssets.itemsDefinitionFile,
        uploadToFirebase: _uploadFirebase,
        writeExcel: _writeExcel,
      );
      if (!mounted) return;
      setState(() {
        _lastLog =
            'Ítems combinados: ${r.itemCount}. Líneas drop.tsv: ${r.dropLineCount}.'
            '${r.uploaded ? ' Subido a Firestore.' : ''}'
            '${r.excelPath != null ? ' Excel: ${r.excelPath}' : ''}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.itemCount > 0
                ? 'Pipeline completado (${r.itemCount} ítems).'
                : 'No se obtuvieron ítems; revisa los assets.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline Worldshift'),
        backgroundColor: const Color(0xFF764ba2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Combina loot + definiciones de ítem desde assets, opcionalmente '
            'exporta Excel y sube la colección `items` a Firestore.',
            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            'Archivos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '· ${WorldshiftAssets.lootTableFile}\n'
            '· ${WorldshiftAssets.itemsDefinitionFile}\n'
            '· ${WorldshiftAssets.dropFile} (validado en pantalla Loot)',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Subir a Firestore'),
            subtitle: const Text('Colección "items" (requiere Firebase inicializado)'),
            value: _uploadFirebase,
            onChanged: _busy
                ? null
                : (v) => setState(() => _uploadFirebase = v),
          ),
          SwitchListTile(
            title: const Text('Generar Excel'),
            subtitle: const Text('items_history.xlsx en Descargas'),
            value: _writeExcel,
            onChanged: _busy ? null : (v) => setState(() => _writeExcel = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _runPipeline,
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_busy ? 'Procesando…' : 'Ejecutar pipeline'),
          ),
          if (_lastLog != null) ...[
            const SizedBox(height: 24),
            Text(
              _lastLog!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Unidades: ejecuta en consola\n'
            'dart run tool/generate_worldshift_assets.dart',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
