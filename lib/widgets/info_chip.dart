import 'package:flutter/material.dart';

import '../ui/ui_constants.dart';

/// 小さな札（「12日連続」「残り2日」「くり返し」など）。
class InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const InfoChip({super.key, required this.label, required this.color, required this.background, this.icon});

  /// デイリーの連続達成日数。
  factory InfoChip.streak(int days) => InfoChip(
        label: '$days日連続',
        color: AppColors.streak,
        background: AppColors.streakSoft,
        icon: Icons.local_fire_department,
      );

  /// 期間限定の残り日数。期限日当日は「今日が期限」。
  factory InfoChip.daysLeft(int days) => InfoChip(
        label: days <= 0 ? '今日が期限' : '残り$days日',
        color: AppColors.achieve,
        background: AppColors.achieve.withValues(alpha: 0.1),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 8 : 5, 1, 8, 1),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 2)],
          Text(label, style: AppTextStyles.small.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
