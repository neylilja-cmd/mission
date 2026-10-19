import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mission_reward_app/app/mission_app.dart';
import 'package:mission_reward_app/state/app_state.dart';
import 'package:mission_reward_app/storage/wallpaper_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MissionApp(state: AppState(wallpaperStore: MemoryWallpaperStore())));
    await tester.pumpAndSettle();
  }

  testWidgets('スマホ幅でホームが表示され、各タブに移動できる', (tester) async {
    await pumpApp(tester, const Size(390, 844));

    expect(find.text('現在のポイント'), findsOneWidget);
    expect(find.text('ミッション追加'), findsOneWidget);
    expect(find.text('褒美追加'), findsOneWidget);

    await tester.tap(find.text('ミッション'));
    await tester.pumpAndSettle();
    expect(find.text('ミッションがありません'), findsOneWidget);

    await tester.tap(find.text('褒美').last);
    await tester.pumpAndSettle();
    expect(find.text('褒美がありません'), findsOneWidget);

    await tester.tap(find.text('記録'));
    await tester.pumpAndSettle();
    expect(find.text('履歴がありません'), findsOneWidget);
  });

  testWidgets('PC幅でもレイアウトが崩れない', (tester) async {
    await pumpApp(tester, const Size(1280, 800));
    expect(find.text('現在のポイント'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('入力エラーが表示され、確認画面を経て登録される', (tester) async {
    await pumpApp(tester, const Size(390, 844));

    await tester.tap(find.text('ミッション追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認へ'));
    await tester.pumpAndSettle();
    expect(find.text('内容を入力してください'), findsOneWidget);
    expect(find.text('ポイントを入力してください'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '内容'), '筋トレ30分');
    await tester.enterText(find.widgetWithText(TextField, '獲得ポイント（1〜999）'), '１０００');
    await tester.tap(find.text('確認へ'));
    await tester.pumpAndSettle();
    expect(find.text('1〜999の数字で入力してください'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '獲得ポイント（1〜999）'), '３０');
    await tester.tap(find.text('確認へ'));
    await tester.pumpAndSettle();
    expect(find.text('この内容で登録しますか？'), findsOneWidget);
    expect(find.text('30 P'), findsOneWidget);

    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ミッション'));
    await tester.pumpAndSettle();
    expect(find.text('筋トレ30分'), findsOneWidget);
  });
}
