import 'package:worldshift_assistant/utils/utils.dart';
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
          borderRadius: BorderRadius.circular(10),
          color: Colors.black.withOpacity(0.75),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black,
              ),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent, // Muy claro y transparente
                    Colors.grey.shade300
                        .withOpacity(0.4), // Gris claro y menos transparente
                    Colors.grey.shade300
                        .withOpacity(0.45), // Gris claro y menos transparente
                    Colors.grey.shade300
                        .withOpacity(0.4), // Gris claro y menos transparente
                    Colors.transparent, // Transparente hacia la derecha
                  ],
                  stops: const [
                    0.0,
                    0.3,
                    0.5,
                    0.7,
                    1.0
                  ], // Define en qué punto cambia el color
                ),
              ),
              child: Text(
                '(${getSlotValueOrDescription(slot)})',
                style: const TextStyle(
                  color: Colors.black,
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
                            return Row(
                              children: [
                                Text(
                                  '${innerEntry.value.startsWith('-') ? innerEntry.value : '+${innerEntry.value}'}',
                                  style: TextStyle(
                                    color: Colors.lightGreenAccent.shade400,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  ' ${getAttributeValue(innerEntry.key)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1.5,
                                            0.0), // La distancia de la sombra
                                        blurRadius:
                                            0.0, // Difusión de la sombra
                                        color:
                                            Colors.black, // Color de la sombra
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
