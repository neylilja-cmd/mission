import 'package:flutter/material.dart';

import '../ui/ui_constants.dart';

/// 達成・未達成・受け取り済みを示す「はんこ」風のスタンプ表示。
/// 少し斜めに傾けた枠付きテキストで、結果確定の重みを視覚的に出す。
class StampBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StampBadge({super.key, required this.label, required this.color});

  factory StampBadge.achieved() => const StampBadge(label: '達成', color: AppColors.achieve);
  factory StampBadge.failed() => const StampBadge(label: '未達成', color: AppColors.muted);
  factory StampBadge.received() => const StampBadge(label: '受取済', color: AppColors.muted);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.17,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: appFontFamily,
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
