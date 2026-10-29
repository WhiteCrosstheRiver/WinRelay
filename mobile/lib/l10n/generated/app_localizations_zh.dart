// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get pairPc => '配对电脑';

  @override
  String get pairScanHint => '扫描电脑上 WinRelay 显示的二维码。';

  @override
  String get pairOrPaste => '或粘贴链接';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => '粘贴';

  @override
  String get connect => '连接';

  @override
  String get pairFooter => '连接后在电脑上点击“批准”。每个链接只能用一次。';

  @override
  String get pairBadLink => '这不是 WinRelay 链接。请在电脑上的 WinRelay 里重新复制。';

  @override
  String get pcsTitle => '我的电脑';

  @override
  String get pcsEmpty => '先配对一台电脑。';

  @override
  String get settings => '设置';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · 端口 $port';
  }

  @override
  String get waitingApprovalSub => '等待电脑端批准';

  @override
  String get renamePc => '重命名电脑';

  @override
  String get rename => '重命名';

  @override
  String get remove => '移除';

  @override
  String get refresh => '刷新';

  @override
  String connectingTo(String name) {
    return '正在连接 $name…';
  }

  @override
  String get approveTitle => '在电脑上批准这部手机';

  @override
  String approveBody(String name) {
    return '打开电脑上的 WinRelay,点击“$name”旁边的批准。';
  }

  @override
  String get cantConnect => '无法连接';

  @override
  String errUnreachable(String name) {
    return '无法连接到 $name。请确认电脑已开机、WinRelay 正在运行,且当前网络可以访问它。';
  }

  @override
  String errDropped(String name) {
    return '与 $name 的连接已断开。';
  }

  @override
  String get searchWindows => '搜索窗口';

  @override
  String get hideOnPc => '在电脑上隐藏该窗口';

  @override
  String get hideOnPcSub => '隐身:控制期间电脑屏幕上不显示该窗口';

  @override
  String get noMatch => '没有匹配的窗口。下拉即可刷新。';

  @override
  String get viewMode => '仅查看';

  @override
  String get tapMode => '点按';

  @override
  String get viewTip => '只看不动:点按不会在电脑上产生点击';

  @override
  String get tapTip => '点按会在电脑上产生点击';

  @override
  String get stealthTip => '隐身中:电脑端不显示';

  @override
  String get reconnecting => '正在重新连接电脑…';

  @override
  String get pcLocked => '电脑已锁定。解锁后才能继续控制该窗口。';

  @override
  String get composeHint => '写好要发给该窗口的消息';

  @override
  String get sendWithEnter => '用回车发送';

  @override
  String get settingsTitle => '设置';

  @override
  String get secThisPhone => '本机';

  @override
  String get phoneName => '手机名称';

  @override
  String get phoneNameSub => '配对时显示在电脑上';

  @override
  String get secAppearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get secTouch => '触摸与输入';

  @override
  String get defaultTouch => '默认触摸模式';

  @override
  String get defaultTouchSub => '“仅查看”不会在电脑上产生点击;“点按”会把点按变成点击';

  @override
  String get composeMode => '编写模式';

  @override
  String get composeModeSub => '先写完整条消息(带自动纠错),再整条发送。关闭:每个按键实时发送到电脑。';

  @override
  String get returnSends => '回车键发送';

  @override
  String get enterKeyEnter => '回车';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+回车';

  @override
  String get vibrate => '快捷键振动';

  @override
  String get secQuickKeys => '快捷键';

  @override
  String get secPicture => '画面';

  @override
  String get textSize => '文字大小';

  @override
  String get stealthDefault => '默认在电脑上隐藏窗口';

  @override
  String get stealthDefaultSub => '隐身模式。仍可对单个窗口切换。';

  @override
  String get keepScreenOn => '控制时保持手机屏幕常亮';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get hideKeyboard => '收起键盘';

  @override
  String get showKeyboard => '打开键盘';

  @override
  String get qkNewLine => '换行';

  @override
  String get qkPaste => '粘贴';

  @override
  String get qkPageUp => '上翻页';

  @override
  String get qkPageDown => '下翻页';

  @override
  String get qkDelete => '删除';

  @override
  String get secStream => '画面传输';

  @override
  String get rxFps => '接收帧率';

  @override
  String get rxFpsSub => '越低越省网络,画面越不连贯';

  @override
  String get rxScale => '接收分辨率';

  @override
  String get rxScaleSub => '画面越小,流量越省';

  @override
  String get rxGray => '灰度模式';

  @override
  String get rxGraySub => '黑白画面,大幅节省流量';

  @override
  String get switchIme => '切换输入法';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get pairPc => '配對電腦';

  @override
  String get pairScanHint => '掃描電腦上 WinRelay 顯示的 QR 碼。';

  @override
  String get pairOrPaste => '或貼上連結';

  @override
  String get pairLinkHint => 'winrelay://pair?…';

  @override
  String get paste => '貼上';

  @override
  String get connect => '連接';

  @override
  String get pairFooter => '連接後在電腦上按「核准」。每條連結只能使用一次。';

  @override
  String get pairBadLink => '這不是 WinRelay 連結。請在電腦的 WinRelay 重新複製。';

  @override
  String get pcsTitle => '我的電腦';

  @override
  String get pcsEmpty => '先配對一部電腦。';

  @override
  String get settings => '設定';

  @override
  String pairedSubtitle(String host, String port) {
    return '$host · 連接埠 $port';
  }

  @override
  String get waitingApprovalSub => '等待電腦端核准';

  @override
  String get renamePc => '重新命名電腦';

  @override
  String get rename => '重新命名';

  @override
  String get remove => '移除';

  @override
  String get refresh => '重新整理';

  @override
  String connectingTo(String name) {
    return '正在連線 $name…';
  }

  @override
  String get approveTitle => '在電腦上核准這支手機';

  @override
  String approveBody(String name) {
    return '開啟電腦上的 WinRelay,按「$name」旁的核准。';
  }

  @override
  String get cantConnect => '無法連線';

  @override
  String errUnreachable(String name) {
    return '無法連上 $name。請確認電腦已開機、WinRelay 正在執行,且目前的網路連得到它。';
  }

  @override
  String errDropped(String name) {
    return '與 $name 的連線已中斷。';
  }

  @override
  String get searchWindows => '搜尋視窗';

  @override
  String get hideOnPc => '在電腦上隱藏此視窗';

  @override
  String get hideOnPcSub => '隱形模式:控制時電腦螢幕不會顯示此視窗';

  @override
  String get noMatch => '沒有符合的視窗。向下滑動即可重新整理。';

  @override
  String get viewMode => '僅檢視';

  @override
  String get tapMode => '點按';

  @override
  String get viewTip => '只看不點:點按不會在電腦產生點擊';

  @override
  String get tapTip => '點按會在電腦產生點擊';

  @override
  String get stealthTip => '隱形中:電腦端不顯示';

  @override
  String get reconnecting => '正在重新連線電腦…';

  @override
  String get pcLocked => '電腦已鎖定。解鎖後才能繼續控制此視窗。';

  @override
  String get composeHint => '輸入要傳給此視窗的訊息';

  @override
  String get sendWithEnter => '以 Enter 傳送';

  @override
  String get settingsTitle => '設定';

  @override
  String get secThisPhone => '本機';

  @override
  String get phoneName => '手機名稱';

  @override
  String get phoneNameSub => '配對時顯示在電腦上';

  @override
  String get secAppearance => '外觀';

  @override
  String get theme => '佈景主題';

  @override
  String get themeSystem => '依系統設定';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '依系統設定';

  @override
  String get secTouch => '觸控與輸入';

  @override
  String get defaultTouch => '預設觸控模式';

  @override
  String get defaultTouchSub => '「僅檢視」不會在電腦產生點擊;「點按」會將點按變成點擊';

  @override
  String get composeMode => '編寫模式';

  @override
  String get composeModeSub => '先寫好完整訊息(含自動校正),再一次傳送。關閉:每個按鍵即時傳送到電腦。';

  @override
  String get returnSends => 'Enter 鍵送出';

  @override
  String get enterKeyEnter => 'Enter';

  @override
  String get enterKeyCtrlEnter => 'Ctrl+Enter';

  @override
  String get vibrate => '快捷鍵震動';

  @override
  String get secQuickKeys => '快捷鍵';

  @override
  String get secPicture => '畫面';

  @override
  String get textSize => '文字大小';

  @override
  String get stealthDefault => '預設在電腦上隱藏視窗';

  @override
  String get stealthDefaultSub => '隱形模式。仍可個別切換。';

  @override
  String get keepScreenOn => '控制時保持螢幕恆亮';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get hideKeyboard => '收起鍵盤';

  @override
  String get showKeyboard => '開啟鍵盤';

  @override
  String get qkNewLine => '換行';

  @override
  String get qkPaste => '貼上';

  @override
  String get qkPageUp => '上一頁';

  @override
  String get qkPageDown => '下一頁';

  @override
  String get qkDelete => '刪除';

  @override
  String get secStream => '畫面傳輸';

  @override
  String get rxFps => '接收幀率';

  @override
  String get rxFpsSub => '越低越省網路,畫面越不連貫';

  @override
  String get rxScale => '接收解析度';

  @override
  String get rxScaleSub => '畫面越小,流量越省';

  @override
  String get rxGray => '灰階模式';

  @override
  String get rxGraySub => '黑白畫面,大幅節省流量';

  @override
  String get switchIme => '切換輸入法';
}
