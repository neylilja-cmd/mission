import 'package:flutter/material.dart';

import '../state/app_state.dart';

/// 壁紙、または壁紙が未設定のときの標準背景を全面に敷く。
class AppBackground extends StatelessWidget {
  final AppState state;
  final Widget child;
  const AppBackground({super.key, required this.state, required this.child});

  @override
  Widget build(BuildContext context) {
    final bytes = state.wallpaper;
    return DecoratedBox(
      decoration: bytes != null
          ? BoxDecoration(
              color: const Color(0xFFB9A7E4),
              image: DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
                // 画面比率に合わない画像でも、上寄せ/中央/下寄せを選べるようにする。
                alignment: _alignment(state.wallpaperAlignment),
              ),
            )
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [Color(0xFF8FA6E6), Color(0xFFB9A7E4), Color(0xFFF0BFAE)],
                stops: [0, 0.45, 1],
              ),
            ),
      child: bytes != null
          ? child
          : DecoratedBox(
              // 標準背景に柔らかい光だまりを重ねて、のっぺりした印象を避ける。
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.7, -0.8),
                  radius: 0.9,
                  colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.8, 0.6),
                    radius: 0.9,
                    colors: [Color(0xCCFFD6BE), Color(0x00FFD6BE)],
                  ),
                ),
                child: child,
              ),
            ),
    );
  }
}

/// 壁紙位置の文字列設定 ('top'/'center'/'bottom') を Alignment に変換する。
Alignment _alignment(String value) {
  switch (value) {
    case 'top':
      return Alignment.topCenter;
    case 'bottom':
      return Alignment.bottomCenter;
    default:
      return Alignment.center;
  }
}
