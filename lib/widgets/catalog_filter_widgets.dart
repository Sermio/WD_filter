import 'package:flutter/material.dart';

/// App bar con el mismo gradiente que ítems / unidades (sin imagen de banner).
class CatalogListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CatalogListAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  static const _gradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF667eea),
        Color(0xFF764ba2),
        Color(0xFFf093fb),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      flexibleSpace: Container(decoration: _gradient),
      actions: actions,
    );
  }
}

/// Search field styled like filter TypeAheads: flat white, gray border, light shadow.
class CatalogSearchBar extends StatelessWidget {
  const CatalogSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF667eea),
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade600,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

/// Contenedor del panel de filtros (como el bloque blanco de ítems).
class CatalogFilterPanel extends StatelessWidget {
  const CatalogFilterPanel({
    super.key,
    required this.child,
    this.maxHeight = 320,
  });

  final Widget child;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        children: [child],
      ),
    );
  }
}

/// Mismo comportamiento que [MultiSelectChip] en ítems: Humans / Tribes / Aliens.
class RaceFilterToggleButtons extends StatelessWidget {
  const RaceFilterToggleButtons({
    super.key,
    required this.selectedRaces,
    required this.onChanged,
  });

  final List<String> selectedRaces;
  final ValueChanged<List<String>> onChanged;

  static const labels = ['Humans', 'Tribes', 'Aliens'];

  static const _labelToRaceFolder = {
    'Humans': 'humans',
    'Tribes': 'mutants',
    'Aliens': 'aliens',
  };

  /// Carpetas `raceFolder` del catálogo a partir de las etiquetas seleccionadas.
  static List<String> raceFoldersFromLabels(List<String> labels) {
    return labels
        .map((l) => _labelToRaceFolder[l])
        .whereType<String>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColors = [
      Colors.blue,
      Colors.orange.shade800,
      Colors.greenAccent.shade700,
    ];
    final isSelected =
        labels.map((l) => selectedRaces.contains(l)).toList();

    return Center(
      child: ToggleButtons(
        isSelected: isSelected,
        onPressed: (int index) {
          final next = List<String>.from(selectedRaces);
          final label = labels[index];
          if (next.contains(label)) {
            next.remove(label);
          } else {
            next.add(label);
          }
          onChanged(next);
        },
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        fillColor: Colors.grey.shade200,
        color: Colors.black,
        constraints: const BoxConstraints(minHeight: 36, minWidth: 76),
        children: List.generate(labels.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              labels[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected[index]
                    ? selectedColors[index]
                    : Colors.black,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Tipo de habilidad: todas / pasivas / activas (un solo valor).
class AbilityKindToggleButtons extends StatelessWidget {
  const AbilityKindToggleButtons({
    super.key,
    required this.kind,
    required this.onChanged,
  });

  /// '' = todas, 'passive', 'active'
  final String kind;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['All', 'Passive', 'Active'];
    final isSelected = [
      kind.isEmpty,
      kind == 'passive',
      kind == 'active',
    ];

    return Center(
      child: ToggleButtons(
        isSelected: isSelected,
        onPressed: (index) {
          onChanged(['', 'passive', 'active'][index]);
        },
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        fillColor: Colors.grey.shade200,
        color: Colors.black,
        constraints: const BoxConstraints(minHeight: 36, minWidth: 68),
        children: labels
            .map(
              (l) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  l,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Botón «Limpiar filtros» con gradiente (como en ítems).
class CatalogClearFiltersButton extends StatelessWidget {
  const CatalogClearFiltersButton({
    super.key,
    required this.onPressed,
    this.label = 'Clear filters',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.clear_all, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
