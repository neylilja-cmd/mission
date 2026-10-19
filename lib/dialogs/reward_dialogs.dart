import 'package:flutter/material.dart';

import '../models/reward.dart';
import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../utils/business_day.dart';
import '../utils/input_rules.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/pill_tabs.dart';
import 'confirm_dialog.dart';
import 'form_fields.dart';

/// 褒美追加ダイアログ。
/// 「確認へ」で入力チェックを行い、問題なければ登録確認を挟んでから登録する。
Future<void> showRewardEditor(BuildContext context, AppState state) async {
  final titleController = TextEditingController();
  final costController = TextEditingController();
  final noteController = TextEditingController();
  var repeatable = false;
  String? titleError;
  String? costError;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        Future<void> submit() async {
          setDialogState(() {
            titleError = validateTitle(titleController.text);
            costError = validatePoints(costController.text, max: InputRules.rewardCostMax);
          });
          if (titleError != null || costError != null) return;

          final title = titleController.text.trim();
          final cost = parsePoints(costController.text);
          final note = noteController.text.trim();
          final confirmed = await confirmRegistration(
            ctx,
            rows: [
              ('受け取り', repeatable ? 'くり返し（何度でも）' : '1回限り'),
              ('内容', title),
              ('必要ポイント', '$cost P'),
              ('備考', note),
            ],
            warning: '登録後は、内容・ポイント・受け取り方の変更はできません（削除はできます）。',
          );
          if (!confirmed) return;

          await state.addReward(Reward(
            id: generateId(),
            title: title,
            note: note,
            cost: cost,
            received: false,
            repeatable: repeatable,
            createdAt: DateTime.now(),
          ));
          if (ctx.mounted) Navigator.pop(ctx);
        }

        return AlertDialog(
          title: const Text('褒美追加'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PillTabs<bool>(
                    items: const {false: '1回限り', true: 'くり返し'},
                    selected: repeatable,
                    onChanged: (v) => setDialogState(() => repeatable = v),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    repeatable ? '受け取っても一覧に残り、何度でも受け取れます。' : '1度受け取ったら終わりです。',
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: 16),
                  TitleField(
                    controller: titleController,
                    errorText: titleError,
                    onChanged: (_) => setDialogState(() => titleError = null),
                  ),
                  formGap,
                  PointsField(
                    controller: costController,
                    label: '必要ポイント（1〜${InputRules.rewardCostMax}）',
                    errorText: costError,
                    onChanged: (_) => setDialogState(() => costError = null),
                  ),
                  formGap,
                  NoteField(controller: noteController),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            FilledButton(onPressed: submit, child: const Text('確認へ')),
          ],
        );
      },
    ),
  );
}

/// 褒美詳細ダイアログ（受け取り / 削除）。
Future<void> showRewardDetail(BuildContext context, AppState state, Reward reward) async {
  final canReceive = reward.available && state.points >= reward.cost;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(reward.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reward.repeatable ? 'くり返しの褒美' : '1回限りの褒美', style: AppTextStyles.label),
          const SizedBox(height: 6),
          Text(
            '必要ポイント  ${reward.cost} P',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.reward),
          ),
          Text('現在のポイント  ${state.points} P', style: AppTextStyles.body),
          if (reward.repeatable && reward.receivedCount > 0)
            Text('受け取り  ${reward.receivedCount}回', style: AppTextStyles.body),
          if (reward.available && !canReceive) ...[
            const SizedBox(height: 6),
            Text('あと ${reward.cost - state.points} P で受け取れます', style: AppTextStyles.label),
          ],
          if (reward.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('備考', style: AppTextStyles.label),
            const SizedBox(height: 2),
            Text(reward.note, style: AppTextStyles.body),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.achieve),
          onPressed: () async {
            final confirmed = await confirmOnce(
              ctx,
              title: 'この褒美を削除しますか？',
              message: '「${reward.title}」を一覧から削除します。\n'
                  '使ったポイントは戻りません（受け取った記録は履歴に残ります）。',
              confirmLabel: '削除する',
              destructive: true,
            );
            if (!confirmed) return;
            await state.deleteReward(reward);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('削除'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('戻る')),
        if (canReceive)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.reward),
            onPressed: () async {
              final confirmed = await confirmTwoStep(
                ctx,
                '本当に受け取りますか？',
                '${reward.cost}ポイントを消費します。\nこの操作は取り消せません。\n本当に受け取りますか？',
              );
              if (confirmed) {
                await state.receive(reward);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  showCelebration(
                    context,
                    message: '褒美を受け取った！',
                    pointsText: '-${reward.cost} P',
                    color: AppColors.reward,
                  );
                }
              }
            },
            child: const Text('受け取る'),
          ),
      ],
    ),
  );
}
