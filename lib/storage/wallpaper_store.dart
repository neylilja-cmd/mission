import 'dart:typed_data';

import 'wallpaper_store_io.dart' if (dart.library.js_interop) 'wallpaper_store_web.dart' as impl;

/// 壁紙画像の保存先。
/// 画像はサイズが大きいので、ミッションなどのデータ本体（SharedPreferences）とは
/// 別の場所に置き、壁紙側で問題が起きてもデータ本体に影響しないようにする。
/// - Web: IndexedDB
/// - Windows など: アプリ専用フォルダ内のファイル
abstract class WallpaperStore {
  factory WallpaperStore() = impl.PlatformWallpaperStore;

  Future<Uint8List?> read();
  Future<void> write(Uint8List bytes);
  Future<void> delete();

  /// 旧版（画像ファイルのパスを保存していた頃）の壁紙を読み込む。
  /// Web では旧版が存在しないので常に null。
  Future<Uint8List?> readLegacyFile(String path);
}

/// テストなどで使う、メモリ上だけの保存先。
class MemoryWallpaperStore implements WallpaperStore {
  Uint8List? bytes;

  @override
  Future<Uint8List?> read() async => bytes;
  @override
  Future<void> write(Uint8List value) async => bytes = value;
  @override
  Future<void> delete() async => bytes = null;
  @override
  Future<Uint8List?> readLegacyFile(String path) async => null;
}
