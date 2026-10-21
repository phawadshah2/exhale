import 'package:exhale/app/router/app_router.dart';
import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExhaleApp extends ConsumerWidget {
  const ExhaleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppPalette.accentAt(
      ref.watch(currentSettingsProvider.select((s) => s.accentIndex)),
    ).color;
    return MaterialApp.router(
      title: 'Exhale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(Brightness.light, accent: accent),
      darkTheme: AppTheme.of(Brightness.dark, accent: accent),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      // Glass follows the iOS Reduce Transparency setting.
      builder: (context, child) => GlassMode(
        enabled: !(ref.watch(reduceTransparencyProvider).value ?? false),
        child: child!,
      ),
    );
  }
}
