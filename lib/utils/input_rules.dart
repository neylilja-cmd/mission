import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 入力欄のルール（文字数・ポイントの上限など）と、そのチェック処理。
/// 登録後は内容を変更できない仕様のため、入口でしっかり弾く。
abstract final class InputRules {
  static const int titleMaxLength = 30;
  static const int missionPointsMax = 999;
  static const int rewardCostMax = 99999;
}

/// 全角数字を半角に変換し、数字以外の文字を取り除く入力フォーマッタ。
/// 日本語入力のまま「１００」と打っても数字として扱えるようにする。
class DigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 変換中（IMEの未確定文字がある状態）は触らず、確定後に整形する。
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) return newValue;

    final digits = normalizeDigits(newValue.text);
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// 全角数字を半角にし、数字以外を除いた文字列を返す。
String normalizeDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0xFF10 && rune <= 0xFF19) {
      buffer.writeCharCode(rune - 0xFF10 + 0x30);
    } else if (rune >= 0x30 && rune <= 0x39) {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// 内容（タイトル）のチェック。問題なければ null、あればエラー文を返す。
String? validateTitle(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '内容を入力してください';
  if (trimmed.characters.length > InputRules.titleMaxLength) {
    return '${InputRules.titleMaxLength}文字以内で入力してください';
  }
  return null;
}

/// ポイントのチェック。問題なければ null、あればエラー文を返す。
String? validatePoints(String text, {required int max}) {
  final value = int.tryParse(normalizeDigits(text));
  if (text.trim().isEmpty) return 'ポイントを入力してください';
  if (value == null || value < 1 || value > max) return '1〜$maxの数字で入力してください';
  return null;
}

/// チェック済みのポイント入力を数値にする。
int parsePoints(String text) => int.parse(normalizeDigits(text));
