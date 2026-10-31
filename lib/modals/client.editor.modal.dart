import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_masked_formatter/multi_masked_formatter.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/client.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class ClientEditorModal extends StatefulWidget {
  bool editing;
  Client client;

  ClientEditorModal({super.key, this.editing = false, required this.client});

  @override
  State<ClientEditorModal> createState() => _ClientEditorModalState();
}

class _ClientEditorModalState extends State<ClientEditorModal> {
  TextEditingController name = TextEditingController();
  TextEditingController identification = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController address = TextEditingController();

  String oldIdentification = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String get title {
    return widget.editing ? 'EDITANDO CLIENTE' : 'AGREGANDO CLIENTE';
  }

  String get btnTitle {
    return widget.editing ? 'EDITAR CLIENTE' : 'AGREGAR CLIENTE';
  }

  bool get esContado {
    return name.text.contains('CLIENTE CONTADO');
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        showLoader(context);
        widget.client.name = name.text.trim();
        widget.client.identification = identification.text.trim();
        widget.client.email = email.text.isEmpty ? null : email.text.trim();
        widget.client.phone = phone.text.isEmpty ? null : phone.text.trim();
        widget.client.address =
            address.text.isEmpty ? null : address.text.trim();

        if (!widget.editing) {
          await widget.client.create();
          await LogHandler.printEvent('CLIENTE: ${widget.client.name} CREADO');
          Navigator.pop(context, 'CREATE');
        } else {
          var isChanged = oldIdentification != identification.text;

          if (isChanged) {
            var exist = await Client.checkIfExistInvoices(
                identification: oldIdentification);
            if (exist) {
              throw 'ESTE RNC/CEDULA ($oldIdentification) NO SE PUEDE CAMBIAR TIENE FACTURAS ACTIVAS';
            }
          }

          await widget.client.update();
          await LogHandler.printEvent(
              'CLIENTE: ${widget.client.name} ACTUALIZADO');
          Navigator.pop(context);
          Navigator.pop(context, 'UPDATE');
          showTopSnackBar(context,
              message: widget.editing ? 'CLIENTE EDITADO' : 'CLIENTE CREADO',
              color: Colors.green);
        }
      } catch (e) {
        await LogHandler.printError(e.toString());
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    oldIdentification = widget.client.identification ?? '';

    name.value = TextEditingValue(text: widget.client.name ?? '');
    identification.value =
        TextEditingValue(text: widget.client.identification ?? '');
    email.value = TextEditingValue(text: widget.client.email ?? '');
    phone.value = TextEditingValue(text: widget.client.phone ?? '');
    address.text = widget.client.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          key: _formKey,
          child: Container(
              width: 350,
              padding: EdgeInsets.all(kDefaultPadding),
              child: Column(
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
                  Expanded(
                      child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                        TextFormField(
                          controller: name,
                          autofocus: true,
                          readOnly: esContado,
                          validator: (val) =>
                              val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                          decoration: InputDecoration(
                              labelText: 'NOMBRE',
                              hintText: 'Escribir nombre...'),
                        ),
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                        TextFormField(
                          controller: identification,
                          readOnly: esContado,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          maxLength: 11,
                          validator: (val) =>
                              val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                          decoration: InputDecoration(
                              labelText: 'RNC/CEDULA',
                              hintText: 'Escribir algo...'),
                        ),
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                        TextFormField(
                          controller: phone,
                          inputFormatters: [
                            MultiMaskedTextInputFormatter(
                                masks: ['xxx-xxx-xxxx'], separator: '-')
                          ],
                          decoration: InputDecoration(
                              labelText: 'TELEFONO', hintText: '809 000 0000'),
                        ),
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                        TextFormField(
                          controller: email,
                          decoration: InputDecoration(
                              labelText: 'CORREO',
                              hintText: 'correo@example.com'),
                        ),
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                        TextFormField(
                          controller: address,
                          maxLines: 4,
                          decoration: InputDecoration(
                              labelText: 'DIRECCION',
                              hintText: 'Escribir direccion...'),
                        ),
                        SizedBox(
                          height: kDefaultPadding,
                        ),
                      ],
                    ),
                  )),
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
