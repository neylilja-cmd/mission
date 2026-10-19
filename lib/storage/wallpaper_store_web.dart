import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'wallpaper_store.dart';

const _dbName = 'mission_reward_app';
const _storeName = 'files';
const _key = 'wallpaper';

class PlatformWallpaperStore implements WallpaperStore {
  Future<web.IDBDatabase>? _db;

  Future<web.IDBDatabase> _open() => _db ??= () {
        final completer = Completer<web.IDBDatabase>();
        final request = web.window.indexedDB.open(_dbName, 1);
        request.onupgradeneeded = (web.Event _) {
          (request.result as web.IDBDatabase).createObjectStore(_storeName);
        }.toJS;
        request.onsuccess = (web.Event _) {
          completer.complete(request.result as web.IDBDatabase);
        }.toJS;
        request.onerror = (web.Event _) {
          completer.completeError(StateError('IndexedDB を開けませんでした'));
        }.toJS;
        return completer.future;
      }();

  Future<JSAny?> _run(String mode, web.IDBRequest Function(web.IDBObjectStore store) action) async {
    final db = await _open();
    final store = db.transaction(_storeName.toJS, mode).objectStore(_storeName);
    final request = action(store);
    final completer = Completer<JSAny?>();
    request.onsuccess = (web.Event _) {
      completer.complete(request.result);
    }.toJS;
    request.onerror = (web.Event _) {
      completer.completeError(StateError('壁紙の読み書きに失敗しました'));
    }.toJS;
    return completer.future;
  }

  @override
  Future<Uint8List?> read() async {
    final result = await _run('readonly', (s) => s.get(_key.toJS));
    if (result == null || result.isUndefinedOrNull) return null;
    return (result as JSUint8Array).toDart;
  }

  @override
  Future<void> write(Uint8List bytes) => _run('readwrite', (s) => s.put(bytes.toJS, _key.toJS));

  @override
  Future<void> delete() => _run('readwrite', (s) => s.delete(_key.toJS));

  @override
  Future<Uint8List?> readLegacyFile(String path) async => null;
}
