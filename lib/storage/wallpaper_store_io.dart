import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'wallpaper_store.dart';

class PlatformWallpaperStore implements WallpaperStore {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}wallpaper.jpg');
  }

  @override
  Future<Uint8List?> read() async {
    final file = await _file();
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> delete() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }

  @override
  Future<Uint8List?> readLegacyFile(String path) async {
    final file = File(path);
    return await file.exists() ? file.readAsBytes() : null;
  }
}
