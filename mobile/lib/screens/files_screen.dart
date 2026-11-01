import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';

import '../connection.dart';
import '../l10n/generated/app_localizations.dart';
import '../store.dart';

/// Phone-side file manager for the PC: browse drives and folders like a
/// mobile file manager, upload files from this phone, download to the phone
/// and share anywhere.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key, required this.conn});

  final HostConnection conn;

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String path = '';
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String? busy;
  StreamSubscription? _fsSub;
  StreamSubscription? _uploadSub;
  int _nextId = 100;
  bool _disposed = false;
  /// Navigation history (per session, this screen).
  final List<String> _back = [];
  final List<String> _forward = [];
  /// Filled from the host's first listing so the screen opens on the PC's
  /// desktop instead of a bare drive list.
  String _desktopPath = '';
  bool _wantDesktop = true;
  Timer? _navTimeout;
  final Map<int, ({String file, int received, int total})> _downloads = {};
  final Map<int, String> _downloadNames = {};
  // Chunks must hit the disk strictly in offset order; the WS events arrive
  // in order but our disk writes are async, so chain them per download.
  final Map<int, RandomAccessFile> _dlRafs = {};
  final Map<int, Future<void>> _dlChains = {};

  HostConnection get conn => widget.conn;

  @override
  void initState() {
    super.initState();
    _fsSub = conn.fsEvents.stream.listen(_onFsEvent);
    // Remembered location wins; first open falls back to the PC's desktop.
    final saved = Store.I.lastDirByPc[conn.pc.id];
    _wantDesktop = (saved == null || saved.isEmpty);
    _fetch(saved ?? '');
  }

  @override
  void dispose() {
    _disposed = true;
    _navTimeout?.cancel();
    _fsSub?.cancel();
    _uploadSub?.cancel();
    super.dispose();
  }

  void _onFsEvent(Map<String, dynamic> m) {
    if (_disposed || !mounted) return;
    switch (m['t']) {
      case 'fs_entries':
        if (m['desktop'] != null && (m['desktop'] as String).isNotEmpty) {
          _desktopPath = m['desktop'] as String;
        }
        if ((m['path'] as String) == path) {
          if (_wantDesktop && path.isEmpty && _desktopPath.isNotEmpty) {
            _wantDesktop = false;
            _desktopPath = _desktopPath.replaceAll('/', String.fromCharCode(92));
            _fetch(_desktopPath);
            return;
          }
          _navTimeout?.cancel();
          Store.I.setLastDir(conn.pc.id, path);
          setState(() {
            items = (m['items'] as List).cast<Map<String, dynamic>>();
            loading = false;
          });
        }
      case 'fs_chunk':
        _onChunk(m);
      case 'fs_done':
        _onDone(m);
    }
  }

  void _fetch(String p, {bool push = true}) {
    setState(() {
      if (push && p != path) {
        _back.add(path);
        _forward.clear();
      }
      path = p;
      loading = true;
    });
    _navTimeout?.cancel();
    _navTimeout = Timer(const Duration(seconds: 4), () {
      if (mounted && loading) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.invalidPath)),
        );
      }
    });
    conn.fsList(p);
  }

  void _goBack() {
    if (_back.isEmpty) return;
    _forward.add(path);
    final p = _back.removeLast();
    _fetch(p, push: false);
  }

  void _goForward() {
    if (_forward.isEmpty) return;
    _back.add(path);
    final p = _forward.removeLast();
    _fetch(p, push: false);
  }

  Future<void> _jumpDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final c = TextEditingController(text: path);
    final dest = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.jumpPath),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: l10n.pathHint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l10n.save)),
        ],
      ),
    );
    if (dest != null && dest.isNotEmpty) _fetch(dest);
  }

  String _join(String dir, String name) => dir.isEmpty ? name : '$dir\\$name';

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  // ---- upload ----

  /// Bottom sheet listing this phone's Download/Documents; tapping a file
  /// uploads it into the folder the PC side is browsing. Reading the phone's
  /// shared storage directly needs the all-files-access permission.
  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context)!;
    const files = MethodChannel('winrelay/files');
    final granted = await files.invokeMethod<bool>('hasStorage') ?? false;
    if (!granted && mounted) {
      await files.invokeMethod('requestStorage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.grantStorage)));
      }
      return;
    }
    if (!mounted) return;
    final entries = <(String, File)>[];
    for (final dir in ['/sdcard/Download', '/sdcard/Documents']) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final e in d.listSync().whereType<File>()) {
        entries.add((e.uri.pathSegments.last, e));
      }
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<File>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.uploadFromPhone, style: Theme.of(ctx).textTheme.titleSmall),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Download / Documents')),
            ),
          for (final (name, f) in entries)
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(_sizeLabel(f.lengthSync())),
              onTap: () => Navigator.pop(ctx, f),
            ),
        ]),
      ),
    );
    if (picked == null || !mounted) return;
    _startUpload(picked, picked.uri.pathSegments.last);
  }

  void _startUpload(File f, String name) {
    final l10n = AppLocalizations.of(context)!;
    final id = _nextId++;
    final size = f.lengthSync();
    setState(() => busy = '${l10n.upload} · $name · 0%');
    var ready = false;
    _uploadSub?.cancel();
    _uploadSub = conn.fsEvents.stream.listen((m) {
      if (m['t'] == 'fs_upload_ready' && m['id'] == id && !ready) {
        ready = true;
        _streamUpload(id, f, size, name);
      }
      if (m['t'] == 'fs_done' && m['id'] == id && !ready) {
        _uploadSub?.cancel();
        setState(() => busy = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m['error'] ?? l10n.transferFailed)));
        }
      }
    });
    conn.fsUploadBegin(id, _join(path, name), size);
  }

  Future<void> _streamUpload(int id, File f, int size, String name) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      var sent = 0;
      await for (final chunk in f.openRead()) {
        await conn.fsUploadChunk(id, sent, size, Uint8List.fromList(chunk));
        sent += chunk.length;
        if (mounted) setState(() => busy = '${l10n.upload} · $name · ${(sent * 100 / size).round()}%');
      }
      conn.fsUploadEnd(id);
    } catch (e) {
      if (mounted) setState(() => busy = null);
      _uploadSub?.cancel();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    // fs_done closes the busy state via _onDone.
  }

  // ---- download ----

  Future<void> _download(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    // Save straight into the phone's Download folder (we already hold
    // all-files access); share stays available as a follow-up action.
    const files = MethodChannel('winrelay/files');
    final granted = await files.invokeMethod<bool>('hasStorage') ?? false;
    if (!granted) {
      await files.invokeMethod('requestStorage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.grantStorage)));
      }
      return;
    }
    final id = _nextId++;
    final name = item['name'] as String;
    final target = File('/sdcard/Download/$name');
    _downloads[id] = (file: target.path, received: 0, total: 0);
    _downloadNames[id] = name;
    _dlRafs[id] = target.openSync(mode: FileMode.write);
    setState(() => busy = '${l10n.download} · $name · 0%');
    conn.fsDownload(id, _join(path, name));
  }

  Future<void> _onChunk(Map<String, dynamic> m) async {
    if (m['kind'] != 3) return;
    final id = m['id'] as int;
    final dl = _downloads[id];
    final raf = _dlRafs[id];
    if (dl == null || raf == null) return;
    // Copy out of the message buffer, then serialize disk writes: event
    // delivery is ordered but our async writes would race on a big file.
    final data = Uint8List.fromList(m['data'] as Uint8List);
    final off = m['offset'] as int;
    final prev = _dlChains[id] ?? Future.value();
    _dlChains[id] = prev.then((_) async {
      await raf.setPosition(off);
      await raf.writeFrom(data);
    });
    final received = dl.received + data.length;
    final total = m['total'] as int;
    _downloads[id] = (file: dl.file, received: received, total: total);
    if (mounted && busy != null) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => busy = '${l10n.download} · ${_downloadNames[id]} · ${total > 0 ? (received * 100 / total).round() : 100}%');
    }
  }

  Future<void> _onDone(Map<String, dynamic> m) async {
    final id = m['id'] as int;
    final l10n = AppLocalizations.of(context)!;
    if (_downloads.containsKey(id)) {
      final dl = _downloads.remove(id)!;
      final name = _downloadNames.remove(id) ?? 'file';
      if (mounted) setState(() => busy = null);
      if (m['ok'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.savedTo(name)),
          action: SnackBarAction(
            label: l10n.openFile,
            onPressed: () => OpenFilex.open(dl.file),
          ),
        ));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m['error'] ?? l10n.transferFailed)));
      }
      return;
    }
    if (busy != null && m['ok'] == true) {
      _uploadSub?.cancel();
      if (mounted) setState(() => busy = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.transferDone)));
        _fetch(path);
      }
    } else if (busy != null && m['ok'] == false && m['error'] != null && mounted) {
      setState(() => busy = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m['error']!)));
    }
  }

  // ---- actions ----

  Future<void> _newFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newFolder),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: l10n.folderName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l10n.save)),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      conn.fsMkdir(_join(path, name));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _fetch(path);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final name = item['name'] as String;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteItem)),
        ],
      ),
    );
    if (ok == true) {
      conn.fsDelete(_join(path, name));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _fetch(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = path.isEmpty ? l10n.thisPc : (path.split('\\').lastWhere((s) => s.isNotEmpty, orElse: () => path));
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.goBack,
            onPressed: _back.isEmpty ? null : _goBack,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: l10n.goForward,
            onPressed: _forward.isEmpty ? null : _goForward,
          ),
          if (path.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: l10n.thisPc,
              onPressed: () => _fetch(''),
            ),
          IconButton(icon: const Icon(Icons.create_new_folder_outlined), tooltip: l10n.newFolder, onPressed: _newFolder),
          IconButton(icon: const Icon(Icons.refresh), tooltip: l10n.refresh, onPressed: () => _fetch(path)),
        ],
      ),
      body: Column(children: [
        if (path.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: _jumpDialog,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_location_alt_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(path, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ),
            ),
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? Center(child: Text(l10n.emptyDir))
                  : RefreshIndicator(
                      onRefresh: () async => _fetch(path),
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final it = items[i];
                          final isDir = it['dir'] as bool;
                          final name = it['name'] as String;
                          return ListTile(
                            leading: Icon(
                              isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
                              color: isDir ? Theme.of(context).colorScheme.primary : null,
                            ),
                            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: isDir ? null : Text(_sizeLabel(it['size'] as int)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'download' && !isDir) _download(it);
                                if (v == 'delete') _confirmDelete(it);
                              },
                              itemBuilder: (_) => [
                                if (!isDir) PopupMenuItem(value: 'download', child: Text(l10n.download)),
                                PopupMenuItem(value: 'delete', child: Text(l10n.deleteItem)),
                              ],
                            ),
                            onTap: () {
                              if (isDir) _fetch(_join(path, name));
                            },
                          );
                        },
                      ),
                    ),
        ),
        if (busy != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(child: Text(busy!, overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload_file),
        label: Text(l10n.upload),
        onPressed: path.isEmpty ? null : _upload,
      ),
    );
  }
}
