import 'package:flutter/material.dart';

/// L-Corp 风格主题定义。
///
/// 配色规范：
/// - 主背景（Background）：深蓝 #1A2A3A
/// - 主色 / 强调（Primary / Accent）：工业蓝灰 #6E8AA6
/// - 次级表面（Surface）：深蓝灰 #233447
/// - 警告 / 活跃（Alert / Active）：警报红 #E53935
class AppColors {
  AppColors._();

  /// 主背景色：深蓝。
  static const Color background = Color(0xFF1A2A3A);

  /// 主强调色：工业蓝灰。
  static const Color primary = Color(0xFF6E8AA6);

  /// 次级表面色：深蓝灰（比背景略浅）。
  static const Color surface = Color(0xFF233447);

  /// 警告 / 活跃色：警报红。
  static const Color alert = Color(0xFFE53935);

  /// 主文字色（在深色背景上的亮色文字）。
  static const Color onBackground = Color(0xFFD7E3EE);

  /// 次要文字 / 提示文字。
  static const Color hint = Color(0xFF7A8A98);

  /// 危险 / 错误（突破警报深红边缘）。
  static const Color danger = Color(0xFFB71C1C);

  /// 网格线色：半透明蓝灰网格。
  static const Color gridLine = Color(0x336E8AA6);

  /// 机密遮盖斜纹底色：警报红 / 深蓝交替。
  static const Color cautionStripe = Color(0xFFE53935);
  static const Color cautionStripeAlt = Color(0xFF1A2A3A);
}

/// L-Corp App 全局主题。
class AppTheme {
  AppTheme._();

  /// 等宽终端字体族（系统等宽字体回退栈）。
  static const String monoFontFamily = 'monospace';

  /// 应用 ThemeData。
  static ThemeData get themeData {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.alert,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.onBackground,
      error: AppColors.danger,
      onError: AppColors.onBackground,
    );

    final TextTheme textTheme = const TextTheme(
      displayLarge: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      headlineLarge: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
      ),
      bodyLarge: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
      ),
      bodyMedium: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
      ),
      bodySmall: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.hint,
      ),
      labelLarge: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      labelMedium: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
        letterSpacing: 1.2,
      ),
      labelSmall: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.hint,
        letterSpacing: 1.0,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: monoFontFamily,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.primary, width: 1),
          borderRadius: BorderRadius.zero,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.primary,
        thickness: 0.5,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontFamily: monoFontFamily,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontFamily: monoFontFamily,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: monoFontFamily,
            letterSpacing: 1.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          fontFamily: monoFontFamily,
          color: AppColors.hint,
        ),
        labelStyle: const TextStyle(
          fontFamily: monoFontFamily,
          color: AppColors.primary,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.alert, width: 2),
          borderRadius: BorderRadius.zero,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surface,
        circularTrackColor: AppColors.surface,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(
          fontFamily: monoFontFamily,
          color: AppColors.primary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.primary, width: 1),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
