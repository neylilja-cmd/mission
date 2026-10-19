import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/mission.dart';
import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../utils/business_day.dart';
import '../utils/input_rules.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/info_chip.dart';
import '../widgets/pill_tabs.dart';
import 'confirm_dialog.dart';
import 'form_fields.dart';

const missionTypeLabels = {
  MissionType.daily: 'デイリー',
  MissionType.normal: '通常',
  MissionType.limited: '期間限定',
};

final _dateFormat = DateFormat('yyyy/MM/dd');

/// ミッション追加ダイアログ。
/// 「確認へ」で入力チェックを行い、問題なければ登録確認を挟んでから登録する。
Future<void> showMissionEditor(BuildContext context, AppState state) async {
  MissionType type = MissionType.daily;
  final titleController = TextEditingController();
  final pointsController = TextEditingController();
  final noteController = TextEditingController();
  DateTime? deadlineDate;
  String? titleError;
  String? pointsError;
  String? deadlineError;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        Future<void> submit() async {
          setDialogState(() {
            titleError = validateTitle(titleController.text);
            pointsError = validatePoints(pointsController.text, max: InputRules.missionPointsMax);
            deadlineError = type == MissionType.limited && deadlineDate == null ? '期限を選んでください' : null;
          });
          if (titleError != null || pointsError != null || deadlineError != null) return;

          final title = titleController.text.trim();
          final points = parsePoints(pointsController.text);
          final note = noteController.text.trim();
          final confirmed = await confirmRegistration(
            ctx,
            rows: [
              ('種類', missionTypeLabels[type]!),
              ('内容', title),
              ('獲得ポイント', '$points P'),
              if (type == MissionType.limited) ('期限', _dateFormat.format(deadlineDate!)),
              ('備考', note),
            ],
            warning: type == MissionType.daily
                ? '登録後は削除できません（内容・ポイント・備考は後から編集できます）。'
                : type == MissionType.limited
                    ? '登録後は、内容・ポイント・期限の変更や削除はできません。'
                    : '登録後は、内容・ポイントの変更や削除はできません。',
          );
          if (!confirmed) return;

          await state.addMission(Mission(
            id: generateId(),
            title: title,
            note: note,
            points: points,
            type: type,
            status: MissionStatus.active,
            createdAt: DateTime.now(),
            // 期限日の AM4:59:59 として保存する（期限日の営業日の終わりまでが期限内）。
            deadline: deadlineDate == null
                ? null
                : DateTime(deadlineDate!.year, deadlineDate!.month, deadlineDate!.day, 4, 59, 59),
          ));
          if (ctx.mounted) Navigator.pop(ctx);
        }

        return AlertDialog(
          title: const Text('ミッション追加'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PillTabs<MissionType>(
                    items: missionTypeLabels,
                    selected: type,
                    onChanged: (t) => setDialogState(() => type = t),
                  ),
                  const SizedBox(height: 18),
                  TitleField(
                    controller: titleController,
                    errorText: titleError,
                    onChanged: (_) => setDialogState(() => titleError = null),
                  ),
                  formGap,
                  PointsField(
                    controller: pointsController,
                    label: '獲得ポイント（1〜${InputRules.missionPointsMax}）',
                    errorText: pointsError,
                    onChanged: (_) => setDialogState(() => pointsError = null),
                  ),
                  if (type == MissionType.limited) ...[
                    formGap,
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final now = DateTime.now();
                        // 営業日基準の「今日」から選べるようにする（AM5:00前は前日扱い）。
                        final today = DateFormat('yyyy-MM-dd').parse(todayBusinessDayKey());
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: today,
                          lastDate: DateTime(now.year + 10),
                          initialDate: deadlineDate ?? today.add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            deadlineDate = picked;
                            deadlineError = null;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '期限',
                          errorText: deadlineError,
                          suffixIcon: const Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(
                          deadlineDate == null ? '日付を選ぶ' : _dateFormat.format(deadlineDate!),
                          style: deadlineDate == null
                              ? AppTextStyles.body.copyWith(color: AppColors.muted)
                              : AppTextStyles.body,
                        ),
                      ),
                    ),
                  ],
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

/// ミッション詳細ダイアログ（達成 / 編集 / 削除）。
Future<void> showMissionDetail(BuildContext context, AppState state, Mission mission) async {
  final today = todayBusinessDayKey();
  final streak = mission.currentStreak(today);
  final daysLeft = mission.status == MissionStatus.active ? mission.daysLeft(today) : null;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(mission.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${missionTypeLabels[mission.type]}ミッション', style: AppTextStyles.label),
          const SizedBox(height: 6),
          Text(
            '獲得ポイント  ${mission.points} P',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          if (mission.deadline != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('期限  ${_dateFormat.format(mission.deadline!)}', style: AppTextStyles.body),
                if (daysLeft != null) ...[const SizedBox(width: 8), InfoChip.daysLeft(daysLeft)],
              ],
            ),
          ],
          if (streak >= 2) ...[const SizedBox(height: 8), InfoChip.streak(streak)],
          if (mission.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('備考', style: AppTextStyles.label),
            const SizedBox(height: 2),
            Text(mission.note, style: AppTextStyles.body),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('戻る')),
        // デイリーミッションのみ、いつでも内容を変更できる。
        if (mission.type == MissionType.daily)
          TextButton(
            onPressed: () async {
              final saved = await showMissionEditDialog(context, state, mission);
              if (saved && ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('編集'),
          ),
        if (mission.status == MissionStatus.active)
          FilledButton(
            onPressed: () async {
              final confirmed = await confirmTwoStep(
                ctx,
                '本当に達成しましたか？',
                '${mission.points}ポイントを獲得します。\nこの操作は取り消せません。\n本当に達成しますか？',
              );
              if (confirmed) {
                await state.complete(mission);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  showCelebration(
                    context,
                    message: 'ミッション達成！',
                    pointsText: '+${mission.points} P',
                    color: AppColors.primary,
                  );
                }
              }
            },
            child: const Text('達成する'),
          ),
        if (mission.status != MissionStatus.active)
          TextButton(
            onPressed: () async {
              await state.deleteMission(mission);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('削除'),
          ),
      ],
    ),
  );
}

/// デイリーミッションの内容編集ダイアログ。
/// 保存された場合のみ true を返す（呼び出し元で詳細ダイアログを閉じる判定に使う）。
Future<bool> showMissionEditDialog(BuildContext context, AppState state, Mission mission) async {
  final titleController = TextEditingController(text: mission.title);
  final pointsController = TextEditingController(text: mission.points.toString());
  final noteController = TextEditingController(text: mission.note);
  String? titleError;
  String? pointsError;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('デイリーミッションを編集'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                TitleField(
                  controller: titleController,
                  errorText: titleError,
                  onChanged: (_) => setDialogState(() => titleError = null),
                ),
                formGap,
                PointsField(
                  controller: pointsController,
                  label: '獲得ポイント（1〜${InputRules.missionPointsMax}）',
                  errorText: pointsError,
                  onChanged: (_) => setDialogState(() => pointsError = null),
                ),
                formGap,
                NoteField(controller: noteController),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () async {
              setDialogState(() {
                titleError = validateTitle(titleController.text);
                pointsError = validatePoints(pointsController.text, max: InputRules.missionPointsMax);
              });
              if (titleError != null || pointsError != null) return;

              mission.title = titleController.text.trim();
              mission.points = parsePoints(pointsController.text);
              mission.note = noteController.text.trim();
              await state.updateMission(mission);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
  return saved ?? false;
}
