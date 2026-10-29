// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get pairPc => 'Привязать ПК';

  @override
  String get pairScanHint => 'Отсканируйте код, показанный в WinRelay на ПК.';

  @override
  String get pairOrPaste => 'Или вставьте ссылку';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => 'Вставить';

  @override
  String get connect => 'Подключить';

  @override
  String get pairFooter =>
      'После подключения нажмите «Одобрить» на ПК. Каждая ссылка работает один раз.';

  @override
  String get pairBadLink =>
      'Это не ссылка WinRelay. Скопируйте её заново из WinRelay на ПК.';

  @override
  String get pcsTitle => 'Ваши ПК';

  @override
  String get pcsEmpty => 'Сначала привяжите ПК.';

  @override
  String get settings => 'Настройки';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · порт $port';
  }

  @override
  String get waitingApprovalSub => 'Ожидает одобрения на ПК';

  @override
  String get renamePc => 'Переименовать ПК';

  @override
  String get rename => 'Переименовать';

  @override
  String get remove => 'Удалить';

  @override
  String get refresh => 'Обновить';

  @override
  String connectingTo(String name) {
    return 'Подключение к $name…';
  }

  @override
  String get approveTitle => 'Одобрите этот телефон на ПК';

  @override
  String approveBody(String name) {
    return 'Откройте WinRelay на ПК и нажмите «Одобрить» рядом с «$name».';
  }

  @override
  String get cantConnect => 'Не удаётся подключиться';

  @override
  String errUnreachable(String name) {
    return 'Не удаётся связаться с $name. Убедитесь, что ПК включён, WinRelay запущен и сеть до него достаёт.';
  }

  @override
  String errDropped(String name) {
    return 'Соединение с $name потеряно.';
  }

  @override
  String get searchWindows => 'Поиск окон';

  @override
  String get hideOnPc => 'Скрывать окно на ПК';

  @override
  String get hideOnPcSub =>
      'Скрытность: экран ПК не будет показывать окно во время управления';

  @override
  String get noMatch => 'Ничего не найдено. Потяните вниз, чтобы обновить.';

  @override
  String get viewMode => 'Просмотр';

  @override
  String get tapMode => 'Нажатие';

  @override
  String get viewTip => 'Только смотреть: нажатия не кликают на ПК';

  @override
  String get tapTip => 'Нажатия кликают на ПК';

  @override
  String get stealthTip => 'Скрытность: скрыто на ПК';

  @override
  String get reconnecting => 'Переподключение к ПК…';

  @override
  String get pcLocked =>
      'ПК заблокирован. Разблокируйте его, чтобы продолжить управление окном.';

  @override
  String get composeHint => 'Напишите сообщение для этого окна';

  @override
  String get sendWithEnter => 'Отправить по Enter';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get secThisPhone => 'Этот телефон';

  @override
  String get phoneName => 'Имя телефона';

  @override
  String get phoneNameSub => 'Показывается на ПК при привязке';

  @override
  String get secAppearance => 'Оформление';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get secTouch => 'Касания и ввод';

  @override
  String get defaultTouch => 'Режим касаний по умолчанию';

  @override
  String get defaultTouchSub =>
      '«Просмотр» не кликает на ПК; «Нажатие» превращает касания в клики';

  @override
  String get composeMode => 'Режим набора';

  @override
  String get composeModeSub =>
      'Сначала напишите всё сообщение (с автокоррекцией), затем отправьте. Выкл.: каждая клавиша уходит на ПК сразу.';

  @override
  String get returnSends => 'Клавиша Enter отправляет';

  @override
  String get enterKeyEnter => 'Enter';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Enter';

  @override
  String get vibrate => 'Вибрация на быстрых клавишах';

  @override
  String get secQuickKeys => 'Быстрые клавиши';

  @override
  String get secPicture => 'Картинка';

  @override
  String get textSize => 'Размер текста';

  @override
  String get stealthDefault => 'По умолчанию скрывать окна на ПК';

  @override
  String get stealthDefaultSub => 'Скрытность. Можно менять для каждого окна.';

  @override
  String get keepScreenOn => 'Держать экран включённым во время управления';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get hideKeyboard => 'Скрыть клавиатуру';

  @override
  String get showKeyboard => 'Показать клавиатуру';

  @override
  String get qkNewLine => 'Новая строка';

  @override
  String get qkPaste => 'Вставить';

  @override
  String get qkPageUp => 'Страница вверх';

  @override
  String get qkPageDown => 'Страница вниз';

  @override
  String get qkDelete => 'Удалить';

  @override
  String get secStream => 'Трансляция';

  @override
  String get rxFps => 'Частота кадров приёма';

  @override
  String get rxFpsSub =>
      'Ниже = меньше нагрузка на сеть, менее плавная картинка';

  @override
  String get rxScale => 'Размер картинки';

  @override
  String get rxScaleSub => 'Меньше картинка = намного меньше трафика';

  @override
  String get rxGray => 'Оттенки серого';

  @override
  String get rxGraySub => 'Чёрно-белая картинка; резко сокращает трафик';

  @override
  String get switchIme => 'Сменить клавиатуру';

  @override
  String get webMode => 'Веб';

  @override
  String get webModeTip =>
      'Сёрфите как на телефоне; ПК последует за вашей навигацией';

  @override
  String get loadFromPc => 'Загрузить страницу, открытую на ПК';
}
