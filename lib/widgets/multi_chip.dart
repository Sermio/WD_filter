import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:worldshift_assistant/widgets/catalog_filter_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Misma selección múltiple de raza que en ítems: Humans / Tribes / Aliens (sin bosses).
class MultiSelectChip extends StatelessWidget {
  const MultiSelectChip({
    super.key,
    required this.labels,
  });

  /// Reservado por compatibilidad; el toggle usa [RaceFilterToggleButtons.labels].
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        return RaceFilterToggleButtons(
          selectedRaces: filterProvider.selectedRaces,
          onChanged: filterProvider.setSelectedRaces,
          includeBosses: false,
        );
      },
    );
  }
}
