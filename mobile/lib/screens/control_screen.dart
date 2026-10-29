import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../connection.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/live_keyboard.dart';
import '../widgets/quick_keys.dart';
import '../widgets/video_view.dart';
import 'settings_screen.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key, required this.conn, required this.win, required this.stealth});
  final HostConnection conn;
  final WinInfo win;
  final bool stealth;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> with WidgetsBindingObserver {
  final _kbFocus = FocusNode();
  final _compose = TextEditingController();
  late bool _tapMode;
  bool _opened = false;
  Orientation? _orientation;
  Timer? _rotateDebounce;
  void Function(String)? _prevOnError;

  HostConnection get conn => widget.conn;
  AppSettings get settings => Store.I.settings;

  @override
  void initState() {
    super.initState();
    _tapMode = settings.tapModeDefault;
    WidgetsBinding.instance.addObserver(this);
    conn.addListener(_changed);
    _kbFocus.addListener(_changed);
    conn.onSessionClosed = (reason) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
      Navigator.of(context).maybePop();
    };
    _prevOnError = conn.onError;
    conn.onError = (msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (conn.openId == null || conn.frame.value == null) Navigator.of(context).maybePop();
    };
    if (settings.keepScreenOn) WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.orientationOf(context);
    if (!_opened) {
      _opened = true;
      _orientation = o;
      conn.open(widget.win.id, stealth: widget.stealth, viewport: _viewport(), scale: settings.windowScale);
    } else if (o != _orientation) {
      // Phone rotated: reshape the PC window. Keyboard show/hide is ignored on purpose.
      _orientation = o;
      _rotateDebounce?.cancel();
      _rotateDebounce = Timer(const Duration(milliseconds: 400), () {
        if (mounted) conn.setViewport(_viewport());
      });
    }
  }

  /// The area the picture gets: full screen minus app bar and quick keys.
  /// Uses the whole screen, not the space left by the keyboard, so the PC
  /// window doesn't reshape every time the keyboard opens.
  Map<String, double> _viewport() {
    final mq = MediaQuery.of(context);
    final chrome = kToolbarHeight + 52 + mq.padding.top + mq.padding.bottom;
    return {'w': mq.size.width, 'h': (mq.size.height - chrome).clamp(200, 4000).toDouble(), 'dpr': mq.devicePixelRatio};
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // Back from another app: reconnect if the link dropped. The connection
    // re-opens this window by itself once the PC says hello.
    if (s == AppLifecycleState.resumed && conn.state == ConnState.failed) conn.connect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    conn.removeListener(_changed);
    conn.onSessionClosed = null;
    conn.onError = _prevOnError;
    _rotateDebounce?.cancel();
    conn.close();
    WakelockPlus.disable();
    _kbFocus.dispose();
    _compose.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _quickKey(String k) async {
    if (k == 'paste') {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null && text.isNotEmpty) conn.text(text);
    } else {
      conn.key(k);
    }
  }

  void _toggleKeyboard() {
    if (_kbFocus.hasFocus) {
      _kbFocus.unfocus();
    } else {
      _kbFocus.requestFocus();
    }
  }

  void _sendCompose() {
    final text = _compose.text;
    if (text.isEmpty) return;
    conn.text(text);
    conn.key(settings.enterKey);
    _compose.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = conn.openTitle.isNotEmpty ? conn.openTitle : widget.win.title;
    final reconnecting = conn.state != ConnState.ready;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.stealth)
            const Tooltip(
              message: 'Stealth: hidden on the PC',
              child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.visibility_off_outlined)),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('View'), tooltip: 'Look only: taps do nothing on the PC'),
                ButtonSegment(value: true, label: Text('Tap'), tooltip: 'Taps click on the PC'),
              ],
              selected: {_tapMode},
              onSelectionChanged: (v) => setState(() => _tapMode = v.first),
            ),
          ),
        ],
      ),
      body: Column(children: [
        if (reconnecting)
          _Notice(color: scheme.secondaryContainer, text: 'Reconnecting to the PC…'),
        if (conn.locked)
          _Notice(color: scheme.errorContainer, text: 'The PC is locked. Unlock it to keep controlling this window.'),
        Expanded(child: VideoView(conn: conn, tapMode: _tapMode)),
        if (settings.composeMode)
          _ComposeBar(controller: _compose, onSend: _sendCompose)
        else
          LiveKeyboard(
            focusNode: _kbFocus,
            enterKey: settings.enterKey,
            onText: conn.text,
            onKey: conn.key,
          ),
        QuickKeysBar(
          keys: settings.quickKeys,
          onKey: _quickKey,
          haptics: settings.haptics,
          keyboardOpen: settings.composeMode ? false : _kbFocus.hasFocus,
          onToggleKeyboard: settings.composeMode ? () => FocusScope.of(context).unfocus() : _toggleKeyboard,
          onLongPress: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ]),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(text),
      );
}

/// Compose mode: write the whole message first (with autocorrect), then send it with Enter.
class _ComposeBar extends StatelessWidget {
  const _ComposeBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Write a message for this window',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(icon: const Icon(Icons.send), tooltip: 'Send with Enter', onPressed: onSend),
      ]),
    );
  }
}
