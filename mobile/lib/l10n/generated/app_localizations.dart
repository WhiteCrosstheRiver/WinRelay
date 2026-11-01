import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @pairPc.
  ///
  /// In en, this message translates to:
  /// **'Pair a PC'**
  String get pairPc;

  /// No description provided for @pairScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the code shown in WinRelay on your PC.'**
  String get pairScanHint;

  /// No description provided for @pairOrPaste.
  ///
  /// In en, this message translates to:
  /// **'Or paste the link'**
  String get pairOrPaste;

  /// No description provided for @pairLinkHint.
  ///
  /// In en, this message translates to:
  /// **'winrelay://pair?…'**
  String get pairLinkHint;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @pairFooter.
  ///
  /// In en, this message translates to:
  /// **'After connecting, click Approve on the PC. Each link works once.'**
  String get pairFooter;

  /// No description provided for @pairBadLink.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a WinRelay link. Copy it again from WinRelay on the PC.'**
  String get pairBadLink;

  /// No description provided for @pcsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your PCs'**
  String get pcsTitle;

  /// No description provided for @pcsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pair a PC to get started.'**
  String get pcsEmpty;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @pairedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{host} · port {port}'**
  String pairedSubtitle(String host, String port);

  /// No description provided for @waitingApprovalSub.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval on the PC'**
  String get waitingApprovalSub;

  /// No description provided for @renamePc.
  ///
  /// In en, this message translates to:
  /// **'Rename PC'**
  String get renamePc;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @connectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}…'**
  String connectingTo(String name);

  /// No description provided for @approveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this phone on your PC'**
  String get approveTitle;

  /// No description provided for @approveBody.
  ///
  /// In en, this message translates to:
  /// **'Open WinRelay on the PC and click Approve next to \"{name}\".'**
  String approveBody(String name);

  /// No description provided for @cantConnect.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect'**
  String get cantConnect;

  /// No description provided for @errUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach {name}. Check that the PC is on, WinRelay is running, and you\'re on a network that can reach it.'**
  String errUnreachable(String name);

  /// No description provided for @errDropped.
  ///
  /// In en, this message translates to:
  /// **'The connection to {name} dropped.'**
  String errDropped(String name);

  /// No description provided for @searchWindows.
  ///
  /// In en, this message translates to:
  /// **'Search windows'**
  String get searchWindows;

  /// No description provided for @hideOnPc.
  ///
  /// In en, this message translates to:
  /// **'Hide the window on the PC'**
  String get hideOnPc;

  /// No description provided for @hideOnPcSub.
  ///
  /// In en, this message translates to:
  /// **'Stealth: the PC\'s screen won\'t show it while you control it'**
  String get hideOnPcSub;

  /// No description provided for @noMatch.
  ///
  /// In en, this message translates to:
  /// **'No windows match. Pull down to refresh.'**
  String get noMatch;

  /// No description provided for @viewMode.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewMode;

  /// No description provided for @tapMode.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get tapMode;

  /// No description provided for @viewTip.
  ///
  /// In en, this message translates to:
  /// **'Look only: taps do nothing on the PC'**
  String get viewTip;

  /// No description provided for @tapTip.
  ///
  /// In en, this message translates to:
  /// **'Taps click on the PC'**
  String get tapTip;

  /// No description provided for @stealthTip.
  ///
  /// In en, this message translates to:
  /// **'Stealth: hidden on the PC'**
  String get stealthTip;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to the PC…'**
  String get reconnecting;

  /// No description provided for @pcLocked.
  ///
  /// In en, this message translates to:
  /// **'The PC is locked. Unlock it to keep controlling this window.'**
  String get pcLocked;

  /// No description provided for @composeHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message for this window'**
  String get composeHint;

  /// No description provided for @sendWithEnter.
  ///
  /// In en, this message translates to:
  /// **'Send with Enter'**
  String get sendWithEnter;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @secThisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get secThisPhone;

  /// No description provided for @phoneName.
  ///
  /// In en, this message translates to:
  /// **'Phone name'**
  String get phoneName;

  /// No description provided for @phoneNameSub.
  ///
  /// In en, this message translates to:
  /// **'Shown on the PC when you pair'**
  String get phoneNameSub;

  /// No description provided for @secAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get secAppearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @secTouch.
  ///
  /// In en, this message translates to:
  /// **'Touch and typing'**
  String get secTouch;

  /// No description provided for @defaultTouch.
  ///
  /// In en, this message translates to:
  /// **'Default touch mode'**
  String get defaultTouch;

  /// No description provided for @defaultTouchSub.
  ///
  /// In en, this message translates to:
  /// **'View never clicks on the PC; Tap turns taps into clicks'**
  String get defaultTouchSub;

  /// No description provided for @composeMode.
  ///
  /// In en, this message translates to:
  /// **'Compose mode'**
  String get composeMode;

  /// No description provided for @composeModeSub.
  ///
  /// In en, this message translates to:
  /// **'Write a whole message first, with autocorrect, then send it. Off: every key goes to the PC as you type.'**
  String get composeModeSub;

  /// No description provided for @returnSends.
  ///
  /// In en, this message translates to:
  /// **'Return key sends'**
  String get returnSends;

  /// No description provided for @enterKeyEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enterKeyEnter;

  /// No description provided for @enterKeyCtrlEnter.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Enter'**
  String get enterKeyCtrlEnter;

  /// No description provided for @vibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on quick keys'**
  String get vibrate;

  /// No description provided for @secQuickKeys.
  ///
  /// In en, this message translates to:
  /// **'Quick keys'**
  String get secQuickKeys;

  /// No description provided for @secPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get secPicture;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @stealthDefault.
  ///
  /// In en, this message translates to:
  /// **'Hide windows on the PC by default'**
  String get stealthDefault;

  /// No description provided for @stealthDefaultSub.
  ///
  /// In en, this message translates to:
  /// **'Stealth. You can still switch it per window.'**
  String get stealthDefaultSub;

  /// No description provided for @keepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep this screen on while controlling'**
  String get keepScreenOn;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @hideKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get hideKeyboard;

  /// No description provided for @showKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Show keyboard'**
  String get showKeyboard;

  /// No description provided for @qkNewLine.
  ///
  /// In en, this message translates to:
  /// **'New line'**
  String get qkNewLine;

  /// No description provided for @qkPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get qkPaste;

  /// No description provided for @qkPageUp.
  ///
  /// In en, this message translates to:
  /// **'Page up'**
  String get qkPageUp;

  /// No description provided for @qkPageDown.
  ///
  /// In en, this message translates to:
  /// **'Page down'**
  String get qkPageDown;

  /// No description provided for @qkDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get qkDelete;

  /// No description provided for @secStream.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get secStream;

  /// No description provided for @rxFps.
  ///
  /// In en, this message translates to:
  /// **'Frame rate'**
  String get rxFps;

  /// No description provided for @rxFpsSub.
  ///
  /// In en, this message translates to:
  /// **'Lower = smoother network, choppier picture'**
  String get rxFpsSub;

  /// No description provided for @rxScale.
  ///
  /// In en, this message translates to:
  /// **'Picture size'**
  String get rxScale;

  /// No description provided for @rxScaleSub.
  ///
  /// In en, this message translates to:
  /// **'Smaller picture = much less data'**
  String get rxScaleSub;

  /// No description provided for @rxGray.
  ///
  /// In en, this message translates to:
  /// **'Grayscale mode'**
  String get rxGray;

  /// No description provided for @rxGraySub.
  ///
  /// In en, this message translates to:
  /// **'Black-and-white picture; cuts data use sharply'**
  String get rxGraySub;

  /// No description provided for @switchIme.
  ///
  /// In en, this message translates to:
  /// **'Switch keyboard'**
  String get switchIme;

  /// No description provided for @webMode.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get webMode;

  /// No description provided for @webModeTip.
  ///
  /// In en, this message translates to:
  /// **'Browse like on a phone; the PC follows your navigation'**
  String get webModeTip;

  /// No description provided for @loadFromPc.
  ///
  /// In en, this message translates to:
  /// **'Load the page the PC is showing'**
  String get loadFromPc;

  /// No description provided for @filesTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTitle;

  /// No description provided for @thisPc.
  ///
  /// In en, this message translates to:
  /// **'This PC'**
  String get thisPc;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItem;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be moved to the Recycle Bin.'**
  String deleteConfirmBody(Object name);

  /// No description provided for @downloadDone.
  ///
  /// In en, this message translates to:
  /// **'Downloaded. Choose where to keep it.'**
  String get downloadDone;

  /// No description provided for @transferDone.
  ///
  /// In en, this message translates to:
  /// **'Transfer complete'**
  String get transferDone;

  /// No description provided for @transferFailed.
  ///
  /// In en, this message translates to:
  /// **'Transfer failed'**
  String get transferFailed;

  /// No description provided for @emptyDir.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get emptyDir;

  /// No description provided for @grantStorage.
  ///
  /// In en, this message translates to:
  /// **'Allow all-files access in the next screen, then try again.'**
  String get grantStorage;

  /// No description provided for @uploadFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Send a file from this phone'**
  String get uploadFromPhone;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get goBack;

  /// No description provided for @goForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get goForward;

  /// No description provided for @addressBarHint.
  ///
  /// In en, this message translates to:
  /// **'Search or type a URL'**
  String get addressBarHint;

  /// No description provided for @followPc.
  ///
  /// In en, this message translates to:
  /// **'Follow the PC'**
  String get followPc;

  /// No description provided for @pcScreen.
  ///
  /// In en, this message translates to:
  /// **'PC screen'**
  String get pcScreen;

  /// No description provided for @clipCopyFromPc.
  ///
  /// In en, this message translates to:
  /// **'Copy this PC\'s clipboard'**
  String get clipCopyFromPc;

  /// No description provided for @clipPasteToPc.
  ///
  /// In en, this message translates to:
  /// **'Paste relayed text into this PC'**
  String get clipPasteToPc;

  /// No description provided for @clipEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard relay is empty — copy something first.'**
  String get clipEmpty;

  /// No description provided for @clipCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied ({n} chars). Control the other PC and press paste.'**
  String clipCopied(Object n);

  /// No description provided for @clipPasted.
  ///
  /// In en, this message translates to:
  /// **'Pasted into the PC.'**
  String get clipPasted;

  /// No description provided for @colorColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colorColor;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get colorGray;

  /// No description provided for @colorBw.
  ///
  /// In en, this message translates to:
  /// **'Pure black-white'**
  String get colorBw;

  /// No description provided for @jumpPath.
  ///
  /// In en, this message translates to:
  /// **'Jump to path'**
  String get jumpPath;

  /// No description provided for @pathHint.
  ///
  /// In en, this message translates to:
  /// **'PC path, e.g. C:\\Users\\me\\Desktop'**
  String get pathHint;

  /// No description provided for @invalidPath.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open that path.'**
  String get invalidPath;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to phone Download as {name}'**
  String savedTo(Object name);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get appsTitle;

  /// No description provided for @searchApps.
  ///
  /// In en, this message translates to:
  /// **'Search apps…'**
  String get searchApps;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @appOpen.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get appOpen;

  /// No description provided for @appClose.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get appClose;

  /// No description provided for @closeAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Close app?'**
  String get closeAppTitle;

  /// No description provided for @closeAppBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be closed on the PC (apps may prompt about unsaved work).'**
  String closeAppBody(Object name);

  /// No description provided for @appDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get appDone;

  /// No description provided for @appsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No apps match.'**
  String get appsEmpty;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openFile;

  /// No description provided for @cameraPermNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan the pairing code.'**
  String get cameraPermNeeded;

  /// No description provided for @cameraPermOff.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is off. Enable it in Settings to scan.'**
  String get cameraPermOff;

  /// No description provided for @cameraAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get cameraAllow;

  /// No description provided for @cameraOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get cameraOpenSettings;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera failed to start. Try again.'**
  String get cameraError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'ko',
        'pt',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
