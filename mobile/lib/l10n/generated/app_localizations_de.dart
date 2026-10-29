// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get pairPc => 'PC koppeln';

  @override
  String get pairScanHint =>
      'Scanne den Code, den WinRelay auf dem PC anzeigt.';

  @override
  String get pairOrPaste => 'Oder Link einfügen';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => 'Einfügen';

  @override
  String get connect => 'Verbinden';

  @override
  String get pairFooter =>
      'Tippe nach dem Verbinden auf dem PC auf „Zulassen“. Jeder Link funktioniert nur einmal.';

  @override
  String get pairBadLink =>
      'Das ist kein WinRelay-Link. Kopiere ihn erneut aus WinRelay auf dem PC.';

  @override
  String get pcsTitle => 'Deine PCs';

  @override
  String get pcsEmpty => 'Koppel zuerst einen PC.';

  @override
  String get settings => 'Einstellungen';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · Port $port';
  }

  @override
  String get waitingApprovalSub => 'Wartet auf Freigabe am PC';

  @override
  String get renamePc => 'PC umbenennen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get remove => 'Entfernen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String connectingTo(String name) {
    return 'Verbinde mit $name…';
  }

  @override
  String get approveTitle => 'Dieses Telefon am PC freigeben';

  @override
  String approveBody(String name) {
    return 'Öffne WinRelay auf dem PC und klicke neben „$name“ auf Zulassen.';
  }

  @override
  String get cantConnect => 'Keine Verbindung möglich';

  @override
  String errUnreachable(String name) {
    return '$name nicht erreichbar. Prüfe, ob der PC an ist, WinRelay läuft und dein Netzwerk ihn erreicht.';
  }

  @override
  String errDropped(String name) {
    return 'Die Verbindung zu $name wurde getrennt.';
  }

  @override
  String get searchWindows => 'Fenster suchen';

  @override
  String get hideOnPc => 'Fenster auf dem PC verbergen';

  @override
  String get hideOnPcSub =>
      'Tarnung: Der PC-Bildschirm zeigt das Fenster während der Steuerung nicht';

  @override
  String get noMatch =>
      'Keine Fenster gefunden. Zum Aktualisieren nach unten ziehen.';

  @override
  String get viewMode => 'Ansehen';

  @override
  String get tapMode => 'Tippen';

  @override
  String get viewTip => 'Nur zuschauen: Tippen klickt nicht auf dem PC';

  @override
  String get tapTip => 'Tippen klickt auf dem PC';

  @override
  String get stealthTip => 'Tarnung: auf dem PC verborgen';

  @override
  String get reconnecting => 'Neu verbinden…';

  @override
  String get pcLocked =>
      'Der PC ist gesperrt. Entsperre ihn, um dieses Fenster weiter zu steuern.';

  @override
  String get composeHint => 'Nachricht für dieses Fenster schreiben';

  @override
  String get sendWithEnter => 'Mit Enter senden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get secThisPhone => 'Dieses Telefon';

  @override
  String get phoneName => 'Telefonname';

  @override
  String get phoneNameSub => 'Wird beim Koppeln auf dem PC angezeigt';

  @override
  String get secAppearance => 'Darstellung';

  @override
  String get theme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemeinstellung';

  @override
  String get secTouch => 'Touch und Eingabe';

  @override
  String get defaultTouch => 'Standard-Touchmodus';

  @override
  String get defaultTouchSub =>
      '„Ansehen“ klickt nie auf dem PC; „Tippen“ macht aus Tippen Klicks';

  @override
  String get composeMode => 'Verfassenmodus';

  @override
  String get composeModeSub =>
      'Erst die ganze Nachricht schreiben (mit Autokorrektur), dann senden. Aus: jede Taste geht live an den PC.';

  @override
  String get returnSends => 'Enter-Taste sendet';

  @override
  String get enterKeyEnter => 'Enter';

  @override
  String get enterKeyCtrlEnter => 'Strg+Enter';

  @override
  String get vibrate => 'Bei Schnelltasten vibrieren';

  @override
  String get secQuickKeys => 'Schnelltasten';

  @override
  String get secPicture => 'Bild';

  @override
  String get textSize => 'Textgröße';

  @override
  String get stealthDefault => 'Fenster standardmäßig auf dem PC verbergen';

  @override
  String get stealthDefaultSub => 'Tarnung. Pro Fenster umschaltbar.';

  @override
  String get keepScreenOn => 'Bildschirm während der Steuerung an lassen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get hideKeyboard => 'Tastatur ausblenden';

  @override
  String get showKeyboard => 'Tastatur einblenden';

  @override
  String get qkNewLine => 'Neue Zeile';

  @override
  String get qkPaste => 'Einfügen';

  @override
  String get qkPageUp => 'Seite hoch';

  @override
  String get qkPageDown => 'Seite runter';

  @override
  String get qkDelete => 'Entf';

  @override
  String get secStream => 'Übertragung';

  @override
  String get rxFps => 'Bildrate (Empfang)';

  @override
  String get rxFpsSub => 'Niedriger = schont das Netz, Bild ruckelt eher';

  @override
  String get rxScale => 'Bildgröße';

  @override
  String get rxScaleSub => 'Kleineres Bild = deutlich weniger Daten';

  @override
  String get rxGray => 'Graustufenmodus';

  @override
  String get rxGraySub => 'Schwarzweißbild; spart deutlich Datenvolumen';

  @override
  String get switchIme => 'Tastatur wechseln';
}
