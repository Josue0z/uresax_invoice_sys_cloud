
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListViewSelectorWidget extends StatefulWidget {
  int itemCount;

  ScrollController? controller;

  bool enabled;

  final Function(int index)? onEnterPressed;

  Widget? Function(
    BuildContext,
    int,
    bool hasFocus,
    FocusNode focusNode,
    GlobalKey key,
  )
  itemBuilder;

  Widget Function(BuildContext, int) separatorBuilder;

  ListViewSelectorWidget({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.onEnterPressed,
    this.controller,
    this.enabled = true
  });

  @override
  State<ListViewSelectorWidget> createState() => _ListViewSelectorWidgetState();
}

class _ListViewSelectorWidgetState extends State<ListViewSelectorWidget> {
  int moveY = 0;
  FocusNode listviewhandlerFocus = FocusNode();
   List<FocusNode> parentItemsFocus = [];
  List<FocusNode> itemsFocus = [];
  List<GlobalKey> keys = [];

  @override
  initState() {
    if (!mounted) return;

    itemsFocus = List.generate(widget.itemCount, (i) => FocusNode());
    parentItemsFocus = List.generate(widget.itemCount, (i) => FocusNode());
    keys = List.generate(widget.itemCount, (i) => GlobalKey());

    itemsFocus[0].requestFocus();
    parentItemsFocus[0].requestFocus();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: listviewhandlerFocus,
      onKeyEvent: widget.enabled == false ? null : (event) {


        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (moveY > 0) {
              moveY -= 1;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (moveY < widget.itemCount - 1) {
              moveY += 1;
            }
          }
        }
        setState(() {});

        itemsFocus[moveY].requestFocus();
        parentItemsFocus[moveY].requestFocus();

        var key = keys[moveY];

        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeIn,
          );
        }
      },
      child: ListView.separated(
        itemCount: widget.itemCount,
        controller: widget.controller,
        separatorBuilder: widget.separatorBuilder,
        itemBuilder: (ctx, i) {
          var focus = itemsFocus[i];
          var focusParent = parentItemsFocus[i];
          var key = keys[i];

      
          var child =  widget.enabled == false? widget.itemBuilder.call(ctx, i, moveY == -1, focus, key) :   widget.itemBuilder.call(ctx, i, moveY == i, focus, key);


          return Focus(
            autofocus: widget.enabled,
            focusNode: focusParent,
            onKeyEvent:widget.enabled == false ? null : (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter) {
                widget.onEnterPressed?.call(i);

                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },
            child: child!,
          );
        },
      ),
    );
  }
}
