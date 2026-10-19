import 'dart:ui';

import 'package:flutter/material.dart';

import '../ui/ui_constants.dart';

/// 壁紙の上に浮かべる半透明パネル。全画面でこの1種類に統一する。
///
/// [blur] を true にすると背景をぼかし、どんな壁紙の上でも文字が読みやすくなる。
/// ぼかしは描画負荷が高いので、件数が増える一覧の行では false にし、
/// 代わりに少し濃い白で同じ見え方に寄せる。
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool blur;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.blur = true,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(UiConstants.panelRadius);
    Widget content = Material(
      color: Colors.white.withValues(alpha: blur ? 0.62 : 0.74),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (blur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: content),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x1F1E2050), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: content,
    );
  }
}
