import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/design_system/presentation/design_system_page.dart';
import 'package:exhale/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExhaleApp extends ConsumerWidget {
  const ExhaleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Exhale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Temporary home until the splash and tabs are built.
      home: const DesignSystemPage(),
    );
  }
}
