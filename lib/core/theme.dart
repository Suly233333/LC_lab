import 'package:flutter/material.dart';

/// L-Corp 风格主题定义。
///
/// 原作复刻配色（黄黑大色块）：
/// - 主背景（Background）：纯黑 #000000
/// - 主色 / 强调（Primary / Accent）：警示黄 #FFD700
/// - 次级表面（Surface）：暗黑 #0A0A0A
/// - 警告 / 活跃（Alert / Active）：突破红 #E53935
/// - 主文字（onBackground）：警示黄 #FFD700
class AppColors {
  AppColors._();

  /// 主背景色：纯黑（原作机密档案底色）。
  static const Color background = Color(0xFF000000);

  /// 主强调色：警示黄（脑叶公司经典 Caution Yellow）。
  static const Color primary = Color(0xFFFFD700);

  /// 次级表面色：极暗灰（接近黑）。
  static const Color surface = Color(0xFF0A0A0A);

  /// 警告 / 活跃色：突破红（Qliphoth 警报色）。
  static const Color alert = Color(0xFFE53935);

  /// 主文字色：警示黄（与 primary 相同）。
  static const Color onBackground = Color(0xFFFFD700);

  /// 次要文字 / 提示文字：暗黄。
  static const Color hint = Color(0xFFB8A14A);

  /// 危险 / 错误：深红。
  static const Color danger = Color(0xFFB71C1C);

  /// 网格线色：半透明暗黄。
  static const Color gridLine = Color(0x33FFD700);

  /// 机密遮盖斜纹底色：警示黄 / 纯黑交替（原作 Caution 警示带）。
  static const Color cautionStripe = Color(0xFFFFD700);
  static const Color cautionStripeAlt = Color(0xFF000000);
}

/// L-Corp App 全局主题。
class AppTheme {
  AppTheme._();

  /// 等宽终端字体族（系统等宽字体回退栈）。
  static const String monoFontFamily = 'monospace';

  /// 全局圆角半径（原作风格：直角，几乎无圆角）。
  static const double cornerRadius = 0.0;

  /// 较小圆角（用于标签 / chip）。
  static const double smallRadius = 0.0;

  /// 全局 BorderRadius（直角）。
  static const BorderRadius borderRadius = BorderRadius.zero;

  /// 应用 ThemeData。
  static ThemeData get themeData {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.alert,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.onBackground,
      error: AppColors.danger,
      onError: Colors.white,
    );

    final TextTheme textTheme = const TextTheme(
      displayLarge: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      headlineLarge: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
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
        color: AppColors.onBackground,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
      labelMedium: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.onBackground,
        letterSpacing: 0.8,
      ),
      labelSmall: TextStyle(
        fontFamily: monoFontFamily,
        color: AppColors.hint,
        letterSpacing: 0.6,
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
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          fontFamily: monoFontFamily,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 2.0,
        ),
        shape: Border(
          bottom: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.primary, width: 1),
          borderRadius: BorderRadius.zero,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.primary.withValues(alpha: 0.4),
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
            letterSpacing: 1.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          textStyle: const TextStyle(
            fontFamily: monoFontFamily,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: monoFontFamily,
            letterSpacing: 0.8,
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
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
          borderRadius: borderRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
          borderRadius: borderRadius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
          borderRadius: borderRadius,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surface,
        circularTrackColor: AppColors.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: const TextStyle(
          fontFamily: monoFontFamily,
          color: AppColors.onBackground,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.primary, width: 1),
          borderRadius: borderRadius,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.primary, width: 1),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
