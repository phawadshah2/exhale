import 'package:exhale/app/app.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.setupDependencies();
  runApp(const ProviderScope(child: ExhaleApp()));
}
