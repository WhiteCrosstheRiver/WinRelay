import 'package:flutter/material.dart';

/// An invisible text field that turns the phone keyboard into a PC keyboard.
///
/// The field always holds a two-character sentinel. Anything typed after it is
/// sent and cleared; a shorter value means Backspace was pressed. Because the
/// field is never empty, Backspace keeps working even with nothing "typed".
/// While an input method is composing (Chinese, Japanese…), nothing is sent
/// until the word is committed.
class LiveKeyboard extends StatefulWidget {
  const LiveKeyboard({super.key, required this.focusNode, required this.onText, required this.onKey, required this.enterKey});

  final FocusNode focusNode;
  final void Function(String text) onText;
  final void Function(String key) onKey;

  /// Key sent for the keyboard's Return: 'enter' or 'ctrl_enter'.
  final String enterKey;

  @override
  State<LiveKeyboard> createState() => _LiveKeyboardState();
}

class _LiveKeyboardState extends State<LiveKeyboard> {
  static const _sentinel = '\u200b\u200b';
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController();
    _reset();
    _c.addListener(_onChange);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _reset() {
    _c.value = const TextEditingValue(
      text: _sentinel,
      selection: TextSelection.collapsed(offset: _sentinel.length),
    );
  }

  void _onChange() {
    final v = _c.value;
    if (v.composing.isValid && !v.composing.isCollapsed) return; // IME still composing
    final t = v.text;
    if (t == _sentinel) return;

    if (t.startsWith(_sentinel)) {
      _emit(t.substring(_sentinel.length));
    } else if (t.length < _sentinel.length) {
      for (var i = 0; i < _sentinel.length - t.length; i++) {
        widget.onKey('backspace');
      }
    } else {
      // The keyboard replaced text in an unexpected way; send what's new.
      _emit(t.replaceAll('\u200b', ''));
    }
    _reset();
  }

  void _emit(String s) {
    final parts = s.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) widget.onText(parts[i]);
      if (i < parts.length - 1) widget.onKey(widget.enterKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0,
        child: TextField(
          controller: _c,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: null,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          showCursor: false,
          decoration: const InputDecoration.collapsed(hintText: ''),
        ),
      ),
    );
  }
}
