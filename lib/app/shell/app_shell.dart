import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.spa),
            selectedIcon: Icon(Symbols.spa, fill: 1),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Symbols.settings),
            selectedIcon: Icon(Symbols.settings, fill: 1),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
