import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings get s => Store.I.settings;

  void _save(VoidCallback change) {
    setState(change);
    Store.I.saveSettings();
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: s.deviceName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phone name'),
        content: TextField(controller: c, autofocus: true, maxLength: 40),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) _save(() => s.deviceName = name);
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        _header('This phone'),
        ListTile(
          title: const Text('Phone name'),
          subtitle: Text('${s.deviceName} · shown on the PC when you pair'),
          onTap: _editName,
        ),

        _header('Touch and typing'),
        ListTile(
          title: const Text('Default touch mode'),
          subtitle: const Text('View never clicks on the PC; Tap turns taps into clicks'),
          trailing: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [ButtonSegment(value: false, label: Text('View')), ButtonSegment(value: true, label: Text('Tap'))],
            selected: {s.tapModeDefault},
            onSelectionChanged: (v) => _save(() => s.tapModeDefault = v.first),
          ),
        ),
        SwitchListTile(
          title: const Text('Compose mode'),
          subtitle: const Text('Write a whole message first, with autocorrect, then send it. Off: every key goes to the PC as you type.'),
          value: s.composeMode,
          onChanged: (v) => _save(() => s.composeMode = v),
        ),
        ListTile(
          title: const Text('Return key sends'),
          trailing: DropdownButton<String>(
            value: s.enterKey,
            items: const [
              DropdownMenuItem(value: 'enter', child: Text('Enter')),
              DropdownMenuItem(value: 'ctrl_enter', child: Text('Ctrl+Enter')),
            ],
            onChanged: (v) => _save(() => s.enterKey = v!),
          ),
        ),
        SwitchListTile(
          title: const Text('Vibrate on quick keys'),
          value: s.haptics,
          onChanged: (v) => _save(() => s.haptics = v),
        ),

        _header('Quick keys'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 4, children: [
            for (final e in allQuickKeys.entries)
              FilterChip(
                label: Text(e.value),
                selected: s.quickKeys.contains(e.key),
                onSelected: (on) => _save(() {
                  if (on) {
                    // Keep the bar in the standard order.
                    s.quickKeys = allQuickKeys.keys.where((k) => k == e.key || s.quickKeys.contains(k)).toList();
                  } else {
                    s.quickKeys = s.quickKeys.where((k) => k != e.key).toList();
                  }
                }),
              ),
          ]),
        ),

        _header('Picture'),
        ListTile(
          title: const Text('Text size'),
          subtitle: Slider(
            value: s.textSize,
            min: 0.75,
            max: 2.0,
            divisions: 5,
            label: '${(s.textSize * 100).round()}%',
            onChanged: (v) => _save(() => s.textSize = v),
          ),
          trailing: Text('${(s.textSize * 100).round()}%'),
        ),
        SwitchListTile(
          title: const Text('Hide windows on the PC by default'),
          subtitle: const Text('Stealth. You can still switch it per window.'),
          value: s.stealthDefault,
          onChanged: (v) => _save(() => s.stealthDefault = v),
        ),
        SwitchListTile(
          title: const Text('Keep this screen on while controlling'),
          value: s.keepScreenOn,
          onChanged: (v) => _save(() => s.keepScreenOn = v),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}
