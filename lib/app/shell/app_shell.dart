import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/liquid_glass.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/tracking/presentation/log_flow.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
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

  void _logNow(BuildContext context, WidgetRef ref) {
    final habitId = ref.read(primaryHabitProvider)?.id;
    if (habitId != null) unawaited(logNow(context, ref, habitId: habitId));
  }

  void _showLogMenu(BuildContext context, WidgetRef ref, Rect anchor) {
    final habitId = ref.read(primaryHabitProvider)?.id;
    if (habitId == null) return;
    final today = ref.read(todayProvider);
    unawaited(
      showGlassMenu(
        context,
        anchor: anchor,
        items: [
          GlassMenuItem(
            label: 'Log now',
            icon: AppIcons.add,
            onSelected: () => logNow(context, ref, habitId: habitId),
          ),
          GlassMenuItem(
            label: 'Add a missed log',
            icon: AppIcons.clock,
            onSelected: () =>
                showLogEditorSheet(context, habitId: habitId, day: today),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onLog: () => _logNow(context, ref),
        onLogMenu: (anchor) => _showLogMenu(context, ref, anchor),
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

/// Liquid Glass tab capsule with icon-only tabs, plus a round "+" log
/// button (tap logs, long-press opens a menu).
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
    required this.onLog,
    required this.onLogMenu,
    super.key,
  });

  final List<FloatingTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLog;
  final ValueChanged<Rect> onLogMenu;

  static const double _tabWidth = 76;
  static const double height = 60;
  static const double _inset = 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageMargin,
          8,
          AppSpacing.pageMargin,
          0,
        ),
        child: AppGlassLayer(
          child: Row(
            children: [
              AppGlass(
                radius: height / 2,
                child: Padding(
                  padding: const EdgeInsets.all(_inset),
                  child: SizedBox(
                    width: _tabWidth * tabs.length,
                    height: height - _inset * 2,
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
                                alpha: 0.2,
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
              const Spacer(),
              _LogButton(onTap: onLog, onLongPress: onLogMenu),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({required this.onTap, required this.onLongPress});

  final VoidCallback onTap;
  final ValueChanged<Rect> onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: 'Log',
      child: Semantics(
        button: true,
        label: 'Log',
        hint: 'Long-press for more',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: () {
            final box = context.findRenderObject()! as RenderBox;
            onLongPress(box.localToGlobal(Offset.zero) & box.size);
          },
          child: AppGlass(
            tint: colors.primaryContainer.withValues(alpha: 0.6),
            child: SizedBox.square(
              dimension: FloatingTabBar.height,
              child: Icon(
                AppIcons.add,
                size: 28,
                color: colors.onPrimaryContainer,
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
                  color: selected ? colors.primary : colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
