import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:conduit/features/hosts/presentation/widgets/auth_method_picker.dart';
import 'package:conduit/features/hosts/presentation/widgets/hardware_key_list.dart';
import 'package:conduit/features/hosts/presentation/widgets/host_form_chrome.dart';
import 'package:conduit/features/hosts/presentation/widgets/key_source_actions.dart';
import 'package:conduit/features/hosts/presentation/widgets/ssh_key_summary.dart';
import 'package:conduit/features/hosts/presentation/widgets/tag_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HostConnectionSection extends StatelessWidget {
  const HostConnectionSection({
    required this.nameController,
    required this.hostController,
    required this.portController,
    required this.usernameController,
    required this.requiredValidator,
    required this.portValidator,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController usernameController;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> portValidator;

  @override
  Widget build(BuildContext context) {
    return HostFormSectionCard(
      icon: Icons.dns_rounded,
      title: 'Connection',
      caption: 'Where to reach this machine.',
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Display name',
            hintText: 'production-edge-01',
            prefixIcon: Icon(Icons.label_important_outline_rounded),
          ),
          textInputAction: TextInputAction.next,
          validator: requiredValidator,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: 'Host or IP',
                  hintText: 'edge.example.com',
                  prefixIcon: Icon(Icons.public_rounded),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: requiredValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: portValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

class HostAuthenticationSection extends StatelessWidget {
  const HostAuthenticationSection({
    required this.authMethod,
    required this.passwordController,
    required this.privateKeyController,
    required this.passphraseController,
    required this.showPassword,
    required this.showPassphrase,
    required this.forwardAgent,
    required this.externalAuthOfferKey,
    required this.keyInspection,
    required this.hardwareKeys,
    required this.hardwareKeyInspections,
    required this.hardwareKeysError,
    required this.requiredValidator,
    required this.keyMaterialValidator,
    required this.onAuthMethodChanged,
    required this.onTogglePasswordVisibility,
    required this.onTogglePassphraseVisibility,
    required this.onPasteKey,
    required this.onImportKeyFile,
    required this.onGenerateKey,
    required this.onViewPublicKey,
    required this.onAddHardwareKey,
    required this.onRenameHardwareKey,
    required this.onRemoveHardwareKey,
    required this.onViewHardwareKeyPublicKey,
    required this.onForwardAgentChanged,
    required this.onExternalAuthOfferKeyChanged,
    super.key,
  });

  final SshAuthMethod authMethod;
  final TextEditingController passwordController;
  final TextEditingController privateKeyController;
  final TextEditingController passphraseController;
  final bool showPassword;
  final bool showPassphrase;
  final bool forwardAgent;
  final bool externalAuthOfferKey;
  final SshKeyInspection? keyInspection;
  final List<HardwareKeyEntry> hardwareKeys;
  final Map<String, SshKeyInspection> hardwareKeyInspections;
  final String? hardwareKeysError;
  final FormFieldValidator<String> requiredValidator;
  final FormFieldValidator<String> keyMaterialValidator;
  final ValueChanged<SshAuthMethod> onAuthMethodChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onTogglePassphraseVisibility;
  final VoidCallback onPasteKey;
  final VoidCallback onImportKeyFile;
  final VoidCallback onGenerateKey;
  final VoidCallback onViewPublicKey;
  final VoidCallback onAddHardwareKey;
  final ValueChanged<HardwareKeyEntry> onRenameHardwareKey;
  final ValueChanged<HardwareKeyEntry> onRemoveHardwareKey;
  final ValueChanged<HardwareKeyEntry> onViewHardwareKeyPublicKey;
  final ValueChanged<bool> onForwardAgentChanged;
  final ValueChanged<bool> onExternalAuthOfferKeyChanged;

  @override
  Widget build(BuildContext context) {
    return HostFormSectionCard(
      icon: Icons.lock_outline_rounded,
      title: 'Authentication',
      caption: 'Credentials are stored in platform secure storage.',
      children: [
        AuthMethodPicker(value: authMethod, onChanged: onAuthMethodChanged),
        const SizedBox(height: 14),
        if (authMethod == SshAuthMethod.external) ...[
          AuthExplainer(method: authMethod),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Offer temporary public key'),
              subtitle: const Text(
                'Helps servers that authenticate externally but still expect '
                'a public-key login attempt.',
              ),
              value: externalAuthOfferKey,
              onChanged: onExternalAuthOfferKeyChanged,
            ),
          ),
        ],
        if (authMethod == SshAuthMethod.password)
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'Use this for password-only SSH login.',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                tooltip: showPassword ? 'Hide' : 'Show',
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: onTogglePasswordVisibility,
              ),
            ),
            obscureText: !showPassword,
            validator: authMethod == SshAuthMethod.password
                ? requiredValidator
                : null,
          ),
        if (authMethod == SshAuthMethod.hardwareKey) ...[
          AuthExplainer(method: authMethod),
          const SizedBox(height: 16),
          HardwareKeyList(
            entries: hardwareKeys,
            inspections: hardwareKeyInspections,
            errorText: hardwareKeysError,
            onAdd: onAddHardwareKey,
            onRename: onRenameHardwareKey,
            onRemove: onRemoveHardwareKey,
            onViewPublicKey: onViewHardwareKeyPublicKey,
          ),
        ],
        if (authMethod == SshAuthMethod.privateKey) ...[
          AuthExplainer(method: authMethod),
          const SizedBox(height: 16),
          KeySourceActions(
            onImportFile: onImportKeyFile,
            onPaste: onPasteKey,
            onGenerate: onGenerateKey,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: privateKeyController,
            decoration: const InputDecoration(
              labelText: 'Private key',
              helperText: 'Import, paste, or generate a key.',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(Icons.vpn_key_outlined),
              ),
            ),
            minLines: 5,
            maxLines: 9,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            validator: keyMaterialValidator,
          ),
          if (keyInspection != null) ...[
            const SizedBox(height: 12),
            SshKeySummary(
              inspection: keyInspection!,
              onViewPublicKey: onViewPublicKey,
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: passphraseController,
            decoration: InputDecoration(
              labelText: 'Key passphrase',
              helperText: 'Leave empty for an unencrypted key.',
              prefixIcon: const Icon(Icons.shield_outlined),
              suffixIcon: IconButton(
                tooltip: showPassphrase ? 'Hide' : 'Show',
                icon: Icon(
                  showPassphrase
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: onTogglePassphraseVisibility,
              ),
            ),
            obscureText: !showPassphrase,
          ),
        ],
        if (authMethod == SshAuthMethod.privateKey ||
            authMethod == SshAuthMethod.hardwareKey) ...[
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Forward SSH agent'),
              subtitle: const Text(
                'Let hosts you connect to use this key to authenticate '
                'onward. Hardware keys prompt for a touch on each use.',
              ),
              value: forwardAgent,
              onChanged: onForwardAgentChanged,
            ),
          ),
        ],
      ],
    );
  }
}

class HostAdvancedSection extends StatelessWidget {
  const HostAdvancedSection({
    required this.tags,
    required this.tagController,
    required this.tagFocusNode,
    required this.timeoutController,
    required this.moshLocaleController,
    required this.tmuxSessionNameController,
    required this.tmuxStartDirectoryController,
    required this.useMosh,
    required this.predictiveEchoEnabled,
    required this.startTmuxOnConnect,
    required this.tmuxPrefixKey,
    required this.timeoutValidator,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onUseMoshChanged,
    required this.onPredictiveEchoChanged,
    required this.onStartTmuxOnConnectChanged,
    required this.onTmuxPrefixKeyChanged,
    super.key,
  });

  final List<String> tags;
  final TextEditingController tagController;
  final FocusNode tagFocusNode;
  final TextEditingController timeoutController;
  final TextEditingController moshLocaleController;
  final TextEditingController tmuxSessionNameController;
  final TextEditingController tmuxStartDirectoryController;
  final bool useMosh;
  final bool predictiveEchoEnabled;
  final bool startTmuxOnConnect;
  final TmuxPrefixKey tmuxPrefixKey;
  final FormFieldValidator<String> timeoutValidator;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<bool> onUseMoshChanged;
  final ValueChanged<bool> onPredictiveEchoChanged;
  final ValueChanged<bool> onStartTmuxOnConnectChanged;
  final ValueChanged<TmuxPrefixKey> onTmuxPrefixKeyChanged;

  @override
  Widget build(BuildContext context) {
    return HostFormSectionCard(
      icon: Icons.tune_rounded,
      title: 'Advanced',
      caption: 'Optional tagging and connection timing.',
      children: [
        TagEditor(
          tags: tags,
          controller: tagController,
          focusNode: tagFocusNode,
          onAdd: onAddTag,
          onRemove: onRemoveTag,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: timeoutController,
          decoration: const InputDecoration(
            labelText: 'Connection timeout',
            suffixText: 'sec',
            prefixIcon: Icon(Icons.timer_outlined),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: timeoutValidator,
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
            value: useMosh,
            onChanged: onUseMoshChanged,
          ),
        ),
        if (useMosh) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: moshLocaleController,
            decoration: const InputDecoration(
              labelText: 'Mosh locale',
              helperText: 'Must be a UTF-8 locale installed on the host.',
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
              value: predictiveEchoEnabled,
              onChanged: onPredictiveEchoChanged,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start tmux on connect'),
            subtitle: const Text(
              'Attach to the named tmux session, or create it if needed.',
            ),
            value: startTmuxOnConnect,
            onChanged: onStartTmuxOnConnectChanged,
          ),
        ),
        if (startTmuxOnConnect) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: tmuxSessionNameController,
            decoration: const InputDecoration(
              labelText: 'Tmux session name',
              hintText: defaultTmuxSessionName,
              helperText: 'Conduit attaches to this session, or creates it.',
              prefixIcon: Icon(Icons.view_stream_outlined),
            ),
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: tmuxStartDirectoryController,
            decoration: const InputDecoration(
              labelText: 'Tmux start directory',
              hintText: '~/projects',
              helperText:
                  'Used when a new tmux session is created. An existing tmux '
                  'session keeps its directory.',
              helperMaxLines: 2,
              prefixIcon: Icon(Icons.folder_outlined),
            ),
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<TmuxPrefixKey>(
          initialValue: tmuxPrefixKey,
          decoration: const InputDecoration(
            labelText: 'Tmux prefix',
            helperText: 'Used by the Tmux and Tmux+ key-row buttons.',
            prefixIcon: Icon(Icons.keyboard_command_key_rounded),
          ),
          items: [
            for (final key in TmuxPrefixKey.values)
              DropdownMenuItem(value: key, child: Text(key.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              onTmuxPrefixKeyChanged(value);
            }
          },
        ),
      ],
    );
  }
}
