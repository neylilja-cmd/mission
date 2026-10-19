import 'package:intl/intl.dart';

/// ミッションやポイント履歴の一意なIDを生成する。
/// マイクロ秒単位のタイムスタンプなので、同一マイクロ秒内に複数回
/// 呼ばれない限り衝突しない。
String generateId() => DateTime.now().microsecondsSinceEpoch.toString();

/// 「営業日」の区切りを計算するためのオフセット。
/// このアプリでは深夜〜早朝(AM5:00より前)の活動を「前日扱い」にしたいので、
/// 実時刻から5時間引いた時刻の「日付」をその日のキーとして扱う。
/// 例: 6/16 02:00 の操作は 6/15 のデイリーミッション/履歴として扱われる。
const businessDayOffset = Duration(hours: 5);

final _keyFormat = DateFormat('yyyy-MM-dd');

/// 指定した日時が属する「営業日」のキー (yyyy-MM-dd) を返す。
String businessDayKey(DateTime dateTime) => _keyFormat.format(dateTime.subtract(businessDayOffset));

/// 「今日」の営業日キー（よく使うのでショートカット）。
String todayBusinessDayKey() => businessDayKey(DateTime.now());

/// 日付キーの差（日数）を返す。[to] が [from] より後なら正の値。
/// 夏時間などの影響を受けないよう、UTCの日付として計算する。
int dayKeyDiff(String from, String to) {
  DateTime parse(String key) {
    final d = _keyFormat.parse(key);
    return DateTime.utc(d.year, d.month, d.day);
  }

  return parse(to).difference(parse(from)).inDays;
}

/// 日付キーの前日のキーを返す。
String previousDayKey(String key) {
  final d = _keyFormat.parse(key);
  return _keyFormat.format(DateTime(d.year, d.month, d.day - 1));
}

/// 期限日時から「期限日」のキーを返す。
/// 期限は「期限日の AM4:59:59」として保存されているため、時刻は無視して日付部分だけを使う。
/// その営業日（翌日 AM5:00 まで）が終わるまでが期限内。
String deadlineDayKey(DateTime deadline) => _keyFormat.format(deadline);

/// 次の営業日の切り替わり（AM5:00）の日時を返す。
DateTime nextBusinessDayStart(DateTime now) {
  final todayStart = DateTime(now.year, now.month, now.day, 5);
  return now.isBefore(todayStart) ? todayStart : DateTime(now.year, now.month, now.day + 1, 5);
}
