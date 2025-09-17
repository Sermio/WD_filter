import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/item_description_widget.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              widget.name,
              style: TextStyle(
                color: getRarityColor(widget.itemData['rarity']),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                (widget.map.isNotEmpty &&
                        widget.itemData['obtainedFrom'] != null &&
                        widget.itemData['obtainedFrom'].isNotEmpty)
                    ? "${widget.map} - ${widget.itemData['obtainedFrom']}"
                    : widget.map.isNotEmpty
                        ? widget.map
                        : widget.itemData['obtainedFrom']?.isNotEmpty ?? false
                            ? widget.itemData['obtainedFrom']
                            : 'Unknown',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            leading: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ItemCompleteFrame(
                slot: widget.itemData['slot'],
                race: widget.itemData['race'],
                rarity: widget.rarity,
              ),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 20,
                      title: Text(
                        widget.name,
                        style: TextStyle(
                            color: getRarityColor(widget.itemData['rarity']),
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      content: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade50,
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: ItemDescription(
                              itemName: widget.name,
                              rarity: widget.rarity,
                              slot: widget.itemData['slot'],
                              obtainedFrom: widget.obtainedFrom,
                              attributes: widget.itemData['attributes']),
                        ),
                      ),
                      actions: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
