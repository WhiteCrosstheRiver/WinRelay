import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models.dart';
import 'store.dart';

enum ConnState { connecting, waitingApproval, ready, failed }

class Frame {
  Frame(this.w, this.h, this.jpeg);
  final int w, h;
  final Uint8List jpeg;
}

/// One connection to one PC. Text frames are JSON; binary frames are
/// [kind u8][window id u64 LE][w u32 LE][h u32 LE][JPEG].
class HostConnection extends ChangeNotifier {
  HostConnection(this.pc);

  final PcEntry pc;
  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _ping;

  ConnState state = ConnState.connecting;
  /// Why we are in the failed state, so the UI can show a localized message:
  /// 'unreachable' | 'dropped' | 'server'.
  String? failKind;
  String? serverMessage;
  String hostName = '';

  List<WinInfo> windows = [];
  final Map<int, Uint8List> thumbs = {};
  final Set<int> _thumbAsked = {};

  /// Current page of the controlled browser window, pushed by the PC when a
  /// browser session opens and after each `get_url`. Null for non-browsers.
  String? browserUrl;

  /// File-transfer events (fs_entries / fs_meta / fs_done / fs_chunk) for the
  /// Files screen; broadcast because only that screen listens.
  final fsEvents = StreamController<Map<String, dynamic>>.broadcast();
  /// Clipboard-relay events (clip_text / clip_ok).
  final clipEvents = StreamController<Map<String, dynamic>>.broadcast();
  /// App-launcher events (apps / app_result) for the launcher screen.
  final appsEvents = StreamController<Map<String, dynamic>>.broadcast();
  /// Latest app-launcher candidates (matching the query last sent).
  List<AppInfo> apps = [];
  Completer<String>? _clipGetPending;
  Completer<bool>? _clipSetPending;

  /// Video frames bypass notifyListeners so only the picture repaints.
  final ValueNotifier<Frame?> frame = ValueNotifier(null);
  int? openId;
  String openTitle = '';
  bool openStealth = false;
  bool locked = false;

  /// Called when the PC ends the session (window closed, kicked, idle).
  void Function(String reason)? onSessionClosed;

  /// Called for errors worth showing as a snackbar.
  void Function(String msg)? onError;

  /// The last open request, replayed automatically after a reconnect.
  Map<String, dynamic>? _reopen;

  bool _disposed = false;

  Future<void> connect() async {
    await _teardown();
    state = ConnState.connecting;
    failKind = null;
    serverMessage = null;
    _notify();
    try {
      final ch = WebSocketChannel.connect(pc.wsUri);
      await ch.ready.timeout(const Duration(seconds: 8));
      _ch = ch;
      _sub = ch.stream.listen(_onData, onDone: _onDone, onError: (_) => _onDone());
      final s = Store.I;
      _send({
        't': 'hello',
        'device_id': s.deviceId,
        'device_name': s.settings.deviceName,
        if (pc.secret != null) 'secret': pc.secret,
        if (pc.secret == null && pc.token != null) 'token': pc.token,
      });
      _ping = Timer.periodic(const Duration(seconds: 10), (_) => _send({'t': 'ping'}));
    } catch (_) {
      state = ConnState.failed;
      failKind = 'unreachable';
      _notify();
    }
  }

  void _onDone() {
    if (_disposed) return;
    if (state != ConnState.failed) {
      state = ConnState.failed;
      failKind ??= 'dropped';
    }
    _notify();
  }

  void _onData(dynamic data) {
    if (data is String) {
      _onJson(jsonDecode(data) as Map<String, dynamic>);
      return;
    }
    final b = data is Uint8List ? data : Uint8List.fromList(List<int>.from(data as List));
    if (b.length >= 25 && (b[0] == 3 || b[0] == 4)) {
      // File-transfer chunk: [kind][id u64][offset u64][total u64][data].
      final fd = ByteData.sublistView(b);
      fsEvents.add({
        't': 'fs_chunk',
        'kind': b[0],
        'id': fd.getUint64(1, Endian.little),
        'offset': fd.getUint64(9, Endian.little),
        'total': fd.getUint64(17, Endian.little),
        'data': Uint8List.sublistView(b, 25),
      });
      return;
    }
    if (b.length < 17) return;
    final bd = ByteData.sublistView(b);
    final kind = bd.getUint8(0);
    final id = bd.getUint64(1, Endian.little);
    final w = bd.getUint32(9, Endian.little);
    final h = bd.getUint32(13, Endian.little);
    final jpeg = Uint8List.sublistView(b, 17);
    if (kind == 1 && id == openId) {
      frame.value = Frame(w, h, jpeg);
    } else if (kind == 2) {
      thumbs[id] = jpeg;
      _notify();
    }
  }

  void _onJson(Map<String, dynamic> m) {
    switch (m['t']) {
      case 'welcome':
        state = ConnState.ready;
        hostName = m['host'] as String? ?? '';
        failKind = null;
        serverMessage = null;
        list();
        if (_reopen != null) _send(_reopen!);
      case 'pending':
        state = ConnState.waitingApproval;
      case 'approved':
        pc.secret = m['secret'] as String;
        pc.token = null;
        Store.I.savePc(pc);
      case 'denied':
        state = ConnState.failed;
        failKind = 'server';
        serverMessage = m['reason'] as String?;
        if (serverMessage != null && serverMessage!.contains('Pair it again')) {
          pc.secret = null; // the PC forgot us; the next attempt needs a fresh link
        }
      case 'windows':
        windows = (m['items'] as List).map((e) => WinInfo.fromJson(e as Map<String, dynamic>)).toList();
      case 'opened':
        openId = (m['id'] as num).toInt();
        openTitle = m['title'] as String? ?? '';
        openStealth = m['stealth'] as bool? ?? false;
        locked = false;
      case 'closed':
        final reason = m['reason'] as String? ?? '';
        openId = null;
        frame.value = null;
        if (reason != 'closed') {
          _reopen = null;
          onSessionClosed?.call(reason);
        }
      case 'locked':
        locked = m['locked'] as bool? ?? false;
      case 'url':
        browserUrl = m['url'] as String?;
      case 'fs_entries' || 'fs_meta' || 'fs_done' || 'fs_upload_ready':
        fsEvents.add(m);
      case 'clip_text':
        _clipGetPending?.complete(m['s'] as String? ?? '');
        _clipGetPending = null;
        clipEvents.add(m);
      case 'clip_ok':
        _clipSetPending?.complete(true);
        _clipSetPending = null;
        clipEvents.add(m);
      case 'apps':
        if (m['q'] == _appsQuery) {
          apps = (m['items'] as List).map((e) => AppInfo.fromJson(e as Map<String, dynamic>)).toList();
          notifyListeners();
        }
      case 'app_result':
        appsEvents.add(m);
      case 'error':
        final msg = m['msg'] as String? ?? 'Something went wrong on the PC.';
        _reopen = null;
        onError?.call(msg);
      case 'pong':
        return;
    }
    _notify();
  }

  // ---- requests ----

  void list() => _send({'t': 'list'});

  void requestThumb(int id) {
    if (_thumbAsked.add(id)) _send({'t': 'thumb', 'id': id});
  }

  void refreshThumbs() {
    _thumbAsked.clear();
    thumbs.clear();
  }

  /// Opens a window. `rxFps`/`rxScale`/`rxGray` are the phone's stream-tuning
  /// settings; the host keeps applying them on every reconnect (they ride in
  /// the open request, which is replayed after a drop).
  void open(
    int id, {
    required bool stealth,
    required Map<String, double> viewport,
    required double scale,
    int? rxFps,
    double? rxScale,
    bool? rxGray,
    bool? rxBw,
  }) {
    _reopen = {
      't': 'open',
      'id': id,
      'stealth': stealth,
      'viewport': viewport,
      'scale': scale,
      if (rxFps != null) 'fps': rxFps,
      if (rxScale != null) 'pic_scale': rxScale,
      if (rxGray != null) 'gray': rxGray,
      if (rxBw != null) 'bw': rxBw,
    };
    openId = id;
    _send(_reopen!);
  }

  /// Live retune of the stream while a session runs.
  void setStream({int? fps, double? picScale, bool? gray}) {
    _send({
      't': 'stream',
      if (fps != null) 'fps': fps,
      if (picScale != null) 'pic_scale': picScale,
      if (gray != null) 'gray': gray,
    });
  }

  /// Points the PC's browser at [url] (the phone's web view navigated).
  void navigate(String url) => _send({'t': 'navigate', 'url': url});

  /// Asks the PC to re-read the browser's current page (HostMsg::Url).
  void requestUrl() => _send({'t': 'get_url'});

  // ---- file access ----
  /// Debug tracer: the host logs every text frame it receives, even
  /// unparseable ones, so this shows up in the host log verbatim.
  void trace(String s) => _send({'t': s});

  void fsList(String path) => _send({'t': 'fs_list', 'path': path});
  void fsMkdir(String path) => _send({'t': 'fs_mkdir', 'path': path});
  void fsDelete(String path) => _send({'t': 'fs_delete', 'path': path});
  void fsDownload(int id, String path) => _send({'t': 'fs_download', 'id': id, 'path': path});
  void fsUploadBegin(int id, String path, int size) =>
      _send({'t': 'fs_upload_begin', 'id': id, 'path': path, 'size': size});
  Future<void> fsUploadChunk(int id, int offset, int total, Uint8List data) async {
    final frame = Uint8List(25 + data.length);
    final bd = ByteData.view(frame.buffer);
    bd.setUint8(0, 4);
    bd.setUint64(1, id, Endian.little);
    bd.setUint64(9, offset, Endian.little);
    bd.setUint64(17, total, Endian.little);
    frame.setRange(25, frame.length, data);
    _ch?.sink.add(frame);
  }

  void fsUploadEnd(int id) => _send({'t': 'fs_upload_end', 'id': id});

  // ---- app launcher ----
  String _appsQuery = '';

  /// Searches Start-Menu apps on the PC; results arrive via [apps].
  void appsSearch(String q) {
    _appsQuery = q;
    _send({'t': 'apps_search', 'q': q});
  }

  void appLaunch(String path) => _send({'t': 'app_launch', 'path': path});

  void appClose(String name) => _send({'t': 'app_close', 'name': name});

  // ---- clipboard relay (phone bridges two PCs) ----

  /// Reads this PC's clipboard text. Resolves '' when it holds no text.
  Future<String> clipGet() async {
    _clipGetPending?.complete('');
    final c = Completer<String>();
    _clipGetPending = c;
    _send({'t': 'clip_get'});
    return c.future.timeout(const Duration(seconds: 6), onTimeout: () => '');
  }

  /// Writes this PC's clipboard. The caller then sends Ctrl+V to paste.
  Future<bool> clipSet(String s) async {
    _clipSetPending?.complete(false);
    final c = Completer<bool>();
    _clipSetPending = c;
    _send({'t': 'clip_set', 's': s});
    return c.future.timeout(const Duration(seconds: 6), onTimeout: () => false);
  }

  void setViewport(Map<String, double> viewport) {
    if (_reopen != null) _reopen!['viewport'] = viewport;
    _send({'t': 'viewport', 'viewport': viewport});
  }

  void close() {
    _reopen = null;
    openId = null;
    frame.value = null;
    _send({'t': 'close'});
  }

  void text(String s) => _send({'t': 'text', 's': s});
  void key(String k) => _send({'t': 'key', 'k': k});
  void tap(double x, double y, String kind) => _send({'t': 'tap', 'x': x, 'y': y, 'kind': kind});
  void scroll(int dy, {double? x, double? y}) => _send({'t': 'scroll', 'dy': dy, if (x != null) 'x': x, if (y != null) 'y': y});

  void _send(Map<String, dynamic> m) {
    try {
      _ch?.sink.add(jsonEncode(m));
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _teardown() async {
    _ping?.cancel();
    await _sub?.cancel();
    await _ch?.sink.close();
    _ch = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _teardown();
    frame.dispose();
    fsEvents.close();
    clipEvents.close();
    appsEvents.close();
    super.dispose();
  }
}
