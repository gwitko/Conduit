import 'dart:async';
import 'dart:convert';

import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/theme/app_theme.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:conduit/features/hosts/presentation/public_key_sheet.dart';
import 'package:conduit/features/hosts/presentation/widgets/key_source_actions.dart';
import 'package:conduit/features/hosts/presentation/widgets/ssh_key_summary.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class AddedHardwareKey {
  const AddedHardwareKey({required this.entry, required this.inspection});

  final HardwareKeyEntry entry;
  final SshKeyInspection inspection;
}

Future<AddedHardwareKey?> showAddHardwareKeySheet({
  required BuildContext context,
  required SshKeyService keyService,
  required Set<String> existingFingerprints,
  required Set<String> existingStubs,
}) {
  return showModalBottomSheet<AddedHardwareKey>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle(Theme.of(context).brightness),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _AddHardwareKeySheet(
          keyService: keyService,
          existingFingerprints: existingFingerprints,
          existingStubs: existingStubs,
        ),
      ),
    ),
  );
}

class _AddHardwareKeySheet extends StatefulWidget {
  const _AddHardwareKeySheet({
    required this.keyService,
    required this.existingFingerprints,
    required this.existingStubs,
  });

  final SshKeyService keyService;
  final Set<String> existingFingerprints;
  final Set<String> existingStubs;

  @override
  State<_AddHardwareKeySheet> createState() => _AddHardwareKeySheetState();
}

class _AddHardwareKeySheetState extends State<_AddHardwareKeySheet> {
  final _stubController = TextEditingController();
  final _labelController = TextEditingController();
  final _passphraseController = TextEditingController();
  SshKeyInspection? _inspection;
  String? _blockingError;
  bool _showPassphrase = false;
  bool _labelEdited = false;
  Timer? _verifyTimer;
  int _verifyToken = 0;

  static const _verifyDebounce = Duration(milliseconds: 350);

  String get _stub => _stubController.text.trim();

  @override
  void initState() {
    super.initState();
    _stubController.addListener(_recomputeInspection);
    _passphraseController.addListener(_recomputeInspection);
  }

  @override
  void dispose() {
    _verifyTimer?.cancel();
    _stubController.dispose();
    _labelController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  bool get _needsPassphrase => switch (_inspection?.status) {
    SshKeyStatus.needsPassphrase ||
    SshKeyStatus.verifying ||
    SshKeyStatus.wrongPassphrase => true,
    SshKeyStatus.securityKeyStub => _passphraseController.text.isNotEmpty,
    _ => false,
  };

  bool get _canAdd =>
      _blockingError == null &&
      _inspection?.status == SshKeyStatus.securityKeyStub;

  void _setStub(String text) {
    _labelEdited = _labelController.text.trim().isNotEmpty && _labelEdited;
    _passphraseController.clear();
    _stubController.text = text.trim();
  }

  void _recomputeInspection() {
    _verifyTimer?.cancel();
    final token = ++_verifyToken;
    if (_stub.isEmpty) {
      _applyInspection(null);
      return;
    }
    final preview = widget.keyService.inspect(_stub);
    if (preview.status == SshKeyStatus.needsPassphrase &&
        _passphraseController.text.isNotEmpty) {
      _applyInspection(const SshKeyInspection.verifying());
      final stub = _stub;
      final passphrase = _passphraseController.text;
      _verifyTimer = Timer(_verifyDebounce, () async {
        final result = await widget.keyService.verify(
          stub,
          passphrase: passphrase,
        );
        if (!mounted || token != _verifyToken) return;
        _applyInspection(result);
      });
    } else {
      _applyInspection(preview);
    }
  }

  void _applyInspection(SshKeyInspection? inspection) {
    final details = inspection?.details;
    String? blockingError;
    if (inspection != null) {
      blockingError = switch (inspection.status) {
        SshKeyStatus.valid => context.l10n.addHardwareKeyNormalKey,
        SshKeyStatus.invalid => context.l10n.addHardwareKeyNotStub,
        _ => null,
      };
      if (inspection.status == SshKeyStatus.securityKeyStub &&
          details != null) {
        if (widget.existingFingerprints.contains(details.fingerprintSha256) ||
            widget.existingStubs.contains(_stub)) {
          blockingError = context.l10n.addHardwareKeyDuplicate;
        } else if (!_labelEdited) {
          _labelController.text = details.comment.trim();
        }
      }
    }
    setState(() {
      _inspection = inspection;
      _blockingError = blockingError;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty || !mounted) return;
    _setStub(text);
  }

  Future<void> _importFile() async {
    final l10n = context.l10n;
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(withData: true);
    } catch (_) {
      _showSnack(l10n.commonFilePickerFailed);
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      _showSnack(l10n.commonFileReadFailed);
      return;
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      _showSnack(l10n.addHardwareKeyNotTextStub);
      return;
    }
    if (!mounted) return;
    _setStub(text);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _viewPublicKey() {
    final details = _inspection?.details;
    if (details == null) return;
    showPublicKeySheet(context: context, details: details);
  }

  void _add() {
    final inspection = _inspection;
    if (inspection?.status != SshKeyStatus.securityKeyStub || !_canAdd) {
      return;
    }
    final entry = HardwareKeyEntry(
      id: const Uuid().v4(),
      privateKey: _stub,
      label: _labelController.text.trim(),
      passphrase: _passphraseController.text,
    );
    Navigator.of(
      context,
    ).pop(AddedHardwareKey(entry: entry, inspection: inspection!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inspection = _inspection;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.addHardwareKeyTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const Spacer(),
              const ConduitGlyph(size: 24),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.addHardwareKeyBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          KeySourceActions(onImportFile: _importFile, onPaste: _paste),
          const SizedBox(height: 14),
          TextField(
            controller: _stubController,
            decoration: InputDecoration(
              labelText: context.l10n.addHardwareKeyStubLabel,
              helperText: context.l10n.addHardwareKeyStubHint,
              helperMaxLines: 2,
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(Icons.vpn_key_outlined),
              ),
            ),
            minLines: 5,
            maxLines: 9,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
          if (inspection != null) ...[
            const SizedBox(height: 14),
            SshKeySummary(
              inspection: inspection,
              onViewPublicKey: _viewPublicKey,
            ),
          ],
          if (_blockingError != null) ...[
            const SizedBox(height: 14),
            _ErrorNotice(message: _blockingError!),
          ],
          if (_needsPassphrase) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _passphraseController,
              decoration: InputDecoration(
                labelText: context.l10n.addHardwareKeyPassphrase,
                helperText: context.l10n.addHardwareKeyPassphraseHint,
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.shield_outlined),
                suffixIcon: IconButton(
                  tooltip: _showPassphrase
                      ? context.l10n.actionHide
                      : context.l10n.actionShow,
                  icon: Icon(
                    _showPassphrase
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _showPassphrase = !_showPassphrase),
                ),
              ),
              obscureText: !_showPassphrase,
            ),
          ],
          if (inspection?.status == SshKeyStatus.securityKeyStub) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _labelController,
              onChanged: (_) => _labelEdited = true,
              decoration: InputDecoration(
                labelText: context.l10n.labelLabel,
                helperText: context.l10n.addHardwareKeyLabelHint,
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.label_outline_rounded),
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _canAdd ? _add : null,
              icon: const Icon(Icons.check_rounded),
              label: Text(context.l10n.addHardwareKeySubmit),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.error.withValues(alpha: 0.08),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
