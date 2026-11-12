import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app icon (rounded square), for showing inside the app.
const appIconAsset = 'assets/icons/preview_rounded_square_128.png';

/// Kotohori's palette: a quiet dark "screening room" with one accent, gold —
/// what you dig up (言掘り = word digging). Light mode keeps the gold, darker.
abstract final class KColors {
  static const screen = Color(0xFF121417);
  static const surface = Color(0xFF1C1F24);
  static const raised = Color(0xFF262A31);
  static const text = Color(0xFFECEAE4);
  static const muted = Color(0xFF9A9C9F);
  static const gold = Color(0xFFE2B85C);
  static const onGold = Color(0xFF241A05);

  static const lightScreen = Color(0xFFF3F4F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFE6E8EC);
  static const lightText = Color(0xFF1B1D21);
  static const lightMuted = Color(0xFF5E6168);
  static const lightGold = Color(0xFF8A6A1F);
}

const headingFont = 'ZenKakuGothicNew';

/// Pop-up messages are a compact centred card on tablets; on phones they span
/// the width (minus margins), as a fixed width wouldn't fit.
double? snackBarWidth(Size screen) => screen.width >= 600 ? 440 : null;

/// [snackWidth]: see [snackBarWidth].
ThemeData buildTheme(Brightness brightness, {double? snackWidth}) {
  final dark = brightness == Brightness.dark;
  final gold = dark ? KColors.gold : KColors.lightGold;
  final screen = dark ? KColors.screen : KColors.lightScreen;
  final surface = dark ? KColors.surface : KColors.lightSurface;
  final raised = dark ? KColors.raised : KColors.lightRaised;
  final text = dark ? KColors.text : KColors.lightText;
  final muted = dark ? KColors.muted : KColors.lightMuted;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: KColors.gold,
        brightness: brightness,
      ).copyWith(
        primary: gold,
        onPrimary: dark ? KColors.onGold : Colors.white,
        surface: screen,
        onSurface: text,
        onSurfaceVariant: muted,
        surfaceContainerLowest: screen,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: raised,
        surfaceContainerHighest: raised,
        outlineVariant: dark
            ? const Color(0xFF30343B)
            : const Color(0xFFD9DBE0),
      );

  final base = ThemeData(colorScheme: scheme, brightness: brightness);
  TextStyle? heading(TextStyle? s) =>
      s?.copyWith(fontFamily: headingFont, fontWeight: FontWeight.w700);
  final textTheme = base.textTheme.copyWith(
    displaySmall: heading(base.textTheme.displaySmall),
    headlineMedium: heading(base.textTheme.headlineMedium),
    headlineSmall: heading(base.textTheme.headlineSmall),
    titleLarge: heading(base.textTheme.titleLarge),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: screen,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: screen,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: text),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    // Floating gold card (the app's accent), dark text, like the Play button.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      width: snackWidth,
      backgroundColor: scheme.primary,
      contentTextStyle: TextStyle(
        color: scheme.onPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: scheme.onPrimary,
      closeIconColor: scheme.onPrimary,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: surface),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      showDragHandle: true,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

/// Content is capped at [maxWidth] and centred, so lists stay readable on a
/// tablet; the bottom clears the nav bar / Samsung taskbar.
EdgeInsets pagePadding(
  BuildContext context, {
  double maxWidth = 760,
  double top = 16,
  double bottom = 24,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = math.max(16.0, (width - maxWidth) / 2);
  return EdgeInsets.fromLTRB(
    side,
    top,
    side,
    bottom + MediaQuery.paddingOf(context).bottom,
  );
}

/// A titled group of settings rows on one rounded surface.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });
  final String title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title,
              style: t.textTheme.titleSmall?.copyWith(
                color: t.colorScheme.primary,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (final (i, c) in children.indexed) ...[
                  if (i > 0) const Divider(indent: 20, endIndent: 20),
                  c,
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                footer!,
                style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
