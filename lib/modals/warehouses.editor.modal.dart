import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class WareHousesEditorModal extends StatefulWidget {
  WareHouses wareHouse;
  bool editing;
  WareHousesEditorModal(
      {super.key, required this.wareHouse, this.editing = false});

  @override
  State<WareHousesEditorModal> createState() => _WareHousesEditorModalState();
}

class _WareHousesEditorModalState extends State<WareHousesEditorModal> {
  TextEditingController name = TextEditingController();
  TextEditingController rncOrId = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String get title {
    return widget.editing ? 'EDITANDO ALMACEN' : 'AGREGANDO ALMACEN';
  }

  String get btnText {
    return widget.editing ? 'EDITAR ALMACEN' : 'CREAR ALMACEN';
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      WareHouses? wareHouse;
      try {
        widget.wareHouse.name = name.text;

        if (widget.editing) {
          await widget.wareHouse.update();
          await LogHandler.printEvent(
              'ALMACEN: ${widget.wareHouse.name} ACTUALIZADO');
        } else {
          wareHouse = await widget.wareHouse.create();
          await LogHandler.printEvent(
              'ALMACEN: ${widget.wareHouse.name} CREADO');
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
    name.text = widget.wareHouse.name ?? '';

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
                Container(
                  margin: EdgeInsets.only(bottom: kDefaultPadding),
                  child: TextFormField(
                    controller: name,
                    validator: (val) =>
                        val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                    decoration: InputDecoration(
                        labelText: 'Nombre', hintText: 'Escribir algo...'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: _onSubmit, child: Text(btnText)),
                )
              ],
            ),
          )),
    );
  }
}
