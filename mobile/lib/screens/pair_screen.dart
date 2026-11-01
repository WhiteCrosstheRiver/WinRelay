import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/generated/app_localizations.dart';
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
  final _controller = MobileScannerController(
    detectionTimeoutMs: 600,
    formats: const [BarcodeFormat.qrCode],
  );
  PermissionStatus _camStatus = PermissionStatus.denied;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _checkCam();
  }

  Future<void> _checkCam() async {
    final st = await Permission.camera.status;
    setState(() => _camStatus = st);
    if (st.isGranted || st.isLimited) _controller.start();
  }

  Future<void> _askCam() async {
    final st = await Permission.camera.request();
    setState(() => _camStatus = st);
    if (st.isGranted || st.isLimited) _controller.start();
  }

  Future<void> _use(String raw) async {
    if (_done) return;
    final pc = parsePairLink(raw);
    if (pc == null) {
      setState(() => _error = AppLocalizations.of(context)!.pairBadLink);
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

  Widget _camBox(BuildContext ctx, IconData icon, String text, {String? button, VoidCallback? onTap}) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 44, color: Theme.of(ctx).colorScheme.primary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(text, textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodyMedium),
        ),
        if (button != null) ...[
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.settings), label: Text(button)),
        ],
      ]),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _link.text = data!.text!;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pairPc), automaticallyImplyLeading: !widget.first),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.pairScanHint, style: t.titleMedium),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 280,
              child: switch (_camStatus) {
                PermissionStatus.granted ||
                PermissionStatus.limited ||
                PermissionStatus.provisional =>
                  MobileScanner(
                    controller: _controller,
                    errorBuilder: (ctx, err, _) => _camBox(ctx, Icons.error_outline,
                        AppLocalizations.of(ctx)!.cameraError),
                    onDetect: (capture) {
                      final value = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
                      if (value != null) _use(value);
                    },
                  ),
                PermissionStatus.permanentlyDenied ||
                PermissionStatus.restricted =>
                  _camBox(context, Icons.block, AppLocalizations.of(context)!.cameraPermOff,
                      button: AppLocalizations.of(context)!.cameraOpenSettings,
                      onTap: () => openAppSettings()),
                _ => _camBox(context, Icons.photo_camera_outlined,
                    AppLocalizations.of(context)!.cameraPermNeeded,
                    button: AppLocalizations.of(context)!.cameraAllow,
                    onTap: _askCam),
              },
            ),
          ),
          const SizedBox(height: 28),
          Text(l10n.pairOrPaste, style: t.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _link,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.pairLinkHint,
              errorText: _error,
              suffixIcon: IconButton(icon: const Icon(Icons.content_paste), tooltip: l10n.paste, onPressed: _paste),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => _use(_link.text), child: Text(l10n.connect)),
          const SizedBox(height: 20),
          Text(
            l10n.pairFooter,
            style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
