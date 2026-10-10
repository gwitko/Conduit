// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionDone => 'Done';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionSave => 'Save';

  @override
  String get actionBack => 'Back';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionImport => 'Import';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionGenerate => 'Generate';

  @override
  String get actionUpload => 'Upload';

  @override
  String get actionInstall => 'Install';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionReplace => 'Replace';

  @override
  String get actionTrust => 'Trust';

  @override
  String get actionReject => 'Reject';

  @override
  String get actionForget => 'Forget';

  @override
  String get actionReinstall => 'Reinstall';

  @override
  String get actionUnlock => 'Unlock';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionShow => 'Show';

  @override
  String get actionHide => 'Hide';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionManage => 'Manage';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionReconnect => 'Reconnect';

  @override
  String get labelPassword => 'Password';

  @override
  String get labelLabel => 'Label';

  @override
  String get labelName => 'Name';

  @override
  String get labelText => 'Text';

  @override
  String get labelHost => 'Host';

  @override
  String get hostFormHost => 'Host or IP';

  @override
  String get hostFormPort => 'Port';

  @override
  String get hostFormUsername => 'Username';

  @override
  String get hostFormDisplayName => 'Display name';

  @override
  String get hostFormSectionConnection => 'Connection';

  @override
  String get hostFormSectionAuthentication => 'Authentication';

  @override
  String get hostFormSectionAdvanced => 'Advanced';

  @override
  String get labelAlgorithm => 'Algorithm';

  @override
  String get labelFingerprint => 'Fingerprint';

  @override
  String get labelVersion => 'Version';

  @override
  String get labelDistribution => 'Distribution';

  @override
  String get labelDiskUsage => 'Disk usage';

  @override
  String get labelAndroidFiles => 'Android files';

  @override
  String get labelTags => 'Tags';

  @override
  String get labelFiles => 'Files';

  @override
  String get labelMachines => 'Machines';

  @override
  String get labelSnippets => 'Snippets';

  @override
  String get terminalCloseCompose => 'Close compose';

  @override
  String get actionCopyPath => 'Copy path';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionDownloadAsTar => 'Download as tar';

  @override
  String get labelOpenSourceLicenses => 'Open-source licenses';

  @override
  String get securityKeyChooseTitle => 'Choose security key';

  @override
  String get securityKeyPinLabel => 'FIDO2 PIN';

  @override
  String get securityKeyPinTitle => 'Security key PIN';

  @override
  String get securityKeyPinBody => 'Enter the PIN for your hardware security key.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageSubtitle => 'Applies to the whole app immediately. No restart needed.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Pick a developer palette. The home screen, editor, and dialogs share the same look.';

  @override
  String get appearanceShowLocalShell => 'Show local shell';

  @override
  String get appearanceShowLocalShellHint => 'Show the local terminal shortcut on the home screen.';

  @override
  String get backupTitle => 'Backup and restore';

  @override
  String get appearanceBackupRestoreHint => 'Export settings and machines or import a saved backup.';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceFontSize => 'Font size';

  @override
  String get appearanceKeyRows => 'Key rows';

  @override
  String get appearanceEnterSends => 'Enter sends';

  @override
  String get appearanceSendMouseTaps => 'Send mouse taps';

  @override
  String get appearanceSendMouseTapsHint => 'Forward terminal taps as mouse clicks when apps enable mouse tracking.';

  @override
  String get appearanceGlobalSnippets => 'Global snippets';

  @override
  String get appearanceGlobalSnippetsHint => 'Shown from the Snip key-row menu on every machine.';

  @override
  String get appearanceAddRow => 'Add row';

  @override
  String get appearanceEditKeys => 'Edit keys';

  @override
  String get appearanceRemoveRow => 'Remove row';

  @override
  String get appearanceCustom => 'Custom';

  @override
  String get appearanceCustomKey => 'Custom key';

  @override
  String get appearanceSendEnterAfterText => 'Send Enter after text';

  @override
  String get appearanceControlKey => 'Control key';

  @override
  String get appearanceKeyPassphraseHint => 'Leave empty for an unencrypted key.';

  @override
  String get appearanceTmuxPrefixHint => 'Used by the Tmux and Tmux+ key-row buttons.';

  @override
  String get appearanceTmuxSessionHint => 'Attach to the named tmux session, or create it if needed.';

  @override
  String get appearanceTmuxAutostart => 'Conduit attaches to this session, or creates it.';

  @override
  String get appearanceDisableRunOnConnect => 'Disable run on connect';

  @override
  String get appearanceRunOnConnect => 'Run on connect';

  @override
  String appearanceKeyRowsCount(int count) {
    return 'Key Rows ($count)';
  }

  @override
  String appearanceRowLabel(int index) {
    return 'Row $index';
  }

  @override
  String appearanceRowKeysTitle(int index) {
    return 'Row $index Keys';
  }

  @override
  String appearanceKeyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keys',
      one: '1 key',
    );
    return '$_temp0';
  }

  @override
  String get paletteCaptionCatppuccin => 'Mocha, calm and polished';

  @override
  String get paletteCaptionTokyoNight => 'Deep blue IDE focus';

  @override
  String get paletteCaptionDracula => 'High-contrast neon classic';

  @override
  String get paletteCaptionNord => 'Arctic, restrained, cool';

  @override
  String get paletteCaptionGruvbox => 'Warm retro terminal energy';

  @override
  String get paletteCaptionSolarized => 'Balanced low-glare contrast';

  @override
  String get paletteCaptionOneDark => 'Atom-inspired editor calm';

  @override
  String get paletteCaptionRosePine => 'Muted dusk, soft contrast';

  @override
  String get paletteCaptionEverforest => 'Green low-glare woodland';

  @override
  String get paletteCaptionMonokai => 'Punchy classic code color';

  @override
  String get paletteCaptionAyuDark => 'Warm amber night coding';

  @override
  String get paletteCaptionKanagawa => 'Muted ink and wave tones';

  @override
  String get paletteCaptionNightOwl => 'Crisp blue late-night focus';

  @override
  String get paletteCaptionPalenight => 'Soft violet editor glow';

  @override
  String get paletteCaptionSynthwave => 'Electric retro terminal pop';

  @override
  String get paletteCaptionGithubDark => 'Quiet modern code contrast';

  @override
  String get hostsTrustedKeys => 'Trusted keys';

  @override
  String get hostsLock => 'Lock';

  @override
  String get hostsStatSaved => 'Saved';

  @override
  String get hostsStatLiveSessions => 'Live sessions';

  @override
  String get hostsResumeSessions => 'Resume sessions';

  @override
  String get hostsSavedMachines => 'Saved machines';

  @override
  String get hostsSavedMachinesHint => 'SSH and Mosh connections you have saved.';

  @override
  String get hostsSortMachines => 'Sort machines';

  @override
  String get hostsErrorTitle => 'Something went wrong';

  @override
  String get hostsEmptyTitle => 'No saved machines yet';

  @override
  String get commonNoMatches => 'No matches';

  @override
  String get commonNoMatchesHint => 'Try a different search or clear filters.';

  @override
  String get hostsPickMachine => 'Pick a machine to spin up a new tab.';

  @override
  String get hostsGrantFileAccess => 'Grant file access, then open the shell again.';

  @override
  String get hostsDuplicateTitle => 'Duplicate machine';

  @override
  String get hostsDuplicateBody => 'Copy the saved password and key material into the new machine?';

  @override
  String get hostsDuplicateWithoutSecrets => 'Without secrets';

  @override
  String get hostsDuplicateWithSecrets => 'Copy secrets';

  @override
  String get hostsDeleteTitle => 'Delete machine?';

  @override
  String hostsCopiedEndpoint(String endpoint) {
    return 'Copied $endpoint';
  }

  @override
  String hostsDeleteBody(String name) {
    return 'Conduit will forget “$name”.';
  }

  @override
  String hostsActiveSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active',
      one: '1 active',
    );
    return '$_temp0';
  }

  @override
  String get hostFormEditTitle => 'Edit machine';

  @override
  String get hostFormNewTitle => 'New machine';

  @override
  String get hostFormEditSubtitle => 'Update connection details and credentials.';

  @override
  String get hostFormNewSubtitle => 'Connection profile and credentials.';

  @override
  String get hostFormSave => 'Save changes';

  @override
  String get hostFormAdd => 'Add machine';

  @override
  String get hostFormStoredLocally => 'Stored on-device only • never synced to the cloud';

  @override
  String get hostFormRenameHardwareKey => 'Rename hardware key';

  @override
  String hostFormRemoveHardwareKeyTitle(String label) {
    return 'Remove \"$label\"?';
  }

  @override
  String get hostFormRemoveHardwareKeyBody => 'The stub is removed from this host. Your security key and the server are not affected.';

  @override
  String get hostFormReplaceKeyTitle => 'Replace key?';

  @override
  String get hostFormReplaceKeyBody => 'The private key field already has content. Replace it?';

  @override
  String get hostFormGenerateKeyTitle => 'Generate Ed25519 key';

  @override
  String get hostFormGenerateKeyBody => 'A new key pair is created on this device. The public key is shown next so you can add it to the server.';

  @override
  String get hostFormKeyLabelHint => 'Shown as the key comment.';

  @override
  String get hostFormKeyPassphrase => 'Passphrase (optional)';

  @override
  String get hostFormKeyPassphraseHint => 'Encrypts the private key. Leave empty for none.';

  @override
  String get hostFormOfferTempKey => 'Offer temporary public key';

  @override
  String get hostFormOfferTempKeyHint => 'Helps servers that authenticate externally but still expect a public-key login attempt.';

  @override
  String get hostFormPrivateKey => 'Private key';

  @override
  String get hostFormKeyPassphraseLabel => 'Key passphrase';

  @override
  String get hostFormPrivateKeyHint => 'Use a normal SSH private key. If the key is encrypted, enter its passphrase below.';

  @override
  String get hostFormPrivateKeyEmpty => 'Import, paste, or generate a key.';

  @override
  String get hostFormForwardAgent => 'Forward SSH agent';

  @override
  String get hostFormForwardAgentHint => 'Let hosts you connect to use this key to authenticate onward. Hardware keys prompt for a touch on each use.';

  @override
  String get hostFormConnectionTimeout => 'Connection timeout';

  @override
  String get hostFormConnectWithMosh => 'Connect with Mosh';

  @override
  String get hostFormConnectWithMoshHint => 'Roaming UDP session over SSH. Requires mosh-server on the host and open UDP ports.';

  @override
  String get hostFormMoshLocale => 'Mosh locale';

  @override
  String get hostFormMoshLocaleHint => 'Must be a UTF-8 locale installed on the host.';

  @override
  String get hostFormMoshPorts => 'Mosh UDP ports';

  @override
  String get hostFormMoshPortsHint => 'Port or range like 60000:61000. Empty uses 60001:60999.';

  @override
  String get hostFormPredictiveEcho => 'Predictive echo (experimental)';

  @override
  String get hostFormPredictiveEchoHint => 'Show local input previews on laggy Mosh sessions.';

  @override
  String get hostFormStartTmux => 'Start tmux on connect';

  @override
  String get hostFormTmuxSession => 'Tmux session name';

  @override
  String get hostFormTmuxDirectory => 'Tmux start directory';

  @override
  String get hostFormTmuxPrefix => 'Tmux prefix';

  @override
  String get hostFormTmuxDirectoryHint => 'Used when a new tmux session is created. An existing tmux session keeps its directory.';

  @override
  String get hostFormHostSnippets => 'Host snippets';

  @override
  String get hostFormHostSnippetsHint => 'Shown in the Snip key-row menu for this machine. Hidden snippets are useful for passwords or other secrets.';

  @override
  String get authPasswordHint => 'Use the account password for SSH login.';

  @override
  String get authPasswordDetail => 'Use this for password-only SSH login.';

  @override
  String get authHardwareKey => 'Hardware key';

  @override
  String get authPrivateKeyHint => 'Use a PEM or OpenSSH private key.';

  @override
  String get authHardwareKeyHint => 'Use one or more security keys over USB or NFC.';

  @override
  String get authExternal => 'External';

  @override
  String get authExternalHint => 'Use this when authentication is handled outside Conduit, without storing a password or private key in the app.';

  @override
  String get authHardwareKeyDetail => 'Add the OpenSSH *_sk key stub for each security key you own. When you connect, Conduit asks whichever key you present to sign over USB or NFC.';

  @override
  String get hardwareKeysTitle => 'Hardware keys';

  @override
  String get hardwareKeysEmpty => 'No hardware keys yet. Add the OpenSSH *_sk stub for each security key you want to use with this host. Any of them will unlock the connection.';

  @override
  String hardwareKeysCount(int count) {
    return 'Hardware keys ($count)';
  }

  @override
  String get hardwareKeysOptions => 'Key options';

  @override
  String get hostCardOptions => 'Machine options';

  @override
  String get hostCardDuplicate => 'Duplicate';

  @override
  String get hostCardCopyAddress => 'Copy address';

  @override
  String get hostCardViewPublicKey => 'View public key';

  @override
  String get hostKeyPassphraseMismatch => 'That passphrase did not match this key.';

  @override
  String get hostsSearchHint => 'Search machines, hosts, tags…';

  @override
  String get hostFormTagsHint => 'production, edge, eu-west…  press enter to add';

  @override
  String get hostFormAddTag => 'Add tag';

  @override
  String publicKeyCreatedBody(String algorithm) {
    return 'A new $algorithm key is saved on this device. Add the public key below to the server, then connect.';
  }

  @override
  String get publicKeyInstructions => 'Add this line to ~/.ssh/authorized_keys on the host you want to reach.';

  @override
  String get publicKeySave => 'Save .pub';

  @override
  String get publicKeyCopied => 'Public key copied to clipboard';

  @override
  String get publicKeySaved => 'Public key saved';

  @override
  String get publicKeySaveFailed => 'Could not save the public key';

  @override
  String get publicKeyPrivateNote => 'The private half never leaves this device. It is held in platform secure storage with your other credentials.';

  @override
  String get addHardwareKeyTitle => 'Add hardware key';

  @override
  String get addHardwareKeyBody => 'Import or paste the OpenSSH *_sk stub that ssh-keygen created for this security key. The stub only points to the key; the private part never leaves the hardware.';

  @override
  String get addHardwareKeyStubLabel => 'OpenSSH hardware key stub';

  @override
  String get addHardwareKeyStubHint => 'Import or paste the id_ed25519_sk or id_ecdsa_sk file.';

  @override
  String get addHardwareKeyPassphrase => 'Stub passphrase';

  @override
  String get addHardwareKeyPassphraseHint => 'This stub file is encrypted.';

  @override
  String get addHardwareKeyLabelHint => 'Shown when Conduit asks for this key, e.g. \"5C work\" or \"NFC backup\".';

  @override
  String get addHardwareKeySubmit => 'Add key';

  @override
  String get terminalRecallLine => 'Recall a sent line';

  @override
  String get terminalComposeHint => 'Compose a line, Enter to send …';

  @override
  String get terminalNoSessions => 'No sessions open';

  @override
  String get terminalBackToMachines => 'Back to machines';

  @override
  String get terminalFunctionKeys => 'Function keys';

  @override
  String get terminalTmuxActions => 'Tmux actions';

  @override
  String get tmuxActionNewWindow => 'New window';

  @override
  String get tmuxActionPreviousWindow => 'Previous window';

  @override
  String get tmuxActionNextWindow => 'Next window';

  @override
  String get tmuxActionWindowList => 'Window list';

  @override
  String get tmuxActionLastWindow => 'Last window';

  @override
  String get tmuxActionRenameWindow => 'Rename window';

  @override
  String get tmuxActionSplitHorizontal => 'Split horizontal';

  @override
  String get tmuxActionSplitVertical => 'Split vertical';

  @override
  String get tmuxActionPaneLeft => 'Pane left';

  @override
  String get tmuxActionPaneRight => 'Pane right';

  @override
  String get tmuxActionPaneUp => 'Pane up';

  @override
  String get tmuxActionPaneDown => 'Pane down';

  @override
  String get tmuxActionZoomPane => 'Zoom pane';

  @override
  String get tmuxActionCommandPrompt => 'Command prompt';

  @override
  String get tmuxActionScrollback => 'Scrollback';

  @override
  String get tmuxActionClosePane => 'Close pane';

  @override
  String get tmuxActionCloseWindow => 'Close window';

  @override
  String get tmuxActionDetach => 'Detach';

  @override
  String get terminalNoSnippets => 'No snippets saved';

  @override
  String get commonWorking => 'Working…';

  @override
  String get trustedKeysTitle => 'Trusted host keys';

  @override
  String get trustedKeysSubtitle => 'Servers Conduit has connected to before.';

  @override
  String get trustedKeysEmpty => 'Connect to a host and you’ll be asked to trust its key - the fingerprint lands here.';

  @override
  String get trustedKeysEmptyTitle => 'No trusted keys yet';

  @override
  String get trustedKeysForgetTitle => 'Forget trusted key?';

  @override
  String get hostKeyPreviouslyTrusted => 'Previously trusted:';

  @override
  String trustedKeysForgetBody(String host, int port) {
    return 'Conduit will prompt again the next time you connect to $host:$port.';
  }

  @override
  String get hostKeyChangedTitle => 'Host key changed';

  @override
  String get hostKeyTrustTitle => 'Trust this host?';

  @override
  String get hostKeyTrustNew => 'Trust new key';

  @override
  String hostKeyUnknownBody(String host, int port) {
    return 'Conduit has not connected to $host:$port before. Verify the fingerprint matches the one reported by the server (e.g. `ssh-keygen -E md5 -lf <key>`).';
  }

  @override
  String hostKeyMismatchBody(String host, int port) {
    return 'The server at $host:$port is presenting a different key than the one you previously trusted. This can indicate a man-in-the-middle attack, or the server may have been legitimately rekeyed.';
  }

  @override
  String get keyChecking => 'Checking key…';

  @override
  String get keyCheckingPassphrase => 'Checking passphrase…';

  @override
  String get localShellReadyBody => 'Open a shell, or run several sessions side by side.';

  @override
  String localShellUpdateHint(String command) {
    return 'Update packages from inside the shell with  $command . ';
  }

  @override
  String get sftpOpening => 'Opening files…';

  @override
  String get sftpOpenFailed => 'Could not open files';

  @override
  String get sftpEmptyTitle => 'Empty folder';

  @override
  String get sftpEmptyBody => 'Upload a file or create a folder to get started.';

  @override
  String get sftpNewFolder => 'New folder';

  @override
  String get sftpFolderName => 'Folder name';

  @override
  String get sftpNewName => 'New name';

  @override
  String get sftpItemOptions => 'Item options';

  @override
  String get sftpSearchFolder => 'Search folder';

  @override
  String get sftpClearSearch => 'Clear search';

  @override
  String get sftpSortFiles => 'Sort files';

  @override
  String get sftpSortModified => 'Modified';

  @override
  String get sftpSortSize => 'Size';

  @override
  String get sftpSortType => 'Type';

  @override
  String get sftpKindFolder => 'folder';

  @override
  String get sftpKindFile => 'file';

  @override
  String get sftpUploading => 'Uploading';

  @override
  String get sftpDownloading => 'Downloading';

  @override
  String sftpDeleteBody(String name) {
    return '“$name” will be removed from the server.';
  }

  @override
  String sftpItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String sftpFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders',
      one: '1 folder',
    );
    return '$_temp0';
  }

  @override
  String sftpFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get snippetAdd => 'Add snippet';

  @override
  String get snippetEdit => 'Edit snippet';

  @override
  String get snippetCommandLabel => 'Command or text';

  @override
  String get snippetSendEnter => 'Send Enter after snippet';

  @override
  String get snippetHidden => 'Hidden snippet';

  @override
  String get snippetHiddenHint => 'Use for passwords or other secrets.';

  @override
  String get snippetEmpty => 'No snippets saved.';

  @override
  String get backupBody => 'Backups include appearance, terminal settings, saved machines, order, and trusted host keys.';

  @override
  String get backupExportPlain => 'Export without secrets';

  @override
  String get backupExportPlainHint => 'Passwords and private key material are removed.';

  @override
  String get backupExportEncrypted => 'Export encrypted with secrets';

  @override
  String get backupExportEncryptedHint => 'Credentials are protected with a backup password.';

  @override
  String get backupImport => 'Import backup';

  @override
  String get backupImportHint => 'Imported machines are merged into this device.';

  @override
  String get backupPassword => 'Backup password';

  @override
  String get backupEnterPassword => 'Enter password';

  @override
  String get backupConfirmPassword => 'Confirm password';

  @override
  String get backupShowPassword => 'Show password';

  @override
  String get backupHidePassword => 'Hide password';

  @override
  String get backupPasswordHint => 'Use at least 12 characters and at least three of lowercase, uppercase, numbers, and symbols.';

  @override
  String get lockSubtitle => 'Private SSH workspaces, protected locally.';

  @override
  String get lockFooter => 'Encrypted SSH sessions • zero cloud sync';

  @override
  String get lockContinueWithoutAuth => 'Continue without auth';

  @override
  String get lockNoticeNotConfigured => 'Device authentication is not configured. Set a screen lock to keep saved hosts private.';

  @override
  String get lockNoticeCancelled => 'Authentication was cancelled.';

  @override
  String get lockNoticeUnavailable => 'Device authentication is unavailable on this device. Set a screen lock for better protection.';

  @override
  String get localShellNew => 'New local shell';

  @override
  String get localShellRenameTitle => 'Rename shell';

  @override
  String get localShellNewSession => 'New session';

  @override
  String get localShellIncompleteTitle => 'Setup is incomplete';

  @override
  String get localShellResumeInstall => 'Resume install';

  @override
  String get localShellChecking => 'Checking local shells…';

  @override
  String get localShellHint => 'Run commands locally, no server required.';

  @override
  String get localShellSetUp => 'Set up a local shell';

  @override
  String get localShellNameHint => 'Shown on the home screen and terminal tabs.';

  @override
  String get localShellSetupTitle => 'Run Linux on this phone';

  @override
  String get localShellSetupBody => 'A full Linux userland running locally through proot - no server, no root. Pick a distribution; you can set up as many shells as you like, including several of the same distribution.';

  @override
  String get localShellSetupCaption => 'Arch, Debian, Ubuntu, Alpine and more';

  @override
  String get localShellInstallHint => 'The image downloads once and unpacks on your device. Wi-Fi recommended.';

  @override
  String get localShellLicensesBody => 'The local shell uses proot and root filesystem images packaged through Termux, maintained by their upstream distributions. Conduit redistributes the bundled tools under their own open-source licenses.';

  @override
  String get localShellStageUnpacking => 'Unpacking root filesystem… (this can take a few minutes)';

  @override
  String get localShellStageConfiguring => 'Running first-time setup…';

  @override
  String localShellStageDownloading(String distro) {
    return 'Downloading $distro…';
  }

  @override
  String localShellReinstallTitle(String name) {
    return 'Reinstall $name?';
  }

  @override
  String localShellRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String localShellReadyTitle(String distro) {
    return '$distro is ready';
  }

  @override
  String localShellSettingUp(String distro) {
    return 'Setting up $distro';
  }

  @override
  String localShellRemoveBody(String name) {
    return 'This deletes this environment and everything in it. Any open $name tabs will be closed first. Other shells are not affected.';
  }

  @override
  String localShellReinstallBody(String name) {
    return 'This wipes this environment - including any packages you installed - and downloads a fresh image. Any open $name tabs will be closed first.';
  }

  @override
  String localShellInstallWithSize(String size) {
    return 'Install · $size';
  }

  @override
  String localShellDownloadWithSize(String size) {
    return 'Download $size';
  }

  @override
  String get commonUnknown => 'unknown';

  @override
  String get commonRequired => 'Required';

  @override
  String get brandTagline => 'SSH workspaces';

  @override
  String get terminalFontSystemMonospace => 'System mono';

  @override
  String get terminalFontNerdFont => 'Nerd Font';

  @override
  String get terminalEnterCr => 'Carriage return';

  @override
  String get terminalEnterLf => 'Line feed';

  @override
  String get terminalEnterCrlf => 'Carriage return + line feed';

  @override
  String get hostsEmptyBody => 'Add an SSH or Mosh server and Conduit will keep its credentials in your device’s secure storage.';

  @override
  String get hostsSortLastConnected => 'Last connected';

  @override
  String get hostsSortAdded => 'Added';

  @override
  String get hostsSortManual => 'Manual';

  @override
  String get publicKeyCreatedTitle => 'Key created';

  @override
  String get publicKeyTitle => 'Public key';

  @override
  String get authExternalBody => 'Let the SSH server authenticate without saved credentials.';

  @override
  String hardwareKeyItemTitle(int index) {
    return 'Hardware key $index';
  }

  @override
  String get hostCardJustNow => 'just now';

  @override
  String hostCardMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hostCardHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String hostCardDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String hostCardMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String get hostFormConnectionHint => 'Where to reach this machine.';

  @override
  String get hostFormAuthenticationHint => 'Credentials are stored in platform secure storage.';

  @override
  String get hostFormAdvancedHint => 'Optional tagging and connection timing.';

  @override
  String get sshKeyEncryptedHint => 'This key is encrypted. Enter its passphrase below to unlock it.';

  @override
  String get addHardwareKeyNormalKey => 'This is a normal private key. Use it with the Private key method instead.';

  @override
  String get addHardwareKeyNotStub => 'This is not a recognized OpenSSH security-key stub (id_ed25519_sk or id_ecdsa_sk).';

  @override
  String get addHardwareKeyDuplicate => 'This key is already added to this host.';

  @override
  String get addHardwareKeyNotTextStub => 'That file isn\'t a text key stub.';

  @override
  String get commonFilePickerFailed => 'Could not open the file picker.';

  @override
  String get commonFileReadFailed => 'That file could not be read.';

  @override
  String hostFormImported(String name) {
    return 'Imported $name';
  }

  @override
  String get hostFormGenerateFailed => 'Could not generate a key.';

  @override
  String get hostFormNeedHardwareKey => 'Add at least one hardware key.';

  @override
  String get hostFormEnterKeyPassphrase => 'Enter the key passphrase to unlock it.';

  @override
  String get hostFormInvalidPrivateKey => 'Use a valid PEM or OpenSSH private key.';

  @override
  String get hostFormStubUseHardwareKey => 'This is a hardware-key stub. Choose Hardware key instead.';

  @override
  String get hostFormNotTextKey => 'That file isn\'t a text private key.';

  @override
  String get hostFormNotPrivateKey => 'That file isn\'t a recognized private key.';

  @override
  String get hostFormInvalidPort => 'Use a port or low:high range within 1-65535.';

  @override
  String sftpNoMatchQuery(String query) {
    return 'Nothing in this folder matches “$query”.';
  }

  @override
  String get sftpCopiedPath => 'Copied path';

  @override
  String sftpSavedTar(String name) {
    return 'Saved $name.tar';
  }

  @override
  String sftpSavedFile(String name) {
    return 'Saved $name';
  }

  @override
  String sftpUploadedFile(String name) {
    return 'Uploaded $name';
  }

  @override
  String get sftpFileUnreadable => 'One of those files could not be read.';

  @override
  String sftpUploadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uploaded $count files',
      one: 'Uploaded 1 file',
    );
    return '$_temp0';
  }

  @override
  String sftpDeleteTitle(String kind) {
    return 'Delete $kind?';
  }

  @override
  String sftpVisibleOfTotal(int visible, int total) {
    return '$visible of $total';
  }

  @override
  String sftpCountsSummary(String item, String folders, String files) {
    return '$item  ·  $folders folders  ·  $files files';
  }

  @override
  String sftpTransferProgress(String action, String name) {
    return '$action $name';
  }

  @override
  String snippetWithEnter(String text) {
    return '$text + Enter';
  }

  @override
  String get localShellFullBuildOnly => 'Full build only';

  @override
  String get localShellPermissionNeeded => 'Permission needed';

  @override
  String get localShellMountHint => 'Grant file access to mount phone storage at /mnt/android.';

  @override
  String get localShellMountUnavailable => 'Phone storage mounting is available in the full build.';

  @override
  String get localShellSetupFailedBody => 'Something went wrong during setup.';

  @override
  String get localShellErrorDownload => 'Download failed';

  @override
  String get localShellErrorStorage => 'Not enough storage';

  @override
  String get localShellErrorCorrupt => 'Download was corrupted';

  @override
  String get localShellErrorUnpack => 'Could not unpack the image';

  @override
  String get localShellErrorConfigure => 'Configuration failed';

  @override
  String get localShellErrorUnavailable => 'Not available on this device';

  @override
  String get localShellErrorGeneric => 'Setup failed';

  @override
  String get localShellIncompleteBody => 'This shell was added but its image never finished installing. Resume to pick up where it left off, or remove it.';

  @override
  String localShellStatusDownloading(String percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get localShellStatusUnpacking => 'Unpacking…';

  @override
  String get localShellStatusConfiguring => 'Configuring…';

  @override
  String get localShellStatusFailed => 'Setup failed - tap to retry';

  @override
  String localShellStatusChecking(String distro) {
    return '$distro · checking…';
  }

  @override
  String localShellStatusIncomplete(String distro) {
    return '$distro · setup incomplete, tap to resume';
  }

  @override
  String localShellStatusReady(String distro, String size) {
    return '$distro · $size';
  }

  @override
  String get backupExportCancelled => 'Export cancelled.';

  @override
  String get backupExported => 'Backup exported.';

  @override
  String get backupImportCancelled => 'Import cancelled.';

  @override
  String backupImported(int hosts, int keys) {
    return 'Imported $hosts machines and $keys trusted keys.';
  }

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get backupPasswordMismatch => 'Passwords do not match.';

  @override
  String get backupPasswordRequired => 'Enter the backup password.';

  @override
  String get lockAuthReason => 'Unlock Conduit to access saved SSH machines.';

  @override
  String get lockAuthTitle => 'Authentication required';

  @override
  String get lockAuthHint => 'Verify identity';

  @override
  String get appearanceSectionMode => 'Mode';

  @override
  String get appearanceSectionTerminal => 'Terminal';

  @override
  String get appearanceSectionHome => 'Home';

  @override
  String get appearanceSectionBackup => 'Backup';

  @override
  String get appearanceSectionPalette => 'Palette';

  @override
  String get labelDevice => 'Device';

  @override
  String get terminalSnippetGroupGlobal => 'Global';

  @override
  String securityKeyPinAttemptsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts remaining.',
      one: '1 attempt remaining.',
    );
    return '$_temp0';
  }

  @override
  String get localShellErrorNotInstalled => 'The local shell is not installed.';

  @override
  String get localShellErrorAndroidOnly => 'The local shell is only available on Android.';

  @override
  String get localShellErrorArm64Only => 'The local shell requires a 64-bit ARM (arm64-v8a) device.';

  @override
  String get localShellErrorChecksumFailed => 'Downloaded archive failed checksum verification.';

  @override
  String localShellErrorHttpStatus(String status) {
    return 'Unexpected HTTP status $status';
  }

  @override
  String get localShellErrorLowDisk => 'No space left on device.';

  @override
  String localShellErrorProotLaunch(String error) {
    return 'Could not launch proot/tar: $error';
  }

  @override
  String localShellErrorTarExit(String code, String stderr) {
    return 'tar exited with $code: $stderr';
  }

  @override
  String localShellErrorFirstBootLaunch(String error) {
    return 'Could not launch first-boot shell: $error';
  }

  @override
  String localShellErrorFirstBootExit(String code, String stderr) {
    return 'First-boot configuration exited with $code: $stderr';
  }

  @override
  String get localShellErrorStartFailed => 'Could not start the local shell.';

  @override
  String get localShellErrorSessionClosed => 'The local shell session is closed.';

  @override
  String get hostsErrorNotAList => 'Expected a list of hosts.';

  @override
  String get hostsErrorUnreadable => 'Saved hosts could not be read.';

  @override
  String get sftpErrorNotConnected => 'Not connected.';

  @override
  String get sftpErrorTransferInProgress => 'A transfer is already in progress.';

  @override
  String sftpErrorUploadFailed(String name) {
    return 'Could not upload $name.';
  }

  @override
  String sftpErrorOpenFailed(String endpoint) {
    return 'Could not open files on $endpoint.';
  }

  @override
  String sftpErrorPathTooLong(String path) {
    return 'Path is too long to archive: $path';
  }

  @override
  String terminalErrorConnectFailed(String endpoint) {
    return 'Could not connect to $endpoint.';
  }

  @override
  String get terminalErrorSessionClosed => 'The SSH session is closed.';

  @override
  String terminalErrorMoshStartFailed(String endpoint) {
    return 'Could not start a Mosh session on $endpoint.';
  }

  @override
  String get terminalErrorMoshStartupTimeout => 'Timed out waiting for mosh-server startup.';

  @override
  String get terminalErrorMoshSessionClosed => 'The Mosh session is closed.';

  @override
  String terminalStarting(String name) {
    return 'Starting $name...';
  }

  @override
  String terminalConnecting(String endpoint) {
    return 'Connecting to $endpoint...';
  }

  @override
  String get terminalShellExited => 'Shell exited.';

  @override
  String get terminalConnectionClosed => 'Connection closed.';

  @override
  String terminalConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get sshErrorKeyNotUsable => 'The presented security key does not hold any usable key for this host.';

  @override
  String get sshErrorAuthRejected => 'SSH server rejected the configured credentials.';

  @override
  String get sshErrorAuthAborted => 'SSH authentication stopped before it completed.';

  @override
  String sshErrorHandshakeFailed(String message) {
    return 'SSH handshake failed: $message';
  }

  @override
  String get ctapErrorPinInvalid => 'Security key PIN was incorrect.';

  @override
  String get ctapErrorPinBlocked => 'Security key PIN is blocked. Reset the key FIDO app to use it again.';

  @override
  String get ctapErrorPinAuthBlocked => 'The security key temporarily locked itself. Move it away from the phone (or unplug it) for a few seconds, then present it again.';

  @override
  String get ctapErrorPinNotSet => 'This security key needs a FIDO2 PIN before it can be used.';

  @override
  String get ctapErrorPuatRequired => 'This security key requires PIN or user verification.';

  @override
  String get ctapErrorTouchTimeout => 'Security key touch timed out.';

  @override
  String get ctapErrorUpRequired => 'Touch is required on the security key.';

  @override
  String get ctapErrorCancelled => 'Security key authentication was cancelled.';

  @override
  String get ctapErrorNoCredentials => 'This security key does not have the credential for this SSH key stub.';

  @override
  String get ctapErrorPinAuthInvalid => 'Security key rejected the PIN authentication data.';

  @override
  String get ctapErrorInvalidOption => 'Security key rejected the requested verification option.';

  @override
  String get ctapErrorUnauthorizedPermission => 'Security key rejected the requested authentication permission.';

  @override
  String ctapErrorGeneric(String status) {
    return 'Security key failed with CTAP status $status.';
  }

  @override
  String get securityKeyPermissionDenied => 'USB security key permission was denied.';

  @override
  String get securityKeyNfcTimeout => 'The NFC prompt timed out before a security key was read.';

  @override
  String get securityKeyNfcInterrupted => 'NFC security key read was interrupted. Hold the key still and try again.';

  @override
  String securityKeyOperationFailed(String code) {
    return 'Security key operation failed: $code.';
  }

  @override
  String get sshErrorPrivateKeyUnreadable => 'Private key could not be loaded.';

  @override
  String get sshErrorNoHardwareKeys => 'Add at least one hardware key to this host.';

  @override
  String hardwareKeyFallbackName(String index) {
    return 'hardware key $index';
  }

  @override
  String sshErrorHardwareKeyUnreadable(String label) {
    return 'Hardware key \"$label\" could not be loaded.';
  }

  @override
  String sshErrorHardwareKeyNeedsStub(String label) {
    return 'Hardware key \"$label\" requires an OpenSSH security-key stub (id_ed25519_sk or id_ecdsa_sk), not a normal private key.';
  }

  @override
  String get backupErrorRootNotObject => 'Backup root is not an object.';

  @override
  String get backupErrorNotConduit => 'This does not look like a Conduit backup.';

  @override
  String get backupErrorFormatUnsupported => 'This backup format is not supported.';

  @override
  String get backupErrorPasswordWrong => 'The password is wrong or the backup changed.';

  @override
  String get backupErrorPayloadInvalid => 'The encrypted backup payload is invalid.';

  @override
  String get backupErrorPayloadMissing => 'The backup payload is missing.';

  @override
  String get backupErrorEncryptedUnsupported => 'This encrypted backup is not supported.';

  @override
  String get backupErrorEncryptedInvalid => 'This encrypted backup is invalid.';

  @override
  String get backupPasswordRuleLength => 'Use at least 12 characters.';

  @override
  String get backupPasswordRuleSpaces => 'Remove spaces from the start or end.';

  @override
  String get backupPasswordRuleClasses => 'Use at least three of lowercase, uppercase, numbers, and symbols.';

  @override
  String securityKeyNotSelectedKey(String label) {
    return '\"$label\" was not the selected security key.';
  }

  @override
  String get securityKeyAccepted => 'Hardware key accepted.';

  @override
  String get securityKeyEnterPin => 'Enter the PIN for this security key.';

  @override
  String get securityKeyPinIncorrectRetry => 'Security key PIN was incorrect. Try again.';

  @override
  String securityKeyNotOnPresented(String label) {
    return '\"$label\" is not on the presented security key.';
  }

  @override
  String get securityKeySelectionCancelled => 'Security key selection was cancelled.';

  @override
  String securityKeyUsing(String label) {
    return 'Using security key \"$label\".';
  }

  @override
  String securityKeyWaitingForAny(String count) {
    return 'Waiting for hardware key over USB or NFC. Any of your $count enrolled keys will work...';
  }

  @override
  String get securityKeyWaitingForKey => 'Waiting for hardware key over USB or NFC...';

  @override
  String securityKeySwitchingTo(String label) {
    return 'This security key holds \"$label\". Switching to it...';
  }

  @override
  String get securityKeyHoldsNoSaved => 'This security key does not hold any of the keys saved for this host.';

  @override
  String securityKeyNotOnThisKey(String label) {
    return '\"$label\" is not on this security key.';
  }

  @override
  String securityKeyHoldsKeyPresentInstead(String label) {
    return 'That security key does not hold \"$label\". Present \"$label\" instead.';
  }

  @override
  String get securityKeyPinRequired => 'Security key PIN is required.';

  @override
  String get securityKeyPinRequiredShort => 'Security key PIN required.';

  @override
  String get securityKeyPinEntryCancelled => 'Security key PIN entry was cancelled.';

  @override
  String get securityKeyPinAccepted => 'Security key PIN accepted.';

  @override
  String get securityKeyPinUnverified => 'Security key PIN could not be verified.';

  @override
  String get securityKeyPinProtocolUnsupported => 'Unsupported security key PIN protocol.';

  @override
  String get securityKeyTouchUsb => 'Touch your USB security key.';

  @override
  String get securityKeyHoldNfc => 'Keep your NFC security key held against the phone.';

  @override
  String get securityKeyTouchOrHold => 'Touch your USB key, or hold your NFC key near the phone.';

  @override
  String get securityKeyHoldNearPhone => 'Hold your security key near the phone.';

  @override
  String get securityKeySigningFailed => 'Security key signing failed.';

  @override
  String get securityKeyAppletSelectFailed => 'FIDO applet selection failed.';

  @override
  String get securityKeyCommandFailed => 'FIDO command failed.';

  @override
  String get securityKeyResponseTooShort => 'FIDO response was too short.';

  @override
  String securityKeyEmptyApdu(String message) {
    return '$message Empty APDU response.';
  }

  @override
  String securityKeyApduStatus(String message, String sw) {
    return '$message APDU status $sw.';
  }

  @override
  String get securityKeyUsbAndroidOnly => 'USB security keys are only supported on Android.';

  @override
  String get securityKeyUsbEmptyResponse => 'USB security key returned an empty response.';

  @override
  String get securityKeyAuthenticatorDataShort => 'Authenticator data was too short.';

  @override
  String get securityKeyMalformedSignature => 'Malformed DER ECDSA signature.';

  @override
  String securityKeyNotHoldLabel(String label) {
    return 'The presented security key does not hold \"$label\".';
  }

  @override
  String get securityKeyNfcRetrying => 'NFC read was interrupted. Keep the key still near the phone; retrying...';
}
