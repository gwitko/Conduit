import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class HostFormPage extends StatefulWidget {
  const HostFormPage({this.host, this.themeController, super.key});

  final SavedHost? host;
  final ThemeController? themeController;

  @override
  State<HostFormPage> createState() => _HostFormPageState();
}

class _HostFormPageState extends State<HostFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _tagController = TextEditingController();
  final _timeoutController = TextEditingController(text: '12');
  final _moshLocaleController = TextEditingController(text: 'C.UTF-8');
  final FocusNode _tagFocusNode = FocusNode();
  SshAuthMethod _authMethod = SshAuthMethod.password;
  bool _showPassword = false;
  bool _showPassphrase = false;
  bool _useMosh = false;
  bool _predictiveEchoEnabled = false;
  List<String> _tags = const [];

  bool get _isEditing => widget.host != null;

  @override
  void initState() {
    super.initState();
    final host = widget.host;
    if (host != null) {
      _nameController.text = host.name;
      _hostController.text = host.host;
      _portController.text = host.port.toString();
      _usernameController.text = host.username;
      _passwordController.text = host.password;
      _privateKeyController.text = host.privateKey;
      _passphraseController.text = host.passphrase;
      _tags = List<String>.from(host.tags);
      _timeoutController.text = host.connectionTimeoutSeconds.toString();
      _authMethod = host.authMethod;
      _useMosh = host.useMosh;
      _moshLocaleController.text = host.moshLocale;
      _predictiveEchoEnabled = host.predictiveEchoEnabled;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _passphraseController.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    _timeoutController.dispose();
    _moshLocaleController.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    if (_tags.any((t) => t.toLowerCase() == trimmed.toLowerCase())) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags = [..._tags, trimmed];
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags = _tags.where((t) => t != tag).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = widget.themeController?.palette;
    final body = SafeArea(
      bottom: shouldApplyBottomSafeArea(context),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            _HeaderBar(
              title: _isEditing ? 'Edit machine' : 'New machine',
              subtitle: _isEditing
                  ? 'Update connection details and credentials.'
                  : 'Connection profile and credentials.',
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.dns_rounded,
              title: 'Connection',
              caption: 'Where to reach this machine.',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    hintText: 'production-edge-01',
                    prefixIcon: Icon(Icons.label_important_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host or IP',
                          hintText: 'edge.example.com',
                          prefixIcon: Icon(Icons.public_rounded),
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(labelText: 'Port'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.next,
                        validator: _validatePort,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.lock_outline_rounded,
              title: 'Authentication',
              caption: 'Credentials are stored in platform secure storage.',
              children: [
                _AuthMethodPicker(
                  value: _authMethod,
                  onChanged: (method) => setState(() => _authMethod = method),
                ),
                const SizedBox(height: 14),
                if (_authMethod == SshAuthMethod.password)
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: 'Use this for password-only SSH login.',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Hide' : 'Show',
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    obscureText: !_showPassword,
                    validator: _authMethod == SshAuthMethod.password
                        ? _required
                        : null,
                  ),
                if (_authMethod == SshAuthMethod.privateKey ||
                    _authMethod == SshAuthMethod.hardwareKey) ...[
                  _AuthExplainer(method: _authMethod),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _privateKeyController,
                    decoration: InputDecoration(
                      labelText: _authMethod == SshAuthMethod.hardwareKey
                          ? 'OpenSSH hardware key stub'
                          : 'Private key',
                      helperText: _authMethod == SshAuthMethod.hardwareKey
                          ? 'Paste the id_ed25519_sk or id_ecdsa_sk file.'
                          : 'Paste a PEM or OpenSSH private key.',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Icon(Icons.vpn_key_outlined),
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Paste key',
                        icon: const Icon(Icons.content_paste_rounded),
                        onPressed: _pasteKey,
                      ),
                    ),
                    minLines: 5,
                    maxLines: 9,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                    ),
                    validator:
                        (_authMethod == SshAuthMethod.privateKey ||
                            _authMethod == SshAuthMethod.hardwareKey)
                        ? _validateKeyMaterial
                        : null,
                  ),
                  if (_authMethod == SshAuthMethod.privateKey ||
                      _authMethod == SshAuthMethod.hardwareKey) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passphraseController,
                      decoration: InputDecoration(
                        labelText: _authMethod == SshAuthMethod.hardwareKey
                            ? 'Stub passphrase'
                            : 'Key passphrase',
                        helperText: _authMethod == SshAuthMethod.hardwareKey
                            ? 'Only needed if the *_sk file is encrypted.'
                            : 'Leave empty for an unencrypted key.',
                        prefixIcon: const Icon(Icons.shield_outlined),
                        suffixIcon: IconButton(
                          tooltip: _showPassphrase ? 'Hide' : 'Show',
                          icon: Icon(
                            _showPassphrase
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _showPassphrase = !_showPassphrase,
                          ),
                        ),
                      ),
                      obscureText: !_showPassphrase,
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.tune_rounded,
              title: 'Advanced',
              caption: 'Optional tagging and connection timing.',
              children: [
                _TagEditor(
                  tags: _tags,
                  controller: _tagController,
                  focusNode: _tagFocusNode,
                  onAdd: _addTag,
                  onRemove: _removeTag,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeoutController,
                  decoration: const InputDecoration(
                    labelText: 'Connection timeout',
                    suffixText: 'sec',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validateTimeout,
                ),
                const SizedBox(height: 4),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Connect with Mosh'),
                    subtitle: const Text(
                      'Roaming UDP session over SSH. Requires mosh-server on the '
                      'host and open UDP ports.',
                    ),
                    value: _useMosh,
                    onChanged: (value) => setState(() {
                      _useMosh = value;
                      if (value) {
                        _predictiveEchoEnabled = false;
                      }
                    }),
                  ),
                ),
                if (_useMosh) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _moshLocaleController,
                    decoration: const InputDecoration(
                      labelText: 'Mosh locale',
                      helperText:
                          'Must be a UTF-8 locale installed on the host.',
                      prefixIcon: Icon(Icons.language_outlined),
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Predictive echo (experimental)'),
                      subtitle: const Text(
                        'Show local input previews on laggy Mosh sessions.',
                      ),
                      value: _predictiveEchoEnabled,
                      onChanged: (value) =>
                          setState(() => _predictiveEchoEnabled = value),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_isEditing ? 'Save changes' : 'Add machine'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Stored on-device only • never synced to the cloud',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: palette == null
          ? body
          : ConduitBackdrop(palette: palette, child: body),
    );
  }

  Future<void> _pasteKey() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    if (_privateKeyController.text.isNotEmpty) {
      if (!mounted) return;
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace key?'),
          content: const Text(
            'The private key field already has content. Replace it with the '
            'clipboard contents?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    _privateKeyController.text = text;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_tagController.text.trim().isNotEmpty) {
      _addTag(_tagController.text);
    }

    final currentHost = widget.host;
    final savedHost = SavedHost(
      id: currentHost?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.parse(_portController.text),
      username: _usernameController.text.trim(),
      authMethod: _authMethod,
      password: _passwordController.text,
      privateKey: _privateKeyController.text,
      passphrase:
          (_authMethod == SshAuthMethod.privateKey ||
              _authMethod == SshAuthMethod.hardwareKey)
          ? _passphraseController.text
          : '',
      tags: _tags,
      connectionTimeoutSeconds: int.parse(_timeoutController.text),
      useMosh: _useMosh,
      moshLocale: _moshLocaleController.text.trim().isEmpty
          ? 'C.UTF-8'
          : _moshLocaleController.text.trim(),
      predictiveEchoEnabled: _predictiveEchoEnabled,
      lastConnectedAt: currentHost?.lastConnectedAt,
    );

    Navigator.of(context).pop(savedHost);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validateKeyMaterial(String? value) {
    final required = _required(value);
    if (required != null) {
      return required;
    }
    try {
      final keyPairs = SSHKeyPair.fromPem(
        value!,
        _passphraseController.text.isEmpty ? null : _passphraseController.text,
      );
      final hasSecurityKey = keyPairs.any(
        (keyPair) => keyPair is OpenSSHSecurityKeyPair,
      );
      if (_authMethod == SshAuthMethod.privateKey && hasSecurityKey) {
        return 'This is a hardware-key stub. Choose Hardware key instead.';
      }
      if (_authMethod == SshAuthMethod.hardwareKey && !hasSecurityKey) {
        return 'Use id_ed25519_sk or id_ecdsa_sk, not a normal private key.';
      }
    } catch (_) {
      return _authMethod == SshAuthMethod.hardwareKey
          ? 'Paste a valid OpenSSH *_sk key stub.'
          : 'Paste a valid PEM or OpenSSH private key.';
    }
    return null;
  }

  String? _validatePort(String? value) {
    final port = int.tryParse(value ?? '');
    if (port == null || port < 1 || port > 65535) return '1-65535';
    return null;
  }

  String? _validateTimeout(String? value) {
    final timeout = int.tryParse(value ?? '');
    if (timeout == null || timeout < 3 || timeout > 120) return '3-120';
    return null;
  }
}

class _TagEditor extends StatelessWidget {
  const _TagEditor({
    required this.tags,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Tags',
            hintText: 'production, edge, eu-west…  press enter to add',
            prefixIcon: const Icon(Icons.tag_rounded),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.trim().isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Add tag',
                  icon: Icon(
                    Icons.add_circle_rounded,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => onAdd(value.text),
                );
              },
            ),
          ),
          onSubmitted: (value) {
            onAdd(value);
            focusNode.requestFocus();
          },
          onChanged: (value) {
            if (value.contains(',')) {
              final parts = value.split(',');
              for (final part in parts.take(parts.length - 1)) {
                onAdd(part);
              }
              controller.text = parts.last.trimLeft();
              controller.selection = TextSelection.collapsed(
                offset: controller.text.length,
              );
            }
          },
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                _EditableTagChip(label: tag, onRemove: () => onRemove(tag)),
            ],
          ),
        ],
      ],
    );
  }
}

class _EditableTagChip extends StatelessWidget {
  const _EditableTagChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.14),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag_rounded, size: 13, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthMethodPicker extends StatelessWidget {
  const _AuthMethodPicker({required this.value, required this.onChanged});

  final SshAuthMethod value;
  final ValueChanged<SshAuthMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        _AuthMethodTile(
          value: SshAuthMethod.password,
          groupValue: value,
          icon: Icons.password_rounded,
          title: 'Password',
          subtitle: 'Use the account password for SSH login.',
          onChanged: onChanged,
        ),
        _AuthMethodTile(
          value: SshAuthMethod.privateKey,
          groupValue: value,
          icon: Icons.vpn_key_rounded,
          title: 'Private key',
          subtitle: 'Use a PEM or OpenSSH private key.',
          onChanged: onChanged,
        ),
        _AuthMethodTile(
          value: SshAuthMethod.hardwareKey,
          groupValue: value,
          icon: Icons.usb_rounded,
          title: 'Hardware key',
          subtitle: 'Use an OpenSSH *_sk stub with USB or NFC.',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AuthMethodTile extends StatelessWidget {
  const _AuthMethodTile({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final SshAuthMethod value;
  final SshAuthMethod groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<SshAuthMethod> onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: _selected
                ? Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.12),
                    colorScheme.surface,
                  )
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: _selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _selected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: _selected
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

class _AuthExplainer extends StatelessWidget {
  const _AuthExplainer({required this.method});

  final SshAuthMethod method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hardwareKey = method == SshAuthMethod.hardwareKey;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.08),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hardwareKey ? Icons.usb_rounded : Icons.vpn_key_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hardwareKey
                  ? 'Use the OpenSSH *_sk private key stub from your computer. '
                        'Conduit stores the stub, then asks your security key '
                        'to sign over USB or NFC when you connect.'
                  : 'Use a normal SSH private key. If the key is encrypted, '
                        'enter its passphrase below.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton.outlined(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const ConduitGlyph(size: 26),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String caption;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.16),
                    colorScheme.surface,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(
                      caption,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
