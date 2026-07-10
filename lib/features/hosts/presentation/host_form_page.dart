import 'dart:async';
import 'dart:convert';

import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/hosts/data/dartssh2_ssh_key_service.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:conduit/features/hosts/presentation/add_hardware_key_sheet.dart';
import 'package:conduit/features/hosts/presentation/public_key_sheet.dart';
import 'package:conduit/features/hosts/presentation/widgets/hardware_key_list.dart';
import 'package:conduit/features/hosts/presentation/widgets/host_form_chrome.dart';
import 'package:conduit/features/hosts/presentation/widgets/host_form_sections.dart';
import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class HostFormPage extends StatefulWidget {
  const HostFormPage({
    this.host,
    this.themeController,
    this.keyService = const Dartssh2SshKeyService(),
    super.key,
  });

  final SavedHost? host;
  final ThemeController? themeController;
  final SshKeyService keyService;

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
  final _moshPortsController = TextEditingController();
  final _tmuxSessionNameController = TextEditingController(
    text: defaultTmuxSessionName,
  );
  final _tmuxStartDirectoryController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  SshAuthMethod _authMethod = SshAuthMethod.password;
  bool _showPassword = false;
  bool _showPassphrase = false;
  bool _useMosh = false;
  bool _predictiveEchoEnabled = false;
  bool _externalAuthOfferKey = true;
  bool _forwardAgent = false;
  bool _startTmuxOnConnect = false;
  TmuxPrefixKey _tmuxPrefixKey = defaultTmuxPrefixKey;
  List<String> _tags = const [];
  List<HardwareKeyEntry> _hardwareKeys = const [];
  List<TerminalSnippet> _snippets = const [];
  String _connectSnippetId = '';
  final _hardwareKeyInspections = <String, SshKeyInspection>{};
  String? _hardwareKeysError;
  SshKeyInspection? _keyInspection;
  Timer? _verifyTimer;
  int _verifyToken = 0;

  static const _verifyDebounce = Duration(milliseconds: 350);

  bool get _isEditing => widget.host != null;

  bool get _usesKeyAuth =>
      _authMethod == SshAuthMethod.privateKey ||
      _authMethod == SshAuthMethod.hardwareKey;

  @override
  void initState() {
    super.initState();
    _privateKeyController.addListener(_recomputeKeyInspection);
    _passphraseController.addListener(_recomputeKeyInspection);
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
      _hardwareKeys = List<HardwareKeyEntry>.from(
        host.authMethod == SshAuthMethod.hardwareKey
            ? host.effectiveHardwareKeys
            : host.hardwareKeys,
      );
      for (final entry in _hardwareKeys) {
        _inspectHardwareKey(entry);
      }
      _timeoutController.text = host.connectionTimeoutSeconds.toString();
      _authMethod = host.authMethod;
      _useMosh = host.useMosh;
      _moshLocaleController.text = host.moshLocale;
      _moshPortsController.text = host.moshPorts;
      _predictiveEchoEnabled = host.predictiveEchoEnabled;
      _externalAuthOfferKey = host.externalAuthOfferKey;
      _forwardAgent = host.forwardAgent;
      _startTmuxOnConnect = host.startTmuxOnConnect;
      _tmuxPrefixKey = host.tmuxPrefixKey;
      _tmuxSessionNameController.text = host.tmuxSessionName;
      _tmuxStartDirectoryController.text = host.tmuxStartDirectory;
      _snippets = List<TerminalSnippet>.from(host.snippets);
      _connectSnippetId = host.connectSnippetId;
    }
    _keyInspection = _cheapPreview();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recomputeKeyInspection();
    });
  }

  SshKeyInspection? _cheapPreview() {
    if (_authMethod != SshAuthMethod.privateKey ||
        _privateKeyController.text.trim().isEmpty) {
      return null;
    }
    return widget.keyService.inspect(_privateKeyController.text);
  }

  void _inspectHardwareKey(HardwareKeyEntry entry) {
    if (entry.passphrase.isEmpty) {
      _hardwareKeyInspections[entry.id] = widget.keyService.inspect(
        entry.privateKey,
      );
      return;
    }
    unawaited(
      widget.keyService
          .verify(entry.privateKey, passphrase: entry.passphrase)
          .then((inspection) {
            if (!mounted) return;
            setState(() => _hardwareKeyInspections[entry.id] = inspection);
          }),
    );
  }

  void _recomputeKeyInspection() {
    _verifyTimer?.cancel();
    final token = ++_verifyToken;
    final preview = _cheapPreview();
    if (preview?.status == SshKeyStatus.needsPassphrase &&
        _passphraseController.text.isNotEmpty) {
      _setInspection(const SshKeyInspection.verifying());
      final key = _privateKeyController.text;
      final passphrase = _passphraseController.text;
      _verifyTimer = Timer(_verifyDebounce, () async {
        final result = await widget.keyService.verify(
          key,
          passphrase: passphrase,
        );
        if (!mounted || token != _verifyToken) return;
        _setInspection(result);
      });
    } else {
      _setInspection(preview);
    }
  }

  void _setInspection(SshKeyInspection? next) {
    if (next?.status == _keyInspection?.status &&
        next?.details?.fingerprintSha256 ==
            _keyInspection?.details?.fingerprintSha256) {
      return;
    }
    setState(() => _keyInspection = next);
  }

  @override
  void dispose() {
    _verifyTimer?.cancel();
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
    _moshPortsController.dispose();
    _tmuxSessionNameController.dispose();
    _tmuxStartDirectoryController.dispose();
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
            HostFormHeader(
              title: _isEditing ? 'Edit machine' : 'New machine',
              subtitle: _isEditing
                  ? 'Update connection details and credentials.'
                  : 'Connection profile and credentials.',
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 20),
            HostConnectionSection(
              nameController: _nameController,
              hostController: _hostController,
              portController: _portController,
              usernameController: _usernameController,
              requiredValidator: _required,
              portValidator: _validatePort,
            ),
            const SizedBox(height: 14),
            HostAuthenticationSection(
              authMethod: _authMethod,
              passwordController: _passwordController,
              privateKeyController: _privateKeyController,
              passphraseController: _passphraseController,
              showPassword: _showPassword,
              showPassphrase: _showPassphrase,
              forwardAgent: _forwardAgent,
              externalAuthOfferKey: _externalAuthOfferKey,
              keyInspection: _keyInspection,
              hardwareKeys: _hardwareKeys,
              hardwareKeyInspections: _hardwareKeyInspections,
              hardwareKeysError: _hardwareKeysError,
              requiredValidator: _required,
              keyMaterialValidator: _validateKeyMaterial,
              onAuthMethodChanged: _changeAuthMethod,
              onTogglePasswordVisibility: () =>
                  setState(() => _showPassword = !_showPassword),
              onTogglePassphraseVisibility: () =>
                  setState(() => _showPassphrase = !_showPassphrase),
              onPasteKey: _pasteKey,
              onImportKeyFile: _importKeyFile,
              onGenerateKey: _generateKey,
              onViewPublicKey: _viewPublicKey,
              onAddHardwareKey: _addHardwareKey,
              onRenameHardwareKey: _renameHardwareKey,
              onRemoveHardwareKey: _removeHardwareKey,
              onViewHardwareKeyPublicKey: _viewHardwareKeyPublicKey,
              onForwardAgentChanged: (value) =>
                  setState(() => _forwardAgent = value),
              onExternalAuthOfferKeyChanged: (value) =>
                  setState(() => _externalAuthOfferKey = value),
            ),
            const SizedBox(height: 14),
            HostAdvancedSection(
              tags: _tags,
              tagController: _tagController,
              tagFocusNode: _tagFocusNode,
              timeoutController: _timeoutController,
              moshLocaleController: _moshLocaleController,
              moshPortsController: _moshPortsController,
              tmuxSessionNameController: _tmuxSessionNameController,
              tmuxStartDirectoryController: _tmuxStartDirectoryController,
              useMosh: _useMosh,
              predictiveEchoEnabled: _predictiveEchoEnabled,
              startTmuxOnConnect: _startTmuxOnConnect,
              tmuxPrefixKey: _tmuxPrefixKey,
              snippets: _snippets,
              connectSnippetId: _connectSnippetId,
              timeoutValidator: _validateTimeout,
              moshPortsValidator: _validateMoshPorts,
              onAddTag: _addTag,
              onRemoveTag: _removeTag,
              onUseMoshChanged: (value) => setState(() {
                _useMosh = value;
                if (value) {
                  _predictiveEchoEnabled = false;
                }
              }),
              onPredictiveEchoChanged: (value) =>
                  setState(() => _predictiveEchoEnabled = value),
              onStartTmuxOnConnectChanged: (value) =>
                  setState(() => _startTmuxOnConnect = value),
              onTmuxPrefixKeyChanged: (value) =>
                  setState(() => _tmuxPrefixKey = value),
              onSnippetsChanged: (snippets) => setState(() {
                _snippets = snippets;
                if (!_snippets.any(
                  (snippet) => snippet.id == _connectSnippetId,
                )) {
                  _connectSnippetId = '';
                }
              }),
              onConnectSnippetChanged: (snippetId) =>
                  setState(() => _connectSnippetId = snippetId),
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

  void _changeAuthMethod(SshAuthMethod method) {
    setState(() {
      _authMethod = method;
      _hardwareKeysError = null;
    });
    if (method == SshAuthMethod.hardwareKey) {
      _adoptStubFromPrivateKeyField();
    }
    _recomputeKeyInspection();
  }

  void _adoptStubFromPrivateKeyField() {
    final text = _privateKeyController.text.trim();
    if (text.isEmpty || _hardwareKeys.isNotEmpty) return;
    final inspection = widget.keyService.inspect(
      text,
      passphrase: _passphraseController.text,
    );
    final details = inspection.details;
    if (inspection.status != SshKeyStatus.securityKeyStub || details == null) {
      return;
    }
    final entry = HardwareKeyEntry(
      id: const Uuid().v4(),
      privateKey: text,
      label: details.comment.trim(),
      passphrase: _passphraseController.text,
    );
    setState(() {
      _hardwareKeys = [entry];
      _hardwareKeyInspections[entry.id] = inspection;
      _privateKeyController.clear();
      _passphraseController.clear();
    });
  }

  Future<void> _addHardwareKey() async {
    final fingerprints = <String>{
      for (final inspection in _hardwareKeyInspections.values)
        if (inspection.details != null) inspection.details!.fingerprintSha256,
    };
    final added = await showAddHardwareKeySheet(
      context: context,
      keyService: widget.keyService,
      existingFingerprints: fingerprints,
      existingStubs: {
        for (final entry in _hardwareKeys) entry.privateKey.trim(),
      },
    );
    if (added == null || !mounted) return;
    setState(() {
      _hardwareKeys = [..._hardwareKeys, added.entry];
      _hardwareKeyInspections[added.entry.id] = added.inspection;
      _hardwareKeysError = null;
    });
  }

  Future<void> _renameHardwareKey(HardwareKeyEntry entry) async {
    final index = _hardwareKeys.indexWhere((key) => key.id == entry.id);
    if (index < 0) return;
    final controller = TextEditingController(
      text: displayLabelForHardwareKey(
        entry,
        index,
        _hardwareKeyInspections[entry.id],
      ),
    );
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename hardware key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Label'),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
    if (label == null || !mounted) return;
    setState(() {
      _hardwareKeys = [
        for (final key in _hardwareKeys)
          key.id == entry.id ? key.copyWith(label: label.trim()) : key,
      ];
    });
  }

  Future<void> _removeHardwareKey(HardwareKeyEntry entry) async {
    final index = _hardwareKeys.indexWhere((key) => key.id == entry.id);
    if (index < 0) return;
    final label = displayLabelForHardwareKey(
      entry,
      index,
      _hardwareKeyInspections[entry.id],
    );
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove "$label"?'),
        content: const Text(
          'The stub is removed from this host. Your security key and the '
          'server are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove != true || !mounted) return;
    setState(() {
      _hardwareKeys = _hardwareKeys
          .where((key) => key.id != entry.id)
          .toList(growable: false);
      _hardwareKeyInspections.remove(entry.id);
    });
  }

  void _viewHardwareKeyPublicKey(HardwareKeyEntry entry) {
    final details = _hardwareKeyInspections[entry.id]?.details;
    if (details == null) return;
    showPublicKeySheet(context: context, details: details);
  }

  Future<void> _pasteKey() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    if (!mounted) return;
    if (_privateKeyController.text.isNotEmpty && !await _confirmReplaceKey()) {
      return;
    }
    _privateKeyController.text = text;
  }

  Future<void> _importKeyFile() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(withData: true);
    } catch (_) {
      if (mounted) _showSnack('Could not open the file picker.');
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) _showSnack('That file could not be read.');
      return;
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      if (mounted) _showSnack("That file isn't a text private key.");
      return;
    }
    if (!mounted) return;
    if (_privateKeyController.text.isNotEmpty && !await _confirmReplaceKey()) {
      return;
    }
    _privateKeyController.text = text.trim();
    if (!mounted) return;
    _showSnack(
      _cheapPreview()?.status == SshKeyStatus.invalid
          ? "That file isn't a recognized private key."
          : 'Imported ${file.name}',
    );
  }

  Future<void> _generateKey() async {
    if (_privateKeyController.text.isNotEmpty && !await _confirmReplaceKey()) {
      return;
    }
    if (!mounted) return;
    final options = await _promptGenerateOptions();
    if (options == null) return;
    final GeneratedSshKey generated;
    try {
      generated = widget.keyService.generateEd25519(
        comment: options.comment.trim(),
        passphrase: options.passphrase,
      );
    } catch (_) {
      if (mounted) _showSnack('Could not generate a key.');
      return;
    }
    setState(() => _authMethod = SshAuthMethod.privateKey);
    _passphraseController.text = options.passphrase;
    _privateKeyController.text = generated.privateKeyPem;
    if (!mounted) return;
    await showPublicKeySheet(
      context: context,
      details: generated.details,
      freshlyGenerated: true,
    );
  }

  void _viewPublicKey() {
    final details = _keyInspection?.details;
    if (details == null) return;
    showPublicKeySheet(context: context, details: details);
  }

  Future<bool> _confirmReplaceKey() async {
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace key?'),
        content: const Text(
          'The private key field already has content. Replace it?',
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
    return replace ?? false;
  }

  Future<({String comment, String passphrase})?> _promptGenerateOptions() {
    final username = _usernameController.text.trim();
    final commentController = TextEditingController(
      text: username.isEmpty ? 'conduit' : '$username@conduit',
    );
    final passphraseController = TextEditingController();
    return showDialog<({String comment, String passphrase})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Ed25519 key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new key pair is created on this device. The public key is '
              'shown next so you can add it to the server.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Label',
                helperText: 'Shown as the key comment.',
                helperMaxLines: 2,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passphraseController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passphrase (optional)',
                helperText: 'Encrypts the private key. Leave empty for none.',
                helperMaxLines: 2,
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop((
              comment: commentController.text,
              passphrase: passphraseController.text,
            )),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Generate'),
          ),
        ],
      ),
    ).whenComplete(() {
      commentController.dispose();
      passphraseController.dispose();
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_authMethod == SshAuthMethod.hardwareKey && _hardwareKeys.isEmpty) {
      setState(() {
        _hardwareKeysError = 'Add at least one hardware key.';
      });
      return;
    }

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
      password: _authMethod == SshAuthMethod.password
          ? _passwordController.text
          : '',
      privateKey: _authMethod == SshAuthMethod.privateKey
          ? _privateKeyController.text
          : '',
      passphrase: _authMethod == SshAuthMethod.privateKey
          ? _passphraseController.text
          : '',
      hardwareKeys: _authMethod == SshAuthMethod.hardwareKey
          ? List<HardwareKeyEntry>.unmodifiable(_hardwareKeys)
          : const [],
      externalAuthOfferKey: _externalAuthOfferKey,
      forwardAgent: _usesKeyAuth && _forwardAgent,
      tags: _tags,
      connectionTimeoutSeconds: int.parse(_timeoutController.text),
      useMosh: _useMosh,
      moshLocale: _moshLocaleController.text.trim().isEmpty
          ? 'C.UTF-8'
          : _moshLocaleController.text.trim(),
      moshPorts: _useMosh ? _moshPortsController.text.trim() : '',
      predictiveEchoEnabled: _predictiveEchoEnabled,
      startTmuxOnConnect: _startTmuxOnConnect,
      tmuxPrefixKey: _tmuxPrefixKey,
      tmuxSessionName: _tmuxSessionNameController.text.trim().isEmpty
          ? defaultTmuxSessionName
          : _tmuxSessionNameController.text.trim(),
      tmuxStartDirectory: _tmuxStartDirectoryController.text.trim(),
      snippets: List<TerminalSnippet>.unmodifiable(_snippets),
      connectSnippetId:
          _snippets.any((snippet) => snippet.id == _connectSnippetId)
          ? _connectSnippetId
          : '',
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
    final inspection = widget.keyService.inspect(
      value!,
      passphrase: _passphraseController.text,
    );
    return switch (inspection.status) {
      SshKeyStatus.needsPassphrase => 'Enter the key passphrase to unlock it.',
      SshKeyStatus.verifying => null,
      SshKeyStatus.wrongPassphrase => 'That passphrase did not match this key.',
      SshKeyStatus.invalid => 'Use a valid PEM or OpenSSH private key.',
      SshKeyStatus.securityKeyStub =>
        'This is a hardware-key stub. Choose Hardware key instead.',
      SshKeyStatus.valid => null,
    };
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

  String? _validateMoshPorts(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (MoshPortRange.tryParse(trimmed) == null) {
      return 'Use a port or low:high range within 1-65535.';
    }
    return null;
  }
}
