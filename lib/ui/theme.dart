import 'package:flutter/material.dart';

import '../models/theme_color.dart';

// MiliConfig v2.0.0 Design System — Bettbox-inspired calm opaque surfaces,
// high-contrast crisp typography, and modern Android 15/16 page motion.

const kHeroRadius = 24.0;
const kCardRadius = 18.0;
const kSmallCardRadius = 14.0;
const kDialogRadius = 24.0;
const kMenuRadius = 16.0;
const kInputRadius = 14.0;

RoundedSuperellipseBorder roundedShape(
  double radius, {
  BorderSide side = BorderSide.none,
}) => RoundedSuperellipseBorder(
  borderRadius: BorderRadius.circular(radius),
  side: side,
);

const kFieldGap = 16.0;
const kRangeDashGap = 12.0;

ThemeData buildTheme(Brightness brightness, ThemeColor color) {
  final isDark = brightness == Brightness.dark;
  final baseScheme = ColorScheme.fromSeed(
    seedColor: color.seed,
    brightness: brightness,
  );

  final scheme = isDark
      ? baseScheme.copyWith(
          primary: color.seed,
          onPrimary: const Color(0xFF0A1016),
          primaryContainer: Color.alphaBlend(
            color.seed.withValues(alpha: 0.18),
            color.darkCard,
          ),
          onPrimaryContainer: const Color(0xFFF2F5FA),
          secondary: color.accent,
          onSecondary: const Color(0xFF0A1016),
          secondaryContainer: Color.alphaBlend(
            color.accent.withValues(alpha: 0.14),
            color.darkCard,
          ),
          onSecondaryContainer: const Color(0xFFE7ECF4),
          surface: color.darkBg,
          surfaceContainerLowest: color.darkBg,
          surfaceContainerLow: color.darkSurface,
          surfaceContainer: color.darkCard,
          surfaceContainerHigh: const Color(0xFF252B35),
          surfaceContainerHighest: const Color(0xFF2D3440),
          onSurface: const Color(0xFFF2F4F8),
          onSurfaceVariant: const Color(0xFFA2ACB9),
          outline: const Color(0xFF3A4250),
          outlineVariant: const Color(0xFF2A303C),
        )
      : baseScheme.copyWith(
          primary: color.seed == const Color(0xFF34D399)
              ? const Color(0xFF0F8B5D)
              : color.seed,
          surface: const Color(0xFFF4F6FA),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFEDF1F7),
          surfaceContainer: Colors.white,
          surfaceContainerHigh: const Color(0xFFE6ECF4),
          surfaceContainerHighest: const Color(0xFFDCE4EE),
          onSurface: const Color(0xFF141820),
          onSurfaceVariant: const Color(0xFF566070),
          outline: const Color(0xFFC6CFDC),
          outlineVariant: const Color(0xFFE0E6EF),
        );

  final inputDecoration = InputDecorationTheme(
    filled: true,
    fillColor: isDark ? const Color(0xFF232833) : const Color(0xFFEDF1F7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kInputRadius),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kInputRadius),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kInputRadius),
      borderSide: BorderSide(color: scheme.primary, width: 1.5),
    ),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'OpenSans',
    scaffoldBackgroundColor: isDark ? color.darkBg : scheme.surface,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? color.darkBg : scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: scheme.onSurface,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
    ),
    cardTheme: CardThemeData(
      shape: roundedShape(
        kCardRadius,
        side: BorderSide(color: scheme.outlineVariant, width: 0.9),
      ),
      color: scheme.surfaceContainer,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      shape: roundedShape(
        kDialogRadius,
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerHigh,
      shape: roundedShape(
        kMenuRadius,
        side: BorderSide(color: scheme.outlineVariant, width: 0.9),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: roundedShape(14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: roundedShape(14),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.primaryContainer,
      shape: roundedShape(12),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    inputDecorationTheme: inputDecoration,
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: inputDecoration,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 0.75,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF252B36) : const Color(0xFF1A1F29),
      contentTextStyle: const TextStyle(color: Color(0xFFF2F4F8)),
      shape: roundedShape(14),
    ),
  );
}
