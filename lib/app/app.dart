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
      // Text stops at 200%, Apple's bar for Larger Text: Flutter scales every
      // style alike, so past this titles grow far beyond iOS's own.
      // Glass follows the iOS Reduce Transparency setting.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 2,
        child: GlassMode(
          enabled: !(ref.watch(reduceTransparencyProvider).value ?? false),
          child: child!,
        ),
      ),
    );
  }
}
