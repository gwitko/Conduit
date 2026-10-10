import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/local_shell/domain/local_shell_distro.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:flutter/material.dart';

class LocalShellSetupRequest {
  const LocalShellSetupRequest({required this.distroId, required this.name});

  final String distroId;
  final String name;
}

class LocalShellSetupPage extends StatefulWidget {
  const LocalShellSetupPage({required this.controller, super.key});

  final LocalShellController controller;

  @override
  State<LocalShellSetupPage> createState() => _LocalShellSetupPageState();
}

class _LocalShellSetupPageState extends State<LocalShellSetupPage> {
  late String _distroId;
  late final TextEditingController _nameController;
  bool _nameEdited = false;

  @override
  void initState() {
    super.initState();
    _distroId = widget.controller.catalog.first.id;
    _nameController = TextEditingController(text: _suggestedName(_distroId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _suggestedName(String distroId) {
    final distro = widget.controller.distroById(distroId);
    if (distro == null) return '';
    final taken = widget.controller.instances
        .map((instance) => instance.name)
        .toSet();
    if (!taken.contains(distro.name)) return distro.name;
    var suffix = 2;
    while (taken.contains('${distro.name} $suffix')) {
      suffix += 1;
    }
    return '${distro.name} $suffix';
  }

  void _selectDistro(String distroId) {
    setState(() {
      _distroId = distroId;
      if (!_nameEdited) {
        _nameController.text = _suggestedName(distroId);
      }
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    Navigator.of(context).pop(
      LocalShellSetupRequest(
        distroId: _distroId,
        name: name.isEmpty ? _suggestedName(_distroId) : name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.controller.distroById(_distroId);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.localShellNew)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.localShellSetupTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.localShellSetupBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              for (final distro in widget.controller.catalog) ...[
                _DistroOption(
                  distro: distro,
                  selected: distro.id == _distroId,
                  onTap: () => _selectDistro(distro.id),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                onChanged: (_) => _nameEdited = true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: context.l10n.labelName,
                  helperText: context.l10n.localShellNameHint,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  selected == null
                      ? context.l10n.actionInstall
                      : context.l10n.localShellInstallWithSize(
                          formatLocalShellBytes(
                            selected.manifest.downloadSizeBytes,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.localShellInstallHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistroOption extends StatelessWidget {
  const _DistroOption({
    required this.distro,
    required this.selected,
    required this.onTap,
  });

  final LocalShellDistro distro;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.55)
                  : colorScheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      distro.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.localShellDownloadWithSize(
                        formatLocalShellBytes(
                          distro.manifest.downloadSizeBytes,
                        ),
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatLocalShellBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return 'unknown';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final fixed = unit == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$fixed ${units[unit]}';
}
