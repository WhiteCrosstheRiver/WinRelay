import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../connection.dart';
import '../l10n/generated/app_localizations.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/live_keyboard.dart';
import '../widgets/web_pane.dart';
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
  /// Browser windows start in web mode (the whole point: the page renders
  /// natively on the phone); the video stream is one tap away. Non-browser
  /// windows never enter web mode.
  late bool _webMode;
  Orientation? _orientation;
  Timer? _rotateDebounce;
  void Function(String)? _prevOnError;

  HostConnection get conn => widget.conn;
  AppSettings get settings => Store.I.settings;

  @override
  void initState() {
    super.initState();
    _tapMode = settings.tapModeDefault;
    _webMode = isBrowserExe(widget.win.exe);
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
      conn.open(
        widget.win.id,
        stealth: widget.stealth,
        viewport: _viewport(),
        scale: settings.windowScale,
        rxFps: settings.rxFps,
        rxScale: settings.rxScale,
        rxGray: settings.rxColorMode == 'gray',
        rxBw: settings.rxColorMode == 'bw',
      );
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

  /// Clipboard relay, copy side: grab the controlled PC's clipboard text into
  /// the phone buffer (and the phone's own clipboard for reuse anywhere).
  Future<void> _clipCopy() async {
    final l10n = AppLocalizations.of(context)!;
    final text = await conn.clipGet();
    Store.I.clipBuffer = text;
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text.isEmpty ? l10n.clipEmpty : l10n.clipCopied(text.length))),
      );
    }
  }

  /// Clipboard relay, paste side: write the relayed text into this PC's
  /// clipboard, then Ctrl+V lands it in the focused window (a dialog, say).
  Future<void> _clipPaste() async {
    final l10n = AppLocalizations.of(context)!;
    final text = Store.I.clipBuffer;
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.clipEmpty)));
      }
      return;
    }
    final ok = await conn.clipSet(text);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.transferFailed)));
      }
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    conn.key('ctrl_v');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.clipPasted)));
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
    final l10n = AppLocalizations.of(context)!;
    final title = conn.openTitle.isNotEmpty ? conn.openTitle : widget.win.title;
    final reconnecting = conn.state != ConnState.ready;
    final isBrowser = isBrowserExe(widget.win.exe);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.stealth)
            Tooltip(
              message: l10n.stealthTip,
              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.visibility_off_outlined)),
            ),
          // Browser windows: web view by default; this toggles to the raw
          // video stream for touching the browser chrome itself.
          if (isBrowser)
            IconButton(
              icon: Icon(_webMode ? Icons.desktop_windows_outlined : Icons.language),
              tooltip: _webMode ? l10n.pcScreen : l10n.webMode,
              onPressed: () => setState(() => _webMode = !_webMode),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.viewMode), tooltip: l10n.viewTip),
                ButtonSegment(value: true, label: Text(l10n.tapMode), tooltip: l10n.tapTip),
              ],
              selected: {_tapMode},
              onSelectionChanged: (v) => setState(() => _tapMode = v.first),
            ),
          ),
        ],
      ),
      body: isBrowser && _webMode
          ? WebPane(conn: conn)
          : Column(children: [
              if (reconnecting)
                _Notice(color: scheme.secondaryContainer, text: l10n.reconnecting),
              if (conn.locked)
                _Notice(color: scheme.errorContainer, text: l10n.pcLocked),
              Expanded(child: VideoView(conn: conn, tapMode: _tapMode)),
              if (settings.composeMode)
                _ComposeBar(controller: _compose, onSend: _sendCompose, hint: l10n.composeHint, sendTip: l10n.sendWithEnter)
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
                onClipCopy: _clipCopy,
                onClipPaste: _clipPaste,
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
  const _ComposeBar({required this.controller, required this.onSend, required this.hint, required this.sendTip});
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;
  final String sendTip;

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
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(icon: const Icon(Icons.send), tooltip: sendTip, onPressed: onSend),
      ]),
    );
  }
}
