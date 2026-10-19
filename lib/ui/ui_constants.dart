import 'package:flutter/material.dart';

/// 色の役割。意味ごとに色を固定し、画面をまたいで統一する。
abstract final class AppColors {
  /// 基本色（操作・ポイント）。
  static const primary = Color(0xFF4352B8);
  static const primarySoft = Color(0x244352B8);

  /// 達成・期限・注意。
  static const achieve = Color(0xFFD32F2F);

  /// 褒美。
  static const reward = Color(0xFFE8710A);
  static const rewardSoft = Color(0x24E8710A);

  /// 連続記録。
  static const streak = Color(0xFFC2410C);
  static const streakSoft = Color(0x1FEA580C);

  /// 失敗・受取済・補足。
  static const muted = Color(0xFF6B6F80);

  static const text = Color(0xFF1B1D29);
  static const textSub = Color(0xFF3D4152);
  static const inputBorder = Color(0xFFC9CCE0);
}

/// 余白・角丸・パネルの見た目など、UIの共通値。
abstract final class UiConstants {
  static const double panelRadius = 18;
  static const double dialogRadius = 22;
  static const double gap = 12;
  static const double pagePadding = 16;

  /// これ以上の横幅なら PC 向けの横並びレイアウトにする。
  static const double wideBreakpoint = 720;

  /// PC で横に広がりすぎないよう、一覧系の画面はこの幅までにする。
  static const double contentMaxWidth = 640;
}

/// アプリに同梱している日本語フォント。
/// ブラウザ版でもネットから取ってこずに済むので、オフラインでも文字が欠けない。
const appFontFamily = 'NotoSansJP';

/// アプリ全体で使う文字スタイル（5段階）。
/// 壁紙の上ではグレーが薄すぎて読みにくくなるため、色は黒系でほぼ統一し、
/// 太さ・大きさで役割を区別する。
abstract final class AppTextStyles {
  /// ポイント残高など、一番大きく見せる数字。
  static const display = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.primary,
  );

  /// ミッション名・褒美名・見出し。
  static const title = TextStyle(fontFamily: appFontFamily, fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text);

  /// 本文・ボタン内の文字。
  static const body = TextStyle(fontFamily: appFontFamily, fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text);

  /// ラベル・補足（「現在のポイント」「期限」など）。
  static const label = TextStyle(fontFamily: appFontFamily, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSub);

  /// さらに小さい補足。
  static const small = TextStyle(fontFamily: appFontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSub);
}

/// アプリ全体のテーマ。ダイアログ・入力欄・ボタンをパネルと同じ雰囲気に揃える。
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary);
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
  OutlineInputBorder border(Color color, [double width = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiConstants.dialogRadius)),
      titleTextStyle: AppTextStyles.title.copyWith(fontSize: 18),
      contentTextStyle: AppTextStyles.body,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
      border: border(AppColors.inputBorder),
      enabledBorder: border(AppColors.inputBorder),
      focusedBorder: border(AppColors.primary, 2),
      errorBorder: border(AppColors.achieve),
      focusedErrorBorder: border(AppColors.achieve, 2),
      errorStyle: AppTextStyles.small.copyWith(color: AppColors.achieve),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        textStyle: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: AppColors.primarySoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTextStyles.small.copyWith(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSub,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSub,
        ),
      ),
    ),
  );
}
