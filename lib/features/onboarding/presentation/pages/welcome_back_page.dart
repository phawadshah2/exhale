import 'package:flutter/material.dart';

/// The plan reveal for a saved, unpaid plan. Filled in by a later task.
class WelcomeBackPage extends StatelessWidget {
  const WelcomeBackPage({super.key});

  static const pageKey = Key('welcome-back-page');

  @override
  Widget build(BuildContext context) => const Scaffold(key: pageKey);
}
