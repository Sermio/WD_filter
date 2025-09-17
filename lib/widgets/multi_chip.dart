import 'package:worldshift_assistant/models/item_filters_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MultiSelectChip extends StatefulWidget {
  final List<String> labels;
  const MultiSelectChip({
    super.key,
    required this.labels,
  });

  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  late List<bool> _selectedItems;
  final List<Color> selectedColors = [
    Colors.blue,
    Colors.orange.shade800,
    Colors.greenAccent.shade700
  ];

  @override
  void initState() {
    super.initState();
    _selectedItems = List.generate(widget.labels.length, (index) {
      return context
          .read<FilterProvider>()
          .selectedRaces
          .contains(widget.labels[index]);
    });
  }

  @override
  void didUpdateWidget(MultiSelectChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels != widget.labels) {
      setState(() {
        _selectedItems = List.generate(widget.labels.length, (index) {
          return context
              .read<FilterProvider>()
              .selectedRaces
              .contains(widget.labels[index]);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        _selectedItems = List.generate(widget.labels.length, (index) {
          return filterProvider.selectedRaces.contains(widget.labels[index]);
        });

        return ToggleButtons(
          isSelected: _selectedItems,
          onPressed: (int index) {
            setState(() {
              _selectedItems[index] = !_selectedItems[index];
              List<String> selectedItems = [];
              for (int i = 0; i < widget.labels.length; i++) {
                if (_selectedItems[i]) {
                  selectedItems.add(widget.labels[i]);
                }
              }
              filterProvider.setSelectedRaces(selectedItems);
            });
          },
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          fillColor: Colors.grey.shade200,
          color: Colors.black,
          constraints: const BoxConstraints(minHeight: 40.0, minWidth: 80.0),
          children: widget.labels.map((label) {
            int index = widget.labels.indexOf(label);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _selectedItems[index]
                      ? selectedColors[index]
                      : Colors.black,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
