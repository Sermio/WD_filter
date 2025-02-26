import 'package:adv_basics/utils/utils.dart';
import 'package:flutter/material.dart';

class ItemDescription extends StatelessWidget {
  final String itemName;
  final String slot;
  final Map<String, dynamic> attributes;
  final String description;

  const ItemDescription({
    super.key,
    required this.itemName,
    required this.slot,
    required this.attributes,
    required this.description,
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
            // Header with the item name
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black,
              child: Text(
                itemName,
                style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Slot with the technology
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
            // Attributes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: attributes.entries.map((entry) {
                  final value = entry.value;

                  // Comprobar si el valor es un mapa anidado
                  if (value is Map<String, dynamic>) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
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
                    // Si no es un mapa, mostrar el valor directamente
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
            const SizedBox(height: 8),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                getSlotValueOrDescription(description, getDescription: true),
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
