import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../utils/business_day.dart';
import 'shell.dart';

/// アプリのルート。起動時に [AppState] を読み込み、
/// 読み込みが終わるまではローディング表示にする。
class MissionApp extends StatefulWidget {
  final AppState? state;
  const MissionApp({super.key, this.state});

  @override
  State<MissionApp> createState() => _MissionAppState();
}

class _MissionAppState extends State<MissionApp> {
  late final AppState state = widget.state ?? AppState();
  late final AppLifecycleListener lifecycle;
  Timer? dayTimer;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    state.load().then((_) {
      if (!mounted) return;
      setState(() => ready = true);
      _scheduleDayChange();
    });
    // スマホではアプリを開いたまま裏に回すことが多いので、戻ってきたときにも日付を確認する。
    lifecycle = AppLifecycleListener(onResume: () {
      if (!ready) return;
      state.refreshTimeRules();
      _scheduleDayChange();
    });
  }

  /// 次の AM5:00 に日付の切り替え処理を行うタイマーを仕掛ける。
  void _scheduleDayChange() {
    dayTimer?.cancel();
    final now = DateTime.now();
    final wait = nextBusinessDayStart(now).difference(now) + const Duration(seconds: 1);
    dayTimer = Timer(wait, () {
      state.refreshTimeRules();
      _scheduleDayChange();
    });
  }

  @override
  void dispose() {
    dayTimer?.cancel();
    lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mission Reward',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ready
          ? Shell(state: state)
          : const ColoredBox(
              color: Color(0xFFB9A7E4),
              child: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
