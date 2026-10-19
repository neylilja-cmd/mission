import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mission_reward_app/models/mission.dart';
import 'package:mission_reward_app/models/reward.dart';
import 'package:mission_reward_app/state/app_state.dart';
import 'package:mission_reward_app/storage/wallpaper_store.dart';
import 'package:mission_reward_app/utils/business_day.dart';
import 'package:mission_reward_app/utils/input_rules.dart';
import 'package:mission_reward_app/utils/wallpaper_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

Mission _mission({MissionType type = MissionType.daily, DateTime? deadline}) => Mission(
      id: generateId(),
      title: 'テスト',
      note: '',
      points: 10,
      type: type,
      status: MissionStatus.active,
      createdAt: DateTime.now(),
      deadline: deadline,
    );

Future<AppState> _state() async {
  final state = AppState(wallpaperStore: MemoryWallpaperStore());
  await state.load();
  return state;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('入力チェック', () {
    test('全角数字は半角になり、数字以外は除かれる', () {
      expect(normalizeDigits('１２3ア4'), '1234');
    });

    test('ポイントの範囲', () {
      expect(validatePoints('', max: 999), isNotNull);
      expect(validatePoints('0', max: 999), isNotNull);
      expect(validatePoints('1000', max: 999), isNotNull);
      expect(validatePoints('９９９', max: 999), isNull);
      expect(validatePoints('99999', max: 99999), isNull);
    });

    test('内容は空欄不可・30文字まで', () {
      expect(validateTitle('  '), isNotNull);
      expect(validateTitle('あ' * 30), isNull);
      expect(validateTitle('あ' * 31), isNotNull);
    });
  });

  group('日付', () {
    test('AM5:00より前は前日扱い', () {
      expect(businessDayKey(DateTime(2026, 6, 16, 4, 59)), '2026-06-15');
      expect(businessDayKey(DateTime(2026, 6, 16, 5, 0)), '2026-06-16');
    });

    test('次の切り替わり時刻', () {
      expect(nextBusinessDayStart(DateTime(2026, 6, 16, 3)), DateTime(2026, 6, 16, 5));
      expect(nextBusinessDayStart(DateTime(2026, 6, 16, 5)), DateTime(2026, 6, 17, 5));
    });

    test('残り日数は営業日の日付差で数え、当日は0', () {
      final m = _mission(type: MissionType.limited, deadline: DateTime(2026, 10, 21, 4, 59, 59));
      expect(m.daysLeft('2026-10-19'), 2);
      expect(m.daysLeft('2026-10-21'), 0);
      expect(m.daysLeft('2026-10-22'), -1);
    });
  });

  group('ストリーク', () {
    test('連続して達成すると増え、間が空くと途切れる', () {
      final m = _mission()
        ..streak = 3
        ..lastCompletedDay = '2026-10-18';
      expect(m.currentStreak('2026-10-19'), 3);
      expect(m.currentStreak('2026-10-20'), 0);
    });

    test('達成すると1から数え始める', () async {
      final state = await _state();
      final m = _mission();
      await state.addMission(m);
      await state.complete(m);
      expect(m.streak, 1);
      expect(m.currentStreak(todayBusinessDayKey()), 1);

      // 昨日も達成していた扱いにして、もう一度今日達成すると2日目になる。
      m
        ..status = MissionStatus.active
        ..lastCompletedDay = previousDayKey(todayBusinessDayKey());
      await state.complete(m);
      expect(m.streak, 2);
    });

    test('旧データは今日達成済みなら1日目として読み込む', () {
      final m = Mission.fromJson({
        'id': '1',
        'title': 't',
        'points': 1,
        'type': 0,
        'status': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'completedDay': '2026-10-19',
      });
      expect(m.streak, 1);
      expect(m.lastCompletedDay, '2026-10-19');
    });
  });

  group('褒美', () {
    Reward reward({bool repeatable = false}) => Reward(
          id: generateId(),
          title: 'ケーキ',
          note: '',
          cost: 30,
          received: false,
          repeatable: repeatable,
          createdAt: DateTime.now(),
        );

    test('1回限りは1度受け取ったら終わり', () async {
      final state = await _state();
      state.points = 100;
      final r = reward();
      await state.addReward(r);
      await state.receive(r);
      await state.receive(r);
      expect(state.points, 70);
      expect(r.available, isFalse);
    });

    test('くり返しは何度でも受け取れ、回数が増える', () async {
      final state = await _state();
      state.points = 100;
      final r = reward(repeatable: true);
      await state.addReward(r);
      await state.receive(r);
      await state.receive(r);
      expect(state.points, 40);
      expect(r.receivedCount, 2);
      expect(r.available, isTrue);
    });

    test('削除してもポイントと履歴は残る', () async {
      final state = await _state();
      state.points = 100;
      final r = reward();
      await state.addReward(r);
      await state.receive(r);
      await state.deleteReward(r);
      expect(state.rewards, isEmpty);
      expect(state.points, 70);
      expect(state.logs, hasLength(1));
    });
  });

  group('バックアップ', () {
    test('書き出した内容を空の状態に読み込める', () async {
      final source = await _state();
      source.points = 50;
      await source.addMission(_mission());
      final raw = jsonEncode(source.exportBackup());

      SharedPreferences.setMockInitialValues({});
      final target = await _state();
      await target.importBackup(raw);
      expect(target.points, 50);
      expect(target.missions, hasLength(1));
    });

    test('データがあるときは読み込めず、今のデータも変わらない', () async {
      final state = await _state();
      await state.addMission(_mission());
      final raw = jsonEncode(state.exportBackup());
      state.points = 10;
      await expectLater(state.importBackup(raw), throwsA(isA<BackupException>()));
      expect(state.points, 10);
    });

    test('関係ないファイルは読み込まない', () async {
      final state = await _state();
      await expectLater(state.importBackup('{"foo": 1}'), throwsA(isA<BackupException>()));
      await expectLater(state.importBackup('not json'), throwsA(isA<BackupException>()));
      expect(state.isEmpty, isTrue);
    });
  });

  test('期限日の営業日が終わると失敗になる', () async {
    final state = await _state();
    final yesterday = DateTime.now().subtract(const Duration(days: 2));
    final m = _mission(
      type: MissionType.limited,
      deadline: DateTime(yesterday.year, yesterday.month, yesterday.day, 4, 59, 59),
    );
    state.missions.add(m);
    state.refreshTimeRules();
    expect(m.status, MissionStatus.failed);
  });
  test('壁紙は長辺2000pxまで縮小され、JPEGになる', () {
    final original = img.encodePng(img.Image(width: 3000, height: 4000));
    final shrunk = shrinkWallpaper(original)!;
    final decoded = img.decodeJpg(shrunk)!;
    expect(decoded.height, wallpaperMaxSide);
    expect(decoded.width, 1500);
    expect(shrinkWallpaper(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
