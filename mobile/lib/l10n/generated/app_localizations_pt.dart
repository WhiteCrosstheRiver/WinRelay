// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get pairPc => 'Parear um PC';

  @override
  String get pairScanHint => 'Escaneie o código exibido no WinRelay do seu PC.';

  @override
  String get pairOrPaste => 'Ou cole o link';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => 'Colar';

  @override
  String get connect => 'Conectar';

  @override
  String get pairFooter =>
      'Depois de conectar, clique em Aprovar no PC. Cada link funciona uma única vez.';

  @override
  String get pairBadLink =>
      'Isso não é um link do WinRelay. Copie-o novamente do WinRelay no PC.';

  @override
  String get pcsTitle => 'Seus PCs';

  @override
  String get pcsEmpty => 'Pareie um PC para começar.';

  @override
  String get settings => 'Configurações';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · porta $port';
  }

  @override
  String get waitingApprovalSub => 'Aguardando aprovação no PC';

  @override
  String get renamePc => 'Renomear PC';

  @override
  String get rename => 'Renomear';

  @override
  String get remove => 'Remover';

  @override
  String get refresh => 'Atualizar';

  @override
  String connectingTo(String name) {
    return 'Conectando a $name…';
  }

  @override
  String get approveTitle => 'Aprove este telefone no PC';

  @override
  String approveBody(String name) {
    return 'Abra o WinRelay no PC e clique em Aprovar ao lado de \"$name\".';
  }

  @override
  String get cantConnect => 'Não foi possível conectar';

  @override
  String errUnreachable(String name) {
    return 'Não foi possível alcançar $name. Verifique se o PC está ligado, se o WinRelay está em execução e se sua rede consegue alcançá-lo.';
  }

  @override
  String errDropped(String name) {
    return 'A conexão com $name foi perdida.';
  }

  @override
  String get searchWindows => 'Buscar janelas';

  @override
  String get hideOnPc => 'Ocultar a janela no PC';

  @override
  String get hideOnPcSub =>
      'Furtivo: a tela do PC não mostrará a janela enquanto você a controla';

  @override
  String get noMatch =>
      'Nenhuma janela corresponde. Puxe para baixo para atualizar.';

  @override
  String get viewMode => 'Ver';

  @override
  String get tapMode => 'Tocar';

  @override
  String get viewTip => 'Só olhar: toques não clicam no PC';

  @override
  String get tapTip => 'Toques clicam no PC';

  @override
  String get stealthTip => 'Furtivo: oculto no PC';

  @override
  String get reconnecting => 'Reconectando ao PC…';

  @override
  String get pcLocked =>
      'O PC está bloqueado. Desbloqueie para continuar controlando esta janela.';

  @override
  String get composeHint => 'Escreva uma mensagem para esta janela';

  @override
  String get sendWithEnter => 'Enviar com Enter';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get secThisPhone => 'Este telefone';

  @override
  String get phoneName => 'Nome do telefone';

  @override
  String get phoneNameSub => 'Mostrado no PC ao parear';

  @override
  String get secAppearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get secTouch => 'Toque e digitação';

  @override
  String get defaultTouch => 'Modo de toque padrão';

  @override
  String get defaultTouchSub =>
      'Ver nunca clica no PC; Tocar transforma toques em cliques';

  @override
  String get composeMode => 'Modo de composição';

  @override
  String get composeModeSub =>
      'Escreva a mensagem inteira primeiro, com autocorreção, e envie depois. Desligado: cada tecla vai ao PC enquanto você digita.';

  @override
  String get returnSends => 'A tecla Enter envia';

  @override
  String get enterKeyEnter => 'Enter';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Enter';

  @override
  String get vibrate => 'Vibrar nas teclas rápidas';

  @override
  String get secQuickKeys => 'Teclas rápidas';

  @override
  String get secPicture => 'Imagem';

  @override
  String get textSize => 'Tamanho do texto';

  @override
  String get stealthDefault => 'Ocultar janelas no PC por padrão';

  @override
  String get stealthDefaultSub =>
      'Furtivo. Você ainda pode alternar por janela.';

  @override
  String get keepScreenOn => 'Manter a tela ligada enquanto controla';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get hideKeyboard => 'Ocultar teclado';

  @override
  String get showKeyboard => 'Mostrar teclado';

  @override
  String get qkNewLine => 'Nova linha';

  @override
  String get qkPaste => 'Colar';

  @override
  String get qkPageUp => 'Página acima';

  @override
  String get qkPageDown => 'Página abaixo';

  @override
  String get qkDelete => 'Excluir';

  @override
  String get secStream => 'Transmissão';

  @override
  String get rxFps => 'Taxa de quadros recebida';

  @override
  String get rxFpsSub => 'Menor = rede mais leve, imagem menos fluida';

  @override
  String get rxScale => 'Tamanho da imagem';

  @override
  String get rxScaleSub => 'Imagem menor = muito menos dados';

  @override
  String get rxGray => 'Modo tons de cinza';

  @override
  String get rxGraySub => 'Imagem em preto e branco; reduz muito os dados';

  @override
  String get switchIme => 'Mudar teclado';

  @override
  String get webMode => 'Web';

  @override
  String get webModeTip => 'Navegue como no celular; o PC segue sua navegação';

  @override
  String get loadFromPc => 'Carregar a página que o PC mostra';
}
