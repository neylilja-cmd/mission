import 'dart:ui';

import 'package:flutter/material.dart';

import '../screens/home_page.dart';
import '../screens/log_page.dart';
import '../screens/mission_page.dart';
import '../screens/reward_page.dart';
import '../screens/settings_page.dart';
import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../widgets/app_background.dart';

/// ボトムナビゲーションと背景を管理する、アプリの外枠。
class Shell extends StatefulWidget {
  final AppState state;
  const Shell({super.key, required this.state});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsPage(state: widget.state)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final pages = [
          HomePage(
            state: widget.state,
            onNavigate: (i) => setState(() => index = i),
            onOpenSettings: _openSettings,
          ),
          MissionPage(state: widget.state),
          RewardPage(state: widget.state),
          LogPage(state: widget.state),
        ];

        return AppBackground(
          state: widget.state,
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  UiConstants.pagePadding,
                  UiConstants.pagePadding,
                  UiConstants.pagePadding,
                  0,
                ),
                child: pages[index],
              ),
            ),
            bottomNavigationBar: ClipRect(
              child: BackdropFilter(
                // 常時表示される操作エリアなので、ぼかしは効かせつつ背景色もうっすら見える程度にする。
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.8))),
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    height: 68,
                    selectedIndex: index,
                    onDestinationSelected: (i) => setState(() => index = i),
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'ホーム'),
                      NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'ミッション'),
                      NavigationDestination(
                        icon: Icon(Icons.card_giftcard_outlined),
                        selectedIcon: Icon(Icons.card_giftcard),
                        label: '褒美',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long),
                        label: '記録',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
