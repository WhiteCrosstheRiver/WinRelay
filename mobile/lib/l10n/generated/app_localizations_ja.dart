// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get pairPc => 'PC をペアリング';

  @override
  String get pairScanHint => 'PC の WinRelay に表示されるコードをスキャンしてください。';

  @override
  String get pairOrPaste => 'またはリンクを貼り付け';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => '貼り付け';

  @override
  String get connect => '接続';

  @override
  String get pairFooter => '接続後、PC 側で「承認」をクリックしてください。リンクは 1 回のみ有効です。';

  @override
  String get pairBadLink =>
      'WinRelay のリンクではありません。PC の WinRelay からもう一度コピーしてください。';

  @override
  String get pcsTitle => 'PC 一覧';

  @override
  String get pcsEmpty => 'まず PC をペアリングしてください。';

  @override
  String get settings => '設定';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · ポート $port';
  }

  @override
  String get waitingApprovalSub => 'PC 側の承認を待っています';

  @override
  String get renamePc => 'PC 名を変更';

  @override
  String get rename => '名前を変更';

  @override
  String get remove => '削除';

  @override
  String get refresh => '更新';

  @override
  String connectingTo(String name) {
    return '$name に接続中…';
  }

  @override
  String get approveTitle => 'PC でこのスマホを承認してください';

  @override
  String approveBody(String name) {
    return 'PC の WinRelay を開き、「$name」の横にある「承認」をクリックしてください。';
  }

  @override
  String get cantConnect => '接続できません';

  @override
  String errUnreachable(String name) {
    return '$name に接続できません。PC の電源、WinRelay の起動、ネットワーク経路を確認してください。';
  }

  @override
  String errDropped(String name) {
    return '$name への接続が切断されました。';
  }

  @override
  String get searchWindows => 'ウィンドウを検索';

  @override
  String get hideOnPc => 'PC でウィンドウを隠す';

  @override
  String get hideOnPcSub => 'ステルス:制御中、PC の画面には表示されません';

  @override
  String get noMatch => '該当するウィンドウがありません。下にスワイプすると更新できます。';

  @override
  String get viewMode => '表示';

  @override
  String get tapMode => 'タップ';

  @override
  String get viewTip => '見るだけ:タップは PC をクリックしません';

  @override
  String get tapTip => 'タップが PC をクリックします';

  @override
  String get stealthTip => 'ステルス:PC 側に非表示';

  @override
  String get reconnecting => 'PC に再接続中…';

  @override
  String get pcLocked => 'PC がロックされています。ロックを解除すると操作を続けられます。';

  @override
  String get composeHint => 'このウィンドウへのメッセージを入力';

  @override
  String get sendWithEnter => 'Enter で送信';

  @override
  String get settingsTitle => '設定';

  @override
  String get secThisPhone => 'このスマホ';

  @override
  String get phoneName => 'スマホの名前';

  @override
  String get phoneNameSub => 'ペアリング時に PC に表示されます';

  @override
  String get secAppearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システム設定に従う';

  @override
  String get secTouch => 'タッチと入力';

  @override
  String get defaultTouch => '既定のタッチモード';

  @override
  String get defaultTouchSub => '「表示」は PC をクリックしません。「タップ」はタップをクリックにします。';

  @override
  String get composeMode => 'コンポーズモード';

  @override
  String get composeModeSub =>
      'メッセージ全体を書いてから送信します(自動修正あり)。オフ:キー入力がそのまま PC へ送られます。';

  @override
  String get returnSends => 'Enter キーの動作';

  @override
  String get enterKeyEnter => 'Enter';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Enter';

  @override
  String get vibrate => 'クイックキーで振動';

  @override
  String get secQuickKeys => 'クイックキー';

  @override
  String get secPicture => '画面';

  @override
  String get textSize => '文字サイズ';

  @override
  String get stealthDefault => '既定で PC 側のウィンドウを隠す';

  @override
  String get stealthDefaultSub => 'ステルス。ウィンドウごとに切り替え可能。';

  @override
  String get keepScreenOn => '操作中は画面を常に点灯';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get hideKeyboard => 'キーボードを隠す';

  @override
  String get showKeyboard => 'キーボードを表示';

  @override
  String get qkNewLine => '改行';

  @override
  String get qkPaste => '貼り付け';

  @override
  String get qkPageUp => 'ページアップ';

  @override
  String get qkPageDown => 'ページダウン';

  @override
  String get qkDelete => '削除';

  @override
  String get secStream => 'ストリーム';

  @override
  String get rxFps => '受信フレームレート';

  @override
  String get rxFpsSub => '低いほど通信を節約し、映像は滑らかでなくなります';

  @override
  String get rxScale => '受信画像サイズ';

  @override
  String get rxScaleSub => '画像が小さいほど通信量を大きく節約できます';

  @override
  String get rxGray => 'グレースケール';

  @override
  String get rxGraySub => '白黒画像で通信量を大幅に削減';
}
