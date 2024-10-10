import 'package:flutter/material.dart';
import 'package:adv_basics/utils/rarity_colors.dart';

class Ccard extends StatelessWidget {
  final dynamic cardElement;

  const Ccard({Key? key, required this.cardElement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = cardElement?.img.startsWith('http') ||
        cardElement?.img.startsWith('https');
    final imageWidget = isNetworkImage
        ? Image.network(
            cardElement?.img,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          )
        : Image.asset(
            'assets/images/worldshift/items/${cardElement?.img}.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error);
            },
          );

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contenido de texto
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  cardElement?.name ?? 'No Name',
                  style: TextStyle(
                    color: RarityColors.getColor(cardElement?.rarity ?? ''),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Ubicación
                Text(
                  cardElement?.location ?? 'No Location',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(
                    height: 8), // Espacio entre la ubicación y la imagen
              ],
            ),
          ),
          // Imagen con ícono condicional
          if (cardElement?.img != null) // Solo muestra la imagen si no es nula
            GestureDetector(
              onTap: () {
                _showImageDialog(context, imageWidget);
              },
              child: Stack(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8.0), // Margen inferior
                    child: SizedBox(
                      width: double.infinity, // Ancho máximo disponible
                      height: 150, // Altura fija para la imagen
                      child: imageWidget,
                    ),
                  ),
                  if (cardElement?.bis)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Icon(
                        Icons.star, // Puedes cambiar el ícono aquí
                        color: Colors.yellow[700],
                        size: 34,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, Widget imageWidget) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            children: [
              InteractiveViewer(
                child: imageWidget,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
