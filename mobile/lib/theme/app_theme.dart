import 'package:flutter/material.dart';

class AppTheme {
  static const Color brand = Color(0xFF663D90);
  static const Color accent = Color(0xFFF1A559);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
      primary: brand,
      secondary: accent,
      surface: const Color(0xFFFFFFFF),
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
      primary: const Color(0xFFB99BE6),
      secondary: const Color(0xFFF8C68A),
      surface: const Color(0xFF12141A),
    );
    return _base(scheme, Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final fill = isDark ? const Color(0xFF1B1F29) : const Color(0xFFF7F8FC);
    final border = isDark ? const Color(0xFF2A3040) : const Color(0xFFE3E7F0);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Cairo',
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F1116) : const Color(0xFFF4F6FB),
      canvasColor: isDark ? const Color(0xFF12141A) : Colors.white,
      dividerColor: isDark ? const Color(0xFF272C36) : const Color(0xFFE7EAF1),
      cardColor: isDark ? const Color(0xFF161A22) : Colors.white,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF141823) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF141A24),
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF141A24),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF141A24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(
          color: isDark ? Colors.white60 : const Color(0xFF80889A),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1E2430) : const Color(0xFF202534),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF171B24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF171B24) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF171B24) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? Colors.white70 : const Color(0xFF444B5A),
        textColor: isDark ? Colors.white : const Color(0xFF1C2230),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.primary.withValues(alpha: 0.18),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return isDark ? Colors.white70 : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary.withValues(alpha: 0.4);
          return isDark ? Colors.white24 : Colors.black12;
        }),
      ),
    );
  }
}

