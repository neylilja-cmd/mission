import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 壁紙として保存する画像の長辺の上限（px）。スマホ画面の縦解像度と同程度。
const wallpaperMaxSide = 2000;

/// 選ばれた画像を壁紙用に縮小・圧縮して JPEG のバイト列にする。
/// スマホの写真は 1枚で数MB あり、そのままだと保存領域を圧迫するため。
/// 読み込めない形式の場合は null を返す。
Uint8List? shrinkWallpaper(Uint8List original) {
  final decoded = img.decodeImage(original);
  if (decoded == null) return null;

  // スマホで撮った写真の向き情報（EXIF）を画像そのものに反映しておく。
  var image = img.bakeOrientation(decoded);
  final longSide = image.width > image.height ? image.width : image.height;
  if (longSide > wallpaperMaxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: wallpaperMaxSide, interpolation: img.Interpolation.average)
        : img.copyResize(image, height: wallpaperMaxSide, interpolation: img.Interpolation.average);
  }
  return img.encodeJpg(image, quality: 85);
}
