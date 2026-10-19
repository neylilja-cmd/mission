import 'package:flutter/material.dart';

import '../ui/ui_constants.dart';

/// 角丸の切り替えタブ（デイリー／通常／期間限定 など）。
class PillTabs<T> extends StatelessWidget {
  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onChanged;

  /// パネルの上に置くときは false（パネル自体が背景になる）。
  final bool tinted;

  const PillTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.tinted = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tinted ? AppColors.primarySoft : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final entry in items.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: entry.key == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: entry.key == selected
                        ? const [BoxShadow(color: Color(0x1F1E2050), blurRadius: 6, offset: Offset(0, 2))]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.value,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: entry.key == selected ? FontWeight.w700 : FontWeight.w500,
                      color: entry.key == selected ? AppColors.primary : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
