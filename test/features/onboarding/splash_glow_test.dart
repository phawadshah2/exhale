import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/onboarding/presentation/widgets/drifting_particles.dart';
import 'package:exhale/features/onboarding/presentation/widgets/splash_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/no_glow.dart';

void main() {
  testWidgets('the splash has no glow behind or around the logo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SplashScene(
            intro: AlwaysStoppedAnimation(1),
            animate: false,
          ),
        ),
      ),
    );
    await tester.pump();

    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(SplashScene),
        matching: find.byType(DecoratedBox),
      ),
    );

    expect(shadowsUnder(tester, find.byType(SplashScene)), isEmpty);
    expect(
      boxes.where(
        (box) =>
            box.decoration is BoxDecoration &&
            (box.decoration as BoxDecoration).gradient is RadialGradient,
      ),
      isEmpty,
    );
  });

  testWidgets('the dust is drawn without blur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriftingParticles(
          animation: AlwaysStoppedAnimation(0.5),
          color: Colors.teal,
        ),
      ),
    );

    final dust = tester.renderObject(
      find
          .descendant(
            of: find.byType(DriftingParticles),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    expect(dust, paints..circle());
    expect(dust, paintsWithoutBlur);
  });
}
