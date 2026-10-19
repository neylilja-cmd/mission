import '../utils/business_day.dart';

enum MissionType { daily, normal, limited }

enum MissionStatus { active, completed, failed }

/// 1件のミッション（やることリストの項目）を表すモデル。
class Mission {
  final String id;
  String title;
  String note;
  int points;
  MissionType type;
  MissionStatus status;
  final DateTime createdAt;

  /// [MissionType.limited] の場合のみ使用する期限。
  /// 「期限日の AM4:59:59」として保存し、期限日の営業日（翌日 AM5:00 まで）が終わるまでを期限内とする。
  DateTime? deadline;

  /// [MissionType.daily] が「達成済み」になった営業日のキー (yyyy-MM-dd)。
  /// 営業日が変わるとリセットされ、再び挑戦できるようになる。
  String? completedDay;

  /// [MissionType.daily] の連続達成日数と、最後に達成した営業日のキー。
  /// [completedDay] は日付が変わるとリセットされるため、連続判定用に別で持つ。
  int streak;
  String? lastCompletedDay;

  Mission({
    required this.id,
    required this.title,
    required this.note,
    required this.points,
    required this.type,
    required this.status,
    required this.createdAt,
    this.deadline,
    this.completedDay,
    this.streak = 0,
    this.lastCompletedDay,
  });

  /// 今日時点で有効な連続達成日数。
  /// 昨日も今日も達成していなければ、記録上の値に関わらず途切れている。
  int currentStreak(String today) {
    if (lastCompletedDay == null) return 0;
    if (lastCompletedDay == today || lastCompletedDay == previousDayKey(today)) return streak;
    return 0;
  }

  /// 期限日まで残り何日か（期限日当日なら0）。期限がなければ null。
  int? daysLeft(String today) => deadline == null ? null : dayKeyDiff(today, deadlineDayKey(deadline!));

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'points': points,
        'type': type.index,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'completedDay': completedDay,
        'streak': streak,
        'lastCompletedDay': lastCompletedDay,
      };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'],
        title: json['title'],
        note: json['note'] ?? '',
        points: json['points'],
        type: MissionType.values[json['type']],
        status: MissionStatus.values[json['status']],
        createdAt: DateTime.parse(json['createdAt']),
        deadline: json['deadline'] == null ? null : DateTime.parse(json['deadline']),
        completedDay: json['completedDay'],
        // 連続記録が無かった頃のデータは、今日達成済みなら1日目として扱う。
        streak: json['streak'] ?? (json['completedDay'] != null ? 1 : 0),
        lastCompletedDay: json['lastCompletedDay'] ?? json['completedDay'],
      );
}
