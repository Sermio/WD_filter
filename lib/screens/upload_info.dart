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
            'Combined items: ${r.itemCount}. drop.tsv lines: ${r.dropLineCount}.'
            '${r.uploaded ? ' Uploaded to Firestore.' : ''}'
            '${r.excelPath != null ? ' Excel: ${r.excelPath}' : ''}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.itemCount > 0
                ? 'Pipeline finished (${r.itemCount} items).'
                : 'No items produced; check assets.',
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
        title: const Text('Worldshift pipeline'),
        backgroundColor: const Color(0xFF764ba2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Merge loot + item definitions from assets; optionally export Excel '
            'and upload the `items` collection to Firestore.',
            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            'Files',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '· ${WorldshiftAssets.lootTableFile}\n'
            '· ${WorldshiftAssets.itemsDefinitionFile}\n'
            '· ${WorldshiftAssets.dropFile} (validated on Loot screen)',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Upload to Firestore'),
            subtitle: const Text(
              '"items" collection (requires initialized Firebase)',
            ),
            value: _uploadFirebase,
            onChanged: _busy
                ? null
                : (v) => setState(() => _uploadFirebase = v),
          ),
          SwitchListTile(
            title: const Text('Generate Excel'),
            subtitle: const Text('items_history.xlsx in Downloads'),
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
            label: Text(_busy ? 'Running…' : 'Run pipeline'),
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
            'Units: run in terminal\n'
            'dart run tool/generate_worldshift_assets.dart',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
