import 'package:adv_basics/widgets/item_description_widget.dart';
import 'package:flutter/material.dart';

class ExpandableCard extends StatefulWidget {
  final String name;
  final String map;
  final String rarity;
  final Map<String, dynamic> itemData;

  const ExpandableCard({
    Key? key,
    required this.name,
    required this.map,
    required this.rarity,
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
            subtitle: Text(
              (widget.map.isNotEmpty &&
                      widget.itemData['obtainedFrom'] != null &&
                      widget.itemData['obtainedFrom'].isNotEmpty)
                  ? "${widget.map} - ${widget.itemData['obtainedFrom']}"
                  : widget.map.isNotEmpty
                      ? widget.map
                      : widget.itemData['obtainedFrom']?.isNotEmpty ?? false
                          ? widget.itemData['obtainedFrom']
                          : 'Unknown',
            ),
            leading: Image.asset(
              'assets/images/worldshift/items/item_sample.png',
              width: 50,
              height: 50,
            ),
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
                rarity: widget.itemData['rarity'],
                slot: widget.itemData['slot'],
                attributes: widget.itemData['attributes'],
              ),
            ),
        ],
      ),
    );
  }
}
