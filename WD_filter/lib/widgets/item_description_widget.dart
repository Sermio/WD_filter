import 'package:flutter/material.dart';

class ItemDescription extends StatelessWidget {
  const ItemDescription({super.key});

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
              child: const Text(
                'Pinhole Rifle "Widowmaker"',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Subheader with the technology
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.grey.shade800,
              child: const Text(
                '(Nanotechnology)',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            // Attributes
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trooper',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '+3 Damage\n+3 Armor',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Judge',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '+9% Power',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Battle points cost: ' '90',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'This item is related to Nanotechnology, one of\nthe scientific disciplines of the Humans.',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                    fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
