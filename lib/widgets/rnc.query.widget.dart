import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uresax_invoice_sys_cloud/models/client.dart';
import 'package:uresax_invoice_sys_cloud/models/taxpayer.dart';
import 'package:uresax_invoice_sys_cloud/pages/clients_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';

class RncQueryWidget extends StatefulWidget {
  TextEditingController editingController;
  TextEditingController clientName;
  bool editing;
  bool isDense;
  FocusNode? rncEditorFocus;
  Function()? onEnter;

  Function(TaxPayer?, Client? client, bool isValid) onChanged;
  RncQueryWidget(
      {super.key,
      required this.editingController,
      required this.clientName,
      required this.onChanged,
      this.rncEditorFocus,
      this.onEnter,
      this.editing = false,
      this.isDense = false});

  @override
  State<RncQueryWidget> createState() => _RncQueryWidgetState();
}

class _RncQueryWidgetState extends State<RncQueryWidget> {
  Client? client;
  TaxPayer? taxPayer;
  bool notFound = false;
  bool showNumericKeyboard = false;

  _handler() async {
    setState(() {
      notFound = false;
    });
    var words = widget.editingController.text;
    if (words.length == 9 || words.length == 11) {
      client = await Client.findById(words);

      if (client == null) {
        taxPayer = await TaxPayer.findById(words);
        taxPayer?.taxPayerId = Uuid().v4();
      }

      var name = client?.name ?? taxPayer?.taxPayerCompanyName;

      if (name != null) {
        widget.clientName.value = TextEditingValue(text: name);
        widget.onChanged(taxPayer, client, true);
      } else {
        widget.clientName.value = TextEditingValue(text: 'NO ENCONTRADO');
        widget.onChanged(null, null, false);
        setState(() {
          notFound = true;
        });
      }
    } else {
      widget.clientName.value = TextEditingValue.empty;
      widget.onChanged(null, null, false);
    }
  }

  _showClientsPage() async {
    client = await Navigator.push<Client?>(
        context,
        MaterialPageRoute(
            builder: (ctx) => ClientsPage(
                  selectorMode: true,
                  client: Client(identification: widget.editingController.text),
                )));

    if (client != null) {
      widget.clientName.value = TextEditingValue(text: client?.name ?? '');
      widget.editingController.value =
          TextEditingValue(text: client?.identification ?? '');
      widget.onChanged(taxPayer, client, true);
      setState(() {});
    }
  }

  @override
  void initState() {
    widget.editingController.addListener(_handler);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.clientName,
          readOnly: true,
          focusNode: FocusNode(skipTraversal: true),
          decoration: InputDecoration(
              isDense: widget.isDense,
              labelText: 'RAZON SOCIAL',
              hintText: 'NOMBRE...'),
        ),
        SizedBox(
          height: kDefaultPadding,
        ),
        Focus(
            onKeyEvent: (focusnode, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  
                  if(widget.onEnter != null){
                    widget.onEnter!();
                  }else{
                     FocusScope.of(context).nextFocus();
                  }
               
                  return KeyEventResult.handled;
                }
              }

              return KeyEventResult.ignored;
            },
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                if (event.kind == PointerDeviceKind.mouse) {
                  // Solo si el evento es de mouse
                  setState(() {
                    showNumericKeyboard = false;
                  });
                }

                if (event.kind == PointerDeviceKind.touch) {
                  // Solo si el evento es de mouse
                  setState(() {
                    showNumericKeyboard = true;
                  });
                }
              },
              child: FormField<String>(validator: (_) {
                var val = widget.editingController.text;

                return val.isEmpty == true
                    ? 'CAMPO OBLIGATORIO'
                    : !(val.length == 9 || val.length == 11)
                        ? 'LA CANTIDAD DE DIGITOS DEBE SER 9 O 11'
                        : null;
              }, builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnscreenKeyboardTextField(
                      controller: widget.editingController,
                      enabled: !widget.editing,
                      enableOnscreenKeyboard: showNumericKeyboard,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) {
                        setState(() {
                          field.didChange(val);
                        });
                      },
                      decoration: InputDecoration(
                          isDense: widget.isDense,
                          labelText: 'RNC/CEDULA',
                          hintText: 'IDENTIFICACION',
                          errorText: field.errorText,
                          suffixIcon: IconButton(
                              onPressed: _showClientsPage,
                              focusNode: FocusNode(skipTraversal: true),
                              icon: Icon(Icons.add))),
                    )
                  ],
                );
              }),
            ))
      ],
    );
  }
}
