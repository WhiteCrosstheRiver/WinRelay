import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../l10n/generated/app_localizations.dart';

/// Localized label for a quick key. Technical names (Esc, Tab, Ctrl+C, the
/// arrows, Home, End) are universal; natural-language ones get a translation.
String quickKeyLabel(AppLocalizations l10n, String k) => switch (k) {
      'shift_enter' => l10n.qkNewLine,
      'paste' => l10n.qkPaste,
      'pgup' => l10n.qkPageUp,
      'pgdn' => l10n.qkPageDown,
      'delete' => l10n.qkDelete,
      _ => allQuickKeys[k] ?? k,
    };

/// One scrollable row: keyboard toggle, then the user's chosen keys.
class QuickKeysBar extends StatelessWidget {
  const QuickKeysBar({
    super.key,
    required this.keys,
    required this.onKey,
    required this.keyboardOpen,
    required this.onToggleKeyboard,
    required this.haptics,
    this.onLongPress,
    this.onClipCopy,
    this.onClipPaste,
  });

  final List<String> keys;
  final void Function(String key) onKey;
  final bool keyboardOpen;
  final VoidCallback onToggleKeyboard;
  final bool haptics;
  final VoidCallback? onLongPress;

  /// Clipboard relay: grab this PC's clipboard / paste the relayed text.
  final VoidCallback? onClipCopy;
  final VoidCallback? onClipPaste;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                IconButton.filledTonal(
                  icon: Icon(keyboardOpen ? Icons.keyboard_hide_outlined : Icons.keyboard_outlined),
                  tooltip: keyboardOpen ? l10n.hideKeyboard : l10n.showKeyboard,
                  onPressed: onToggleKeyboard,
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.language),
                  tooltip: l10n.switchIme,
                  onPressed: () {
                    // Opens the system input-method picker so another keyboard
                    // (e.g. a Chinese IME) can be chosen in place. No-op where
                    // the platform channel isn't implemented.
                    const MethodChannel('winrelay/ime').invokeMethod('showPicker').catchError((_) {});
                  },
                ),
                if (onClipCopy != null)
                  IconButton.filledTonal(
                    icon: const Icon(Icons.content_copy),
                    tooltip: l10n.clipCopyFromPc,
                    onPressed: onClipCopy,
                  ),
                if (onClipPaste != null)
                  IconButton.filledTonal(
                    icon: const Icon(Icons.content_paste),
                    tooltip: l10n.clipPasteToPc,
                    onPressed: onClipPaste,
                  ),
                const SizedBox(width: 4),
                for (final k in keys)
                  if (allQuickKeys.containsKey(k))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(44, 36),
                        ),
                        onPressed: () {
                          if (haptics) HapticFeedback.selectionClick();
                          onKey(k);
                        },
                        child: Text(quickKeyLabel(l10n, k)),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
