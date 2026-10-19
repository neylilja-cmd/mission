import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dialogs/reward_dialogs.dart';
import '../models/reward.dart';
import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../widgets/glass_panel.dart';
import '../widgets/info_chip.dart';
import '../widgets/stamp_badge.dart';

class RewardPage extends StatelessWidget {
  final AppState state;
  const RewardPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // 受け取れるもの → まだ受け取れないもの（必要ポイント順）→ 受け取り済み の順に並べる。
    final list = [...state.rewards]..sort((a, b) {
        final byAvailable = (a.available ? 0 : 1).compareTo(b.available ? 0 : 1);
        return byAvailable != 0 ? byAvailable : a.cost.compareTo(b.cost);
      });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: UiConstants.contentMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassPanel(
              child: Row(
                children: [
                  const Text('現在のポイント', style: AppTextStyles.label),
                  const Spacer(),
                  Text(
                    '${NumberFormat('#,###').format(state.points)} P',
                    style: AppTextStyles.title.copyWith(fontSize: 22, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UiConstants.gap),
            Expanded(
              child: list.isEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: GlassPanel(
                        child: Text('褒美がありません', style: AppTextStyles.body.copyWith(color: AppColors.muted)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: UiConstants.pagePadding),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _RewardTile(state: state, reward: list[i]),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final AppState state;
  final Reward reward;
  const _RewardTile({required this.state, required this.reward});

  @override
  Widget build(BuildContext context) {
    final canReceive = reward.available && state.points >= reward.cost;
    final statusText = !reward.available
        ? '受け取り済み'
        : canReceive
            ? '受け取れます'
            : 'あと ${reward.cost - state.points} P';

    return Opacity(
      opacity: reward.available ? 1 : 0.55,
      child: GlassPanel(
        blur: false,
        onTap: () => showRewardDetail(context, state, reward),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward.title, style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${reward.cost} P',
                        style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, color: AppColors.reward),
                      ),
                      Text(
                        statusText,
                        style: AppTextStyles.small.copyWith(
                          color: canReceive ? AppColors.reward : AppColors.textSub,
                          fontWeight: canReceive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (reward.repeatable)
                        InfoChip(
                          label: reward.receivedCount > 0 ? 'くり返し・${reward.receivedCount}回' : 'くり返し',
                          color: AppColors.reward,
                          background: AppColors.rewardSoft,
                          icon: Icons.repeat,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            reward.available ? const Icon(Icons.chevron_right, color: AppColors.muted) : StampBadge.received(),
          ],
        ),
      ),
    );
  }
}
