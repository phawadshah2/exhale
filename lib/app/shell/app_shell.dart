import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    FloatingTab(
      icon: AppIcons.home,
      selectedIcon: AppIcons.homeSelected,
      label: 'Home',
    ),
    FloatingTab(
      icon: AppIcons.settings,
      selectedIcon: AppIcons.settingsSelected,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lets pages scroll behind the floating bar; Scaffold reports the bar's
      // height as bottom padding to the body.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: FloatingTabBar(
        tabs: _tabs,
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class FloatingTab {
  const FloatingTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Centered glass capsule with icon-only tabs and a sliding selection pill.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final List<FloatingTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const double _tabWidth = 76;
  static const double _height = 56;
  static const double _inset = 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          heightFactor: 1,
          child: GlassSurface(
            child: Padding(
              padding: const EdgeInsets.all(_inset),
              child: SizedBox(
                width: _tabWidth * tabs.length,
                height: _height - _inset * 2,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      left: currentIndex * _tabWidth,
                      top: 0,
                      bottom: 0,
                      width: _tabWidth,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: colors.primaryContainer.withValues(
                            alpha: 0.18,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < tabs.length; i++)
                          _TabButton(
                            tab: tabs[i],
                            width: _tabWidth,
                            selected: i == currentIndex,
                            onTap: () {
                              if (i != currentIndex) {
                                unawaited(HapticFeedback.selectionClick());
                              }
                              onSelected(i);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final FloatingTab tab;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: Tooltip(
        message: tab.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: width,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  key: ValueKey(selected),
                  size: 24,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
