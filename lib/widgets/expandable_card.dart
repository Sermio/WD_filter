import 'package:worldshift_filters/utils/utils.dart';
import 'package:worldshift_filters/widgets/item_description_widget.dart';
import 'package:flutter/material.dart';

class ExpandableCard extends StatefulWidget {
  final String name;
  final String map;
  final String rarity;
  final String obtainedFrom;
  final Map<String, dynamic> itemData;

  const ExpandableCard({
    Key? key,
    required this.name,
    required this.map,
    required this.rarity,
    required this.obtainedFrom,
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
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.name,
              style: TextStyle(
                  color: getRarityColor(widget.itemData['rarity']),
                  fontWeight: FontWeight.bold),
            ),
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
            leading: ItemCompleteFrame(
              slot: widget.itemData['slot'],
              race: widget.itemData['race'],
              rarity: widget.rarity,
            ),
            trailing: GestureDetector(
              child: const Icon(Icons.info_outline),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      widget.name,
                      style: TextStyle(
                          color: getRarityColor(widget.itemData['rarity']),
                          fontWeight: FontWeight.bold),
                    ),
                    content: SingleChildScrollView(
                      child: ItemDescription(
                          itemName: widget.name,
                          rarity: widget.rarity,
                          slot: widget.itemData['slot'],
                          obtainedFrom: widget.obtainedFrom,
                          attributes: widget.itemData['attributes']),
                    ),
                    // content: Column(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     Text(widget.itemData['map']),
                    //     Text(widget.itemData['race']),
                    //     Text(widget.itemData['rarity']),
                    //     Text(widget.itemData['slot']),
                    //   ],
                    // ),
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
                obtainedFrom: widget.obtainedFrom,
                attributes: widget.itemData['attributes'],
              ),
            ),
        ],
      ),
    );
  }
}

class ItemCompleteFrame extends StatelessWidget {
  final String slot;
  final String race;
  final String rarity;

  const ItemCompleteFrame({
    super.key,
    required this.slot,
    required this.race,
    required this.rarity,
  });

  @override
  Widget build(BuildContext context) {
    final String basePath = getImagePath(race);

    return Container(
      width: 62,
      height: 62,
      color: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            color: Colors.white,
            child: Image.asset(
              'assets/images/items/$basePath/${slot.toUpperCase()}.png',
              scale: 1.5,
              width: 60,
              height: 60,
              cacheWidth: 60,
              cacheHeight: 60,
              fit: BoxFit.contain,
              colorBlendMode: BlendMode.multiply,
            ),
          ),
          BorderRarityColor(
            rarity: rarity,
          ),
          Center(
            child: Image.asset(
              'assets/images/items/$basePath/${slot.toUpperCase()}_frame.png',
              width: 62,
              height: 62,
              cacheWidth: 62,
              cacheHeight: 62,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class BorderRarityColor extends StatelessWidget {
  final String rarity;

  const BorderRarityColor({
    super.key,
    required this.rarity,
  });

  @override
  Widget build(BuildContext context) {
    // Completamente transparente - sin efecto de color
    return const SizedBox.shrink();
  }
}
