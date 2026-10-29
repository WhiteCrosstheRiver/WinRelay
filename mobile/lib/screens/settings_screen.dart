import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/quick_keys.dart';

/// Languages offered in the dropdown, in their own names.
const _languages = <String, String>{
  'en': 'English',
  'zh': '简体中文',
  'zh_TW': '繁體中文',
  'ja': '日本語',
  'ko': '한국어',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'it': 'Italiano',
  'pt': 'Português (Brasil)',
  'ru': 'Русский',
};

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
    final l10n = AppLocalizations.of(context)!;
    final c = TextEditingController(text: s.deviceName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.phoneName),
        content: TextField(controller: c, autofocus: true, maxLength: 40),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l10n.save)),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(children: [
        _header(l10n.secThisPhone),
        ListTile(
          title: Text(l10n.phoneName),
          subtitle: Text('${s.deviceName} · ${l10n.phoneNameSub}'),
          onTap: _editName,
        ),

        _header(l10n.secAppearance),
        ListTile(
          title: Text(l10n.theme),
          trailing: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'system', label: Text(l10n.themeSystem)),
              ButtonSegment(value: 'light', label: Text(l10n.themeLight)),
              ButtonSegment(value: 'dark', label: Text(l10n.themeDark)),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => _save(() => s.themeMode = v.first),
          ),
        ),
        ListTile(
          title: Text(l10n.language),
          trailing: DropdownButton<String>(
            value: _languages.containsKey(s.language) ? s.language : 'system',
            items: [
              DropdownMenuItem(value: 'system', child: Text(l10n.languageSystem)),
              for (final e in _languages.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => _save(() => s.language = v!),
          ),
        ),

        _header(l10n.secTouch),
        ListTile(
          title: Text(l10n.defaultTouch),
          subtitle: Text(l10n.defaultTouchSub),
          trailing: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [ButtonSegment(value: false, label: Text(l10n.viewMode)), ButtonSegment(value: true, label: Text(l10n.tapMode))],
            selected: {s.tapModeDefault},
            onSelectionChanged: (v) => _save(() => s.tapModeDefault = v.first),
          ),
        ),
        SwitchListTile(
          title: Text(l10n.composeMode),
          subtitle: Text(l10n.composeModeSub),
          value: s.composeMode,
          onChanged: (v) => _save(() => s.composeMode = v),
        ),
        ListTile(
          title: Text(l10n.returnSends),
          trailing: DropdownButton<String>(
            value: s.enterKey,
            items: [
              DropdownMenuItem(value: 'enter', child: Text(l10n.enterKeyEnter)),
              DropdownMenuItem(value: 'ctrl_enter', child: Text(l10n.enterKeyCtrlEnter)),
            ],
            onChanged: (v) => _save(() => s.enterKey = v!),
          ),
        ),
        SwitchListTile(
          title: Text(l10n.vibrate),
          value: s.haptics,
          onChanged: (v) => _save(() => s.haptics = v),
        ),

        _header(l10n.secQuickKeys),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 4, children: [
            for (final e in allQuickKeys.entries)
              FilterChip(
                label: Text(quickKeyLabel(l10n, e.key)),
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

        _header(l10n.secStream),
        ListTile(
          title: Text(l10n.rxFps),
          subtitle: Text(l10n.rxFpsSub),
          trailing: DropdownButton<int>(
            value: s.rxFps,
            items: const [
              DropdownMenuItem(value: 2, child: Text('2 fps')),
              DropdownMenuItem(value: 5, child: Text('5 fps')),
              DropdownMenuItem(value: 10, child: Text('10 fps')),
              DropdownMenuItem(value: 15, child: Text('15 fps')),
              DropdownMenuItem(value: 30, child: Text('30 fps')),
            ],
            onChanged: (v) => _save(() => s.rxFps = v!),
          ),
        ),
        ListTile(
          title: Text(l10n.rxScale),
          subtitle: Text(l10n.rxScaleSub),
          trailing: DropdownButton<double>(
            value: s.rxScale,
            items: const [
              DropdownMenuItem(value: 1.0, child: Text('100%')),
              DropdownMenuItem(value: 0.5, child: Text('50%')),
              DropdownMenuItem(value: 0.25, child: Text('25%')),
              DropdownMenuItem(value: 0.1, child: Text('10%')),
              DropdownMenuItem(value: 0.05, child: Text('5%')),
            ],
            onChanged: (v) => _save(() => s.rxScale = v!),
          ),
        ),
        SwitchListTile(
          title: Text(l10n.rxGray),
          subtitle: Text(l10n.rxGraySub),
          value: s.rxGray,
          onChanged: (v) => _save(() => s.rxGray = v),
        ),

        _header(l10n.secPicture),
        ListTile(
          title: Text(l10n.textSize),
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
          title: Text(l10n.stealthDefault),
          subtitle: Text(l10n.stealthDefaultSub),
          value: s.stealthDefault,
          onChanged: (v) => _save(() => s.stealthDefault = v),
        ),
        SwitchListTile(
          title: Text(l10n.keepScreenOn),
          value: s.keepScreenOn,
          onChanged: (v) => _save(() => s.keepScreenOn = v),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}
