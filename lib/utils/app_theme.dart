import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg           = Color(0xFFF0F4FF);
  static const Color bgCard       = Color(0xFFFFFFFF);
  static const Color bgCard2      = Color(0xFFE8EEFF);
  static const Color primary      = Color(0xFF2A3F7E);
  static const Color primaryLight = Color(0xFF3D5AA8);
  static const Color gold         = Color(0xFFC9A84C);
  static const Color goldLight    = Color(0xFFE2C47A);
  static const Color green        = Color(0xFF00C896);
  static const Color red          = Color(0xFFFF4757);
  static const Color textPrimary  = Color(0xFF1A2340);
  static const Color textSecondary= Color(0xFF8896B3);
  static const Color border       = Color(0xFFDDE4F5);

  static const Color darkBg       = Color(0xFF0D1117);
  static const Color darkCard     = Color(0xFF161B22);
  static const Color darkCard2    = Color(0xFF21262D);
  static const Color darkBorder   = Color(0xFF30363D);
  static const Color darkText     = Color(0xFFE6EDF3);
  static const Color darkTextSub  = Color(0xFF8B949E);

  static ThemeData buildTheme(Brightness brightness, Color themeColor) {
    final isDark = brightness == Brightness.dark;
    final lighter = _lighten(themeColor, 0.15);
    return ThemeData(
      fontFamily: 'Tajawal',
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? darkBg : bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: themeColor,
        onPrimary: Colors.white,
        secondary: green,
        onSecondary: Colors.white,
        surface: isDark ? darkCard : bgCard,
        onSurface: isDark ? darkText : textPrimary,
        error: red,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal', fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? darkText : Colors.white,
        ),
        iconTheme: IconThemeData(color: isDark ? darkText : Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard2 : bgCard2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? darkBorder : border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? darkBorder : border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: themeColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: red)),
        hintStyle: TextStyle(color: isDark ? darkTextSub : textSecondary, fontFamily: 'Tajawal'),
        prefixIconColor: isDark ? darkTextSub : textSecondary,
      ),
    );
  }

  // Legacy static themes (default blue) for backwards compat
  static ThemeData get lightTheme => buildTheme(Brightness.light, primary);
  static ThemeData get darkTheme  => buildTheme(Brightness.dark, primary);

  static LinearGradient gradientFor(Color c) => LinearGradient(
    colors: [c, _lighten(c, 0.15)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldLight],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static BoxDecoration glassCard(bool isDark) => BoxDecoration(
    color: isDark ? darkCard : bgCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: isDark ? darkBorder : border),
    boxShadow: isDark ? [] : [
      BoxShadow(color: primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
    ],
  );

  static Color _lighten(Color c, double amount) => Color.fromARGB(
    c.alpha,
    (c.red + (255 - c.red) * amount).round().clamp(0, 255),
    (c.green + (255 - c.green) * amount).round().clamp(0, 255),
    (c.blue + (255 - c.blue) * amount).round().clamp(0, 255),
  );
}
