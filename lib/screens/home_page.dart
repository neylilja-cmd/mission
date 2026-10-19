import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dialogs/mission_dialogs.dart';
import '../dialogs/reward_dialogs.dart';
import '../models/mission.dart';
import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../utils/business_day.dart';
import '../widgets/glass_panel.dart';
import '../widgets/info_chip.dart';

/// 「期限が近い」とみなす残り日数。
const _urgentDays = 3;

/// ホームの中身と下のバーとの間隔。
const _bottomGap = 40.0;

class HomePage extends StatelessWidget {
  final AppState state;
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenSettings;

  const HomePage({super.key, required this.state, required this.onNavigate, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final today = todayBusinessDayKey();
    final dailyMissions = state.missions.where((m) => m.type == MissionType.daily).toList();
    final doneToday =
        dailyMissions.where((m) => m.status == MissionStatus.completed && m.completedDay == today).length;

    final urgentMissions = state.missions
        .where((m) =>
            m.type == MissionType.limited &&
            m.status == MissionStatus.active &&
            m.deadline != null &&
            m.daysLeft(today)! <= _urgentDays)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    final points = _PointsSummary(points: state.points);
    final daily = _DailyProgress(done: doneToday, total: dailyMissions.length);
    final addMission = _AddButton(
      icon: Icons.add,
      label: 'ミッション追加',
      color: AppColors.primary,
      background: AppColors.primarySoft,
      onTap: () => showMissionEditor(context, state),
    );
    final addReward = _AddButton(
      icon: Icons.card_giftcard,
      label: '褒美追加',
      color: AppColors.reward,
      background: AppColors.rewardSoft,
      onTap: () => showRewardEditor(context, state),
    );
    final urgent = _UrgentMissions(missions: urgentMissions, today: today);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= UiConstants.wideBreakpoint;
        final content = wide
            // PC など横幅が広いときは、左から「見るもの → 押すもの」の順に横一列に並べる。
            ? [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(width: 200, height: 136, child: points),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 200,
                        height: 116,
                        child: _DailyProgress(done: doneToday, total: dailyMissions.length, vertical: true),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(width: 160, height: 116, child: addMission),
                      const SizedBox(width: 16),
                      SizedBox(width: 160, height: 116, child: addReward),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]
            // スマホでは上に「見るもの」、下に「押すもの」をまとめる。
            : [
                points,
                const SizedBox(height: UiConstants.gap),
                daily,
                const SizedBox(height: UiConstants.gap),
                Row(
                  children: [
                    Expanded(child: SizedBox(height: 96, child: addMission)),
                    const SizedBox(width: UiConstants.gap),
                    Expanded(child: SizedBox(height: 96, child: addReward)),
                  ],
                ),
                const SizedBox(height: UiConstants.gap),
              ];

        return Stack(
          children: [
            // 壁紙の人物の顔などは画面の上寄りに来ることが多いので、
            // 中身は下のバーに寄せて、上側を壁紙のために空けておく。
            SingleChildScrollView(
              // バーにぴったり付けると窮屈なので、少しだけ間を空ける。
              padding: const EdgeInsets.only(bottom: _bottomGap),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - _bottomGap),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 設定ボタンと重ならないだけの余白は確保する。
                    const SizedBox(height: 56),
                    ...content,
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: UiConstants.contentMaxWidth),
                        // 中身が短くても、パネルは横幅いっぱいに広げる。
                        child: SizedBox(width: double.infinity, child: urgent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(top: 0, right: 0, child: _SettingsButton(onTap: onOpenSettings)),
          ],
        );
      },
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '設定',
      child: SizedBox(
        width: 44,
        height: 44,
        child: GlassPanel(
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: const Icon(Icons.settings, size: 22, color: AppColors.textSub),
        ),
      ),
    );
  }
}

class _PointsSummary extends StatelessWidget {
  final int points;
  const _PointsSummary({required this.points});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('現在のポイント', style: AppTextStyles.label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: NumberFormat('#,###').format(points), style: AppTextStyles.display),
                  TextSpan(
                    text: ' P',
                    style: AppTextStyles.display.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgress extends StatelessWidget {
  final int done;
  final int total;

  /// PC の横並びでは縦に積んだ形で表示する。
  final bool vertical;
  const _DailyProgress({required this.done, required this.total, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: total == 0 ? 0 : done / total,
        minHeight: 8,
        backgroundColor: AppColors.primarySoft,
        color: AppColors.primary,
      ),
    );
    final count = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$done', style: AppTextStyles.title.copyWith(fontSize: vertical ? 28 : 22)),
          TextSpan(text: ' / $total', style: AppTextStyles.label),
        ],
      ),
    );

    return GlassPanel(
      child: vertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('今日のデイリー', style: AppTextStyles.label),
                const SizedBox(height: 6),
                count,
                const SizedBox(height: 8),
                bar,
              ],
            )
          : Row(
              children: [
                const Text('今日のデイリー', style: AppTextStyles.label),
                const SizedBox(width: 12),
                Expanded(child: bar),
                const SizedBox(width: 12),
                count,
              ],
            ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  const _AddButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// 期限が近いミッション（最大3件）を表示する。
/// 2件以上あるときは、一定間隔で自動的に1件ずつ順番に切り替える。
/// 1件のみのときは固定表示。
class _UrgentMissions extends StatefulWidget {
  final List<Mission> missions;
  final String today;
  const _UrgentMissions({required this.missions, required this.today});

  @override
  State<_UrgentMissions> createState() => _UrgentMissionsState();
}

class _UrgentMissionsState extends State<_UrgentMissions> {
  static const _interval = Duration(seconds: 4);
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _UrgentMissions oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 表示件数が変わったら（達成/期限切れなどで入れ替わったら）先頭から出し直す。
    if (widget.missions.length != oldWidget.missions.length) {
      index = 0;
      _restartTimer();
    }
  }

  void _restartTimer() {
    timer?.cancel();
    final shown = widget.missions.take(3).length;
    if (shown > 1) {
      timer = Timer.periodic(_interval, (_) {
        setState(() => index = (index + 1) % shown);
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.missions.take(3).toList();

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('期限が近いミッション', style: AppTextStyles.label),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Text('$_urgentDays日以内に期限を迎えるミッションはありません',
                style: AppTextStyles.body.copyWith(color: AppColors.muted)),
          if (shown.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _MissionLine(
                key: ValueKey(shown[index % shown.length].id),
                mission: shown[index % shown.length],
                today: widget.today,
              ),
            ),
          if (shown.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                shown.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index ? AppColors.primary : AppColors.primarySoft,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionLine extends StatelessWidget {
  final Mission mission;
  final String today;
  const _MissionLine({super.key, required this.mission, required this.today});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(mission.title, style: AppTextStyles.title),
              InfoChip.daysLeft(mission.daysLeft(today)!),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '期限 ${DateFormat('yyyy/MM/dd').format(mission.deadline!)}　+${mission.points} P',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}
