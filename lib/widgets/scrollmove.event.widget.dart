import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class ScrollMoveEventWidget extends StatefulWidget {
  ScrollController scrollControllerY = ScrollController();
  ScrollController? scrollControllerX;
  bool enabledHorizontal;

  Widget child;
  ScrollMoveEventWidget(
      {super.key,
      required this.scrollControllerY,
      this.scrollControllerX,
      this.enabledHorizontal = false,
      required this.child});

  @override
  State<ScrollMoveEventWidget> createState() => _ScrollMoveEventWidgetState();
}

class _ScrollMoveEventWidgetState extends State<ScrollMoveEventWidget> {
  FocusNode focusNodeKeyboard = FocusNode(debugLabel: 'SCROLLMOVE');

  Timer? scrollTimer;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
        policy: NoTraversalPolicy(),
        child: KeyboardListener(
            focusNode: focusNodeKeyboard,
            autofocus: true,
            onKeyEvent: (KeyEvent event) {
              var focusNode = FocusManager.instance.primaryFocus;
              var isTextField =
               focusNode?.context?.widget.key?.toString().contains('editortext')?? false;
                
      

              if (isTextField == false) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  if (event is KeyDownEvent && scrollTimer == null) {
                    scrollTimer =
                        Timer.periodic(const Duration(milliseconds: 50), (_) {
                      final pos = widget.scrollControllerY.position;
                      final target = (widget.scrollControllerY.offset + 50)
                          .clamp(0.0, pos.maxScrollExtent);
                      widget.scrollControllerY.jumpTo(target);
                    });
                  }
                  if (event is KeyUpEvent) {
                    scrollTimer?.cancel();
                    scrollTimer = null;
                  }
                }

                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  if (event is KeyDownEvent && scrollTimer == null) {
                    scrollTimer =
                        Timer.periodic(const Duration(milliseconds: 50), (_) {
                      final pos = widget.scrollControllerY.position;
                      final target = (widget.scrollControllerY.offset - 50)
                          .clamp(0.0, pos.maxScrollExtent);
                      widget.scrollControllerY.jumpTo(target);
                    });
                  }
                  if (event is KeyUpEvent) {
                    scrollTimer?.cancel();
                    scrollTimer = null;
                  }
                }

                if (widget.enabledHorizontal &&
                    widget.scrollControllerX != null) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    if (event is KeyDownEvent && scrollTimer == null) {
                      scrollTimer =
                          Timer.periodic(const Duration(milliseconds: 50), (_) {
                        final pos = widget.scrollControllerX!.position;
                        final target = (widget.scrollControllerX!.offset - 50)
                            .clamp(0.0, pos.maxScrollExtent);
                        widget.scrollControllerX!.jumpTo(target);
                      });
                    }
                    if (event is KeyUpEvent) {
                      scrollTimer?.cancel();
                      scrollTimer = null;
                    }
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    if (event is KeyDownEvent && scrollTimer == null) {
                      scrollTimer =
                          Timer.periodic(const Duration(milliseconds: 50), (_) {
                        final pos = widget.scrollControllerX!.position;
                        final target = (widget.scrollControllerX!.offset + 50)
                            .clamp(0.0, pos.maxScrollExtent);
                        widget.scrollControllerX!.jumpTo(target);
                      });
                    }
                    if (event is KeyUpEvent) {
                      scrollTimer?.cancel();
                      scrollTimer = null;
                    }
                  }
                }
              }
            },
            child: widget.child));
  }
}

class NoTraversalPolicy extends FocusTraversalPolicy {
  FocusNode? findNextFocus(FocusNode currentNode) => null;

  FocusNode? findPreviousFocus(FocusNode currentNode) => null;

  @override
  FocusNode? findFirstFocusInDirection(
      FocusNode currentNode, TraversalDirection direction) {
    return null;
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    return false;
  }

  @override
  Iterable<FocusNode> sortDescendants(
      Iterable<FocusNode> descendants, FocusNode currentNode) {
    return descendants;
  }
}
