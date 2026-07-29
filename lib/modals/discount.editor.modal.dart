import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/discount.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class DiscountEditorModal extends StatefulWidget {
  Discount discount;
  bool editing;
  DiscountEditorModal(
      {super.key, required this.discount, this.editing = false});

  @override
  State<DiscountEditorModal> createState() => _DiscountEditorModalState();
}

class _DiscountEditorModalState extends State<DiscountEditorModal> {
  TextEditingController name = TextEditingController();
  TextEditingController rate = TextEditingController();
  int? currentSymbolId;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String get title {
    return widget.editing ? 'EDITANDO DESCUENTO...' : 'CREANDO DESCUENTO...';
  }

  String get btnTitle {
    return widget.editing ? 'EDITAR DESCUENTO' : 'CREAR DESCUENTO';
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        widget.discount.name = name.text;
        widget.discount.rate = double.tryParse(rate.text);
        widget.discount.symbolId = currentSymbolId;
        if (!widget.editing) {
          await widget.discount.create();
          await LogHandler.printEvent(
              'DESCUENTO: ${widget.discount.name} CREADO');
        } else {
          await widget.discount.update();
          await LogHandler.printEvent(
              'DESCUENTO: ${widget.discount.name} ACTUALIZADO');
        }
        Navigator.pop(context, widget.editing ? 'UPDATE' : 'CREATE');
      } catch (e) {
        await LogHandler.printError(e.toString());
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    name.text = widget.discount.name ?? '';
    rate.text = widget.discount.rate?.toStringAsFixed(2) ?? '';
    currentSymbolId = widget.discount.symbolId;
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          key: _formKey,
          child: SizedBox(
              width: 350,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.all(kDefaultPadding),
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                      color: Theme.of(context).primaryColor))),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close))
                    ],
                  ),
                  SizedBox(
                    height: kDefaultPadding,
                  ),
                  TextFormField(
                    controller: name,
                    validator: (val) =>
                        val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                    decoration: InputDecoration(
                        labelText: 'NOMBRE', hintText: 'Escribir nombre...'),
                  ),
                  SizedBox(
                    height: kDefaultPadding,
                  ),
                  TextFormField(
                    controller: rate,
                    validator: (val) =>
                        val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                    decoration:
                        InputDecoration(labelText: 'TASA', hintText: '0.00'),
                  ),
                  SizedBox(
                    height: kDefaultPadding,
                  ),
                  DropdownButtonFormField(
                      initialValue: currentSymbolId,
                      decoration: InputDecoration(labelText: 'SIMBOLO'),
                      validator: (val) =>
                          val == null ? 'CAMPO OBLIGATORIO' : null,
                      items: List.generate(symbols.length, (index) {
                        var symbol = symbols[index];
                        return DropdownMenuItem(
                            value: symbol.id, child: Text(symbol.name ?? ''));
                      }),
                      onChanged: (option) {
                        currentSymbolId = option;
                      }),
                  SizedBox(
                    height: kDefaultPadding,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _onSubmit, child: Text(btnTitle)),
                  )
                ],
              ))),
    );
  }
}
