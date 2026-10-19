import 'package:flutter/material.dart';

import '../ui/ui_constants.dart';

/// 2段階の確認ダイアログを表示する。
/// [firstMessage] で一度確認し、「はい」が押されたらさらに [secondMessage] で
/// 念押しする。両方 OK された場合のみ true を返す（取り消し不可な操作向け）。
Future<bool> confirmTwoStep(BuildContext context, String firstMessage, String secondMessage) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(firstMessage),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('戻る')),
        FilledButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: ctx,
              builder: (innerCtx) => AlertDialog(
                content: Text(secondMessage),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(innerCtx, false), child: const Text('キャンセル')),
                  FilledButton(onPressed: () => Navigator.pop(innerCtx, true), child: const Text('確定')),
                ],
              ),
            );
            if (ctx.mounted) Navigator.pop(ctx, confirmed ?? false);
          },
          child: const Text('はい'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 1回だけの確認ダイアログ。[destructive] なら確定ボタンを注意色にする。
Future<bool> confirmOnce(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.achieve) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 登録前の確認ダイアログ。入力内容を一覧で見せ、変更できない旨を明記する。
/// 「登録する」が押された場合のみ true を返す。「戻って直す」なら入力画面に戻る。
Future<bool> confirmRegistration(
  BuildContext context, {
  required List<(String, String)> rows,
  required String warning,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('この内容で登録しますか？'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 96, child: Text(label, style: AppTextStyles.label.copyWith(fontSize: 14))),
                    Expanded(
                      child: Text(
                        value.isEmpty ? 'なし' : value,
                        style: value.isEmpty
                            ? AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.muted)
                            : AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.achieve.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.lock_outline, size: 18, color: Color(0xFF9F1D1D)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: AppTextStyles.label.copyWith(color: const Color(0xFF9F1D1D), height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('戻って直す')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('登録する')),
      ],
    ),
  );
  return result ?? false;
}
