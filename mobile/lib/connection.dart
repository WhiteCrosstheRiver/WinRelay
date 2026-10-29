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
  String? message;
  String hostName = '';

  List<WinInfo> windows = [];
  final Map<int, Uint8List> thumbs = {};
  final Set<int> _thumbAsked = {};

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
    message = null;
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
      message = "Couldn't reach ${pc.name}. Check that the PC is on, WinRelay is running, and you're on a network that can reach it.";
      _notify();
    }
  }

  void _onDone() {
    if (_disposed) return;
    if (state != ConnState.failed) {
      state = ConnState.failed;
      message ??= 'The connection to ${pc.name} dropped.';
    }
    _notify();
  }

  void _onData(dynamic data) {
    if (data is String) {
      _onJson(jsonDecode(data) as Map<String, dynamic>);
      return;
    }
    final b = data is Uint8List ? data : Uint8List.fromList(List<int>.from(data as List));
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
        message = null;
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
        message = m['reason'] as String?;
        if (message != null && message!.contains('Pair it again')) {
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

  void open(int id, {required bool stealth, required Map<String, double> viewport, required double scale}) {
    _reopen = {'t': 'open', 'id': id, 'stealth': stealth, 'viewport': viewport, 'scale': scale};
    openId = id;
    _send(_reopen!);
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
  void scroll(int dy) => _send({'t': 'scroll', 'dy': dy});

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
    super.dispose();
  }
}
