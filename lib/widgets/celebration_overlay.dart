import 'dart:async';

import 'package:flutter/material.dart';

/// ミッション達成／褒美受け取りの瞬間だけ表示する、ポップアップ演出。
/// 画面中央にポイント変化がバウンドしながら出て、少し経つと自動的に消える。
/// 通常時の画面はシンプルにしたいので、演出はこの一瞬だけに留める。
Future<void> showCelebration(
  BuildContext context, {
  required String message,
  required String pointsText,
  required Color color,
}) async {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  final completer = Completer<void>();

  entry = OverlayEntry(
    builder: (ctx) => _CelebrationCard(
      message: message,
      pointsText: pointsText,
      color: color,
      onFinished: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

class _CelebrationCard extends StatefulWidget {
  final String message;
  final String pointsText;
  final Color color;
  final VoidCallback onFinished;

  const _CelebrationCard({
    required this.message,
    required this.pointsText,
    required this.color,
    required this.onFinished,
  });

  @override
  State<_CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<_CelebrationCard> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> scale;
  late final Animation<double> opacity;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    scale = CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    opacity = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    controller.forward();
    Future.delayed(const Duration(milliseconds: 1100), () async {
      if (!mounted) return;
      await controller.reverse();
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: opacity,
            child: ScaleTransition(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
                  border: Border.all(color: widget.color, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      widget.pointsText,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
