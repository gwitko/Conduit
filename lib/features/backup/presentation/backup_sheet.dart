import 'dart:async';
import 'dart:typed_data';

import 'package:conduit/features/backup/data/app_backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<void> showBackupSheet({
  required BuildContext context,
  required AppBackupService backupService,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BackupSheet(backupService: backupService),
  );
}

class _BackupSheet extends StatefulWidget {
  const _BackupSheet({required this.backupService});

  final AppBackupService backupService;

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Backup and restore', style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Backups include appearance, terminal settings, saved machines, order, and trusted host keys.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _BackupActionTile(
              icon: Icons.ios_share_rounded,
              title: 'Export without secrets',
              subtitle: 'Passwords and private key material are removed.',
              onTap: _busy ? null : () => _export(includeSecrets: false),
            ),
            const SizedBox(height: 10),
            _BackupActionTile(
              icon: Icons.enhanced_encryption_rounded,
              title: 'Export encrypted with secrets',
              subtitle: 'Credentials are protected with a backup password.',
              onTap: _busy ? null : () => _export(includeSecrets: true),
            ),
            const SizedBox(height: 10),
            _BackupActionTile(
              icon: Icons.restore_rounded,
              title: 'Import backup',
              subtitle: 'Imported machines are merged into this device.',
              onTap: _busy ? null : _import,
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _export({required bool includeSecrets}) async {
    final password = includeSecrets ? await _requestNewPassword() : null;
    if (includeSecrets && password == null) {
      return;
    }
    await _run(() async {
      final bytes = await widget.backupService.exportBackup(
        includeSecrets: includeSecrets,
        password: password,
      );
      final path = await FilePicker.saveFile(
        fileName: _backupFileName(includeSecrets: includeSecrets),
        bytes: bytes,
      );
      if (!mounted) return;
      _showMessage(path == null ? 'Export cancelled.' : 'Backup exported.');
    });
  }

  Future<void> _import() async {
    final result = await FilePicker.pickFiles(withData: true);
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null) {
      return;
    }
    var password = '';
    await _run(() async {
      while (true) {
        try {
          final imported = await widget.backupService.importBackup(
            Uint8List.fromList(bytes),
            password: password.isEmpty ? null : password,
          );
          if (!mounted) return;
          _showMessage(
            'Imported ${imported.hostsImported} machines and '
            '${imported.trustedKeysImported} trusted keys.',
          );
          return;
        } on AppBackupException catch (error) {
          if (!error.message.toLowerCase().contains('password')) {
            rethrow;
          }
          if (!mounted) return;
          final nextPassword = await _requestExistingPassword(error.message);
          if (nextPassword == null) {
            _showMessage('Import cancelled.');
            return;
          }
          password = nextPassword;
        }
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AppBackupException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Backup failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<String?> _requestNewPassword() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _BackupPasswordDialog(confirm: true),
    );
  }

  Future<String?> _requestExistingPassword(String message) {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _BackupPasswordDialog(confirm: false, message: message),
    );
  }

  String _backupFileName({required bool includeSecrets}) {
    final date = DateTime.now().toUtc().toIso8601String().split('T').first;
    final mode = includeSecrets ? 'encrypted' : 'public';
    return 'conduit-$mode-$date.${AppBackupService.fileExtension}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BackupActionTile extends StatelessWidget {
  const _BackupActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({required this.confirm, this.message});

  final bool confirm;
  final String? message;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.confirm ? 'Backup password' : 'Enter password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _confirmationController,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            Text(
              'Use at least 12 characters and at least three of lowercase, uppercase, numbers, and symbols.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }

  void _submit() {
    final password = _passwordController.text;
    if (widget.confirm) {
      final validation = AppBackupPasswordPolicy.validate(password);
      if (validation != null) {
        setState(() => _error = validation);
        return;
      }
      if (password != _confirmationController.text) {
        setState(() => _error = 'Passwords do not match.');
        return;
      }
    } else if (password.isEmpty) {
      setState(() => _error = 'Enter the backup password.');
      return;
    }
    Navigator.of(context).pop(password);
  }
}
