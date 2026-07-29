import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../domain/app_release.dart';
import '../domain/i_update_repository.dart';

/// Checks for an update at launch and prompts if one is available. Never throws
/// — a failed check must not block the app.
Future<void> maybePromptUpdate(BuildContext context) async {
  try {
    final info = await getIt<IUpdateRepository>().checkForUpdate();
    if (info == null || !context.mounted) return;
    await showUpdateSheet(context, info);
  } catch (_) {
    // ignore
  }
}

/// Manual "Check for updates" (from Settings): shows the sheet if an update is
/// available, otherwise a brief "up to date" confirmation.
Future<void> checkForUpdatesInteractive(BuildContext context) async {
  AppUpdateInfo? info;
  try {
    info = await getIt<IUpdateRepository>().checkForUpdate();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Couldn\'t check for updates. Try again later.')));
    }
    return;
  }
  if (!context.mounted) return;
  if (info == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('You\'re on the latest version.')));
  } else {
    await showUpdateSheet(context, info);
  }
}

Future<void> showUpdateSheet(BuildContext context, AppUpdateInfo info) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: !info.mandatory,
    enableDrag: !info.mandatory,
    showDragHandle: !info.mandatory,
    builder: (_) => _UpdateSheet(info: info),
  );
}

enum _Stage { idle, downloading, needsPermission, error }

class _UpdateSheet extends StatefulWidget {
  final AppUpdateInfo info;
  const _UpdateSheet({required this.info});

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  final _repo = getIt<IUpdateRepository>();
  _Stage _stage = _Stage.idle;
  double _progress = 0;
  String? _apkPath;
  String? _error;

  AppRelease get _release => widget.info.release;
  bool get _mandatory => widget.info.mandatory;

  Future<void> _download() async {
    setState(() {
      _stage = _Stage.downloading;
      _progress = 0;
      _error = null;
    });
    try {
      final path = await _repo.downloadApk(
        _release,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      _apkPath = path;
      await _install();
    } catch (_) {
      if (mounted) {
        setState(() {
          _stage = _Stage.error;
          _error = 'Download failed. Check your connection and try again.';
        });
      }
    }
  }

  Future<void> _install() async {
    final path = _apkPath;
    if (path == null) return;
    if (!await _repo.canInstall()) {
      if (mounted) setState(() => _stage = _Stage.needsPermission);
      return;
    }
    await _repo.install(path); // hands off to the system installer
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_mandatory,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: _mandatory ? 24 : 4,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _mandatory ? 'Update required' : 'Update available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Version ${_release.versionName}',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            if (_release.changelog.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_release.changelog),
            ],
            const SizedBox(height: 20),
            ..._body(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    switch (_stage) {
      case _Stage.downloading:
        return [
          LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          const SizedBox(height: 8),
          Text('Downloading… ${(_progress * 100).round()}%'),
        ];
      case _Stage.needsPermission:
        return [
          const Text(
              'To install the update, allow Data Guardian to install apps, then tap Install.'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _repo.openInstallSettings(),
                  child: const Text('Allow installs'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _install,
                  child: const Text('Install'),
                ),
              ),
            ],
          ),
        ];
      case _Stage.error:
        return [
          Text(_error ?? 'Something went wrong.',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
          _actions(primaryLabel: 'Retry', onPrimary: _download),
        ];
      case _Stage.idle:
        return [_actions(primaryLabel: 'Update now', onPrimary: _download)];
    }
  }

  Widget _actions({required String primaryLabel, required VoidCallback onPrimary}) {
    return Row(
      children: [
        if (!_mandatory)
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ),
        if (!_mandatory) const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        ),
      ],
    );
  }
}
