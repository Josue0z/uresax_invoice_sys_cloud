import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



class EscNavigationDemo extends StatefulWidget {
  final Widget child;
  const EscNavigationDemo({super.key,required this.child});

  @override
  State<EscNavigationDemo> createState() => _EscNavigationDemoState();
}

class _EscNavigationDemoState extends State<EscNavigationDemo> {
    final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _focusNode.requestFocus();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true, // activa el listener automáticamente
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          // 👇 acción al presionar ESC
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: GestureDetector(
        onTap: (){
          _focusNode.requestFocus();
        },
        child: widget.child
      )
    );
  }
}