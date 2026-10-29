import 'package:flutter/material.dart';

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
    return MaterialApp(
      title: 'WinRelay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark, useMaterial3: true),
      home: Store.I.pcs.isEmpty ? const PairScreen(first: true) : const PcsScreen(),
    );
  }
}
