import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dialogs/mission_dialogs.dart';
import '../models/mission.dart';
import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../utils/business_day.dart';
import '../widgets/glass_panel.dart';
import '../widgets/info_chip.dart';
import '../widgets/pill_tabs.dart';
import '../widgets/stamp_badge.dart';

class MissionPage extends StatefulWidget {
  final AppState state;
  const MissionPage({super.key, required this.state});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  MissionType selectedType = MissionType.daily;

  @override
  Widget build(BuildContext context) {
    final today = todayBusinessDayKey();
    final list = widget.state.missions.where((m) => m.type == selectedType).toList()
      ..sort((a, b) =>
          (a.status == MissionStatus.active ? 0 : 1).compareTo(b.status == MissionStatus.active ? 0 : 1));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: UiConstants.contentMaxWidth),
        child: Column(
          children: [
            GlassPanel(
              padding: EdgeInsets.zero,
              child: PillTabs<MissionType>(
                items: missionTypeLabels,
                selected: selectedType,
                tinted: false,
                onChanged: (t) => setState(() => selectedType = t),
              ),
            ),
            const SizedBox(height: UiConstants.gap),
            Expanded(
              child: list.isEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: GlassPanel(
                        child: Text('ミッションがありません', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: UiConstants.pagePadding),
                      itemCount: list.length,
                      itemBuilder: (_, i) => MissionTile(state: widget.state, mission: list[i], today: today),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ミッション一覧の1行分。達成済み/失敗のものは薄く表示する。
class MissionTile extends StatelessWidget {
  final AppState state;
  final Mission mission;
  final String today;
  const MissionTile({super.key, required this.state, required this.mission, required this.today});

  @override
  Widget build(BuildContext context) {
    final isActive = mission.status == MissionStatus.active;
    final streak = mission.currentStreak(today);
    final daysLeft = isActive ? mission.daysLeft(today) : null;

    return Opacity(
      opacity: isActive ? 1 : .55,
      child: GlassPanel(
        blur: false,
        onTap: () => showMissionDetail(context, state, mission),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mission.title, style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '+${mission.points} P',
                        style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      if (mission.deadline != null)
                        Text('期限 ${DateFormat('yyyy/MM/dd').format(mission.deadline!)}', style: AppTextStyles.small),
                      if (daysLeft != null) InfoChip.daysLeft(daysLeft),
                      // 連続記録は2日目から表示する（1日目は「連続」と呼ぶほどではないため）。
                      if (streak >= 2) InfoChip.streak(streak),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              const Icon(Icons.chevron_right, color: AppColors.muted)
            else if (mission.status == MissionStatus.completed)
              StampBadge.achieved()
            else
              StampBadge.failed(),
          ],
        ),
      ),
    );
  }
}
