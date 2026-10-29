import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'screens/pair_screen.dart';
import 'screens/pcs_screen.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.I.load();
  runApp(const WinRelayApp());
}

/// Same signal blue as the desktop app's "connected" lamp.
const _seed = Color(0xFF2F6FEB);

class WinRelayApp extends StatelessWidget {
  const WinRelayApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole MaterialApp when settings change, so theme and
    // language switches apply immediately.
    return ListenableBuilder(
      listenable: Store.I,
      builder: (context, _) {
        final s = Store.I.settings;
        return MaterialApp(
          title: 'WinRelay',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: _seed, useMaterial3: true),
          darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark, useMaterial3: true),
          themeMode: switch (s.themeMode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
          locale: s.language == 'system' ? null : _localeOf(s.language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Store.I.pcs.isEmpty ? const PairScreen(first: true) : const PcsScreen(),
        );
      },
    );
  }

  /// 'zh_TW' -> Locale('zh', 'TW'); 'en' -> Locale('en').
  static Locale _localeOf(String code) {
    final i = code.indexOf('_');
    return i < 0 ? Locale(code) : Locale(code.substring(0, i), code.substring(i + 1));
  }
}
