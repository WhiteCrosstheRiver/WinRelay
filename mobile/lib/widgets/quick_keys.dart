import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';

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
  });

  final List<String> keys;
  final void Function(String key) onKey;
  final bool keyboardOpen;
  final VoidCallback onToggleKeyboard;
  final bool haptics;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  tooltip: keyboardOpen ? 'Hide keyboard' : 'Show keyboard',
                  onPressed: onToggleKeyboard,
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
                        child: Text(allQuickKeys[k]!),
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
