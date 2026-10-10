import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:conduit/features/hosts/presentation/widgets/auth_method_picker.dart';
import 'package:conduit/features/hosts/presentation/widgets/hardware_key_list.dart';
import 'package:conduit/features/hosts/presentation/widgets/host_form_chrome.dart';
import 'package:conduit/features/hosts/presentation/widgets/key_source_actions.dart';
import 'package:conduit/features/hosts/presentation/widgets/ssh_key_summary.dart';
import 'package:conduit/features/hosts/presentation/widgets/tag_editor.dart';
import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:conduit/features/snippets/presentation/snippet_editor.dart';
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
      title: context.l10n.hostFormSectionConnection,
      caption: context.l10n.hostFormConnectionHint,
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.hostFormDisplayName,
            hintText: 'production-edge-01',
            prefixIcon: const Icon(Icons.label_important_outline_rounded),
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
                decoration: InputDecoration(
                  labelText: context.l10n.hostFormHost,
                  hintText: 'edge.example.com',
                  prefixIcon: const Icon(Icons.public_rounded),
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
                decoration: InputDecoration(
                  labelText: context.l10n.hostFormPort,
                ),
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
          decoration: InputDecoration(
            labelText: context.l10n.hostFormUsername,
            prefixIcon: const Icon(Icons.person_outline_rounded),
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
      title: context.l10n.hostFormSectionAuthentication,
      caption: context.l10n.hostFormAuthenticationHint,
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
              title: Text(context.l10n.hostFormOfferTempKey),
              subtitle: Text(context.l10n.hostFormOfferTempKeyHint),
              value: externalAuthOfferKey,
              onChanged: onExternalAuthOfferKeyChanged,
            ),
          ),
        ],
        if (authMethod == SshAuthMethod.password)
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: context.l10n.labelPassword,
              helperText: context.l10n.authPasswordDetail,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                tooltip: showPassword
                    ? context.l10n.actionHide
                    : context.l10n.actionShow,
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
            decoration: InputDecoration(
              labelText: context.l10n.hostFormPrivateKey,
              helperText: context.l10n.hostFormPrivateKeyEmpty,
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
              labelText: context.l10n.hostFormKeyPassphraseLabel,
              helperText: context.l10n.appearanceKeyPassphraseHint,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.shield_outlined),
              suffixIcon: IconButton(
                tooltip: showPassphrase
                    ? context.l10n.actionHide
                    : context.l10n.actionShow,
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
              title: Text(context.l10n.hostFormForwardAgent),
              subtitle: Text(context.l10n.hostFormForwardAgentHint),
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
    required this.moshPortsController,
    required this.tmuxSessionNameController,
    required this.tmuxStartDirectoryController,
    required this.useMosh,
    required this.predictiveEchoEnabled,
    required this.startTmuxOnConnect,
    required this.tmuxPrefixKey,
    required this.snippets,
    required this.connectSnippetId,
    required this.timeoutValidator,
    required this.moshPortsValidator,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onUseMoshChanged,
    required this.onPredictiveEchoChanged,
    required this.onStartTmuxOnConnectChanged,
    required this.onTmuxPrefixKeyChanged,
    required this.onSnippetsChanged,
    required this.onConnectSnippetChanged,
    super.key,
  });

  final List<String> tags;
  final TextEditingController tagController;
  final FocusNode tagFocusNode;
  final TextEditingController timeoutController;
  final TextEditingController moshLocaleController;
  final TextEditingController moshPortsController;
  final TextEditingController tmuxSessionNameController;
  final TextEditingController tmuxStartDirectoryController;
  final bool useMosh;
  final bool predictiveEchoEnabled;
  final bool startTmuxOnConnect;
  final TmuxPrefixKey tmuxPrefixKey;
  final List<TerminalSnippet> snippets;
  final String connectSnippetId;
  final FormFieldValidator<String> timeoutValidator;
  final FormFieldValidator<String> moshPortsValidator;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<bool> onUseMoshChanged;
  final ValueChanged<bool> onPredictiveEchoChanged;
  final ValueChanged<bool> onStartTmuxOnConnectChanged;
  final ValueChanged<TmuxPrefixKey> onTmuxPrefixKeyChanged;
  final ValueChanged<List<TerminalSnippet>> onSnippetsChanged;
  final ValueChanged<String> onConnectSnippetChanged;

  @override
  Widget build(BuildContext context) {
    return HostFormSectionCard(
      icon: Icons.tune_rounded,
      title: context.l10n.hostFormSectionAdvanced,
      caption: context.l10n.hostFormAdvancedHint,
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
          decoration: InputDecoration(
            labelText: context.l10n.hostFormConnectionTimeout,
            suffixText: 'sec',
            prefixIcon: const Icon(Icons.timer_outlined),
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
            title: Text(context.l10n.hostFormConnectWithMosh),
            subtitle: Text(context.l10n.hostFormConnectWithMoshHint),
            value: useMosh,
            onChanged: onUseMoshChanged,
          ),
        ),
        if (useMosh) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: moshLocaleController,
            decoration: InputDecoration(
              labelText: context.l10n.hostFormMoshLocale,
              helperText: context.l10n.hostFormMoshLocaleHint,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.language_outlined),
            ),
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: moshPortsController,
            decoration: InputDecoration(
              labelText: context.l10n.hostFormMoshPorts,
              helperText: context.l10n.hostFormMoshPortsHint,
              helperMaxLines: 2,
              errorMaxLines: 2,
              prefixIcon: const Icon(Icons.settings_ethernet_rounded),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
            ],
            validator: moshPortsValidator,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.hostFormPredictiveEcho),
              subtitle: Text(context.l10n.hostFormPredictiveEchoHint),
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
            title: Text(context.l10n.hostFormStartTmux),
            subtitle: Text(context.l10n.appearanceTmuxSessionHint),
            value: startTmuxOnConnect,
            onChanged: onStartTmuxOnConnectChanged,
          ),
        ),
        if (startTmuxOnConnect) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: tmuxSessionNameController,
            decoration: InputDecoration(
              labelText: context.l10n.hostFormTmuxSession,
              hintText: defaultTmuxSessionName,
              helperText: context.l10n.appearanceTmuxAutostart,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.view_stream_outlined),
            ),
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: tmuxStartDirectoryController,
            decoration: InputDecoration(
              labelText: context.l10n.hostFormTmuxDirectory,
              hintText: '~/projects',
              helperText: context.l10n.hostFormTmuxDirectoryHint,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.folder_outlined),
            ),
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<TmuxPrefixKey>(
          initialValue: tmuxPrefixKey,
          decoration: InputDecoration(
            labelText: context.l10n.hostFormTmuxPrefix,
            helperText: context.l10n.appearanceTmuxPrefixHint,
            helperMaxLines: 2,
            prefixIcon: const Icon(Icons.keyboard_command_key_rounded),
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
        const SizedBox(height: 18),
        SnippetListEditor(
          title: context.l10n.hostFormHostSnippets,
          caption: context.l10n.hostFormHostSnippetsHint,
          snippets: snippets,
          onChanged: onSnippetsChanged,
          connectSnippetId: connectSnippetId,
          onConnectSnippetChanged: onConnectSnippetChanged,
        ),
      ],
    );
  }
}
