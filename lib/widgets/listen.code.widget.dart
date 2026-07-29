import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListenCodeWidget extends StatefulWidget {
  final Widget child;
  final void Function(String) onScan;
  final bool enabled;

  final FocusNode focusNode;

  const ListenCodeWidget({
    super.key,
    required this.child,
    required this.onScan,
    required this.focusNode,
    this.enabled = true,
  });

  @override
  State<ListenCodeWidget> createState() => _ListenCodeWidgetState();
}

class _ListenCodeWidgetState extends State<ListenCodeWidget> {
  String code = '';
  Timer? _scanTimer;
  Timer? xtimer;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final char = event.character;
    if (char == null ||
        char.isEmpty ||
        char.codeUnitAt(0) < 32 ||
        char.codeUnitAt(0) > 126 ||
        event.logicalKey == LogicalKeyboardKey.numLock) {
      return KeyEventResult.ignored;
    }

    code += char;

    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 500), () {
      _onScanComplete(code);
      code = '';
    });

    return KeyEventResult.handled;
  }

  void _onScanComplete(String scannedCode) {
    print('✅ Código escaneado: $scannedCode');
    widget.onScan(scannedCode);
  }

  @override
  void initState() {
    if (widget.enabled) {
      widget.focusNode.requestFocus();
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.enabled,
      onKeyEvent: _handleKey,
      child: widget.child,
    );
  }
}
