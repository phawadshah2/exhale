import 'package:exhale/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // ProviderScope stores the state of every provider in the app.
  runApp(const ProviderScope(child: ExhaleApp()));
}
