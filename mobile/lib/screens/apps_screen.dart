import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../connection.dart';
import '../l10n/generated/app_localizations.dart';
import '../models.dart';

/// Win+S-style launcher for the controlled PC: search Start-Menu apps with
/// live candidates, launch one, or close it (all its windows, gracefully).
class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key, required this.conn});

  final HostConnection conn;

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  StreamSubscription? _sub;
  StreamSubscription? _resultSub;
  bool _disposed = false;

  HostConnection get conn => widget.conn;

  @override
  void initState() {
    super.initState();
    conn.addListener(_onConnChanged);
    _resultSub = conn.appsEvents.stream.listen(_onResult);
    _searchNow('');
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _sub?.cancel();
    _resultSub?.cancel();
    conn.removeListener(_onConnChanged);
    _q.dispose();
    super.dispose();
  }

  void _onConnChanged() {
    if (!_disposed && mounted) setState(() {});
  }

  void _onResult(Map<String, dynamic> m) {
    if (_disposed || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = m['ok'] == true;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appDone)));
      // Refresh candidates so running badges reflect the change.
      _searchNow(_q.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((m['error'] as String?) ?? l10n.transferFailed)),
      );
    }
  }

  void _onQuery(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!_disposed && mounted) _searchNow(v);
    });
  }

  void _searchNow(String q) => conn.appsSearch(q);

  Future<void> _launch(AppInfo a) async {
    HapticFeedback.selectionClick();
    conn.appLaunch(a.path);
  }

  Future<void> _confirmClose(AppInfo a) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.closeAppTitle),
        content: Text(l10n.closeAppBody(a.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.appClose)),
        ],
      ),
    );
    if (ok == true) conn.appClose(a.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apps = conn.apps;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appsTitle)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _q,
            onChanged: _onQuery,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchApps,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: apps.isEmpty
              ? Center(child: Text(l10n.appsEmpty))
              : RefreshIndicator(
                  onRefresh: () async => _searchNow(_q.text),
                  child: ListView.separated(
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final a = apps[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(a.name.isNotEmpty ? a.name[0].toUpperCase() : '?'),
                        ),
                        title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: a.running ? Text(l10n.running) : null,
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            tooltip: l10n.appOpen,
                            onPressed: () => _launch(a),
                          ),
                          if (a.running)
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: l10n.appClose,
                              onPressed: () => _confirmClose(a),
                            ),
                        ]),
                        onTap: () => _launch(a),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }
}
