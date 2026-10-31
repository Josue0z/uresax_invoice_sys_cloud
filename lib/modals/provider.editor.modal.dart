import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/provider.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class ProviderEditorModal extends StatefulWidget {
  Providers provider;
  bool editing;
  ProviderEditorModal(
      {super.key, required this.provider, this.editing = false});

  @override
  State<ProviderEditorModal> createState() => _ProviderEditorModalState();
}

class _ProviderEditorModalState extends State<ProviderEditorModal> {
  TextEditingController name = TextEditingController();
  TextEditingController rncOrId = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController address = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String get title {
    return widget.editing ? 'EDITANDO PROVEEDOR' : 'AGREGANDO PROVEEDOR';
  }

  String get btnText {
    return widget.editing ? 'EDITAR PROVEEDOR' : 'CREAR PROVEEDOR';
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);
      Providers provider = Providers(
        id: widget.provider.id
      );
      try {
        provider.name = name.text.trim();
        provider.rncOrId = rncOrId.text;
        provider.phone = phone.text.isEmpty ? null : phone.text;
        provider.email = email.text.isEmpty ? null : email.text;
        provider.address = address.text.isEmpty ? null : address.text;
        if (widget.editing) {
          await provider.update();
          await LogHandler.printEvent(
              'PROVEEDOR: ${widget.provider.name} ACTUALIZADO');
        } else {
          await provider.create();
          widget.provider = provider;
          await LogHandler.printEvent(
              'PROVEEDOR: ${widget.provider.name} CREADO');
        }
        Navigator.pop(context);
        Navigator.pop(context, widget.editing ? 'UPDATE' : 'CREATE');
      } catch (e) {
        await LogHandler.printError(e.toString());
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    name.text = widget.provider.name ?? '';
    rncOrId.text = widget.provider.rncOrId ?? '';
    phone.text = widget.provider.phone ?? '';
    email.text = widget.provider.email ?? '';
    address.text = widget.provider.address ?? '';
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
                  margin: EdgeInsets.symmetric(vertical: kDefaultPadding),
                  child: TextFormField(
                    controller: rncOrId,
                    autofocus: true,
                    validator: (val) =>
                        val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                    decoration: InputDecoration(
                        labelText: 'Rnc/Cedula', hintText: 'Escribir algo...'),
                  ),
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
                Container(
                  margin: EdgeInsets.only(bottom: kDefaultPadding),
                  child: TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: 'Telefono', hintText: 'Escribir algo...'),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: kDefaultPadding),
                  child: TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: 'Email', hintText: 'Escribir algo...'),
                  ),
                ),

                  Container(
                  margin: EdgeInsets.only(bottom: kDefaultPadding),
                  child: TextFormField(
                    controller: address,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: 'Dirección', hintText: 'Escribir algo...'),
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
