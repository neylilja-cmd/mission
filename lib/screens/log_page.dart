import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/point_log.dart';
import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../utils/business_day.dart';
import '../widgets/glass_panel.dart';

class LogPage extends StatefulWidget {
  final AppState state;
  const LogPage({super.key, required this.state});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  // 最初は「今日（営業日基準）」のグループだけ開いた状態にする。
  final Set<String> openDays = {todayBusinessDayKey()};

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<PointLog>>{};
    for (final log in widget.state.logs) {
      // 履歴は「営業日」単位でまとめる。カレンダー日付でまとめると、
      // AM5:00より前の記録がデイリーミッションのリセット基準とズレてしまうため。
      final key = businessDayKey(log.at);
      (groups[key] ??= []).add(log);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: UiConstants.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: UiConstants.pagePadding),
          children: [
            GlassPanel(child: Text('ポイント履歴', style: AppTextStyles.title.copyWith(fontSize: 18))),
            const SizedBox(height: UiConstants.gap),
            if (days.isEmpty)
              GlassPanel(child: Text('履歴がありません', style: AppTextStyles.body.copyWith(color: AppColors.muted))),
            for (final day in days) ...[
              _DayGroup(
                day: day,
                logs: groups[day]!,
                isOpen: openDays.contains(day),
                onToggle: () => setState(() => openDays.contains(day) ? openDays.remove(day) : openDays.add(day)),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// businessDayKey が返す 'yyyy-MM-dd' 形式を、
/// 「yyyy年M月d日」の日本語表記に変換する。
String _formatJapaneseDay(String dayKey) {
  final date = DateFormat('yyyy-MM-dd').parse(dayKey);
  return DateFormat('yyyy年M月d日').format(date);
}

class _DayGroup extends StatelessWidget {
  final String day;
  final List<PointLog> logs;
  final bool isOpen;
  final VoidCallback onToggle;

  const _DayGroup({
    required this.day,
    required this.logs,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final gained = logs.where((l) => l.delta > 0).fold(0, (sum, l) => sum + l.delta);
    final spent = logs.where((l) => l.delta < 0).fold(0, (sum, l) => sum + l.delta.abs());

    return GlassPanel(
      blur: false,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text(_formatJapaneseDay(day), style: AppTextStyles.title.copyWith(fontSize: 16))),
                  Text('+$gained', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  const Text(' / ', style: AppTextStyles.label),
                  Text('-$spent P', style: AppTextStyles.label.copyWith(color: AppColors.reward, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  // 開閉状態がひと目でわかるよう、開いているときは下向きにする。
                  AnimatedRotation(
                    turns: isOpen ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            for (final log in logs) ...[
              Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.muted.withValues(alpha: 0.2)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.title, style: AppTextStyles.body),
                          Text(DateFormat('HH:mm').format(log.at), style: AppTextStyles.small),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${log.delta >= 0 ? '+' : ''}${log.delta} P',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: log.delta >= 0 ? AppColors.primary : AppColors.reward,
                          ),
                        ),
                        Text('残高 ${log.balance} P', style: AppTextStyles.small),
                      ],
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
