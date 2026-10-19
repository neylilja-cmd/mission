/// ポイントの増減履歴 1件分。
class PointLog {
  final String id;
  final String title;
  final int delta; // 増減量（達成なら+、交換受け取りなら-）
  final int balance; // このログ時点での残高
  final DateTime at;

  PointLog({
    required this.id,
    required this.title,
    required this.delta,
    required this.balance,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'delta': delta,
        'balance': balance,
        'at': at.toIso8601String(),
      };

  factory PointLog.fromJson(Map<String, dynamic> json) => PointLog(
        id: json['id'],
        title: json['title'],
        delta: json['delta'],
        balance: json['balance'],
        at: DateTime.parse(json['at']),
      );
}
