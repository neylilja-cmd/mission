/// ポイントと交換できる「褒美」を表すモデル。
class Reward {
  final String id;
  String title;
  String note;
  int cost;

  /// 1回限りの褒美を受け取り済みかどうか。くり返しの褒美では常に false。
  bool received;

  /// true なら何度でも受け取れる「くり返し」の褒美。登録後は変更しない。
  final bool repeatable;

  /// 受け取った回数（くり返しの褒美で表示に使う）。
  int receivedCount;
  final DateTime createdAt;

  Reward({
    required this.id,
    required this.title,
    required this.note,
    required this.cost,
    required this.received,
    required this.createdAt,
    this.repeatable = false,
    this.receivedCount = 0,
  });

  /// まだ受け取れる状態か（ポイント残高は別途チェックする）。
  bool get available => repeatable || !received;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'cost': cost,
        'received': received,
        'repeatable': repeatable,
        'receivedCount': receivedCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['id'],
        title: json['title'],
        note: json['note'] ?? '',
        cost: json['cost'],
        received: json['received'],
        repeatable: json['repeatable'] ?? false,
        receivedCount: json['receivedCount'] ?? (json['received'] == true ? 1 : 0),
        createdAt: DateTime.parse(json['createdAt']),
      );
}
