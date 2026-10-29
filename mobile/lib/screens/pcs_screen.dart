import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import 'pair_screen.dart';
import 'settings_screen.dart';
import 'windows_screen.dart';

class PcsScreen extends StatefulWidget {
  const PcsScreen({super.key});

  @override
  State<PcsScreen> createState() => _PcsScreenState();
}

class _PcsScreenState extends State<PcsScreen> {
  @override
  void initState() {
    super.initState();
    Store.I.addListener(_changed);
    // With exactly one PC, go straight to its windows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Store.I.pcs.length == 1) _open(Store.I.pcs.first);
    });
  }

  @override
  void dispose() {
    Store.I.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  void _open(PcEntry pc) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => WindowsScreen(pc: pc)));

  Future<void> _rename(PcEntry pc) async {
    final c = TextEditingController(text: pc.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename PC'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      pc.name = name;
      await Store.I.savePc(pc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pcs = Store.I.pcs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your PCs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: pcs.isEmpty
          ? const Center(child: Text('Pair a PC to get started.'))
          : ListView.separated(
              itemCount: pcs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final pc = pcs[i];
                return ListTile(
                  leading: const Icon(Icons.desktop_windows_outlined),
                  title: Text(pc.name),
                  subtitle: Text(pc.isPaired ? '${pc.host} · port ${pc.port}' : 'Waiting for approval on the PC'),
                  onTap: () => _open(pc),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'rename') await _rename(pc);
                      if (v == 'remove') await Store.I.removePc(pc);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Pair a PC'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PairScreen())),
      ),
    );
  }
}
