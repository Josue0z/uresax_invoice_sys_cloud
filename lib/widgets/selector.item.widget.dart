import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';

class SelectorItemWidget<T> extends FormField<T> {
  bool? enabledModeEditor;
  TextEditingController? editingController;
  FocusNode? focusNode;
  String? hintText;
  T? xelement; // 👈 propiedad global

  SelectorItemWidget({
    super.key,
    required BuildContext context,
    required String title,
    required Widget screen,
    this.enabledModeEditor = false,
    this.editingController,
    this.hintText,
    this.focusNode,
    void Function(String?)? onEditing,
    void Function(TapDownDetails)? onFocus,
    required void Function(T?, bool)? onChanged,
    super.initialValue,
    super.validator,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.enabled = true,
    this.xelement,
  }) : super(builder: (state) {
          dynamic value = state.value ?? initialValue;
          String val = value?.name ?? title;

          choose() async {
            // Actualiza la propiedad global del widget
            (state.widget as SelectorItemWidget<T>).xelement =
                await Navigator.push<T>(
                    context, MaterialPageRoute(builder: (ctx) => screen));

            if ((state.widget as SelectorItemWidget<T>).xelement != null) {
              state.didChange((state.widget as SelectorItemWidget<T>).xelement);
              state.save();
              state.validate();
              if (onChanged != null) {
                onChanged((state.widget as SelectorItemWidget<T>).xelement, false);
              }
            }
          }

          return SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: state.hasError
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    child: (state.widget as SelectorItemWidget<T>)
                                .enabledModeEditor ==
                            true
                        ? Padding(
                            padding: EdgeInsets.all(kDefaultPadding * 0.6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTapDown:(details){
                                      if(onFocus != null){
                                        onFocus(details);
                                      }
                                    },
                                    child:TextFormField(
                                    controller: (state.widget
                                            as SelectorItemWidget<T>)
                                        .editingController!,
                                    focusNode: (state.widget
                                            as SelectorItemWidget<T>)
                                        .focusNode!,
                                    enabled: enabled,
                                   
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: (state.widget
                                              as SelectorItemWidget<T>)
                                          .hintText!,
                                    ),
                                    onChanged: (val) {
                                      
                                      if (onEditing != null) {
                                        onEditing(val);
                                      }
                                    },
                                  ),
                                  )
                                ),
                                MouseRegion(
                                  cursor: !enabled
                                      ? MouseCursor.defer
                                      : SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: !enabled ? null : choose,
                                    child: Icon(Icons.arrow_drop_down,
                                        color: Colors.black45),
                                  ),
                                )
                              ],
                            ),
                          )
                        : Ink(
                            child: InkWell(
                              onTap: !enabled ? null : choose,
                              child: Padding(
                                padding:
                                    EdgeInsets.all(kDefaultPadding * 0.8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        val,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.arrow_drop_down,
                                        color: Colors.black45),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                state.hasError
                    ? Container(
                        margin: EdgeInsets.only(
                          top: kDefaultPadding / 2,
                          left: kDefaultPadding / 2,
                        ),
                        child: Text(
                          state.errorText ?? '',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : SizedBox(),
              ],
            ),
          );
        });
}

class CustomEditableText extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  String hintText;
  Function(String) onChanged;
  bool enabled;

  CustomEditableText({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.enabled,
  }) : super(key: key);

  @override
  _CustomEditableTextState createState() => _CustomEditableTextState();
}

class _CustomEditableTextState extends State<CustomEditableText> {
  String value = '';

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const SelectAllTextIntent(SelectionChangedCause.keyboard),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):
            const ExtendSelectionByCharacterIntent(
                forward: true, collapseSelection: false),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):
            const ExtendSelectionByCharacterIntent(
                forward: false, collapseSelection: false),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(
            onInvoke: (intent) {
              widget.controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: widget.controller.text.length,
              );
              return null;
            },
          ),
          CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
            onInvoke: (intent) {
              final selected = widget.controller.selection
                  .textInside(widget.controller.text);
              Clipboard.setData(ClipboardData(text: selected));
              return null;
            },
          ),
          PasteTextIntent: CallbackAction<PasteTextIntent>(
            onInvoke: (intent) async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                widget.controller.text += data!.text!;
              }
              return null;
            },
          ),
          ExtendSelectionByCharacterIntent:
              CallbackAction<ExtendSelectionByCharacterIntent>(
            onInvoke: (intent) {
              final selection = widget.controller.selection;
              final newExtent = intent.forward
                  ? selection.extentOffset + 1
                  : selection.extentOffset - 1;
              widget.controller.selection = TextSelection(
                baseOffset: selection.baseOffset,
                extentOffset: newExtent.clamp(0, widget.controller.text.length),
              );
              return null;
            },
          ),
        },
        child: Stack(
          children: [
            if (widget.controller.text.isEmpty)
              Text(
                widget.hintText,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            EditableText(
              controller: widget.controller,
              keyboardType: TextInputType.text,
              readOnly: widget.enabled,
              mouseCursor: !widget.enabled
                  ? SystemMouseCursors.text
                  : SystemMouseCursors.basic,
              inputFormatters: [UpperCaseTextFormatter()],
              onChanged: (val) {
                widget.onChanged(val);
              },
              focusNode: widget.focusNode,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              cursorColor: Theme.of(context).primaryColor,
              backgroundCursorColor: Theme.of(context).primaryColor,
              showSelectionHandles: true,
              selectAllOnFocus: true,
              scrollPhysics: ClampingScrollPhysics(),
              selectionControls: DesktopTextSelectionControls(),
              paintCursorAboveText: true,
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.selectable(
                  onCopy: () {},
                  onSelectAll: () {},
                  onShare: () {},
                  anchors:
                      TextSelectionToolbarAnchors(primaryAnchor: Offset.zero),
                  selectionGeometry: SelectionGeometry(
                      status: SelectionStatus.uncollapsed, hasContent: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
