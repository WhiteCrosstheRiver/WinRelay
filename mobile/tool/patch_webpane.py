"""Patch web_pane.dart: editable address bar, back/forward, follow-PC polling."""
import io

p = 'lib/widgets/web_pane.dart'
s = io.open(p, encoding='utf-8').read()
orig = s

s = s.replace("""class _WebPaneState extends State<WebPane> {
  late final WebViewController _controller;
  String? _loaded;
  /// Set when WE initiated a load (from the PC's url message): the page that
  /// finishes loading is the PC's own state, so don't echo it back.
  bool _suppressSync = false;
  StreamSubscription? _sub;
  String _status = '';
""", """class _WebPaneState extends State<WebPane> {
  late final WebViewController _controller;
  String? _loaded;
  /// Set when WE initiated a load (from the PC's url message): the page that
  /// finishes loading is the PC's own state, so don't echo it back.
  bool _suppressSync = false;
  Timer? _followTimer;
  bool _follow = true;
  final _addr = TextEditingController();
""")

s = s.replace("""    _loadFromPc();
    // The PC can navigate by itself; follow it when it announces a new URL.
    widget.conn.addListener(_onConnChanged);
  }""", """    _loadFromPc();
    // The PC can navigate by itself; poll its address bar so the phone
    // follows within a few seconds (switchable in the toolbar).
    widget.conn.addListener(_onConnChanged);
    _followTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_follow && mounted) widget.conn.requestUrl();
    });
  }""")

s = s.replace("""  @override
  void dispose() {
    widget.conn.removeListener(_onConnChanged);
    _sub?.cancel();
    super.dispose();
  }""", """  @override
  void dispose() {
    _followTimer?.cancel();
    widget.conn.removeListener(_onConnChanged);
    super.dispose();
  }""")

s = s.replace("""  Future<void> _load(String url) async {
    _loaded = url;
    _suppressSync = true;
    try {
      await _controller.loadRequest(Uri.parse(url));
    } catch (_) {
      _suppressSync = false;
    }
    if (mounted) setState(() => _status = url);
  }""", """  Future<void> _load(String url) async {
    _loaded = url;
    _suppressSync = true;
    try {
      await _controller.loadRequest(Uri.parse(url));
    } catch (_) {
      _suppressSync = false;
    }
    if (mounted) setState(() => _status = url);
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
  }""")

s = s.replace("""              IconButton(
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
              ),""", """              IconButton(
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
                  onSubmitted: _submitAddress,
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
              ),""")

assert s != orig
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('web_pane patched')
