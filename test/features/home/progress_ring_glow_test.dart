import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/home/presentation/widgets/progress_ring.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/no_glow.dart';

void main() {
  testWidgets('a filling ring has no halo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ProgressRing(
            progress: DailyProgress(
              day: LogicalDay(2026, 10, 16),
              count: 3,
              limit: 9,
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));

    final ring = tester.renderObject(
      find
          .descendant(
            of: find.byType(ProgressRing),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

    expect(ring, paints..arc());
    expect(ring, paintsWithoutBlur);
  });
}
