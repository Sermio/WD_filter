import 'package:flutter/material.dart';
import 'package:worldshift_assistant/screens/abilities_list_screen.dart';
import 'package:worldshift_assistant/screens/builder_screen.dart';
import 'package:worldshift_assistant/screens/card_list.dart';
import 'package:worldshift_assistant/screens/units_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// Solo la pestaña visible puede tener foco en descendientes. Si no, los
  /// [TextField] de otras pestañas (siguen montadas en [IndexedStack]) pueden
  /// robar foco y abrir el teclado al pulsar botones en Builder u otras vistas.
  Widget _tabShell(int tabIndex, Widget child) {
    final active = _index == tabIndex;
    return Focus(
      canRequestFocus: active,
      descendantsAreFocusable: active,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _tabShell(0, const CardListScreen()),
          _tabShell(1, const UnitsListScreen()),
          _tabShell(2, const AbilitiesListScreen()),
          _tabShell(3, const BuilderScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Items',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Units',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Abilities',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Builder',
          ),
        ],
      ),
    );
  }
}
