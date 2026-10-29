import 'package:flutter/material.dart';

import '../connection.dart';
import '../models.dart';
import '../store.dart';
import 'control_screen.dart';
import 'settings_screen.dart';

class WindowsScreen extends StatefulWidget {
  const WindowsScreen({super.key, required this.pc});
  final PcEntry pc;

  @override
  State<WindowsScreen> createState() => _WindowsScreenState();
}

class _WindowsScreenState extends State<WindowsScreen> {
  late final HostConnection conn;
  String _query = '';
  late bool _stealth;

  @override
  void initState() {
    super.initState();
    _stealth = Store.I.settings.stealthDefault;
    conn = HostConnection(widget.pc)..addListener(_changed);
    conn.onError = (msg) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    };
    conn.connect();
  }

  @override
  void dispose() {
    conn.removeListener(_changed);
    conn.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _refresh() async {
    conn.refreshThumbs();
    conn.list();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _openWindow(WinInfo w) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ControlScreen(conn: conn, win: w, stealth: _stealth),
    ));
    // Back from control: the window has returned to its place on the PC.
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pc.name),
        actions: [
          if (conn.state == ConnState.ready)
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _refresh),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: switch (conn.state) {
        ConnState.connecting => _centered(
            icon: null,
            title: 'Connecting to ${widget.pc.name}…',
            body: null,
          ),
        ConnState.waitingApproval => _centered(
            icon: Icons.verified_user_outlined,
            title: 'Approve this phone on your PC',
            body: 'Open WinRelay on the PC and click Approve next to "${Store.I.settings.deviceName}".',
          ),
        ConnState.failed => _centered(
            icon: Icons.cloud_off_outlined,
            title: "Can't connect",
            body: conn.message,
            action: FilledButton(onPressed: conn.connect, child: const Text('Try again')),
          ),
        ConnState.ready => _list(context),
      },
    );
  }

  Widget _centered({IconData? icon, required String title, String? body, Widget? action}) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon == null) const CircularProgressIndicator() else Icon(icon, size: 48),
          const SizedBox(height: 20),
          Text(title, style: t.titleLarge, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body, style: t.bodyMedium, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 20), action],
        ]),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final q = _query.toLowerCase();
    final items = conn.windows
        .where((w) => q.isEmpty || w.title.toLowerCase().contains(q) || w.app.toLowerCase().contains(q))
        .toList();

    // Group by app, keeping the host's alphabetical order.
    final groups = <String, List<WinInfo>>{};
    for (final w in items) {
      groups.putIfAbsent(w.app, () => []).add(w);
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SearchBar(
          hintText: 'Search windows',
          leading: const Icon(Icons.search),
          elevation: const WidgetStatePropertyAll(0),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      SwitchListTile(
        title: const Text('Hide the window on the PC'),
        subtitle: const Text("Stealth: the PC's screen won't show it while you control it"),
        value: _stealth,
        onChanged: (v) => setState(() => _stealth = v),
      ),
      const Divider(height: 1),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: items.isEmpty
              ? ListView(children: const [
                  Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No windows match. Pull down to refresh.'))),
                ])
              : ListView(children: [
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    for (final w in entry.value) _tile(w),
                  ],
                  const SizedBox(height: 24),
                ]),
        ),
      ),
    ]);
  }

  Widget _tile(WinInfo w) {
    conn.requestThumb(w.id);
    final thumb = conn.thumbs[w.id];
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 72,
          height: 48,
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: thumb == null
              ? Text(w.app.isEmpty ? '?' : w.app[0], style: TextStyle(color: scheme.onSurfaceVariant))
              : Image.memory(thumb, fit: BoxFit.cover, width: 72, height: 48, gaplessPlayback: true),
        ),
      ),
      title: Text(w.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(w.exe, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _openWindow(w),
    );
  }
}
