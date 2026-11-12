import 'package:flutter/material.dart';

import '../features/dictionary/ui/search_screen.dart';
import '../features/home/home_screen.dart';

/// Top-level sections: Player (videos), Reader (light novels, not built yet)
/// and Dictionary (look up any word). Bottom bar on phones, a rail on wide screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;

  static const _sections = [
    (
      icon: Icons.movie_outlined,
      selected: Icons.movie,
      label: 'Player',
      ready: true,
    ),
    (
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book,
      label: 'Reader',
      ready: false,
    ),
    (
      icon: Icons.translate_outlined,
      selected: Icons.translate,
      label: 'Dictionary',
      ready: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Both tabs stay alive, so a half-typed search or picked video survives switching.
    final body = IndexedStack(
      index: _index,
      children: const [HomeScreen(), SizedBox.shrink(), SearchScreen()],
    );
    void select(int i) => setState(() => _index = i);
    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.9,
                destinations: [
                  for (final s in _sections)
                    NavigationRailDestination(
                      icon: Icon(s.icon),
                      selectedIcon: Icon(s.selected),
                      label: Text(
                        s.ready ? s.label : '${s.label}\nWIP',
                        textAlign: TextAlign.center,
                      ),
                      disabled: !s.ready,
                    ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: [
          for (final s in _sections)
            NavigationDestination(
              icon: Icon(s.icon),
              selectedIcon: Icon(s.selected),
              label: s.ready ? s.label : '${s.label} (soon)',
              enabled: s.ready,
              tooltip: s.ready ? null : 'Light novel reader: coming soon',
            ),
        ],
      ),
    );
  }
}
