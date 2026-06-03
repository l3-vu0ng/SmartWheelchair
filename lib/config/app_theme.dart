import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// [AppTheme] — Design System cho SmartWheel
/// ============================================================================
/// Bảng màu lấy cảm hứng từ UI mockup: nền trắng sạch, accent xanh dương,
/// card trắng bo tròn với shadow nhẹ. Font Inter thay thế SF Pro.
/// ============================================================================
class AppTheme {
  AppTheme._();

  // ===========================================================================
  // 1. BRAND & ACCENT COLORS
  // ===========================================================================

  /// Xanh dương chính — accent toàn hệ thống (Vibrant Blue).
  static const Color primaryBlue = Color(0xFF2563EB);

  /// Xanh dương đậm — gradient hero card.
  static const Color primaryBlueDark = Color(0xFF1D4ED8);

  /// Xanh dương nhạt — background nhẹ cho badge, icon container.
  static const Color primaryBlueLight = Color(0xFFDBEAFE);

  /// Xanh dương rất nhạt — highlight card được chọn.
  static const Color primaryBlueOutline = Color(0xFF93C5FD);

  // ===========================================================================
  // 2. SURFACE COLORS
  // ===========================================================================

  static const Color canvasWhite = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  // ===========================================================================
  // 3. TEXT COLORS
  // ===========================================================================

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFAAAAAA);

  // ===========================================================================
  // 4. SEMANTIC COLORS
  // ===========================================================================

  static const Color statusOnline = Color(0xFF34C759);
  static const Color statusOffline = Color(0xFFFF3B30);
  static const Color statusConnecting = Color(0xFFFFCC00);
  static const Color warningOrange = Color(0xFFFF9500);

  // ===========================================================================
  // 5. BORDERS & DIVIDERS
  // ===========================================================================

  static const Color borderLight = Color(0xFFE8E8ED);
  static const Color divider = Color(0xFFF0F0F0);

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
  // 7. TYPOGRAPHY
  // ===========================================================================

  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: textSecondary,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get labelBold => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get valueLg => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get valueMd => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  // ===========================================================================
  // 8. CARD DECORATION HELPER
  // ===========================================================================

  /// Decoration chuẩn cho card — bo tròn, shadow nhẹ, nền trắng.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: pureBlack.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Decoration cho card được chọn/highlight.
  static BoxDecoration get cardSelectedDecoration => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: primaryBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Decoration cho Glassmorphism.
  static BoxDecoration get glassmorphismDecoration => BoxDecoration(
        color: canvasWhite.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(radiusXl),
        border: Border.all(color: canvasWhite.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: pureBlack.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ===========================================================================
  // 9. THEME DATA
  // ===========================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        onPrimary: textOnPrimary,
        secondary: primaryBlueLight,
        onSecondary: primaryBlue,
        surface: canvasWhite,
        onSurface: textPrimary,
        error: statusOffline,
        onError: canvasWhite,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: canvasWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: headlineMd,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderLight, width: 0.5),
        ),
        margin: const EdgeInsets.all(spacingXs),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: canvasWhite,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: canvasWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 24),
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
    );
  }
}
