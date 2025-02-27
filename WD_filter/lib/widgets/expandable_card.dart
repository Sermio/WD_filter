import 'package:adv_basics/utils/utils.dart';
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
            leading: widget.itemData['slot'] == 'ALIEN_MASTER'
                ? SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/worldshift/items/item.png',
                          scale: 1.4,
                          width: 60,
                          height: 60,
                        ),
                        const BorderRarityColor(),
                        Image.asset(
                          'assets/images/items/humans/sprite_5_2.png',
                          width: 60,
                          height: 60,
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/worldshift/items/item_sample.png',
                          scale: 1.4,
                          width: 60,
                          height: 60,
                        ),
                        const BorderRarityColor(),
                        Image.asset(
                          'assets/images/items/humans/sprite_5_2.png',
                          width: 60,
                          height: 60,
                        ),
                      ],
                    ),
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

class BorderRarityColor extends StatelessWidget {
  const BorderRarityColor({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 5.5,
      left: 8,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade700,
              Colors.transparent,
            ],
            stops: const [0.07, 0.2],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.purple.shade700,
                Colors.transparent,
              ],
              stops: const [0.07, 0.2],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.purple.shade700,
                  Colors.transparent,
                ],
                stops: const [0.07, 0.2],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.purple.shade700,
                    Colors.transparent,
                  ],
                  stops: const [0.07, 0.2],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
