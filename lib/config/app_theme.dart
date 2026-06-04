import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// [AppTheme] — Design System: Ocean Mist · Light · Liquid Glass
/// ============================================================================
/// Warm off-white canvas (#FAFAF9) with Apple-style Liquid Glass
/// (glassmorphism). Single teal accent (#14B8A6). Outfit typography +
/// JetBrains Mono for numeric data. Designed for a Smart Wheelchair IoT app
/// where readability, trust, and calm confidence are paramount.
/// ============================================================================
class AppTheme {
  AppTheme._();

  // ===========================================================================
  // 1. BRAND & ACCENT COLORS — Teal Signal (single accent, saturation ~72%)
  // ===========================================================================

  /// Primary accent — CTAs, active states, focus rings, online indicators.
  static const Color tealSignal = Color(0xFF14B8A6);

  /// Darker teal for gradient endpoints, pressed states.
  static const Color tealDeep = Color(0xFF0D9488);

  /// Very light teal tint — selected backgrounds, icon containers, badges.
  static const Color tealWhisper = Color(0x1414B8A6); // ~8% opacity

  /// Subtle teal shadow tint for active glass elements.
  static const Color tealGlow = Color(0x2614B8A6); // ~15% opacity

  // Legacy aliases — keeps downstream code compiling during migration.
  static const Color primaryBlue = tealSignal;
  static const Color primaryBlueDark = tealDeep;
  static const Color primaryBlueLight = Color(0xFFCCFBF1); // teal-100 equiv
  static const Color primaryBlueOutline = Color(0xFF5EEAD4); // teal-300 equiv

  // ===========================================================================
  // 2. SURFACE COLORS
  // ===========================================================================

  /// Primary background scaffold — warm off-white, never stark #FFF.
  static const Color canvasWarm = Color(0xFFFAFAF9);

  /// Opaque card fill — standard solid cards.
  static const Color pureSurface = Color(0xFFFFFFFF);

  /// Glass surface fill — semi-transparent for Liquid Glass effect.
  static const Color glassSurface = Color(0x8CFFFFFF); // rgba(255,255,255,0.55)

  /// Glass border — catches light, 1px structural on glass panels.
  static const Color glassBorder = Color(0xA6FFFFFF); // rgba(255,255,255,0.65)

  /// Frosted overlay — bottom nav, floating elements.
  static const Color mistOverlay = Color(0xBFFAFAF9); // rgba(250,250,249,0.75)

  /// Frost highlight — inner 1px top/left edge on glass surfaces.
  static const Color frostLine = Color(0x80FFFFFF); // rgba(255,255,255,0.50)

  // Legacy aliases
  static const Color canvasWhite = pureSurface;
  static const Color scaffoldBg = canvasWarm;
  static const Color cardBg = pureSurface;

  // ===========================================================================
  // 3. TEXT COLORS
  // ===========================================================================

  /// Primary text — headlines, values. Zinc-950 depth, never pure black.
  static const Color charcoalInk = Color(0xFF18181B);

  /// Secondary text — descriptions, metadata, captions.
  static const Color mutedSteel = Color(0xFF71717A);

  /// Text on accent-filled surfaces (teal buttons, hero gradient variant).
  static const Color textOnAccent = Color(0xFFFFFFFF);

  /// Very muted text — disabled states, placeholder text.
  static const Color textMuted = Color(0xFFA1A1AA);

  // Legacy aliases
  static const Color textPrimary = charcoalInk;
  static const Color textSecondary = mutedSteel;
  static const Color textOnPrimary = textOnAccent;
  static const Color pureBlack = charcoalInk; // Never use #000000

  // ===========================================================================
  // 4. SEMANTIC COLORS
  // ===========================================================================

  /// Positive — connected, heart rate stable, system normal.
  static const Color vitalEmerald = Color(0xFF10B981);

  /// Warning — low battery, abnormal speed.
  static const Color alertAmber = Color(0xFFF59E0B);

  /// Critical — fall detection, emergency, disconnect.
  static const Color dangerCoral = Color(0xFFEF4444);

  // Legacy aliases
  static const Color statusOnline = vitalEmerald;
  static const Color statusOffline = dangerCoral;
  static const Color statusConnecting = alertAmber;
  static const Color warningOrange = alertAmber;

  // ===========================================================================
  // 5. BORDERS & DIVIDERS
  // ===========================================================================

  /// Standard card border — whisper-light structural line.
  static const Color whisperBorder = Color(0x0F000000); // rgba(0,0,0,0.06)

  /// Divider line — slightly more visible.
  static const Color divider = Color(0xFFF4F4F5);

  // Legacy aliases
  static const Color borderLight = whisperBorder;

  // ===========================================================================
  // 6. SPACING & RADIUS
  // ===========================================================================

  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusPill = 100.0;

  // ===========================================================================
  // 7. TYPOGRAPHY — Outfit (headlines+body), JetBrains Mono (numerics)
  // ===========================================================================

  static TextStyle get headlineLg => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: charcoalInk,
      );

  static TextStyle get headlineMd => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: charcoalInk,
      );

  static TextStyle get sectionLabel => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: mutedSteel,
      );

  static TextStyle get bodyLg => GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: charcoalInk,
      );

  static TextStyle get bodyMd => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: charcoalInk,
      );

  static TextStyle get bodySm => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: mutedSteel,
      );

  static TextStyle get labelBold => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: charcoalInk,
      );

  /// Large numeric value display — JetBrains Mono for tabular alignment.
  static TextStyle get valueLg => GoogleFonts.jetBrainsMono(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: charcoalInk,
      );

  /// Medium numeric value display.
  static TextStyle get valueMd => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: charcoalInk,
      );

  /// Small numeric value — sensor readings, coordinates.
  static TextStyle get valueSm => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: charcoalInk,
      );

  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedSteel,
      );

  // ===========================================================================
  // 8. CARD & GLASS DECORATION HELPERS
  // ===========================================================================

  /// Standard opaque card — white fill, whisper border, diffused shadow.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: pureSurface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: whisperBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0,0,0,0.04)
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      );

  /// Selected/highlight card — teal border accent.
  static BoxDecoration get cardSelectedDecoration => BoxDecoration(
        color: pureSurface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: tealSignal, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tealSignal.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Liquid Glass decoration — frosted translucent panel.
  /// Must be wrapped in a [ClipRRect] + [BackdropFilter] to work.
  /// The parent must have a visually interesting background (gradient, image)
  /// for the frosted effect to be visible.
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(radiusXl),
        border: Border.all(color: glassBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), // rgba(0,0,0,0.06)
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// Liquid Glass for bottom navigation bar — Floating pill.
  static BoxDecoration get glassNavigationDecoration => BoxDecoration(
        color: mistOverlay,
        borderRadius: BorderRadius.circular(radiusXl),
        border: Border.all(color: glassBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), // rgba(0,0,0,0.06)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// Legacy alias — existing code references `glassmorphismDecoration`.
  static BoxDecoration get glassmorphismDecoration => glassNavigationDecoration;

  // ===========================================================================
  // 9. GLASS WIDGET HELPER
  // ===========================================================================

  /// Wraps a child widget with the Liquid Glass effect.
  /// [sigmaX] and [sigmaY] control blur intensity (default 16).
  /// [borderRadius] defaults to [radiusXl] (20px).
  static Widget liquidGlass({
    required Widget child,
    double sigmaX = 16,
    double sigmaY = 16,
    double borderRadius = radiusXl,
    BoxDecoration? decoration,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          decoration: decoration ?? glassDecoration,
          child: child,
        ),
      ),
    );
  }

  // ===========================================================================
  // 10. ANIMATION CURVES & DURATIONS
  // ===========================================================================

  /// Premium spring-like curve for all interactive transitions.
  static const Curve premiumCurve = Curves.easeOutQuart;

  /// Standard transition duration (300ms) for micro-interactions.
  static const Duration transitionDuration = Duration(milliseconds: 300);

  /// Fast transition for nav items, color changes (200ms).
  static const Duration transitionFast = Duration(milliseconds: 200);

  /// Stagger delay for cascading card reveals.
  static const Duration staggerDelay = Duration(milliseconds: 100);

  // ===========================================================================
  // 11. THEME DATA
  // ===========================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: tealSignal,
        onPrimary: textOnAccent,
        secondary: primaryBlueLight,
        onSecondary: tealSignal,
        surface: pureSurface,
        onSurface: charcoalInk,
        error: dangerCoral,
        onError: textOnAccent,
      ),
      scaffoldBackgroundColor: canvasWarm,
      appBarTheme: AppBarTheme(
        backgroundColor: canvasWarm,
        foregroundColor: charcoalInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: headlineMd,
      ),
      cardTheme: CardThemeData(
        color: pureSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: whisperBorder, width: 1),
        ),
        margin: const EdgeInsets.all(spacingXs),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: canvasWarm,
        selectedItemColor: tealSignal,
        unselectedItemColor: mutedSteel,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealSignal,
          foregroundColor: textOnAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: mutedSteel, size: 24),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: headlineLg,
        headlineMedium: headlineMd,
        titleMedium: labelBold,
        bodyLarge: bodyLg,
        bodyMedium: bodyMd,
        bodySmall: bodySm,
        labelSmall: caption,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: tealSignal,
        inactiveTrackColor: tealSignal.withValues(alpha: 0.15),
        thumbColor: tealSignal,
        overlayColor: tealSignal.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? pureSurface
              : mutedSteel;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tealSignal
              : const Color(0xFFE4E4E7);
        }),
      ),
    );
  }
}
