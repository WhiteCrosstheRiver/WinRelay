// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get pairPc => 'Vincular un PC';

  @override
  String get pairScanHint => 'Escanea el código que muestra WinRelay en tu PC.';

  @override
  String get pairOrPaste => 'O pega el enlace';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => 'Pegar';

  @override
  String get connect => 'Conectar';

  @override
  String get pairFooter =>
      'Tras conectar, pulsa Aprobar en el PC. Cada enlace funciona una sola vez.';

  @override
  String get pairBadLink =>
      'Ese no es un enlace de WinRelay. Cópialo de nuevo desde WinRelay en el PC.';

  @override
  String get pcsTitle => 'Tus PC';

  @override
  String get pcsEmpty => 'Vincula un PC para empezar.';

  @override
  String get settings => 'Ajustes';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · puerto $port';
  }

  @override
  String get waitingApprovalSub => 'Esperando aprobación en el PC';

  @override
  String get renamePc => 'Renombrar PC';

  @override
  String get rename => 'Renombrar';

  @override
  String get remove => 'Quitar';

  @override
  String get refresh => 'Actualizar';

  @override
  String connectingTo(String name) {
    return 'Conectando a $name…';
  }

  @override
  String get approveTitle => 'Aprueba este teléfono en tu PC';

  @override
  String approveBody(String name) {
    return 'Abre WinRelay en el PC y pulsa Aprobar junto a \"$name\".';
  }

  @override
  String get cantConnect => 'No se puede conectar';

  @override
  String errUnreachable(String name) {
    return 'No se pudo conectar con $name. Comprueba que el PC está encendido, que WinRelay se está ejecutando y que tu red puede alcanzarlo.';
  }

  @override
  String errDropped(String name) {
    return 'Se perdió la conexión con $name.';
  }

  @override
  String get searchWindows => 'Buscar ventanas';

  @override
  String get hideOnPc => 'Ocultar la ventana en el PC';

  @override
  String get hideOnPcSub =>
      'Sigilo: la pantalla del PC no mostrará la ventana mientras la controlas';

  @override
  String get noMatch =>
      'Ninguna ventana coincide. Desliza hacia abajo para actualizar.';

  @override
  String get viewMode => 'Ver';

  @override
  String get tapMode => 'Tocar';

  @override
  String get viewTip => 'Solo mirar: los toques no hacen clic en el PC';

  @override
  String get tapTip => 'Los toques hacen clic en el PC';

  @override
  String get stealthTip => 'Sigilo: oculto en el PC';

  @override
  String get reconnecting => 'Reconectando con el PC…';

  @override
  String get pcLocked =>
      'El PC está bloqueado. Desbloquéalo para seguir controlando esta ventana.';

  @override
  String get composeHint => 'Escribe un mensaje para esta ventana';

  @override
  String get sendWithEnter => 'Enviar con Enter';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get secThisPhone => 'Este teléfono';

  @override
  String get phoneName => 'Nombre del teléfono';

  @override
  String get phoneNameSub => 'Se muestra en el PC al vincular';

  @override
  String get secAppearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get secTouch => 'Tacto y escritura';

  @override
  String get defaultTouch => 'Modo táctil predeterminado';

  @override
  String get defaultTouchSub =>
      'Ver nunca hace clic en el PC; Tocar convierte los toques en clics';

  @override
  String get composeMode => 'Modo redacción';

  @override
  String get composeModeSub =>
      'Escribe el mensaje completo primero, con autocorrección, y envíalo después. Desactivado: cada tecla va al PC mientras escribes.';

  @override
  String get returnSends => 'La tecla Enter envía';

  @override
  String get enterKeyEnter => 'Enter';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Enter';

  @override
  String get vibrate => 'Vibrar en teclas rápidas';

  @override
  String get secQuickKeys => 'Teclas rápidas';

  @override
  String get secPicture => 'Imagen';

  @override
  String get textSize => 'Tamaño del texto';

  @override
  String get stealthDefault =>
      'Ocultar ventanas en el PC de forma predeterminada';

  @override
  String get stealthDefaultSub => 'Sigilo. Puedes cambiarlo por ventana.';

  @override
  String get keepScreenOn =>
      'Mantener la pantalla encendida mientras controlas';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get hideKeyboard => 'Ocultar teclado';

  @override
  String get showKeyboard => 'Mostrar teclado';

  @override
  String get qkNewLine => 'Nueva línea';

  @override
  String get qkPaste => 'Pegar';

  @override
  String get qkPageUp => 'Página arriba';

  @override
  String get qkPageDown => 'Página abajo';

  @override
  String get qkDelete => 'Suprimir';

  @override
  String get secStream => 'Transmisión';

  @override
  String get rxFps => 'Fotogramas recibidos';

  @override
  String get rxFpsSub => 'Más bajo = red más ligera, imagen menos fluida';

  @override
  String get rxScale => 'Tamaño de imagen';

  @override
  String get rxScaleSub => 'Imagen más pequeña = muchos menos datos';

  @override
  String get rxGray => 'Modo de escala de grises';

  @override
  String get rxGraySub => 'Imagen en blanco y negro; reduce mucho los datos';
}
