import 'package:adv_basics/utils/utils.dart';
import 'package:flutter/material.dart';

class ItemDescription extends StatelessWidget {
  final String itemName;
  final String rarity;
  final String slot;
  final String obtainedFrom;
  final Map<String, dynamic> attributes;

  const ItemDescription({
    super.key,
    required this.itemName,
    required this.rarity,
    required this.slot,
    this.obtainedFrom = '',
    required this.attributes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade900,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black,
              child: Text(
                itemName,
                style: TextStyle(
                  color: getRarityColor(rarity),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.grey.shade800,
              child: Text(
                '(${getSlotValueOrDescription(slot)})',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: attributes.entries.map((entry) {
                  final value = entry.value;

                  if (value is Map<String, dynamic>) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getUnitValue(entry.key),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: value.entries.map((innerEntry) {
                            return Text(
                              '${getAttributeValue(innerEntry.key)}: ${innerEntry.value.startsWith('-') ? innerEntry.value : '+${innerEntry.value}'}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 14,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        const Divider(
                          color: Color.fromARGB(229, 52, 51, 51),
                        ),
                      ],
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '${entry.key}: $value',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                }).toList(),
              ),
            ),
            if (obtainedFrom.toLowerCase().contains('pvp'))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Text(
                      'Battle points cost: ',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(255, 234, 223, 178)),
                    ),
                    Text(
                      getItemPrice(rarity),
                      style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(255, 255, 0, 1)),
                    )
                  ],
                ),
              ),
            // const SizedBox(height: 8),
            const Divider(
              color: Color.fromARGB(229, 52, 51, 51),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                getSlotValueOrDescription(slot, getDescription: true),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
