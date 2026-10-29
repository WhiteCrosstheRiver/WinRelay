import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../connection.dart';
import '../l10n/generated/app_localizations.dart';

/// The phone-native view of a controlled browser's page: the PC's URL opens in
/// a real WebView with touch, zoom and the phone keyboard, and every finished
/// navigation is pushed back so the PC's browser follows along. "Read from PC"
/// pulls the page the PC has navigated to by itself.
class WebPane extends StatefulWidget {
  const WebPane({super.key, required this.conn});

  final HostConnection conn;

  @override
  State<WebPane> createState() => _WebPaneState();
}

class _WebPaneState extends State<WebPane> {
  late final WebViewController _controller;
  String? _loaded;
  /// Set when WE initiated a load (from the PC's url message): the page that
  /// finishes loading is the PC's own state, so don't echo it back.
  bool _suppressSync = false;
  Timer? _followTimer;
  bool _follow = true;
  final _addr = TextEditingController();
  final _addrFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: _onPageFinished,
      ));
    final android = _controller.platform;
    if (android is AndroidWebViewController) {
      android.setMediaPlaybackRequiresUserGesture(false);
    }
    _loadFromPc();
    // The PC can navigate by itself; poll its address bar so the phone
    // follows within a few seconds (switchable in the toolbar).
    widget.conn.addListener(_onConnChanged);
    _followTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_follow && mounted) widget.conn.requestUrl();
    });
  }

  @override
  void dispose() {
    _followTimer?.cancel();
    widget.conn.removeListener(_onConnChanged);
    _addr.dispose();
    _addrFocus.dispose();
    super.dispose();
  }

  void _onConnChanged() {
    final url = widget.conn.browserUrl;
    if (url == null || url == _loaded) return;
    // Don't stomp on the address bar while the user is typing in it.
    if (_addrFocus.hasFocus) {
      _loaded = url;
      return;
    }
    _load(url);
  }

  Future<void> _loadFromPc() async {
    widget.conn.requestUrl();
    // The answer arrives as a conn change; give it a moment, then sync.
    final url = widget.conn.browserUrl;
    if (url != null) _load(url);
  }

  Future<void> _load(String url) async {
    _loaded = url;
    _suppressSync = true;
    try {
      await _controller.loadRequest(Uri.parse(url));
    } catch (_) {
      _suppressSync = false;
    }
  }

  /// Address bar submit: a URL loads directly, anything else becomes a search.
  Future<void> _submitAddress(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final isUrl = t.startsWith('http://') ||
        t.startsWith('https://') ||
        (t.contains('.') && !t.contains(' '));
    final url = isUrl
        ? (t.startsWith('http') ? t : 'https://$t')
        : 'https://www.google.com/search?q=${Uri.encodeComponent(t)}';
    _addr.text = url;
    await _load(url);
  }


  void _onPageFinished(String url) {
    if (mounted && _addr.text != url) setState(() => _addr.text = url);
    if (_suppressSync) {
      _suppressSync = false;
      return;
    }
    if (url.startsWith('http')) widget.conn.navigate(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(children: [
      Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: SafeArea(
          top: false,
          bottom: false,
          child: SizedBox(
            height: 44,
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.goBack,
                onPressed: () => _controller.goBack(),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                tooltip: l10n.goForward,
                onPressed: () => _controller.goForward(),
              ),
              Expanded(
                child: TextField(
                  controller: _addr,
                  focusNode: _addrFocus,
                  onSubmitted: _submitAddress,
                  onTap: () {
                    // Browser convention: focusing the address bar selects the
                    // whole URL, so typing replaces it.
                    if (_addr.text.isNotEmpty) {
                      _addr.selection = TextSelection(baseOffset: 0, extentOffset: _addr.text.length);
                    }
                  },
                  autocorrect: false,
                  enableSuggestions: false,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.addressBarHint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_follow ? Icons.sync : Icons.sync_disabled),
                tooltip: l10n.followPc,
                onPressed: () => setState(() => _follow = !_follow),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refresh,
                onPressed: () => _controller.reload(),
              ),
            ]),
          ),
        ),
      ),
      Expanded(child: WebViewWidget(controller: _controller)),
    ]);
  }
}
