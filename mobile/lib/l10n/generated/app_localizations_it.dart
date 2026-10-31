// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get pairPc => 'Abbina un PC';

  @override
  String get pairScanHint => 'Scansiona il codice mostrato da WinRelay sul PC.';

  @override
  String get pairOrPaste => 'Oppure incolla il link';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => 'Incolla';

  @override
  String get connect => 'Connetti';

  @override
  String get pairFooter =>
      'Dopo la connessione, fai clic su Approva sul PC. Ogni link funziona una sola volta.';

  @override
  String get pairBadLink =>
      'Non è un link di WinRelay. Copialo di nuovo da WinRelay sul PC.';

  @override
  String get pcsTitle => 'I tuoi PC';

  @override
  String get pcsEmpty => 'Abbina un PC per iniziare.';

  @override
  String get settings => 'Impostazioni';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · porta $port';
  }

  @override
  String get waitingApprovalSub => 'In attesa di approvazione sul PC';

  @override
  String get renamePc => 'Rinomina PC';

  @override
  String get rename => 'Rinomina';

  @override
  String get remove => 'Rimuovi';

  @override
  String get refresh => 'Aggiorna';

  @override
  String connectingTo(String name) {
    return 'Connessione a $name…';
  }

  @override
  String get approveTitle => 'Approva questo telefono sul PC';

  @override
  String approveBody(String name) {
    return 'Apri WinRelay sul PC e fai clic su Approva accanto a \"$name\".';
  }

  @override
  String get cantConnect => 'Impossibile connettersi';

  @override
  String errUnreachable(String name) {
    return 'Impossibile raggiungere $name. Verifica che il PC sia acceso, che WinRelay sia in esecuzione e che la rete lo raggiunga.';
  }

  @override
  String errDropped(String name) {
    return 'La connessione a $name è stata persa.';
  }

  @override
  String get searchWindows => 'Cerca finestre';

  @override
  String get hideOnPc => 'Nascondi la finestra sul PC';

  @override
  String get hideOnPcSub =>
      'Furtivo: lo schermo del PC non mostrerà la finestra durante il controllo';

  @override
  String get noMatch =>
      'Nessuna finestra corrisponde. Trascina verso il basso per aggiornare.';

  @override
  String get viewMode => 'Vista';

  @override
  String get tapMode => 'Tocco';

  @override
  String get viewTip => 'Solo osservazione: i tocchi non fanno clic sul PC';

  @override
  String get tapTip => 'I tocchi fanno clic sul PC';

  @override
  String get stealthTip => 'Furtivo: nascosto sul PC';

  @override
  String get reconnecting => 'Riconnessione al PC…';

  @override
  String get pcLocked =>
      'Il PC è bloccato. Sbloccalo per continuare a controllare questa finestra.';

  @override
  String get composeHint => 'Scrivi un messaggio per questa finestra';

  @override
  String get sendWithEnter => 'Invia con Invio';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get secThisPhone => 'Questo telefono';

  @override
  String get phoneName => 'Nome del telefono';

  @override
  String get phoneNameSub => 'Mostrato sul PC durante l\'abbinamento';

  @override
  String get secAppearance => 'Aspetto';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'Predefinito di sistema';

  @override
  String get secTouch => 'Tocco e digitazione';

  @override
  String get defaultTouch => 'Modalità tocco predefinita';

  @override
  String get defaultTouchSub =>
      'Vista non fa mai clic sul PC; Tocco trasforma i tocchi in clic';

  @override
  String get composeMode => 'Modalità composizione';

  @override
  String get composeModeSub =>
      'Scrivi prima il messaggio completo, con autocorrezione, poi invialo. Off: ogni tasto va al PC mentre scrivi.';

  @override
  String get returnSends => 'Il tasto Invio invia';

  @override
  String get enterKeyEnter => 'Invio';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Invio';

  @override
  String get vibrate => 'Vibrazione sui tasti rapidi';

  @override
  String get secQuickKeys => 'Tasti rapidi';

  @override
  String get secPicture => 'Immagine';

  @override
  String get textSize => 'Dimensione testo';

  @override
  String get stealthDefault =>
      'Nascondi le finestre sul PC per impostazione predefinita';

  @override
  String get stealthDefaultSub => 'Furtivo. Puoi cambiarlo per finestra.';

  @override
  String get keepScreenOn => 'Mantieni lo schermo acceso durante il controllo';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get hideKeyboard => 'Nascondi tastiera';

  @override
  String get showKeyboard => 'Mostra tastiera';

  @override
  String get qkNewLine => 'Nuova riga';

  @override
  String get qkPaste => 'Incolla';

  @override
  String get qkPageUp => 'Pagina su';

  @override
  String get qkPageDown => 'Pagina giù';

  @override
  String get qkDelete => 'Canc';

  @override
  String get secStream => 'Trasmissione';

  @override
  String get rxFps => 'Framerate in ricezione';

  @override
  String get rxFpsSub => 'Più basso = rete più leggera, immagine meno fluida';

  @override
  String get rxScale => 'Dimensione immagine';

  @override
  String get rxScaleSub => 'Immagine più piccola = molti meno dati';

  @override
  String get rxGray => 'Modalità scala di grigi';

  @override
  String get rxGraySub => 'Immagine in bianco e nero; riduce molto i dati';

  @override
  String get switchIme => 'Cambia tastiera';

  @override
  String get webMode => 'Web';

  @override
  String get webModeTip =>
      'Naviga come su un telefono; il PC segue la tua navigazione';

  @override
  String get loadFromPc => 'Carica la pagina mostrata sul PC';

  @override
  String get filesTitle => 'File';

  @override
  String get thisPc => 'Questo PC';

  @override
  String get upload => 'Carica';

  @override
  String get download => 'Scarica';

  @override
  String get newFolder => 'Nuova cartella';

  @override
  String get folderName => 'Nome cartella';

  @override
  String get deleteItem => 'Elimina';

  @override
  String get deleteConfirmTitle => 'Eliminare?';

  @override
  String deleteConfirmBody(Object name) {
    return '\"$name\" verrà spostato nel Cestino.';
  }

  @override
  String get downloadDone => 'Scaricato. Scegli dove conservarlo.';

  @override
  String get transferDone => 'Trasferimento completato';

  @override
  String get transferFailed => 'Trasferimento non riuscito';

  @override
  String get emptyDir => 'Cartella vuota';

  @override
  String get grantStorage =>
      'Concedi l\'accesso a tutti i file nella schermata successiva, poi riprova.';

  @override
  String get uploadFromPhone => 'Invia un file da questo telefono';

  @override
  String get goBack => 'Indietro';

  @override
  String get goForward => 'Avanti';

  @override
  String get addressBarHint => 'Cerca o digita un URL';

  @override
  String get followPc => 'Segui il PC';

  @override
  String get pcScreen => 'Schermo PC';

  @override
  String get clipCopyFromPc => 'Copia gli appunti di questo PC';

  @override
  String get clipPasteToPc => 'Incolla il testo relay in questo PC';

  @override
  String get clipEmpty => 'Gli appunti relay sono vuoti: copia prima qualcosa.';

  @override
  String clipCopied(Object n) {
    return 'Copiato ($n caratteri). Controlla l\'altro PC e premi incolla.';
  }

  @override
  String get clipPasted => 'Incollato nel PC.';

  @override
  String get colorColor => 'A colori';

  @override
  String get colorGray => 'Scala di grigi';

  @override
  String get colorBw => 'Bianco e nero puro';

  @override
  String get jumpPath => 'Vai al percorso';

  @override
  String get pathHint => 'Percorso PC, es. C:\\Users\\me\\Desktop';

  @override
  String get invalidPath => 'Impossibile aprire quel percorso.';

  @override
  String savedTo(Object name) {
    return 'Salvato in Download del telefono: $name';
  }

  @override
  String get share => 'Condividi';

  @override
  String get appsTitle => 'App';

  @override
  String get searchApps => 'Cerca app…';

  @override
  String get running => 'In esecuzione';

  @override
  String get appOpen => 'Avvia';

  @override
  String get appClose => 'Chiudi app';

  @override
  String get closeAppTitle => 'Chiudere la app?';

  @override
  String closeAppBody(Object name) {
    return '\"$name\" verrà chiusa sul PC (potrebbe chiedere di salvare).';
  }

  @override
  String get appDone => 'Fatto';

  @override
  String get appsEmpty => 'Nessuna app corrisponde.';
}
