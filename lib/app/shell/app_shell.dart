import 'dart:async';

import 'package:exhale/app/shell/log_hint.dart';
import 'package:exhale/app/shell/page_visits.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/liquid_glass.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/log_flow.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_menu.dart';
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

  /// One habit: log it. Several: pick which in the menu.
  void _onLog(BuildContext context, WidgetRef ref, Rect anchor) {
    final habitId = ref.read(singleHabitIdProvider);
    if (habitId != null) {
      unawaited(_logAndHint(context, ref, habitId));
    } else {
      unawaited(showLogMenu(context, ref, anchor: anchor));
    }
  }

  /// After the first saved log with one habit, explains the + button's menu.
  Future<void> _logAndHint(
    BuildContext context,
    WidgetRef ref,
    int habitId,
  ) async {
    final logged = await logNow(context, ref, habitId: habitId);
    if (!logged || !context.mounted) return;
    if (ref.read(currentSettingsProvider).logHintSeen) return;
    await ref
        .read(settingsActionsProvider)
        .update((s) => s.copyWith(logHintSeen: true));
    if (!context.mounted) return;
    await showLogHint(context);
  }

  void _showLogMenu(BuildContext context, WidgetRef ref, Rect anchor) =>
      unawaited(showLogMenu(context, ref, anchor: anchor));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void bumpVisit(int tab) => ref.read(pageVisitProvider(tab).notifier).bump();

    return ShellReturnListener(
      onReturn: () => bumpVisit(navigationShell.currentIndex),
      child: Scaffold(
        // Lets pages scroll behind the floating bar; Scaffold reports the
        // bar's height as bottom padding to the body.
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: FloatingTabBar(
          tabs: _tabs,
          currentIndex: navigationShell.currentIndex,
          onSelected: (index) {
            // Coming back to a tab replays its entrance animations.
            if (index != navigationShell.currentIndex) bumpVisit(index);
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          onLog: (anchor) => _onLog(context, ref, anchor),
          onLogMenu: (anchor) => _showLogMenu(context, ref, anchor),
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
  final ValueChanged<Rect> onLog;
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

  final ValueChanged<Rect> onTap;
  final ValueChanged<Rect> onLongPress;

  static Rect _anchor(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }

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
          onTap: () => onTap(_anchor(context)),
          onLongPress: () => onLongPress(_anchor(context)),
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
