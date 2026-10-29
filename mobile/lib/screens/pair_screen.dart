import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models.dart';
import '../store.dart';
import 'pcs_screen.dart';
import 'windows_screen.dart';

class PairScreen extends StatefulWidget {
  const PairScreen({super.key, this.first = false});

  /// True when this is the app's first screen (no PCs yet).
  final bool first;

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _link = TextEditingController();
  String? _error;
  bool _done = false;

  Future<void> _use(String raw) async {
    if (_done) return;
    final pc = parsePairLink(raw);
    if (pc == null) {
      setState(() => _error = "That isn't a WinRelay link. Copy it again from WinRelay on the PC.");
      return;
    }
    _done = true;
    await Store.I.savePc(pc);
    if (!mounted) return;
    if (widget.first) {
      // Put "Your PCs" underneath; it opens the only PC's windows by itself.
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PcsScreen()), (_) => false);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WindowsScreen(pc: pc)));
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _link.text = data!.text!;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pair a PC'), automaticallyImplyLeading: !widget.first),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Scan the code shown in WinRelay on your PC.', style: t.titleMedium),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 280,
              child: MobileScanner(
                onDetect: (capture) {
                  final value = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
                  if (value != null) _use(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Or paste the link', style: t.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _link,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'winrelay://pair?…',
              errorText: _error,
              suffixIcon: IconButton(icon: const Icon(Icons.content_paste), tooltip: 'Paste', onPressed: _paste),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => _use(_link.text), child: const Text('Connect')),
          const SizedBox(height: 20),
          Text(
            'After connecting, click Approve on the PC. Each link works once.',
            style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
