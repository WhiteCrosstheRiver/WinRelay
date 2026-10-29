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
  StreamSubscription? _sub;
  String _status = '';

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
    // The PC can navigate by itself; follow it when it announces a new URL.
    widget.conn.addListener(_onConnChanged);
  }

  @override
  void dispose() {
    widget.conn.removeListener(_onConnChanged);
    _sub?.cancel();
    super.dispose();
  }

  void _onConnChanged() {
    final url = widget.conn.browserUrl;
    if (url != null && url != _loaded) _load(url);
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
    if (mounted) setState(() => _status = url);
  }

  void _onPageFinished(String url) {
    if (mounted) setState(() => _status = url);
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
                icon: const Icon(Icons.sync),
                tooltip: l10n.loadFromPc,
                onPressed: _loadFromPc,
              ),
              Expanded(
                child: Text(
                  _status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
