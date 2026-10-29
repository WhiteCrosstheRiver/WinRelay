/// A paired (or pairing) PC.
class PcEntry {
  PcEntry({required this.id, required this.name, required this.host, required this.port, this.token, this.secret});

  final String id;
  String name;
  String host;
  int port;

  /// One-time pairing token from the link. Cleared once the PC approves us.
  String? token;

  /// This phone's own key for this PC, issued on approval.
  String? secret;

  bool get isPaired => secret != null;

  Uri get wsUri => Uri.parse('ws://${host.contains(':') ? '[$host]' : host}:$port/ws');

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'host': host, 'port': port, 'token': token, 'secret': secret};

  factory PcEntry.fromJson(Map<String, dynamic> j) => PcEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        host: j['host'] as String,
        port: j['port'] as int,
        token: j['token'] as String?,
        secret: j['secret'] as String?,
      );
}

/// Parses `winrelay://pair?h=<host>&p=<port>&k=<token>&n=<name>`.
PcEntry? parsePairLink(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != 'winrelay' || uri.host != 'pair') return null;
  final q = uri.queryParameters;
  final host = q['h'], token = q['k'];
  final port = int.tryParse(q['p'] ?? '');
  if (host == null || host.isEmpty || token == null || port == null) return null;
  final name = (q['n'] ?? '').isEmpty ? host : q['n']!;
  return PcEntry(id: '$host:$port', name: name, host: host, port: port, token: token);
}

class WinInfo {
  WinInfo({required this.id, required this.title, required this.app, required this.exe});
  final int id;
  final String title, app, exe;

  factory WinInfo.fromJson(Map<String, dynamic> j) => WinInfo(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String? ?? '',
        app: j['app'] as String? ?? '',
        exe: j['exe'] as String? ?? '',
      );
}

/// Executable names (lowercase, without .exe) of browsers the PC recognizes.
/// Keep in sync with the host's list in host/src/browser.rs.
const browserExes = <String>{
  // Chromium family, international
  'chrome', 'msedge', 'brave', 'vivaldi', 'opera', 'arc', 'duckduckgo', 'chromium',
  'thorium', 'slimjet', 'iridium', 'centbrowser', 'whale', 'yandex', 'browser',
  // Firefox family
  'firefox', 'zen', 'waterfox', 'librewolf', 'palemoon',
  // Chinese browsers
  'qqbrowser', '360se', '360chrome', 'maxthon', 'sogouexplorer', 'baidubrowser',
  'ucbrowser', 'liebao', '2345explorer', 'twinkstar', 'quark-browser', 'quarkpc',
};

/// True when a window's exe belongs to a browser the app can take over in
/// Web mode (the page opens in a phone-native WebView).
bool isBrowserExe(String exe) {
  final e = exe.toLowerCase();
  return browserExes.contains(e.endsWith('.exe') ? e.substring(0, e.length - 4) : e);
}

/// Every quick key the bar can show, in display order: id -> label.
const allQuickKeys = <String, String>{
  'esc': 'Esc',
  'tab': 'Tab',
  'shift_tab': 'Shift+Tab',
  'ctrl_c': 'Ctrl+C',
  'up': '↑',
  'down': '↓',
  'left': '←',
  'right': '→',
  'shift_enter': 'New line',
  'paste': 'Paste',
  'ctrl_v': 'Ctrl+V',
  'ctrl_z': 'Ctrl+Z',
  'home': 'Home',
  'end': 'End',
  'pgup': 'Page up',
  'pgdn': 'Page down',
  'delete': 'Delete',
};

class AppSettings {
  String deviceName = 'My phone';
  bool tapModeDefault = false; // false = View mode
  bool composeMode = false; // false = Live keys
  String enterKey = 'enter'; // or 'ctrl_enter'
  bool stealthDefault = false;
  double textSize = 1.0; // 0.75 .. 2.0
  bool keepScreenOn = true;
  bool haptics = true;
  List<String> quickKeys = ['esc', 'tab', 'shift_tab', 'ctrl_c', 'up', 'down', 'left', 'right', 'shift_enter', 'paste'];
  String themeMode = 'system'; // system | light | dark
  String language = 'system'; // system | BCP47 code with '_' separator, e.g. zh_TW

  /// Stream tuning for the received picture (saves bandwidth):
  /// capture fps, picture downscale (1.0 = full), grayscale mode.
  int rxFps = 15; // 5 | 10 | 15 | 30
  double rxScale = 1.0; // 1.0 | 0.75 | 0.5
  bool rxGray = false;

  /// PC window logical size = phone size x this. Bigger text on the phone = smaller PC window.
  double get windowScale => 1.25 / textSize;

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'tapModeDefault': tapModeDefault,
        'composeMode': composeMode,
        'enterKey': enterKey,
        'stealthDefault': stealthDefault,
        'textSize': textSize,
        'keepScreenOn': keepScreenOn,
        'haptics': haptics,
        'quickKeys': quickKeys,
        'themeMode': themeMode,
        'language': language,
        'rxFps': rxFps,
        'rxScale': rxScale,
        'rxGray': rxGray,
      };

  static AppSettings fromJson(Map<String, dynamic> j) {
    final s = AppSettings();
    s.deviceName = j['deviceName'] as String? ?? s.deviceName;
    s.tapModeDefault = j['tapModeDefault'] as bool? ?? s.tapModeDefault;
    s.composeMode = j['composeMode'] as bool? ?? s.composeMode;
    s.enterKey = j['enterKey'] as String? ?? s.enterKey;
    s.stealthDefault = j['stealthDefault'] as bool? ?? s.stealthDefault;
    s.textSize = (j['textSize'] as num?)?.toDouble() ?? s.textSize;
    s.keepScreenOn = j['keepScreenOn'] as bool? ?? s.keepScreenOn;
    s.haptics = j['haptics'] as bool? ?? s.haptics;
    s.quickKeys = (j['quickKeys'] as List?)?.cast<String>() ?? s.quickKeys;
    s.themeMode = j['themeMode'] as String? ?? s.themeMode;
    s.language = j['language'] as String? ?? s.language;
    s.rxFps = (j['rxFps'] as num?)?.toInt() ?? s.rxFps;
    s.rxScale = (j['rxScale'] as num?)?.toDouble() ?? s.rxScale;
    s.rxGray = j['rxGray'] as bool? ?? s.rxGray;
    return s;
  }
}
