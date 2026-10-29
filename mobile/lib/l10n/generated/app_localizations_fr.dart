// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get pairPc => 'Associer un PC';

  @override
  String get pairScanHint =>
      'Scannez le code affiché dans WinRelay sur votre PC.';

  @override
  String get pairOrPaste => 'Ou collez le lien';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => 'Coller';

  @override
  String get connect => 'Se connecter';

  @override
  String get pairFooter =>
      'Après la connexion, cliquez sur Approuver sur le PC. Chaque lien ne fonctionne qu\'une fois.';

  @override
  String get pairBadLink =>
      'Ce n\'est pas un lien WinRelay. Recopiez-le depuis WinRelay sur le PC.';

  @override
  String get pcsTitle => 'Vos PC';

  @override
  String get pcsEmpty => 'Associez un PC pour commencer.';

  @override
  String get settings => 'Paramètres';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · port $port';
  }

  @override
  String get waitingApprovalSub => 'En attente d\'approbation sur le PC';

  @override
  String get renamePc => 'Renommer le PC';

  @override
  String get rename => 'Renommer';

  @override
  String get remove => 'Retirer';

  @override
  String get refresh => 'Actualiser';

  @override
  String connectingTo(String name) {
    return 'Connexion à $name…';
  }

  @override
  String get approveTitle => 'Approuvez ce téléphone sur votre PC';

  @override
  String approveBody(String name) {
    return 'Ouvrez WinRelay sur le PC et cliquez sur Approuver à côté de « $name ».';
  }

  @override
  String get cantConnect => 'Impossible de se connecter';

  @override
  String errUnreachable(String name) {
    return 'Impossible de joindre $name. Vérifiez que le PC est allumé, que WinRelay fonctionne et que votre réseau peut l\'atteindre.';
  }

  @override
  String errDropped(String name) {
    return 'La connexion à $name a été perdue.';
  }

  @override
  String get searchWindows => 'Rechercher des fenêtres';

  @override
  String get hideOnPc => 'Masquer la fenêtre sur le PC';

  @override
  String get hideOnPcSub =>
      'Furtif : l\'écran du PC n\'affichera pas la fenêtre pendant le contrôle';

  @override
  String get noMatch =>
      'Aucune fenêtre ne correspond. Tirez vers le bas pour actualiser.';

  @override
  String get viewMode => 'Vue';

  @override
  String get tapMode => 'Toucher';

  @override
  String get viewTip =>
      'Regarder seulement : les touchers ne cliquent pas sur le PC';

  @override
  String get tapTip => 'Les touchers cliquent sur le PC';

  @override
  String get stealthTip => 'Furtif : masqué sur le PC';

  @override
  String get reconnecting => 'Reconnexion au PC…';

  @override
  String get pcLocked =>
      'Le PC est verrouillé. Déverrouillez-le pour continuer à contrôler cette fenêtre.';

  @override
  String get composeHint => 'Écrivez un message pour cette fenêtre';

  @override
  String get sendWithEnter => 'Envoyer avec Entrée';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get secThisPhone => 'Ce téléphone';

  @override
  String get phoneName => 'Nom du téléphone';

  @override
  String get phoneNameSub => 'Affiché sur le PC lors de l\'association';

  @override
  String get secAppearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Valeur du système';

  @override
  String get secTouch => 'Tactile et saisie';

  @override
  String get defaultTouch => 'Mode tactile par défaut';

  @override
  String get defaultTouchSub =>
      'Vue ne clique jamais sur le PC ; Toucher transforme les touchers en clics';

  @override
  String get composeMode => 'Mode rédaction';

  @override
  String get composeModeSub =>
      'Écrivez d\'abord le message entier, avec correction automatique, puis envoyez-le. Désactivé : chaque touche part vers le PC au fil de la saisie.';

  @override
  String get returnSends => 'La touche Entrée envoie';

  @override
  String get enterKeyEnter => 'Entrée';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Entrée';

  @override
  String get vibrate => 'Vibrer sur les touches rapides';

  @override
  String get secQuickKeys => 'Touches rapides';

  @override
  String get secPicture => 'Image';

  @override
  String get textSize => 'Taille du texte';

  @override
  String get stealthDefault => 'Masquer les fenêtres sur le PC par défaut';

  @override
  String get stealthDefaultSub => 'Furtif. Vous pouvez le changer par fenêtre.';

  @override
  String get keepScreenOn => 'Garder l\'écran allumé pendant le contrôle';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get hideKeyboard => 'Masquer le clavier';

  @override
  String get showKeyboard => 'Afficher le clavier';

  @override
  String get qkNewLine => 'Nouvelle ligne';

  @override
  String get qkPaste => 'Coller';

  @override
  String get qkPageUp => 'Page précédente';

  @override
  String get qkPageDown => 'Page suivante';

  @override
  String get qkDelete => 'Suppr';

  @override
  String get secStream => 'Transmission';

  @override
  String get rxFps => 'Fréquence de réception';

  @override
  String get rxFpsSub => 'Plus basse = réseau plus léger, image moins fluide';

  @override
  String get rxScale => 'Taille de l\'image';

  @override
  String get rxScaleSub => 'Image plus petite = beaucoup moins de données';

  @override
  String get rxGray => 'Mode niveaux de gris';

  @override
  String get rxGraySub =>
      'Image en noir et blanc ; réduit nettement les données';

  @override
  String get switchIme => 'Changer de clavier';

  @override
  String get webMode => 'Web';

  @override
  String get webModeTip =>
      'Naviguez comme sur un téléphone ; le PC suit votre navigation';

  @override
  String get loadFromPc => 'Charger la page affichée sur le PC';

  @override
  String get filesTitle => 'Fichiers';

  @override
  String get thisPc => 'Ce PC';

  @override
  String get upload => 'Envoyer';

  @override
  String get download => 'Télécharger';

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get folderName => 'Nom du dossier';

  @override
  String get deleteItem => 'Supprimer';

  @override
  String get deleteConfirmTitle => 'Supprimer ?';

  @override
  String deleteConfirmBody(Object name) {
    return '« $name » sera déplacé vers la corbeille.';
  }

  @override
  String get downloadDone => 'Téléchargé. Choisissez où l\'enregistrer.';

  @override
  String get transferDone => 'Transfert terminé';

  @override
  String get transferFailed => 'Échec du transfert';

  @override
  String get emptyDir => 'Dossier vide';

  @override
  String get grantStorage =>
      'Accordez l\'accès à tous les fichiers sur l\'écran suivant, puis réessayez.';

  @override
  String get uploadFromPhone => 'Envoyer un fichier de ce téléphone';

  @override
  String get goBack => 'Retour';

  @override
  String get goForward => 'Avancer';

  @override
  String get addressBarHint => 'Rechercher ou saisir une URL';

  @override
  String get followPc => 'Suivre le PC';

  @override
  String get pcScreen => 'Écran du PC';
}
