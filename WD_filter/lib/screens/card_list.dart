import 'package:adv_basics/utils/utils.dart';
import 'package:adv_basics/widgets/item_description_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardListScreen extends StatelessWidget {
  const CardListScreen({super.key});

  Future<String> loadFileFromAssets(String path) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    return String.fromCharCodes(bytes);
  }

  Future<void> _uploadItems(BuildContext context) async {
    try {
      await processAndUploadItems(
        'assets/tsvFiles/loot_complete.txt',
        'assets/tsvFiles/items_extra_data_complete.txt',
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
        onPressed: () => _uploadItems(context),
      ),
      appBar: AppBar(title: const Text('Card List')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
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
              String name = itemData['name'] ?? 'No name';
              String map = itemData['map'] ?? 'No map';

              return ExpandableCard(
                name: name,
                map: map,
                itemData: itemData,
              );
            },
          );
        },
      ),
    );
  }
}

class ExpandableCard extends StatefulWidget {
  final String name;
  final String map;
  final Map<String, dynamic> itemData;

  const ExpandableCard({
    Key? key,
    required this.name,
    required this.map,
    required this.itemData,
  }) : super(key: key);

  @override
  _ExpandableCardState createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.name),
            subtitle: Text(widget.map),
            leading: Image.asset(
              'assets/images/worldshift/items/item_sample.png',
              width: 50,
              height: 50,
            ),
            // leading: Image.asset(
            //   'assets/images/worldshift/items/item_sample.png',
            //   width: 50,
            //   height: 50,
            // ),
            trailing: GestureDetector(
              child: const Icon(Icons.info_outline),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(widget.name),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.itemData['map']),
                        Text(widget.itemData['race']),
                        Text(widget.itemData['rarity']),
                        Text(widget.itemData['slot']),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                );
              },
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ItemDescription(
                itemName: widget.itemData['name'],
                description: 'description',
                subheader: widget.itemData['slot'],
                attributes: widget.itemData['attributes'],
              ),
              // child: Image.asset(
              //   'assets/images/worldshift/items/item1.png',
              //   fit: BoxFit.cover,
              //   height: 150,
              // ),
            ),
        ],
      ),
    );
  }
}
