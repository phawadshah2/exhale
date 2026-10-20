import 'package:exhale/core/theme/app_color_scheme.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/app_typography.dart';
import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => of(Brightness.light);
  static ThemeData get dark => of(Brightness.dark);

  static final _cache = <(Brightness, Color), ThemeData>{};

  /// Cached per brightness and accent: seeding a scheme isn't free.
  static ThemeData of(
    Brightness brightness, {
    Color accent = AppPalette.eucalyptus,
  }) => _cache.putIfAbsent((
    brightness,
    accent,
  ), () => build(brightness, accent: accent));

  static ThemeData build(
    Brightness brightness, {
    Color accent = AppPalette.eucalyptus,
  }) {
    final colors = buildColorScheme(brightness: brightness, accent: accent);
    final text = AppTypography.textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    final isDark = brightness == Brightness.dark;

    // Cards sit one step above the page: slate in dark, white in light.
    final cardColor = isDark
        ? colors.surfaceContainerLow
        : colors.surfaceContainerLowest;
    final hairline = BorderSide(color: colors.outlineVariant);
    const pill = StadiumBorder();
    const buttonSize = Size.fromHeight(56);

    return ThemeData(
      brightness: brightness,
      colorScheme: colors,
      textTheme: text,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: colors.surface,
      extensions: [ExhaleColors.fromScheme(colors)],
      // iOS conventions: no ink ripples, swipe-back page transitions.
      splashFactory: NoSplash.splashFactory,
      highlightColor: colors.onSurface.withValues(alpha: 0.06),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        // Light cards float on the page without an outline, iOS style.
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: isDark ? hairline : BorderSide.none,
        ),
      ),
      // Primary CTA: solid accent pill ("Start my plan").
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          // Opaque so a disabled floating button doesn't show content behind.
          disabledBackgroundColor: colors.surfaceContainerHighest,
          disabledForegroundColor: colors.onSurfaceVariant.withValues(
            alpha: 0.6,
          ),
          minimumSize: buttonSize,
          shape: pill,
          textStyle: text.titleMedium,
          iconSize: 22,
        ),
      ),
      // Secondary / ghost pill ("Adjust reduction pace").
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surfaceContainerHigh,
          foregroundColor: colors.onSurface,
          minimumSize: buttonSize,
          shape: pill,
          side: hairline,
          textStyle: text.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        selectedColor: colors.primaryContainer,
        checkmarkColor: colors.onPrimaryContainer,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: colors.onPrimaryContainer,
        ),
        side: hairline,
        shape: pill,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primaryContainer,
        indicatorShape: pill,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceContainerHighest,
        contentTextStyle: text.bodyMedium,
        actionTextColor: colors.primary,
        shape: pill,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimaryContainer
              : colors.outline,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(
        color: hairline.color,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        iconColor: colors.onSurfaceVariant,
      ),
    );
  }
}
