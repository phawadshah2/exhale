import 'package:flutter/material.dart';

/// Shown when access has lapsed. Filled in by a later task.
class LockedPage extends StatelessWidget {
  const LockedPage({super.key});

  static const pageKey = Key('locked-page');

  @override
  Widget build(BuildContext context) => const Scaffold(key: pageKey);
}
