import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mission.dart';
import '../models/point_log.dart';
import '../models/reward.dart';
import '../storage/wallpaper_store.dart';
import '../utils/business_day.dart';

/// アプリ全体の状態（ポイント、ミッション、褒美、履歴、壁紙）を保持し、
/// 永続化も担当するクラス。
///
/// [ChangeNotifier] を継承しているので、状態が変わるたびに [notifyListeners]
/// を呼び、画面側 (AnimatedBuilder) が自動的に再描画される。
class AppState extends ChangeNotifier {
  AppState({WallpaperStore? wallpaperStore}) : _wallpaperStore = wallpaperStore ?? WallpaperStore();

  final WallpaperStore _wallpaperStore;

  int points = 0;

  /// 壁紙画像（縮小済みの JPEG）。未設定なら null で、標準背景を表示する。
  Uint8List? wallpaper;

  /// 壁紙のトリミング位置。'top' / 'center' / 'bottom' のいずれか。
  /// 画面比率に合わない画像を設定したとき、どの部分を見せるかを選べるようにする。
  String wallpaperAlignment = 'center';
  List<Mission> missions = [];
  List<Reward> rewards = [];
  List<PointLog> logs = [];

  /// 最後にバックアップを書き出した日時。
  DateTime? lastBackupAt;

  /// 起動時に保存データを読み込む。
  /// 保存データが壊れていても起動できるよう、読み込みに失敗した項目は
  /// 空リスト/初期値のまま続行する。
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    points = prefs.getInt('points') ?? 0;
    wallpaperAlignment = prefs.getString('wallpaperAlignment') ?? 'center';
    missions = _decodeList(prefs.getString('missions'), Mission.fromJson);
    rewards = _decodeList(prefs.getString('rewards'), Reward.fromJson);
    logs = _decodeList(prefs.getString('logs'), PointLog.fromJson);
    final backup = prefs.getString('lastBackupAt');
    lastBackupAt = backup == null ? null : DateTime.tryParse(backup);
    await _loadWallpaper(prefs);
    refreshTimeRules();
  }

  Future<void> _loadWallpaper(SharedPreferences prefs) async {
    try {
      wallpaper = await _wallpaperStore.read();
      // 旧版は画像ファイルのパスを保存していたので、見つかれば新しい保存先へ移す。
      final legacyPath = prefs.getString('wallpaper');
      if (legacyPath != null) {
        if (wallpaper == null) {
          final bytes = await _wallpaperStore.readLegacyFile(legacyPath);
          if (bytes != null) {
            await _wallpaperStore.write(bytes);
            wallpaper = bytes;
          }
        }
        await prefs.remove('wallpaper');
      }
    } catch (_) {
      // 壁紙が読めなくても、標準背景で起動できれば十分。
      wallpaper = null;
    }
  }

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // 保存データが壊れている場合は諦めて空リストから始める。
      return [];
    }
  }

  /// 現在の状態を保存し、画面を更新する。
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('points', points);
    await prefs.setString('wallpaperAlignment', wallpaperAlignment);
    await prefs.setString('missions', jsonEncode(missions.map((e) => e.toJson()).toList()));
    await prefs.setString('rewards', jsonEncode(rewards.map((e) => e.toJson()).toList()));
    await prefs.setString('logs', jsonEncode(logs.map((e) => e.toJson()).toList()));
    if (lastBackupAt == null) {
      await prefs.remove('lastBackupAt');
    } else {
      await prefs.setString('lastBackupAt', lastBackupAt!.toIso8601String());
    }
    notifyListeners();
  }

  /// 営業日の切り替わりに応じて、デイリーミッションのリセットと
  /// 期間限定ミッションの期限切れ判定を行う。
  /// 起動時・AM5:00 のタイマー・アプリ復帰時に呼ばれる（画面描画中には呼ばない）。
  ///
  /// - デイリー: 達成した営業日が「今日」でなくなったら active に戻す。
  ///   昨日も達成していなければ連続記録を 0 に戻す。
  /// - 期間限定: 期限日の営業日が終わっても未達成なら failed にする。
  void refreshTimeRules() {
    final today = todayBusinessDayKey();
    var changed = false;

    for (final mission in missions) {
      if (mission.type == MissionType.daily) {
        if (mission.completedDay != null && mission.completedDay != today) {
          mission.status = MissionStatus.active;
          mission.completedDay = null;
          changed = true;
        }
        if (mission.streak != 0 && mission.currentStreak(today) == 0) {
          mission.streak = 0;
          changed = true;
        }
      }

      if (mission.type == MissionType.limited &&
          mission.status == MissionStatus.active &&
          mission.deadline != null &&
          mission.daysLeft(today)! < 0) {
        mission.status = MissionStatus.failed;
        changed = true;
      }
    }

    // 変更がなくても「残り○日」などの表示は日付で変わるので、画面は更新する。
    if (changed) {
      save();
    } else {
      notifyListeners();
    }
  }

  Future<void> addMission(Mission mission) async {
    missions.add(mission);
    await save();
  }

  /// 既存のミッションを編集内容で置き換える（デイリーのみUIから編集可能）。
  Future<void> updateMission(Mission mission) async {
    final index = missions.indexWhere((m) => m.id == mission.id);
    if (index >= 0) missions[index] = mission;
    await save();
  }

  Future<void> complete(Mission mission) async {
    mission.status = MissionStatus.completed;
    if (mission.type == MissionType.daily) {
      final today = todayBusinessDayKey();
      mission.streak = mission.lastCompletedDay == previousDayKey(today) ? mission.streak + 1 : 1;
      mission.lastCompletedDay = today;
      mission.completedDay = today;
    }
    points += mission.points;
    logs.insert(
      0,
      PointLog(
        id: generateId(),
        title: '${mission.title}を達成',
        delta: mission.points,
        balance: points,
        at: DateTime.now(),
      ),
    );
    await save();
  }

  Future<void> deleteMission(Mission mission) async {
    missions.removeWhere((m) => m.id == mission.id);
    await save();
  }

  Future<void> addReward(Reward reward) async {
    rewards.add(reward);
    await save();
  }

  /// 褒美を削除する。使ったポイントは戻らず、受け取った記録も履歴に残る。
  Future<void> deleteReward(Reward reward) async {
    rewards.removeWhere((r) => r.id == reward.id);
    await save();
  }

  /// 褒美を受け取り、ポイントを消費する。
  /// UI側で残高チェック済みであることを前提としているが、念のため
  /// ここでも受け取れない状態なら何もしない（不正な呼び出しからの防御）。
  Future<void> receive(Reward reward) async {
    if (points < reward.cost || !reward.available) return;
    points -= reward.cost;
    reward.receivedCount += 1;
    if (!reward.repeatable) reward.received = true;
    logs.insert(
      0,
      PointLog(
        id: generateId(),
        title: '${reward.title}を受け取った',
        delta: -reward.cost,
        balance: points,
        at: DateTime.now(),
      ),
    );
    await save();
  }

  /// 壁紙を設定する（縮小済みの画像を渡す）。null で標準背景に戻す。
  Future<void> setWallpaper(Uint8List? bytes) async {
    if (bytes == null) {
      await _wallpaperStore.delete();
    } else {
      await _wallpaperStore.write(bytes);
    }
    wallpaper = bytes;
    notifyListeners();
  }

  /// 壁紙のトリミング位置を変更する（'top' / 'center' / 'bottom'）。
  Future<void> setWallpaperAlignment(String alignment) async {
    wallpaperAlignment = alignment;
    await save();
  }

  /// ポイント・ミッション・褒美・履歴がすべて初期状態か。
  /// バックアップの読み込みはこの状態のときだけ許可する（やり直しの抜け道にしないため）。
  bool get isEmpty => points == 0 && missions.isEmpty && rewards.isEmpty && logs.isEmpty;

  /// バックアップ用のデータ（壁紙以外のすべて）。
  Map<String, dynamic> exportBackup() => {
        'app': backupAppId,
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'points': points,
        'missions': missions.map((e) => e.toJson()).toList(),
        'rewards': rewards.map((e) => e.toJson()).toList(),
        'logs': logs.map((e) => e.toJson()).toList(),
      };

  /// バックアップを書き出したことを記録する。
  Future<void> markBackedUp() async {
    lastBackupAt = DateTime.now();
    await save();
  }

  /// バックアップを読み込み、今のデータを丸ごと置き換える。
  /// データが空でない場合や、ファイルの中身が正しくない場合は [BackupException] を投げ、
  /// 今のデータには一切手を付けない。
  Future<void> importBackup(String raw) async {
    if (!isEmpty) throw const BackupException('データが空のときだけ読み込めます');

    final int newPoints;
    final List<Mission> newMissions;
    final List<Reward> newRewards;
    final List<PointLog> newLogs;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['app'] != backupAppId) throw const FormatException();
      newPoints = json['points'] as int;
      newMissions = (json['missions'] as List).map((e) => Mission.fromJson(e as Map<String, dynamic>)).toList();
      newRewards = (json['rewards'] as List).map((e) => Reward.fromJson(e as Map<String, dynamic>)).toList();
      newLogs = (json['logs'] as List).map((e) => PointLog.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const BackupException('このアプリのバックアップファイルではないか、内容が壊れています');
    }

    points = newPoints;
    missions = newMissions;
    rewards = newRewards;
    logs = newLogs;
    refreshTimeRules();
    await save();
  }

  /// ポイント・ミッション・褒美・履歴をすべて初期状態に戻す。
  /// 壁紙は見た目の好み設定なので対象外（消えると驚きが大きいため）。
  /// 取り消せないため、呼び出し側で確認を取ってから呼ぶこと。
  Future<void> resetAll() async {
    points = 0;
    missions = [];
    rewards = [];
    logs = [];
    await save();
  }
}

const backupAppId = 'mission_reward_app';

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => message;
}
