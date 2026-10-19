import 'package:flutter/material.dart';

import '../utils/input_rules.dart';

/// 内容（タイトル）の入力欄。文字数カウント付き。
class TitleField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  const TitleField({super.key, required this.controller, this.errorText, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: InputRules.titleMaxLength,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: '内容', errorText: errorText),
    );
  }
}

/// ポイントの入力欄。全角数字は半角に変換し、数字以外は入力できない。
class PointsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  const PointsField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [DigitsOnlyFormatter()],
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, errorText: errorText, suffixText: 'P'),
    );
  }
}

/// 備考の入力欄。
class NoteField extends StatelessWidget {
  final TextEditingController controller;
  const NoteField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      minLines: 2,
      decoration: const InputDecoration(labelText: '備考（任意）'),
    );
  }
}

/// 入力欄同士の縦の間隔。
const formGap = SizedBox(height: 14);
