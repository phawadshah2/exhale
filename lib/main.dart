import 'package:exhale/app/app.dart';
import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.setupDependencies();
  // Loads the glass shaders so the first frame doesn't show the fallback.
  await LiquidGlass.precache();
  runApp(
    ProviderScope(
      overrides: await startupOverrides(),
      child: const ExhaleApp(),
    ),
  );
}
