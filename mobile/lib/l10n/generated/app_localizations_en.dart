// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get pairPc => 'Pair a PC';

  @override
  String get pairScanHint => 'Scan the code shown in WinRelay on your PC.';

  @override
  String get pairOrPaste => 'Or paste the link';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => 'Paste';

  @override
  String get connect => 'Connect';

  @override
  String get pairFooter =>
      'After connecting, click Approve on the PC. Each link works once.';

  @override
  String get pairBadLink =>
      'That isn\'t a WinRelay link. Copy it again from WinRelay on the PC.';

  @override
  String get pcsTitle => 'Your PCs';

  @override
  String get pcsEmpty => 'Pair a PC to get started.';

  @override
  String get settings => 'Settings';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · port $port';
  }

  @override
  String get waitingApprovalSub => 'Waiting for approval on the PC';

  @override
  String get renamePc => 'Rename PC';

  @override
  String get rename => 'Rename';

  @override
  String get remove => 'Remove';

  @override
  String get refresh => 'Refresh';

  @override
  String connectingTo(String name) {
    return 'Connecting to $name…';
  }

  @override
  String get approveTitle => 'Approve this phone on your PC';

  @override
  String approveBody(String name) {
    return 'Open WinRelay on the PC and click Approve next to \"$name\".';
  }

  @override
  String get cantConnect => 'Can\'t connect';

  @override
  String errUnreachable(String name) {
    return 'Couldn\'t reach $name. Check that the PC is on, WinRelay is running, and you\'re on a network that can reach it.';
  }

  @override
  String errDropped(String name) {
    return 'The connection to $name dropped.';
  }

  @override
  String get searchWindows => 'Search windows';

  @override
  String get hideOnPc => 'Hide the window on the PC';

  @override
  String get hideOnPcSub =>
      'Stealth: the PC\'s screen won\'t show it while you control it';

  @override
  String get noMatch => 'No windows match. Pull down to refresh.';

  @override
  String get viewMode => 'View';

  @override
  String get tapMode => 'Tap';

  @override
  String get viewTip => 'Look only: taps do nothing on the PC';

  @override
  String get tapTip => 'Taps click on the PC';

  @override
  String get stealthTip => 'Stealth: hidden on the PC';

  @override
  String get reconnecting => 'Reconnecting to the PC…';

  @override
  String get pcLocked =>
      'The PC is locked. Unlock it to keep controlling this window.';

  @override
  String get composeHint => 'Write a message for this window';

  @override
  String get sendWithEnter => 'Send with Enter';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get secThisPhone => 'This phone';

  @override
  String get phoneName => 'Phone name';

  @override
  String get phoneNameSub => 'Shown on the PC when you pair';

  @override
  String get secAppearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get secTouch => 'Touch and typing';

  @override
  String get defaultTouch => 'Default touch mode';

  @override
  String get defaultTouchSub =>
      'View never clicks on the PC; Tap turns taps into clicks';

  @override
  String get composeMode => 'Compose mode';

  @override
  String get composeModeSub =>
      'Write a whole message first, with autocorrect, then send it. Off: every key goes to the PC as you type.';

  @override
  String get returnSends => 'Return key sends';

  @override
  String get enterKeyEnter => 'Enter';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Enter';

  @override
  String get vibrate => 'Vibrate on quick keys';

  @override
  String get secQuickKeys => 'Quick keys';

  @override
  String get secPicture => 'Picture';

  @override
  String get textSize => 'Text size';

  @override
  String get stealthDefault => 'Hide windows on the PC by default';

  @override
  String get stealthDefaultSub =>
      'Stealth. You can still switch it per window.';

  @override
  String get keepScreenOn => 'Keep this screen on while controlling';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get hideKeyboard => 'Hide keyboard';

  @override
  String get showKeyboard => 'Show keyboard';

  @override
  String get qkNewLine => 'New line';

  @override
  String get qkPaste => 'Paste';

  @override
  String get qkPageUp => 'Page up';

  @override
  String get qkPageDown => 'Page down';

  @override
  String get qkDelete => 'Delete';

  @override
  String get secStream => 'Stream';

  @override
  String get rxFps => 'Frame rate';

  @override
  String get rxFpsSub => 'Lower = smoother network, choppier picture';

  @override
  String get rxScale => 'Picture size';

  @override
  String get rxScaleSub => 'Smaller picture = much less data';

  @override
  String get rxGray => 'Grayscale mode';

  @override
  String get rxGraySub => 'Black-and-white picture; cuts data use sharply';

  @override
  String get switchIme => 'Switch keyboard';

  @override
  String get webMode => 'Web';

  @override
  String get webModeTip =>
      'Browse like on a phone; the PC follows your navigation';

  @override
  String get loadFromPc => 'Load the page the PC is showing';

  @override
  String get filesTitle => 'Files';

  @override
  String get thisPc => 'This PC';

  @override
  String get upload => 'Upload';

  @override
  String get download => 'Download';

  @override
  String get newFolder => 'New folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get deleteItem => 'Delete';

  @override
  String get deleteConfirmTitle => 'Delete?';

  @override
  String deleteConfirmBody(Object name) {
    return '\"$name\" will be moved to the Recycle Bin.';
  }

  @override
  String get downloadDone => 'Downloaded. Choose where to keep it.';

  @override
  String get transferDone => 'Transfer complete';

  @override
  String get transferFailed => 'Transfer failed';

  @override
  String get emptyDir => 'Empty folder';

  @override
  String get grantStorage =>
      'Allow all-files access in the next screen, then try again.';

  @override
  String get uploadFromPhone => 'Send a file from this phone';

  @override
  String get goBack => 'Back';

  @override
  String get goForward => 'Forward';

  @override
  String get addressBarHint => 'Search or type a URL';

  @override
  String get followPc => 'Follow the PC';

  @override
  String get pcScreen => 'PC screen';

  @override
  String get clipCopyFromPc => 'Copy this PC\'s clipboard';

  @override
  String get clipPasteToPc => 'Paste relayed text into this PC';

  @override
  String get clipEmpty => 'Clipboard relay is empty — copy something first.';

  @override
  String clipCopied(Object n) {
    return 'Copied ($n chars). Control the other PC and press paste.';
  }

  @override
  String get clipPasted => 'Pasted into the PC.';

  @override
  String get colorColor => 'Colour';

  @override
  String get colorGray => 'Grayscale';

  @override
  String get colorBw => 'Pure black-white';

  @override
  String get jumpPath => 'Jump to path';

  @override
  String get pathHint => 'PC path, e.g. C:\\Users\\me\\Desktop';

  @override
  String get invalidPath => 'Can\'t open that path.';

  @override
  String savedTo(Object name) {
    return 'Saved to phone Download as $name';
  }

  @override
  String get share => 'Share';
}
