import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImport;

  /// No description provided for @actionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// No description provided for @actionGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get actionGenerate;

  /// No description provided for @actionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get actionUpload;

  /// No description provided for @actionInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get actionInstall;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get actionReplace;

  /// No description provided for @actionTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get actionTrust;

  /// No description provided for @actionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get actionReject;

  /// No description provided for @actionForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get actionForget;

  /// No description provided for @actionReinstall.
  ///
  /// In en, this message translates to:
  /// **'Reinstall'**
  String get actionReinstall;

  /// No description provided for @actionUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get actionUnlock;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @actionShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get actionShow;

  /// No description provided for @actionHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get actionHide;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get actionManage;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get actionReconnect;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @labelLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelLabel;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get labelName;

  /// No description provided for @labelText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get labelText;

  /// No description provided for @labelHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get labelHost;

  /// No description provided for @hostFormHost.
  ///
  /// In en, this message translates to:
  /// **'Host or IP'**
  String get hostFormHost;

  /// No description provided for @hostFormPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get hostFormPort;

  /// No description provided for @hostFormUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get hostFormUsername;

  /// No description provided for @hostFormDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get hostFormDisplayName;

  /// No description provided for @hostFormSectionConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get hostFormSectionConnection;

  /// No description provided for @hostFormSectionAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get hostFormSectionAuthentication;

  /// No description provided for @hostFormSectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get hostFormSectionAdvanced;

  /// No description provided for @labelAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get labelAlgorithm;

  /// No description provided for @labelFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get labelFingerprint;

  /// No description provided for @labelVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get labelVersion;

  /// No description provided for @labelDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get labelDistribution;

  /// No description provided for @labelDiskUsage.
  ///
  /// In en, this message translates to:
  /// **'Disk usage'**
  String get labelDiskUsage;

  /// No description provided for @labelAndroidFiles.
  ///
  /// In en, this message translates to:
  /// **'Android files'**
  String get labelAndroidFiles;

  /// No description provided for @labelTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get labelTags;

  /// No description provided for @labelFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get labelFiles;

  /// No description provided for @labelMachines.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get labelMachines;

  /// No description provided for @labelSnippets.
  ///
  /// In en, this message translates to:
  /// **'Snippets'**
  String get labelSnippets;

  /// No description provided for @terminalCloseCompose.
  ///
  /// In en, this message translates to:
  /// **'Close compose'**
  String get terminalCloseCompose;

  /// No description provided for @actionCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get actionCopyPath;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @actionDownloadAsTar.
  ///
  /// In en, this message translates to:
  /// **'Download as tar'**
  String get actionDownloadAsTar;

  /// No description provided for @labelOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get labelOpenSourceLicenses;

  /// No description provided for @securityKeyChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose security key'**
  String get securityKeyChooseTitle;

  /// No description provided for @securityKeyPinLabel.
  ///
  /// In en, this message translates to:
  /// **'FIDO2 PIN'**
  String get securityKeyPinLabel;

  /// No description provided for @securityKeyPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN'**
  String get securityKeyPinTitle;

  /// No description provided for @securityKeyPinBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN for your hardware security key.'**
  String get securityKeyPinBody;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies to the whole app immediately. No restart needed.'**
  String get languageSubtitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a developer palette. The home screen, editor, and dialogs share the same look.'**
  String get appearanceSubtitle;

  /// No description provided for @appearanceShowLocalShell.
  ///
  /// In en, this message translates to:
  /// **'Show local shell'**
  String get appearanceShowLocalShell;

  /// No description provided for @appearanceShowLocalShellHint.
  ///
  /// In en, this message translates to:
  /// **'Show the local terminal shortcut on the home screen.'**
  String get appearanceShowLocalShellHint;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backupTitle;

  /// No description provided for @appearanceBackupRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Export settings and machines or import a saved backup.'**
  String get appearanceBackupRestoreHint;

  /// No description provided for @appearanceThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceThemeSystem;

  /// No description provided for @appearanceThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceThemeDark;

  /// No description provided for @appearanceThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceThemeLight;

  /// No description provided for @appearanceFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get appearanceFontSize;

  /// No description provided for @appearanceKeyRows.
  ///
  /// In en, this message translates to:
  /// **'Key rows'**
  String get appearanceKeyRows;

  /// No description provided for @appearanceEnterSends.
  ///
  /// In en, this message translates to:
  /// **'Enter sends'**
  String get appearanceEnterSends;

  /// No description provided for @appearanceSendMouseTaps.
  ///
  /// In en, this message translates to:
  /// **'Send mouse taps'**
  String get appearanceSendMouseTaps;

  /// No description provided for @appearanceSendMouseTapsHint.
  ///
  /// In en, this message translates to:
  /// **'Forward terminal taps as mouse clicks when apps enable mouse tracking.'**
  String get appearanceSendMouseTapsHint;

  /// No description provided for @appearanceGlobalSnippets.
  ///
  /// In en, this message translates to:
  /// **'Global snippets'**
  String get appearanceGlobalSnippets;

  /// No description provided for @appearanceGlobalSnippetsHint.
  ///
  /// In en, this message translates to:
  /// **'Shown from the Snip key-row menu on every machine.'**
  String get appearanceGlobalSnippetsHint;

  /// No description provided for @appearanceAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get appearanceAddRow;

  /// No description provided for @appearanceEditKeys.
  ///
  /// In en, this message translates to:
  /// **'Edit keys'**
  String get appearanceEditKeys;

  /// No description provided for @appearanceRemoveRow.
  ///
  /// In en, this message translates to:
  /// **'Remove row'**
  String get appearanceRemoveRow;

  /// No description provided for @appearanceCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get appearanceCustom;

  /// No description provided for @appearanceCustomKey.
  ///
  /// In en, this message translates to:
  /// **'Custom key'**
  String get appearanceCustomKey;

  /// No description provided for @appearanceSendEnterAfterText.
  ///
  /// In en, this message translates to:
  /// **'Send Enter after text'**
  String get appearanceSendEnterAfterText;

  /// No description provided for @appearanceControlKey.
  ///
  /// In en, this message translates to:
  /// **'Control key'**
  String get appearanceControlKey;

  /// No description provided for @appearanceKeyPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for an unencrypted key.'**
  String get appearanceKeyPassphraseHint;

  /// No description provided for @appearanceTmuxPrefixHint.
  ///
  /// In en, this message translates to:
  /// **'Used by the Tmux and Tmux+ key-row buttons.'**
  String get appearanceTmuxPrefixHint;

  /// No description provided for @appearanceTmuxSessionHint.
  ///
  /// In en, this message translates to:
  /// **'Attach to the named tmux session, or create it if needed.'**
  String get appearanceTmuxSessionHint;

  /// No description provided for @appearanceTmuxAutostart.
  ///
  /// In en, this message translates to:
  /// **'Conduit attaches to this session, or creates it.'**
  String get appearanceTmuxAutostart;

  /// No description provided for @appearanceDisableRunOnConnect.
  ///
  /// In en, this message translates to:
  /// **'Disable run on connect'**
  String get appearanceDisableRunOnConnect;

  /// No description provided for @appearanceRunOnConnect.
  ///
  /// In en, this message translates to:
  /// **'Run on connect'**
  String get appearanceRunOnConnect;

  /// No description provided for @appearanceKeyRowsCount.
  ///
  /// In en, this message translates to:
  /// **'Key Rows ({count})'**
  String appearanceKeyRowsCount(int count);

  /// No description provided for @appearanceRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Row {index}'**
  String appearanceRowLabel(int index);

  /// No description provided for @appearanceRowKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Row {index} Keys'**
  String appearanceRowKeysTitle(int index);

  /// No description provided for @appearanceKeyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 key} other{{count} keys}}'**
  String appearanceKeyCount(int count);

  /// No description provided for @paletteCaptionCatppuccin.
  ///
  /// In en, this message translates to:
  /// **'Mocha, calm and polished'**
  String get paletteCaptionCatppuccin;

  /// No description provided for @paletteCaptionTokyoNight.
  ///
  /// In en, this message translates to:
  /// **'Deep blue IDE focus'**
  String get paletteCaptionTokyoNight;

  /// No description provided for @paletteCaptionDracula.
  ///
  /// In en, this message translates to:
  /// **'High-contrast neon classic'**
  String get paletteCaptionDracula;

  /// No description provided for @paletteCaptionNord.
  ///
  /// In en, this message translates to:
  /// **'Arctic, restrained, cool'**
  String get paletteCaptionNord;

  /// No description provided for @paletteCaptionGruvbox.
  ///
  /// In en, this message translates to:
  /// **'Warm retro terminal energy'**
  String get paletteCaptionGruvbox;

  /// No description provided for @paletteCaptionSolarized.
  ///
  /// In en, this message translates to:
  /// **'Balanced low-glare contrast'**
  String get paletteCaptionSolarized;

  /// No description provided for @paletteCaptionOneDark.
  ///
  /// In en, this message translates to:
  /// **'Atom-inspired editor calm'**
  String get paletteCaptionOneDark;

  /// No description provided for @paletteCaptionRosePine.
  ///
  /// In en, this message translates to:
  /// **'Muted dusk, soft contrast'**
  String get paletteCaptionRosePine;

  /// No description provided for @paletteCaptionEverforest.
  ///
  /// In en, this message translates to:
  /// **'Green low-glare woodland'**
  String get paletteCaptionEverforest;

  /// No description provided for @paletteCaptionMonokai.
  ///
  /// In en, this message translates to:
  /// **'Punchy classic code color'**
  String get paletteCaptionMonokai;

  /// No description provided for @paletteCaptionAyuDark.
  ///
  /// In en, this message translates to:
  /// **'Warm amber night coding'**
  String get paletteCaptionAyuDark;

  /// No description provided for @paletteCaptionKanagawa.
  ///
  /// In en, this message translates to:
  /// **'Muted ink and wave tones'**
  String get paletteCaptionKanagawa;

  /// No description provided for @paletteCaptionNightOwl.
  ///
  /// In en, this message translates to:
  /// **'Crisp blue late-night focus'**
  String get paletteCaptionNightOwl;

  /// No description provided for @paletteCaptionPalenight.
  ///
  /// In en, this message translates to:
  /// **'Soft violet editor glow'**
  String get paletteCaptionPalenight;

  /// No description provided for @paletteCaptionSynthwave.
  ///
  /// In en, this message translates to:
  /// **'Electric retro terminal pop'**
  String get paletteCaptionSynthwave;

  /// No description provided for @paletteCaptionGithubDark.
  ///
  /// In en, this message translates to:
  /// **'Quiet modern code contrast'**
  String get paletteCaptionGithubDark;

  /// No description provided for @hostsTrustedKeys.
  ///
  /// In en, this message translates to:
  /// **'Trusted keys'**
  String get hostsTrustedKeys;

  /// No description provided for @hostsLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get hostsLock;

  /// No description provided for @hostsStatSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hostsStatSaved;

  /// No description provided for @hostsStatLiveSessions.
  ///
  /// In en, this message translates to:
  /// **'Live sessions'**
  String get hostsStatLiveSessions;

  /// No description provided for @hostsResumeSessions.
  ///
  /// In en, this message translates to:
  /// **'Resume sessions'**
  String get hostsResumeSessions;

  /// No description provided for @hostsSavedMachines.
  ///
  /// In en, this message translates to:
  /// **'Saved machines'**
  String get hostsSavedMachines;

  /// No description provided for @hostsSavedMachinesHint.
  ///
  /// In en, this message translates to:
  /// **'SSH and Mosh connections you have saved.'**
  String get hostsSavedMachinesHint;

  /// No description provided for @hostsSortMachines.
  ///
  /// In en, this message translates to:
  /// **'Sort machines'**
  String get hostsSortMachines;

  /// No description provided for @hostsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get hostsErrorTitle;

  /// No description provided for @hostsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved machines yet'**
  String get hostsEmptyTitle;

  /// No description provided for @commonNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get commonNoMatches;

  /// No description provided for @commonNoMatchesHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or clear filters.'**
  String get commonNoMatchesHint;

  /// No description provided for @hostsPickMachine.
  ///
  /// In en, this message translates to:
  /// **'Pick a machine to spin up a new tab.'**
  String get hostsPickMachine;

  /// No description provided for @hostsGrantFileAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant file access, then open the shell again.'**
  String get hostsGrantFileAccess;

  /// No description provided for @hostsDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate machine'**
  String get hostsDuplicateTitle;

  /// No description provided for @hostsDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'Copy the saved password and key material into the new machine?'**
  String get hostsDuplicateBody;

  /// No description provided for @hostsDuplicateWithoutSecrets.
  ///
  /// In en, this message translates to:
  /// **'Without secrets'**
  String get hostsDuplicateWithoutSecrets;

  /// No description provided for @hostsDuplicateWithSecrets.
  ///
  /// In en, this message translates to:
  /// **'Copy secrets'**
  String get hostsDuplicateWithSecrets;

  /// No description provided for @hostsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete machine?'**
  String get hostsDeleteTitle;

  /// No description provided for @hostsCopiedEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Copied {endpoint}'**
  String hostsCopiedEndpoint(String endpoint);

  /// No description provided for @hostsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Conduit will forget “{name}”.'**
  String hostsDeleteBody(String name);

  /// No description provided for @hostsActiveSessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 active} other{{count} active}}'**
  String hostsActiveSessionCount(int count);

  /// No description provided for @hostFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit machine'**
  String get hostFormEditTitle;

  /// No description provided for @hostFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New machine'**
  String get hostFormNewTitle;

  /// No description provided for @hostFormEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update connection details and credentials.'**
  String get hostFormEditSubtitle;

  /// No description provided for @hostFormNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connection profile and credentials.'**
  String get hostFormNewSubtitle;

  /// No description provided for @hostFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get hostFormSave;

  /// No description provided for @hostFormAdd.
  ///
  /// In en, this message translates to:
  /// **'Add machine'**
  String get hostFormAdd;

  /// No description provided for @hostFormStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'Stored on-device only • never synced to the cloud'**
  String get hostFormStoredLocally;

  /// No description provided for @hostFormRenameHardwareKey.
  ///
  /// In en, this message translates to:
  /// **'Rename hardware key'**
  String get hostFormRenameHardwareKey;

  /// No description provided for @hostFormRemoveHardwareKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{label}\"?'**
  String hostFormRemoveHardwareKeyTitle(String label);

  /// No description provided for @hostFormRemoveHardwareKeyBody.
  ///
  /// In en, this message translates to:
  /// **'The stub is removed from this host. Your security key and the server are not affected.'**
  String get hostFormRemoveHardwareKeyBody;

  /// No description provided for @hostFormReplaceKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace key?'**
  String get hostFormReplaceKeyTitle;

  /// No description provided for @hostFormReplaceKeyBody.
  ///
  /// In en, this message translates to:
  /// **'The private key field already has content. Replace it?'**
  String get hostFormReplaceKeyBody;

  /// No description provided for @hostFormGenerateKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate Ed25519 key'**
  String get hostFormGenerateKeyTitle;

  /// No description provided for @hostFormGenerateKeyBody.
  ///
  /// In en, this message translates to:
  /// **'A new key pair is created on this device. The public key is shown next so you can add it to the server.'**
  String get hostFormGenerateKeyBody;

  /// No description provided for @hostFormKeyLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Shown as the key comment.'**
  String get hostFormKeyLabelHint;

  /// No description provided for @hostFormKeyPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase (optional)'**
  String get hostFormKeyPassphrase;

  /// No description provided for @hostFormKeyPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Encrypts the private key. Leave empty for none.'**
  String get hostFormKeyPassphraseHint;

  /// No description provided for @hostFormOfferTempKey.
  ///
  /// In en, this message translates to:
  /// **'Offer temporary public key'**
  String get hostFormOfferTempKey;

  /// No description provided for @hostFormOfferTempKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Helps servers that authenticate externally but still expect a public-key login attempt.'**
  String get hostFormOfferTempKeyHint;

  /// No description provided for @hostFormPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get hostFormPrivateKey;

  /// No description provided for @hostFormKeyPassphraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Key passphrase'**
  String get hostFormKeyPassphraseLabel;

  /// No description provided for @hostFormPrivateKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Use a normal SSH private key. If the key is encrypted, enter its passphrase below.'**
  String get hostFormPrivateKeyHint;

  /// No description provided for @hostFormPrivateKeyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Import, paste, or generate a key.'**
  String get hostFormPrivateKeyEmpty;

  /// No description provided for @hostFormForwardAgent.
  ///
  /// In en, this message translates to:
  /// **'Forward SSH agent'**
  String get hostFormForwardAgent;

  /// No description provided for @hostFormForwardAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Let hosts you connect to use this key to authenticate onward. Hardware keys prompt for a touch on each use.'**
  String get hostFormForwardAgentHint;

  /// No description provided for @hostFormConnectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get hostFormConnectionTimeout;

  /// No description provided for @hostFormConnectWithMosh.
  ///
  /// In en, this message translates to:
  /// **'Connect with Mosh'**
  String get hostFormConnectWithMosh;

  /// No description provided for @hostFormConnectWithMoshHint.
  ///
  /// In en, this message translates to:
  /// **'Roaming UDP session over SSH. Requires mosh-server on the host and open UDP ports.'**
  String get hostFormConnectWithMoshHint;

  /// No description provided for @hostFormMoshLocale.
  ///
  /// In en, this message translates to:
  /// **'Mosh locale'**
  String get hostFormMoshLocale;

  /// No description provided for @hostFormMoshLocaleHint.
  ///
  /// In en, this message translates to:
  /// **'Must be a UTF-8 locale installed on the host.'**
  String get hostFormMoshLocaleHint;

  /// No description provided for @hostFormMoshPorts.
  ///
  /// In en, this message translates to:
  /// **'Mosh UDP ports'**
  String get hostFormMoshPorts;

  /// No description provided for @hostFormMoshPortsHint.
  ///
  /// In en, this message translates to:
  /// **'Port or range like 60000:61000. Empty uses 60001:60999.'**
  String get hostFormMoshPortsHint;

  /// No description provided for @hostFormPredictiveEcho.
  ///
  /// In en, this message translates to:
  /// **'Predictive echo (experimental)'**
  String get hostFormPredictiveEcho;

  /// No description provided for @hostFormPredictiveEchoHint.
  ///
  /// In en, this message translates to:
  /// **'Show local input previews on laggy Mosh sessions.'**
  String get hostFormPredictiveEchoHint;

  /// No description provided for @hostFormStartTmux.
  ///
  /// In en, this message translates to:
  /// **'Start tmux on connect'**
  String get hostFormStartTmux;

  /// No description provided for @hostFormTmuxSession.
  ///
  /// In en, this message translates to:
  /// **'Tmux session name'**
  String get hostFormTmuxSession;

  /// No description provided for @hostFormTmuxDirectory.
  ///
  /// In en, this message translates to:
  /// **'Tmux start directory'**
  String get hostFormTmuxDirectory;

  /// No description provided for @hostFormTmuxPrefix.
  ///
  /// In en, this message translates to:
  /// **'Tmux prefix'**
  String get hostFormTmuxPrefix;

  /// No description provided for @hostFormTmuxDirectoryHint.
  ///
  /// In en, this message translates to:
  /// **'Used when a new tmux session is created. An existing tmux session keeps its directory.'**
  String get hostFormTmuxDirectoryHint;

  /// No description provided for @hostFormHostSnippets.
  ///
  /// In en, this message translates to:
  /// **'Host snippets'**
  String get hostFormHostSnippets;

  /// No description provided for @hostFormHostSnippetsHint.
  ///
  /// In en, this message translates to:
  /// **'Shown in the Snip key-row menu for this machine. Hidden snippets are useful for passwords or other secrets.'**
  String get hostFormHostSnippetsHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Use the account password for SSH login.'**
  String get authPasswordHint;

  /// No description provided for @authPasswordDetail.
  ///
  /// In en, this message translates to:
  /// **'Use this for password-only SSH login.'**
  String get authPasswordDetail;

  /// No description provided for @authHardwareKey.
  ///
  /// In en, this message translates to:
  /// **'Hardware key'**
  String get authHardwareKey;

  /// No description provided for @authPrivateKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Use a PEM or OpenSSH private key.'**
  String get authPrivateKeyHint;

  /// No description provided for @authHardwareKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Use one or more security keys over USB or NFC.'**
  String get authHardwareKeyHint;

  /// No description provided for @authExternal.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get authExternal;

  /// No description provided for @authExternalHint.
  ///
  /// In en, this message translates to:
  /// **'Use this when authentication is handled outside Conduit, without storing a password or private key in the app.'**
  String get authExternalHint;

  /// No description provided for @authHardwareKeyDetail.
  ///
  /// In en, this message translates to:
  /// **'Add the OpenSSH *_sk key stub for each security key you own. When you connect, Conduit asks whichever key you present to sign over USB or NFC.'**
  String get authHardwareKeyDetail;

  /// No description provided for @hardwareKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Hardware keys'**
  String get hardwareKeysTitle;

  /// No description provided for @hardwareKeysEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hardware keys yet. Add the OpenSSH *_sk stub for each security key you want to use with this host. Any of them will unlock the connection.'**
  String get hardwareKeysEmpty;

  /// No description provided for @hardwareKeysCount.
  ///
  /// In en, this message translates to:
  /// **'Hardware keys ({count})'**
  String hardwareKeysCount(int count);

  /// No description provided for @hardwareKeysOptions.
  ///
  /// In en, this message translates to:
  /// **'Key options'**
  String get hardwareKeysOptions;

  /// No description provided for @hostCardOptions.
  ///
  /// In en, this message translates to:
  /// **'Machine options'**
  String get hostCardOptions;

  /// No description provided for @hostCardDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get hostCardDuplicate;

  /// No description provided for @hostCardCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get hostCardCopyAddress;

  /// No description provided for @hostCardViewPublicKey.
  ///
  /// In en, this message translates to:
  /// **'View public key'**
  String get hostCardViewPublicKey;

  /// No description provided for @hostKeyPassphraseMismatch.
  ///
  /// In en, this message translates to:
  /// **'That passphrase did not match this key.'**
  String get hostKeyPassphraseMismatch;

  /// No description provided for @hostsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search machines, hosts, tags…'**
  String get hostsSearchHint;

  /// No description provided for @hostFormTagsHint.
  ///
  /// In en, this message translates to:
  /// **'production, edge, eu-west…  press enter to add'**
  String get hostFormTagsHint;

  /// No description provided for @hostFormAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get hostFormAddTag;

  /// No description provided for @publicKeyCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'A new {algorithm} key is saved on this device. Add the public key below to the server, then connect.'**
  String publicKeyCreatedBody(String algorithm);

  /// No description provided for @publicKeyInstructions.
  ///
  /// In en, this message translates to:
  /// **'Add this line to ~/.ssh/authorized_keys on the host you want to reach.'**
  String get publicKeyInstructions;

  /// No description provided for @publicKeySave.
  ///
  /// In en, this message translates to:
  /// **'Save .pub'**
  String get publicKeySave;

  /// No description provided for @publicKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Public key copied to clipboard'**
  String get publicKeyCopied;

  /// No description provided for @publicKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Public key saved'**
  String get publicKeySaved;

  /// No description provided for @publicKeySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the public key'**
  String get publicKeySaveFailed;

  /// No description provided for @publicKeyPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'The private half never leaves this device. It is held in platform secure storage with your other credentials.'**
  String get publicKeyPrivateNote;

  /// No description provided for @addHardwareKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add hardware key'**
  String get addHardwareKeyTitle;

  /// No description provided for @addHardwareKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Import or paste the OpenSSH *_sk stub that ssh-keygen created for this security key. The stub only points to the key; the private part never leaves the hardware.'**
  String get addHardwareKeyBody;

  /// No description provided for @addHardwareKeyStubLabel.
  ///
  /// In en, this message translates to:
  /// **'OpenSSH hardware key stub'**
  String get addHardwareKeyStubLabel;

  /// No description provided for @addHardwareKeyStubHint.
  ///
  /// In en, this message translates to:
  /// **'Import or paste the id_ed25519_sk or id_ecdsa_sk file.'**
  String get addHardwareKeyStubHint;

  /// No description provided for @addHardwareKeyPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Stub passphrase'**
  String get addHardwareKeyPassphrase;

  /// No description provided for @addHardwareKeyPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'This stub file is encrypted.'**
  String get addHardwareKeyPassphraseHint;

  /// No description provided for @addHardwareKeyLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Shown when Conduit asks for this key, e.g. \"5C work\" or \"NFC backup\".'**
  String get addHardwareKeyLabelHint;

  /// No description provided for @addHardwareKeySubmit.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get addHardwareKeySubmit;

  /// No description provided for @terminalRecallLine.
  ///
  /// In en, this message translates to:
  /// **'Recall a sent line'**
  String get terminalRecallLine;

  /// No description provided for @terminalComposeHint.
  ///
  /// In en, this message translates to:
  /// **'Compose a line, Enter to send …'**
  String get terminalComposeHint;

  /// No description provided for @terminalNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions open'**
  String get terminalNoSessions;

  /// No description provided for @terminalBackToMachines.
  ///
  /// In en, this message translates to:
  /// **'Back to machines'**
  String get terminalBackToMachines;

  /// No description provided for @terminalFunctionKeys.
  ///
  /// In en, this message translates to:
  /// **'Function keys'**
  String get terminalFunctionKeys;

  /// No description provided for @terminalTmuxActions.
  ///
  /// In en, this message translates to:
  /// **'Tmux actions'**
  String get terminalTmuxActions;

  /// No description provided for @tmuxActionNewWindow.
  ///
  /// In en, this message translates to:
  /// **'New window'**
  String get tmuxActionNewWindow;

  /// No description provided for @tmuxActionPreviousWindow.
  ///
  /// In en, this message translates to:
  /// **'Previous window'**
  String get tmuxActionPreviousWindow;

  /// No description provided for @tmuxActionNextWindow.
  ///
  /// In en, this message translates to:
  /// **'Next window'**
  String get tmuxActionNextWindow;

  /// No description provided for @tmuxActionWindowList.
  ///
  /// In en, this message translates to:
  /// **'Window list'**
  String get tmuxActionWindowList;

  /// No description provided for @tmuxActionLastWindow.
  ///
  /// In en, this message translates to:
  /// **'Last window'**
  String get tmuxActionLastWindow;

  /// No description provided for @tmuxActionRenameWindow.
  ///
  /// In en, this message translates to:
  /// **'Rename window'**
  String get tmuxActionRenameWindow;

  /// No description provided for @tmuxActionSplitHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Split horizontal'**
  String get tmuxActionSplitHorizontal;

  /// No description provided for @tmuxActionSplitVertical.
  ///
  /// In en, this message translates to:
  /// **'Split vertical'**
  String get tmuxActionSplitVertical;

  /// No description provided for @tmuxActionPaneLeft.
  ///
  /// In en, this message translates to:
  /// **'Pane left'**
  String get tmuxActionPaneLeft;

  /// No description provided for @tmuxActionPaneRight.
  ///
  /// In en, this message translates to:
  /// **'Pane right'**
  String get tmuxActionPaneRight;

  /// No description provided for @tmuxActionPaneUp.
  ///
  /// In en, this message translates to:
  /// **'Pane up'**
  String get tmuxActionPaneUp;

  /// No description provided for @tmuxActionPaneDown.
  ///
  /// In en, this message translates to:
  /// **'Pane down'**
  String get tmuxActionPaneDown;

  /// No description provided for @tmuxActionZoomPane.
  ///
  /// In en, this message translates to:
  /// **'Zoom pane'**
  String get tmuxActionZoomPane;

  /// No description provided for @tmuxActionCommandPrompt.
  ///
  /// In en, this message translates to:
  /// **'Command prompt'**
  String get tmuxActionCommandPrompt;

  /// No description provided for @tmuxActionScrollback.
  ///
  /// In en, this message translates to:
  /// **'Scrollback'**
  String get tmuxActionScrollback;

  /// No description provided for @tmuxActionClosePane.
  ///
  /// In en, this message translates to:
  /// **'Close pane'**
  String get tmuxActionClosePane;

  /// No description provided for @tmuxActionCloseWindow.
  ///
  /// In en, this message translates to:
  /// **'Close window'**
  String get tmuxActionCloseWindow;

  /// No description provided for @tmuxActionDetach.
  ///
  /// In en, this message translates to:
  /// **'Detach'**
  String get tmuxActionDetach;

  /// No description provided for @terminalNoSnippets.
  ///
  /// In en, this message translates to:
  /// **'No snippets saved'**
  String get terminalNoSnippets;

  /// No description provided for @commonWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get commonWorking;

  /// No description provided for @trustedKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted host keys'**
  String get trustedKeysTitle;

  /// No description provided for @trustedKeysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Servers Conduit has connected to before.'**
  String get trustedKeysSubtitle;

  /// No description provided for @trustedKeysEmpty.
  ///
  /// In en, this message translates to:
  /// **'Connect to a host and you’ll be asked to trust its key - the fingerprint lands here.'**
  String get trustedKeysEmpty;

  /// No description provided for @trustedKeysEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trusted keys yet'**
  String get trustedKeysEmptyTitle;

  /// No description provided for @trustedKeysForgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget trusted key?'**
  String get trustedKeysForgetTitle;

  /// No description provided for @hostKeyPreviouslyTrusted.
  ///
  /// In en, this message translates to:
  /// **'Previously trusted:'**
  String get hostKeyPreviouslyTrusted;

  /// No description provided for @trustedKeysForgetBody.
  ///
  /// In en, this message translates to:
  /// **'Conduit will prompt again the next time you connect to {host}:{port}.'**
  String trustedKeysForgetBody(String host, int port);

  /// No description provided for @hostKeyChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Host key changed'**
  String get hostKeyChangedTitle;

  /// No description provided for @hostKeyTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust this host?'**
  String get hostKeyTrustTitle;

  /// No description provided for @hostKeyTrustNew.
  ///
  /// In en, this message translates to:
  /// **'Trust new key'**
  String get hostKeyTrustNew;

  /// No description provided for @hostKeyUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'Conduit has not connected to {host}:{port} before. Verify the fingerprint matches the one reported by the server (e.g. `ssh-keygen -E md5 -lf <key>`).'**
  String hostKeyUnknownBody(String host, int port);

  /// No description provided for @hostKeyMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'The server at {host}:{port} is presenting a different key than the one you previously trusted. This can indicate a man-in-the-middle attack, or the server may have been legitimately rekeyed.'**
  String hostKeyMismatchBody(String host, int port);

  /// No description provided for @keyChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking key…'**
  String get keyChecking;

  /// No description provided for @keyCheckingPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Checking passphrase…'**
  String get keyCheckingPassphrase;

  /// No description provided for @localShellReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Open a shell, or run several sessions side by side.'**
  String get localShellReadyBody;

  /// No description provided for @localShellUpdateHint.
  ///
  /// In en, this message translates to:
  /// **'Update packages from inside the shell with  {command} . '**
  String localShellUpdateHint(String command);

  /// No description provided for @sftpOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening files…'**
  String get sftpOpening;

  /// No description provided for @sftpOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open files'**
  String get sftpOpenFailed;

  /// No description provided for @sftpEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get sftpEmptyTitle;

  /// No description provided for @sftpEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Upload a file or create a folder to get started.'**
  String get sftpEmptyBody;

  /// No description provided for @sftpNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get sftpNewFolder;

  /// No description provided for @sftpFolderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get sftpFolderName;

  /// No description provided for @sftpNewName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get sftpNewName;

  /// No description provided for @sftpItemOptions.
  ///
  /// In en, this message translates to:
  /// **'Item options'**
  String get sftpItemOptions;

  /// No description provided for @sftpSearchFolder.
  ///
  /// In en, this message translates to:
  /// **'Search folder'**
  String get sftpSearchFolder;

  /// No description provided for @sftpClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get sftpClearSearch;

  /// No description provided for @sftpSortFiles.
  ///
  /// In en, this message translates to:
  /// **'Sort files'**
  String get sftpSortFiles;

  /// No description provided for @sftpSortModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get sftpSortModified;

  /// No description provided for @sftpSortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sftpSortSize;

  /// No description provided for @sftpSortType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sftpSortType;

  /// No description provided for @sftpKindFolder.
  ///
  /// In en, this message translates to:
  /// **'folder'**
  String get sftpKindFolder;

  /// No description provided for @sftpKindFile.
  ///
  /// In en, this message translates to:
  /// **'file'**
  String get sftpKindFile;

  /// No description provided for @sftpUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get sftpUploading;

  /// No description provided for @sftpDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get sftpDownloading;

  /// No description provided for @sftpDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed from the server.'**
  String sftpDeleteBody(String name);

  /// No description provided for @sftpItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item} other{{count} items}}'**
  String sftpItemCount(int count);

  /// No description provided for @sftpFolderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 folder} other{{count} folders}}'**
  String sftpFolderCount(int count);

  /// No description provided for @sftpFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 file} other{{count} files}}'**
  String sftpFileCount(int count);

  /// No description provided for @snippetAdd.
  ///
  /// In en, this message translates to:
  /// **'Add snippet'**
  String get snippetAdd;

  /// No description provided for @snippetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit snippet'**
  String get snippetEdit;

  /// No description provided for @snippetCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command or text'**
  String get snippetCommandLabel;

  /// No description provided for @snippetSendEnter.
  ///
  /// In en, this message translates to:
  /// **'Send Enter after snippet'**
  String get snippetSendEnter;

  /// No description provided for @snippetHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden snippet'**
  String get snippetHidden;

  /// No description provided for @snippetHiddenHint.
  ///
  /// In en, this message translates to:
  /// **'Use for passwords or other secrets.'**
  String get snippetHiddenHint;

  /// No description provided for @snippetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No snippets saved.'**
  String get snippetEmpty;

  /// No description provided for @backupBody.
  ///
  /// In en, this message translates to:
  /// **'Backups include appearance, terminal settings, saved machines, order, and trusted host keys.'**
  String get backupBody;

  /// No description provided for @backupExportPlain.
  ///
  /// In en, this message translates to:
  /// **'Export without secrets'**
  String get backupExportPlain;

  /// No description provided for @backupExportPlainHint.
  ///
  /// In en, this message translates to:
  /// **'Passwords and private key material are removed.'**
  String get backupExportPlainHint;

  /// No description provided for @backupExportEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Export encrypted with secrets'**
  String get backupExportEncrypted;

  /// No description provided for @backupExportEncryptedHint.
  ///
  /// In en, this message translates to:
  /// **'Credentials are protected with a backup password.'**
  String get backupExportEncryptedHint;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get backupImport;

  /// No description provided for @backupImportHint.
  ///
  /// In en, this message translates to:
  /// **'Imported machines are merged into this device.'**
  String get backupImportHint;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupPassword;

  /// No description provided for @backupEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get backupEnterPassword;

  /// No description provided for @backupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get backupConfirmPassword;

  /// No description provided for @backupShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get backupShowPassword;

  /// No description provided for @backupHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get backupHidePassword;

  /// No description provided for @backupPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters and at least three of lowercase, uppercase, numbers, and symbols.'**
  String get backupPasswordHint;

  /// No description provided for @lockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private SSH workspaces, protected locally.'**
  String get lockSubtitle;

  /// No description provided for @lockFooter.
  ///
  /// In en, this message translates to:
  /// **'Encrypted SSH sessions • zero cloud sync'**
  String get lockFooter;

  /// No description provided for @lockContinueWithoutAuth.
  ///
  /// In en, this message translates to:
  /// **'Continue without auth'**
  String get lockContinueWithoutAuth;

  /// No description provided for @lockNoticeNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Device authentication is not configured. Set a screen lock to keep saved hosts private.'**
  String get lockNoticeNotConfigured;

  /// No description provided for @lockNoticeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Authentication was cancelled.'**
  String get lockNoticeCancelled;

  /// No description provided for @lockNoticeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device authentication is unavailable on this device. Set a screen lock for better protection.'**
  String get lockNoticeUnavailable;

  /// No description provided for @localShellNew.
  ///
  /// In en, this message translates to:
  /// **'New local shell'**
  String get localShellNew;

  /// No description provided for @localShellRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename shell'**
  String get localShellRenameTitle;

  /// No description provided for @localShellNewSession.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get localShellNewSession;

  /// No description provided for @localShellIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup is incomplete'**
  String get localShellIncompleteTitle;

  /// No description provided for @localShellResumeInstall.
  ///
  /// In en, this message translates to:
  /// **'Resume install'**
  String get localShellResumeInstall;

  /// No description provided for @localShellChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking local shells…'**
  String get localShellChecking;

  /// No description provided for @localShellHint.
  ///
  /// In en, this message translates to:
  /// **'Run commands locally, no server required.'**
  String get localShellHint;

  /// No description provided for @localShellSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up a local shell'**
  String get localShellSetUp;

  /// No description provided for @localShellNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on the home screen and terminal tabs.'**
  String get localShellNameHint;

  /// No description provided for @localShellSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Run Linux on this phone'**
  String get localShellSetupTitle;

  /// No description provided for @localShellSetupBody.
  ///
  /// In en, this message translates to:
  /// **'A full Linux userland running locally through proot - no server, no root. Pick a distribution; you can set up as many shells as you like, including several of the same distribution.'**
  String get localShellSetupBody;

  /// No description provided for @localShellSetupCaption.
  ///
  /// In en, this message translates to:
  /// **'Arch, Debian, Ubuntu, Alpine and more'**
  String get localShellSetupCaption;

  /// No description provided for @localShellInstallHint.
  ///
  /// In en, this message translates to:
  /// **'The image downloads once and unpacks on your device. Wi-Fi recommended.'**
  String get localShellInstallHint;

  /// No description provided for @localShellLicensesBody.
  ///
  /// In en, this message translates to:
  /// **'The local shell uses proot and root filesystem images packaged through Termux, maintained by their upstream distributions. Conduit redistributes the bundled tools under their own open-source licenses.'**
  String get localShellLicensesBody;

  /// No description provided for @localShellStageUnpacking.
  ///
  /// In en, this message translates to:
  /// **'Unpacking root filesystem… (this can take a few minutes)'**
  String get localShellStageUnpacking;

  /// No description provided for @localShellStageConfiguring.
  ///
  /// In en, this message translates to:
  /// **'Running first-time setup…'**
  String get localShellStageConfiguring;

  /// No description provided for @localShellStageDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {distro}…'**
  String localShellStageDownloading(String distro);

  /// No description provided for @localShellReinstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Reinstall {name}?'**
  String localShellReinstallTitle(String name);

  /// No description provided for @localShellRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String localShellRemoveTitle(String name);

  /// No description provided for @localShellReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'{distro} is ready'**
  String localShellReadyTitle(String distro);

  /// No description provided for @localShellSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up {distro}'**
  String localShellSettingUp(String distro);

  /// No description provided for @localShellRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes this environment and everything in it. Any open {name} tabs will be closed first. Other shells are not affected.'**
  String localShellRemoveBody(String name);

  /// No description provided for @localShellReinstallBody.
  ///
  /// In en, this message translates to:
  /// **'This wipes this environment - including any packages you installed - and downloads a fresh image. Any open {name} tabs will be closed first.'**
  String localShellReinstallBody(String name);

  /// No description provided for @localShellInstallWithSize.
  ///
  /// In en, this message translates to:
  /// **'Install · {size}'**
  String localShellInstallWithSize(String size);

  /// No description provided for @localShellDownloadWithSize.
  ///
  /// In en, this message translates to:
  /// **'Download {size}'**
  String localShellDownloadWithSize(String size);

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get commonUnknown;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'SSH workspaces'**
  String get brandTagline;

  /// No description provided for @terminalFontSystemMonospace.
  ///
  /// In en, this message translates to:
  /// **'System mono'**
  String get terminalFontSystemMonospace;

  /// No description provided for @terminalFontNerdFont.
  ///
  /// In en, this message translates to:
  /// **'Nerd Font'**
  String get terminalFontNerdFont;

  /// No description provided for @terminalEnterCr.
  ///
  /// In en, this message translates to:
  /// **'Carriage return'**
  String get terminalEnterCr;

  /// No description provided for @terminalEnterLf.
  ///
  /// In en, this message translates to:
  /// **'Line feed'**
  String get terminalEnterLf;

  /// No description provided for @terminalEnterCrlf.
  ///
  /// In en, this message translates to:
  /// **'Carriage return + line feed'**
  String get terminalEnterCrlf;

  /// No description provided for @hostsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add an SSH or Mosh server and Conduit will keep its credentials in your device’s secure storage.'**
  String get hostsEmptyBody;

  /// No description provided for @hostsSortLastConnected.
  ///
  /// In en, this message translates to:
  /// **'Last connected'**
  String get hostsSortLastConnected;

  /// No description provided for @hostsSortAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get hostsSortAdded;

  /// No description provided for @hostsSortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get hostsSortManual;

  /// No description provided for @publicKeyCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Key created'**
  String get publicKeyCreatedTitle;

  /// No description provided for @publicKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get publicKeyTitle;

  /// No description provided for @authExternalBody.
  ///
  /// In en, this message translates to:
  /// **'Let the SSH server authenticate without saved credentials.'**
  String get authExternalBody;

  /// No description provided for @hardwareKeyItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Hardware key {index}'**
  String hardwareKeyItemTitle(int index);

  /// No description provided for @hostCardJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get hostCardJustNow;

  /// No description provided for @hostCardMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String hostCardMinutesAgo(int count);

  /// No description provided for @hostCardHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hostCardHoursAgo(int count);

  /// No description provided for @hostCardDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String hostCardDaysAgo(int count);

  /// No description provided for @hostCardMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String hostCardMonthsAgo(int count);

  /// No description provided for @hostFormConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'Where to reach this machine.'**
  String get hostFormConnectionHint;

  /// No description provided for @hostFormAuthenticationHint.
  ///
  /// In en, this message translates to:
  /// **'Credentials are stored in platform secure storage.'**
  String get hostFormAuthenticationHint;

  /// No description provided for @hostFormAdvancedHint.
  ///
  /// In en, this message translates to:
  /// **'Optional tagging and connection timing.'**
  String get hostFormAdvancedHint;

  /// No description provided for @sshKeyEncryptedHint.
  ///
  /// In en, this message translates to:
  /// **'This key is encrypted. Enter its passphrase below to unlock it.'**
  String get sshKeyEncryptedHint;

  /// No description provided for @addHardwareKeyNormalKey.
  ///
  /// In en, this message translates to:
  /// **'This is a normal private key. Use it with the Private key method instead.'**
  String get addHardwareKeyNormalKey;

  /// No description provided for @addHardwareKeyNotStub.
  ///
  /// In en, this message translates to:
  /// **'This is not a recognized OpenSSH security-key stub (id_ed25519_sk or id_ecdsa_sk).'**
  String get addHardwareKeyNotStub;

  /// No description provided for @addHardwareKeyDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This key is already added to this host.'**
  String get addHardwareKeyDuplicate;

  /// No description provided for @addHardwareKeyNotTextStub.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a text key stub.'**
  String get addHardwareKeyNotTextStub;

  /// No description provided for @commonFilePickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker.'**
  String get commonFilePickerFailed;

  /// No description provided for @commonFileReadFailed.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read.'**
  String get commonFileReadFailed;

  /// No description provided for @hostFormImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {name}'**
  String hostFormImported(String name);

  /// No description provided for @hostFormGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate a key.'**
  String get hostFormGenerateFailed;

  /// No description provided for @hostFormNeedHardwareKey.
  ///
  /// In en, this message translates to:
  /// **'Add at least one hardware key.'**
  String get hostFormNeedHardwareKey;

  /// No description provided for @hostFormEnterKeyPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Enter the key passphrase to unlock it.'**
  String get hostFormEnterKeyPassphrase;

  /// No description provided for @hostFormInvalidPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Use a valid PEM or OpenSSH private key.'**
  String get hostFormInvalidPrivateKey;

  /// No description provided for @hostFormStubUseHardwareKey.
  ///
  /// In en, this message translates to:
  /// **'This is a hardware-key stub. Choose Hardware key instead.'**
  String get hostFormStubUseHardwareKey;

  /// No description provided for @hostFormNotTextKey.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a text private key.'**
  String get hostFormNotTextKey;

  /// No description provided for @hostFormNotPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a recognized private key.'**
  String get hostFormNotPrivateKey;

  /// No description provided for @hostFormInvalidPort.
  ///
  /// In en, this message translates to:
  /// **'Use a port or low:high range within 1-65535.'**
  String get hostFormInvalidPort;

  /// No description provided for @sftpNoMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this folder matches “{query}”.'**
  String sftpNoMatchQuery(String query);

  /// No description provided for @sftpCopiedPath.
  ///
  /// In en, this message translates to:
  /// **'Copied path'**
  String get sftpCopiedPath;

  /// No description provided for @sftpSavedTar.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}.tar'**
  String sftpSavedTar(String name);

  /// No description provided for @sftpSavedFile.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String sftpSavedFile(String name);

  /// No description provided for @sftpUploadedFile.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {name}'**
  String sftpUploadedFile(String name);

  /// No description provided for @sftpFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'One of those files could not be read.'**
  String get sftpFileUnreadable;

  /// No description provided for @sftpUploadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Uploaded 1 file} other{Uploaded {count} files}}'**
  String sftpUploadedCount(int count);

  /// No description provided for @sftpDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {kind}?'**
  String sftpDeleteTitle(String kind);

  /// No description provided for @sftpVisibleOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{visible} of {total}'**
  String sftpVisibleOfTotal(int visible, int total);

  /// No description provided for @sftpCountsSummary.
  ///
  /// In en, this message translates to:
  /// **'{item}  ·  {folders} folders  ·  {files} files'**
  String sftpCountsSummary(String item, String folders, String files);

  /// No description provided for @sftpTransferProgress.
  ///
  /// In en, this message translates to:
  /// **'{action} {name}'**
  String sftpTransferProgress(String action, String name);

  /// No description provided for @snippetWithEnter.
  ///
  /// In en, this message translates to:
  /// **'{text} + Enter'**
  String snippetWithEnter(String text);

  /// No description provided for @localShellFullBuildOnly.
  ///
  /// In en, this message translates to:
  /// **'Full build only'**
  String get localShellFullBuildOnly;

  /// No description provided for @localShellPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get localShellPermissionNeeded;

  /// No description provided for @localShellMountHint.
  ///
  /// In en, this message translates to:
  /// **'Grant file access to mount phone storage at /mnt/android.'**
  String get localShellMountHint;

  /// No description provided for @localShellMountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone storage mounting is available in the full build.'**
  String get localShellMountUnavailable;

  /// No description provided for @localShellSetupFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong during setup.'**
  String get localShellSetupFailedBody;

  /// No description provided for @localShellErrorDownload.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get localShellErrorDownload;

  /// No description provided for @localShellErrorStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage'**
  String get localShellErrorStorage;

  /// No description provided for @localShellErrorCorrupt.
  ///
  /// In en, this message translates to:
  /// **'Download was corrupted'**
  String get localShellErrorCorrupt;

  /// No description provided for @localShellErrorUnpack.
  ///
  /// In en, this message translates to:
  /// **'Could not unpack the image'**
  String get localShellErrorUnpack;

  /// No description provided for @localShellErrorConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configuration failed'**
  String get localShellErrorConfigure;

  /// No description provided for @localShellErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get localShellErrorUnavailable;

  /// No description provided for @localShellErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Setup failed'**
  String get localShellErrorGeneric;

  /// No description provided for @localShellIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'This shell was added but its image never finished installing. Resume to pick up where it left off, or remove it.'**
  String get localShellIncompleteBody;

  /// No description provided for @localShellStatusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String localShellStatusDownloading(String percent);

  /// No description provided for @localShellStatusUnpacking.
  ///
  /// In en, this message translates to:
  /// **'Unpacking…'**
  String get localShellStatusUnpacking;

  /// No description provided for @localShellStatusConfiguring.
  ///
  /// In en, this message translates to:
  /// **'Configuring…'**
  String get localShellStatusConfiguring;

  /// No description provided for @localShellStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Setup failed - tap to retry'**
  String get localShellStatusFailed;

  /// No description provided for @localShellStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'{distro} · checking…'**
  String localShellStatusChecking(String distro);

  /// No description provided for @localShellStatusIncomplete.
  ///
  /// In en, this message translates to:
  /// **'{distro} · setup incomplete, tap to resume'**
  String localShellStatusIncomplete(String distro);

  /// No description provided for @localShellStatusReady.
  ///
  /// In en, this message translates to:
  /// **'{distro} · {size}'**
  String localShellStatusReady(String distro, String size);

  /// No description provided for @backupExportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled.'**
  String get backupExportCancelled;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported.'**
  String get backupExported;

  /// No description provided for @backupImportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled.'**
  String get backupImportCancelled;

  /// No description provided for @backupImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {hosts} machines and {keys} trusted keys.'**
  String backupImported(int hosts, int keys);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get backupPasswordMismatch;

  /// No description provided for @backupPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the backup password.'**
  String get backupPasswordRequired;

  /// No description provided for @lockAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Conduit to access saved SSH machines.'**
  String get lockAuthReason;

  /// No description provided for @lockAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get lockAuthTitle;

  /// No description provided for @lockAuthHint.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get lockAuthHint;

  /// No description provided for @appearanceSectionMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get appearanceSectionMode;

  /// No description provided for @appearanceSectionTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get appearanceSectionTerminal;

  /// No description provided for @appearanceSectionHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get appearanceSectionHome;

  /// No description provided for @appearanceSectionBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get appearanceSectionBackup;

  /// No description provided for @appearanceSectionPalette.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get appearanceSectionPalette;

  /// No description provided for @labelDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get labelDevice;

  /// No description provided for @terminalSnippetGroupGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get terminalSnippetGroupGlobal;

  /// No description provided for @securityKeyPinAttemptsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt remaining.} other{{count} attempts remaining.}}'**
  String securityKeyPinAttemptsRemaining(int count);

  /// No description provided for @localShellErrorNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'The local shell is not installed.'**
  String get localShellErrorNotInstalled;

  /// No description provided for @localShellErrorAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'The local shell is only available on Android.'**
  String get localShellErrorAndroidOnly;

  /// No description provided for @localShellErrorArm64Only.
  ///
  /// In en, this message translates to:
  /// **'The local shell requires a 64-bit ARM (arm64-v8a) device.'**
  String get localShellErrorArm64Only;

  /// No description provided for @localShellErrorChecksumFailed.
  ///
  /// In en, this message translates to:
  /// **'Downloaded archive failed checksum verification.'**
  String get localShellErrorChecksumFailed;

  /// No description provided for @localShellErrorHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'Unexpected HTTP status {status}'**
  String localShellErrorHttpStatus(String status);

  /// No description provided for @localShellErrorLowDisk.
  ///
  /// In en, this message translates to:
  /// **'No space left on device.'**
  String get localShellErrorLowDisk;

  /// No description provided for @localShellErrorProotLaunch.
  ///
  /// In en, this message translates to:
  /// **'Could not launch proot/tar: {error}'**
  String localShellErrorProotLaunch(String error);

  /// No description provided for @localShellErrorTarExit.
  ///
  /// In en, this message translates to:
  /// **'tar exited with {code}: {stderr}'**
  String localShellErrorTarExit(String code, String stderr);

  /// No description provided for @localShellErrorFirstBootLaunch.
  ///
  /// In en, this message translates to:
  /// **'Could not launch first-boot shell: {error}'**
  String localShellErrorFirstBootLaunch(String error);

  /// No description provided for @localShellErrorFirstBootExit.
  ///
  /// In en, this message translates to:
  /// **'First-boot configuration exited with {code}: {stderr}'**
  String localShellErrorFirstBootExit(String code, String stderr);

  /// No description provided for @localShellErrorStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the local shell.'**
  String get localShellErrorStartFailed;

  /// No description provided for @localShellErrorSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'The local shell session is closed.'**
  String get localShellErrorSessionClosed;

  /// No description provided for @hostsErrorNotAList.
  ///
  /// In en, this message translates to:
  /// **'Expected a list of hosts.'**
  String get hostsErrorNotAList;

  /// No description provided for @hostsErrorUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Saved hosts could not be read.'**
  String get hostsErrorUnreadable;

  /// No description provided for @sftpErrorNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected.'**
  String get sftpErrorNotConnected;

  /// No description provided for @sftpErrorTransferInProgress.
  ///
  /// In en, this message translates to:
  /// **'A transfer is already in progress.'**
  String get sftpErrorTransferInProgress;

  /// No description provided for @sftpErrorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload {name}.'**
  String sftpErrorUploadFailed(String name);

  /// No description provided for @sftpErrorOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open files on {endpoint}.'**
  String sftpErrorOpenFailed(String endpoint);

  /// No description provided for @sftpErrorPathTooLong.
  ///
  /// In en, this message translates to:
  /// **'Path is too long to archive: {path}'**
  String sftpErrorPathTooLong(String path);

  /// No description provided for @terminalErrorConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to {endpoint}.'**
  String terminalErrorConnectFailed(String endpoint);

  /// No description provided for @terminalErrorSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'The SSH session is closed.'**
  String get terminalErrorSessionClosed;

  /// No description provided for @terminalErrorMoshStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start a Mosh session on {endpoint}.'**
  String terminalErrorMoshStartFailed(String endpoint);

  /// No description provided for @terminalErrorMoshStartupTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out waiting for mosh-server startup.'**
  String get terminalErrorMoshStartupTimeout;

  /// No description provided for @terminalErrorMoshSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'The Mosh session is closed.'**
  String get terminalErrorMoshSessionClosed;

  /// No description provided for @terminalStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting {name}...'**
  String terminalStarting(String name);

  /// No description provided for @terminalConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {endpoint}...'**
  String terminalConnecting(String endpoint);

  /// No description provided for @terminalShellExited.
  ///
  /// In en, this message translates to:
  /// **'Shell exited.'**
  String get terminalShellExited;

  /// No description provided for @terminalConnectionClosed.
  ///
  /// In en, this message translates to:
  /// **'Connection closed.'**
  String get terminalConnectionClosed;

  /// No description provided for @terminalConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String terminalConnectionFailed(String error);

  /// No description provided for @sshErrorKeyNotUsable.
  ///
  /// In en, this message translates to:
  /// **'The presented security key does not hold any usable key for this host.'**
  String get sshErrorKeyNotUsable;

  /// No description provided for @sshErrorAuthRejected.
  ///
  /// In en, this message translates to:
  /// **'SSH server rejected the configured credentials.'**
  String get sshErrorAuthRejected;

  /// No description provided for @sshErrorAuthAborted.
  ///
  /// In en, this message translates to:
  /// **'SSH authentication stopped before it completed.'**
  String get sshErrorAuthAborted;

  /// No description provided for @sshErrorHandshakeFailed.
  ///
  /// In en, this message translates to:
  /// **'SSH handshake failed: {message}'**
  String sshErrorHandshakeFailed(String message);

  /// No description provided for @ctapErrorPinInvalid.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN was incorrect.'**
  String get ctapErrorPinInvalid;

  /// No description provided for @ctapErrorPinBlocked.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN is blocked. Reset the key FIDO app to use it again.'**
  String get ctapErrorPinBlocked;

  /// No description provided for @ctapErrorPinAuthBlocked.
  ///
  /// In en, this message translates to:
  /// **'The security key temporarily locked itself. Move it away from the phone (or unplug it) for a few seconds, then present it again.'**
  String get ctapErrorPinAuthBlocked;

  /// No description provided for @ctapErrorPinNotSet.
  ///
  /// In en, this message translates to:
  /// **'This security key needs a FIDO2 PIN before it can be used.'**
  String get ctapErrorPinNotSet;

  /// No description provided for @ctapErrorPuatRequired.
  ///
  /// In en, this message translates to:
  /// **'This security key requires PIN or user verification.'**
  String get ctapErrorPuatRequired;

  /// No description provided for @ctapErrorTouchTimeout.
  ///
  /// In en, this message translates to:
  /// **'Security key touch timed out.'**
  String get ctapErrorTouchTimeout;

  /// No description provided for @ctapErrorUpRequired.
  ///
  /// In en, this message translates to:
  /// **'Touch is required on the security key.'**
  String get ctapErrorUpRequired;

  /// No description provided for @ctapErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Security key authentication was cancelled.'**
  String get ctapErrorCancelled;

  /// No description provided for @ctapErrorNoCredentials.
  ///
  /// In en, this message translates to:
  /// **'This security key does not have the credential for this SSH key stub.'**
  String get ctapErrorNoCredentials;

  /// No description provided for @ctapErrorPinAuthInvalid.
  ///
  /// In en, this message translates to:
  /// **'Security key rejected the PIN authentication data.'**
  String get ctapErrorPinAuthInvalid;

  /// No description provided for @ctapErrorInvalidOption.
  ///
  /// In en, this message translates to:
  /// **'Security key rejected the requested verification option.'**
  String get ctapErrorInvalidOption;

  /// No description provided for @ctapErrorUnauthorizedPermission.
  ///
  /// In en, this message translates to:
  /// **'Security key rejected the requested authentication permission.'**
  String get ctapErrorUnauthorizedPermission;

  /// No description provided for @ctapErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Security key failed with CTAP status {status}.'**
  String ctapErrorGeneric(String status);

  /// No description provided for @securityKeyPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'USB security key permission was denied.'**
  String get securityKeyPermissionDenied;

  /// No description provided for @securityKeyNfcTimeout.
  ///
  /// In en, this message translates to:
  /// **'The NFC prompt timed out before a security key was read.'**
  String get securityKeyNfcTimeout;

  /// No description provided for @securityKeyNfcInterrupted.
  ///
  /// In en, this message translates to:
  /// **'NFC security key read was interrupted. Hold the key still and try again.'**
  String get securityKeyNfcInterrupted;

  /// No description provided for @securityKeyOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Security key operation failed: {code}.'**
  String securityKeyOperationFailed(String code);

  /// No description provided for @sshErrorPrivateKeyUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Private key could not be loaded.'**
  String get sshErrorPrivateKeyUnreadable;

  /// No description provided for @sshErrorNoHardwareKeys.
  ///
  /// In en, this message translates to:
  /// **'Add at least one hardware key to this host.'**
  String get sshErrorNoHardwareKeys;

  /// No description provided for @hardwareKeyFallbackName.
  ///
  /// In en, this message translates to:
  /// **'hardware key {index}'**
  String hardwareKeyFallbackName(String index);

  /// No description provided for @sshErrorHardwareKeyUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Hardware key \"{label}\" could not be loaded.'**
  String sshErrorHardwareKeyUnreadable(String label);

  /// No description provided for @sshErrorHardwareKeyNeedsStub.
  ///
  /// In en, this message translates to:
  /// **'Hardware key \"{label}\" requires an OpenSSH security-key stub (id_ed25519_sk or id_ecdsa_sk), not a normal private key.'**
  String sshErrorHardwareKeyNeedsStub(String label);

  /// No description provided for @backupErrorRootNotObject.
  ///
  /// In en, this message translates to:
  /// **'Backup root is not an object.'**
  String get backupErrorRootNotObject;

  /// No description provided for @backupErrorNotConduit.
  ///
  /// In en, this message translates to:
  /// **'This does not look like a Conduit backup.'**
  String get backupErrorNotConduit;

  /// No description provided for @backupErrorFormatUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This backup format is not supported.'**
  String get backupErrorFormatUnsupported;

  /// No description provided for @backupErrorPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'The password is wrong or the backup changed.'**
  String get backupErrorPasswordWrong;

  /// No description provided for @backupErrorPayloadInvalid.
  ///
  /// In en, this message translates to:
  /// **'The encrypted backup payload is invalid.'**
  String get backupErrorPayloadInvalid;

  /// No description provided for @backupErrorPayloadMissing.
  ///
  /// In en, this message translates to:
  /// **'The backup payload is missing.'**
  String get backupErrorPayloadMissing;

  /// No description provided for @backupErrorEncryptedUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This encrypted backup is not supported.'**
  String get backupErrorEncryptedUnsupported;

  /// No description provided for @backupErrorEncryptedInvalid.
  ///
  /// In en, this message translates to:
  /// **'This encrypted backup is invalid.'**
  String get backupErrorEncryptedInvalid;

  /// No description provided for @backupPasswordRuleLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters.'**
  String get backupPasswordRuleLength;

  /// No description provided for @backupPasswordRuleSpaces.
  ///
  /// In en, this message translates to:
  /// **'Remove spaces from the start or end.'**
  String get backupPasswordRuleSpaces;

  /// No description provided for @backupPasswordRuleClasses.
  ///
  /// In en, this message translates to:
  /// **'Use at least three of lowercase, uppercase, numbers, and symbols.'**
  String get backupPasswordRuleClasses;

  /// No description provided for @securityKeyNotSelectedKey.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" was not the selected security key.'**
  String securityKeyNotSelectedKey(String label);

  /// No description provided for @securityKeyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Hardware key accepted.'**
  String get securityKeyAccepted;

  /// No description provided for @securityKeyEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN for this security key.'**
  String get securityKeyEnterPin;

  /// No description provided for @securityKeyPinIncorrectRetry.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN was incorrect. Try again.'**
  String get securityKeyPinIncorrectRetry;

  /// No description provided for @securityKeyNotOnPresented.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" is not on the presented security key.'**
  String securityKeyNotOnPresented(String label);

  /// No description provided for @securityKeySelectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Security key selection was cancelled.'**
  String get securityKeySelectionCancelled;

  /// No description provided for @securityKeyUsing.
  ///
  /// In en, this message translates to:
  /// **'Using security key \"{label}\".'**
  String securityKeyUsing(String label);

  /// No description provided for @securityKeyWaitingForAny.
  ///
  /// In en, this message translates to:
  /// **'Waiting for hardware key over USB or NFC. Any of your {count} enrolled keys will work...'**
  String securityKeyWaitingForAny(String count);

  /// No description provided for @securityKeyWaitingForKey.
  ///
  /// In en, this message translates to:
  /// **'Waiting for hardware key over USB or NFC...'**
  String get securityKeyWaitingForKey;

  /// No description provided for @securityKeySwitchingTo.
  ///
  /// In en, this message translates to:
  /// **'This security key holds \"{label}\". Switching to it...'**
  String securityKeySwitchingTo(String label);

  /// No description provided for @securityKeyHoldsNoSaved.
  ///
  /// In en, this message translates to:
  /// **'This security key does not hold any of the keys saved for this host.'**
  String get securityKeyHoldsNoSaved;

  /// No description provided for @securityKeyNotOnThisKey.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" is not on this security key.'**
  String securityKeyNotOnThisKey(String label);

  /// No description provided for @securityKeyHoldsKeyPresentInstead.
  ///
  /// In en, this message translates to:
  /// **'That security key does not hold \"{label}\". Present \"{label}\" instead.'**
  String securityKeyHoldsKeyPresentInstead(String label);

  /// No description provided for @securityKeyPinRequired.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN is required.'**
  String get securityKeyPinRequired;

  /// No description provided for @securityKeyPinRequiredShort.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN required.'**
  String get securityKeyPinRequiredShort;

  /// No description provided for @securityKeyPinEntryCancelled.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN entry was cancelled.'**
  String get securityKeyPinEntryCancelled;

  /// No description provided for @securityKeyPinAccepted.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN accepted.'**
  String get securityKeyPinAccepted;

  /// No description provided for @securityKeyPinUnverified.
  ///
  /// In en, this message translates to:
  /// **'Security key PIN could not be verified.'**
  String get securityKeyPinUnverified;

  /// No description provided for @securityKeyPinProtocolUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported security key PIN protocol.'**
  String get securityKeyPinProtocolUnsupported;

  /// No description provided for @securityKeyTouchUsb.
  ///
  /// In en, this message translates to:
  /// **'Touch your USB security key.'**
  String get securityKeyTouchUsb;

  /// No description provided for @securityKeyHoldNfc.
  ///
  /// In en, this message translates to:
  /// **'Keep your NFC security key held against the phone.'**
  String get securityKeyHoldNfc;

  /// No description provided for @securityKeyTouchOrHold.
  ///
  /// In en, this message translates to:
  /// **'Touch your USB key, or hold your NFC key near the phone.'**
  String get securityKeyTouchOrHold;

  /// No description provided for @securityKeyHoldNearPhone.
  ///
  /// In en, this message translates to:
  /// **'Hold your security key near the phone.'**
  String get securityKeyHoldNearPhone;

  /// No description provided for @securityKeySigningFailed.
  ///
  /// In en, this message translates to:
  /// **'Security key signing failed.'**
  String get securityKeySigningFailed;

  /// No description provided for @securityKeyAppletSelectFailed.
  ///
  /// In en, this message translates to:
  /// **'FIDO applet selection failed.'**
  String get securityKeyAppletSelectFailed;

  /// No description provided for @securityKeyCommandFailed.
  ///
  /// In en, this message translates to:
  /// **'FIDO command failed.'**
  String get securityKeyCommandFailed;

  /// No description provided for @securityKeyResponseTooShort.
  ///
  /// In en, this message translates to:
  /// **'FIDO response was too short.'**
  String get securityKeyResponseTooShort;

  /// No description provided for @securityKeyEmptyApdu.
  ///
  /// In en, this message translates to:
  /// **'{message} Empty APDU response.'**
  String securityKeyEmptyApdu(String message);

  /// No description provided for @securityKeyApduStatus.
  ///
  /// In en, this message translates to:
  /// **'{message} APDU status {sw}.'**
  String securityKeyApduStatus(String message, String sw);

  /// No description provided for @securityKeyUsbAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'USB security keys are only supported on Android.'**
  String get securityKeyUsbAndroidOnly;

  /// No description provided for @securityKeyUsbEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'USB security key returned an empty response.'**
  String get securityKeyUsbEmptyResponse;

  /// No description provided for @securityKeyAuthenticatorDataShort.
  ///
  /// In en, this message translates to:
  /// **'Authenticator data was too short.'**
  String get securityKeyAuthenticatorDataShort;

  /// No description provided for @securityKeyMalformedSignature.
  ///
  /// In en, this message translates to:
  /// **'Malformed DER ECDSA signature.'**
  String get securityKeyMalformedSignature;

  /// No description provided for @securityKeyNotHoldLabel.
  ///
  /// In en, this message translates to:
  /// **'The presented security key does not hold \"{label}\".'**
  String securityKeyNotHoldLabel(String label);

  /// No description provided for @securityKeyNfcRetrying.
  ///
  /// In en, this message translates to:
  /// **'NFC read was interrupted. Keep the key still near the phone; retrying...'**
  String get securityKeyNfcRetrying;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
