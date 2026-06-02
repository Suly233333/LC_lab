import 'package:flutter/material.dart';

/// L-Corp 风格主题定义。
///
/// 经典蓝白黑配色：
/// - 主背景（Background）：近黑 #0F1620（沉稳深底，比纯黑略柔和）
/// - 主色 / 强调（Primary / Accent）：经典蓝 #2D7DF6
/// - 次级表面（Surface）：深灰 #1B2330
/// - 警告 / 活跃（Alert / Active）：警报红 #E53935
/// - 主文字（onBackground）：近白 #F4F6FA
class AppColors {
  AppColors._();

  /// 主背景色：近黑（#0F1620）。
  static const Color background = Color(0xFF0F1620);

  /// 主强调色：经典蓝（#2D7DF6）。
  static const Color primary = Color(0xFF2D7DF6);

  /// 次级表面色：深灰（比背景略浅，#1B2330）。
  static const Color surface = Color(0xFF1B2330);

  /// 警告 / 活跃色：警报红。
  static const Color alert = Color(0xFFE53935);

  /// 主文字色：近白。
  static const Color onBackground = Color(0xFFF4F6FA);

  /// 次要文字 / 提示文字：中灰白。
  static const Color hint = Color(0xFF9AA4B2);

  /// 危险 / 错误：深红。
  static const Color danger = Color(0xFFB71C1C);

  /// 网格线色：半透明经典蓝。
  static const Color gridLine = Color(0x332D7DF6);

  /// 机密遮盖斜纹底色：警报红 / 近黑交替。
  static const Color cautionStripe = Color(0xFFE53935);
  static const Color cautionStripeAlt = Color(0xFF0F1620);
}

/// L-Corp App 全局主题。
class AppTheme {
  AppTheme._();

  /// 等宽终端字体族（系统等宽字体回退栈）。
  static const String monoFontFamily = 'monospace';

  /// 全局圆角半径（中等圆角，避免方角生硬）。
  static const double cornerRadius = 12.0;

  /// 较小圆角（用于标签 / chip）。
  static const double smallRadius = 8.0;

  /// 全局 BorderRadius。
  static const BorderRadius borderRadius =
      BorderRadius.all(Radius.circular(cornerRadius));

  /// 应用 ThemeData。
  static ThemeData get themeData {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
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
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: monoFontFamily,
          color: AppColors.onBackground,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 1.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.primary, width: 1),
          borderRadius: borderRadius,
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
          foregroundColor: Colors.white,
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
