import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dialogs/confirm_dialog.dart';
import '../state/app_state.dart';
import '../ui/ui_constants.dart';
import '../utils/wallpaper_image.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';
import '../widgets/pill_tabs.dart';

/// 設定画面。壁紙・バックアップ・完全リセットをまとめる。
/// 日々使うものだけをホームに残し、危険な操作を普段の画面から離すため。
class SettingsPage extends StatefulWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppState get state => widget.state;
  bool processingWallpaper = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickWallpaper() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;

    setState(() => processingWallpaper = true);
    // 縮小処理の前に、処理中の表示を画面に出しておく。
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final shrunk = shrinkWallpaper(bytes);
      if (shrunk == null) {
        _showMessage('この画像は読み込めませんでした（JPEG・PNG などを選んでください）');
        return;
      }
      await state.setWallpaper(shrunk);
    } catch (_) {
      _showMessage('壁紙を保存できませんでした');
    } finally {
      if (mounted) setState(() => processingWallpaper = false);
    }
  }

  Future<void> _exportBackup() async {
    final fileName = 'mission_backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    final bytes = utf8.encode(const JsonEncoder.withIndent(' ').convert(state.exportBackup()));
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'バックアップを保存',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      // Web ではダウンロードが始まった時点で null が返るので、PC でキャンセルした場合だけ除外する。
      if (path == null && !kIsWeb) return;
      await state.markBackedUp();
      _showMessage('バックアップを書き出しました');
    } catch (_) {
      _showMessage('バックアップを書き出せませんでした');
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null || !mounted) return;

    final confirmed = await confirmOnce(
      context,
      title: 'バックアップを読み込みますか？',
      message: 'ファイルの内容で、ポイント・ミッション・褒美・履歴を復元します。',
      confirmLabel: '読み込む',
    );
    if (!confirmed) return;

    try {
      await state.importBackup(utf8.decode(bytes));
      _showMessage('バックアップを読み込みました');
    } on BackupException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('このアプリのバックアップファイルではないか、内容が壊れています');
    }
  }

  Future<void> _resetAll() async {
    final confirmed = await confirmTwoStep(
      context,
      '本当に完全リセットしますか？',
      'ポイント・ミッション・褒美・履歴を、すべて初期状態に戻します。（壁紙設定は残ります）\n'
          'この操作は取り消せません。\n本当にリセットしますか？',
    );
    if (confirmed) {
      await state.resetAll();
      _showMessage('すべてのデータをリセットしました');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => AppBackground(
        state: state,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('設定'),
            titleTextStyle: AppTextStyles.title.copyWith(fontSize: 18),
            backgroundColor: Colors.white.withValues(alpha: 0.78),
            surfaceTintColor: Colors.transparent,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: UiConstants.contentMaxWidth),
              child: ListView(
                padding: const EdgeInsets.all(UiConstants.pagePadding),
                children: [
                  _wallpaperSection(),
                  const SizedBox(height: UiConstants.gap),
                  _backupSection(),
                  const SizedBox(height: UiConstants.gap),
                  _resetSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wallpaperSection() {
    return _Section(
      title: '壁紙',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: processingWallpaper ? null : _pickWallpaper,
              child: const Text('画像を選ぶ'),
            ),
            if (state.wallpaper != null)
              OutlinedButton(
                onPressed: processingWallpaper ? null : () => state.setWallpaper(null),
                child: const Text('標準背景に戻す'),
              ),
          ],
        ),
        if (processingWallpaper) ...[
          const SizedBox(height: 10),
          const Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('画像を処理しています…', style: AppTextStyles.label),
            ],
          ),
        ],
        const SizedBox(height: 14),
        const Text('表示位置（画像が画面に合わないとき、どこを見せるか）', style: AppTextStyles.small),
        const SizedBox(height: 6),
        PillTabs<String>(
          items: const {'top': '上', 'center': '中央', 'bottom': '下'},
          selected: state.wallpaperAlignment,
          onChanged: state.setWallpaperAlignment,
        ),
      ],
    );
  }

  Widget _backupSection() {
    final last = state.lastBackupAt;
    return _Section(
      title: 'バックアップ',
      children: [
        const Text(
          'ポイント・ミッション・褒美・履歴をファイルに保存します。'
          'ブラウザのデータが消えたときや、端末を変えたときに読み込んで復元できます（壁紙は含みません）。',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 8),
        Text(
          last == null ? '最終バックアップ：まだありません' : '最終バックアップ：${DateFormat('yyyy/MM/dd HH:mm').format(last)}',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: _exportBackup, child: const Text('書き出す')),
            OutlinedButton(onPressed: state.isEmpty ? _importBackup : null, child: const Text('読み込む')),
          ],
        ),
        if (!state.isEmpty) ...[
          const SizedBox(height: 6),
          const Text('読み込みは、データが空のとき（初回や完全リセット後）だけできます。', style: AppTextStyles.small),
        ],
      ],
    );
  }

  Widget _resetSection() {
    return _Section(
      title: '完全リセット',
      titleColor: AppColors.achieve,
      children: [
        const Text('ポイント・ミッション・褒美・履歴をすべて消します（壁紙は残ります）。取り消せません。', style: AppTextStyles.small),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.achieve,
            side: const BorderSide(color: AppColors.achieve),
          ),
          onPressed: _resetAll,
          child: const Text('リセットする'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final List<Widget> children;
  const _Section({required this.title, required this.children, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title.copyWith(fontSize: 16, color: titleColor)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
