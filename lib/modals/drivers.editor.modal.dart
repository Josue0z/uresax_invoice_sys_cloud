import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/drivers.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class DriversEditorModal extends StatefulWidget {
  bool editing;
  Drivers driver;
  DriversEditorModal({super.key, required this.driver, this.editing = false});

  @override
  State<DriversEditorModal> createState() => _DriversEditorModalState();
}

class _DriversEditorModalState extends State<DriversEditorModal> {
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController email = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String get title {
    return widget.editing ? 'EDITANDO CONDUCTOR...' : 'CREANDO CONDUCTOR...';
  }

  String get btnTitle {
    return widget.editing ? 'EDITAR CONDUCTOR' : 'CREAR CONDUCTOR';
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        widget.driver.name = name.text;
        widget.driver.phone = phone.text.isEmpty ? null : phone.text;
        widget.driver.email = email.text.isEmpty ? null : email.text;
        if (!widget.editing) {
          await widget.driver.create();
        } else {
          await widget.driver.update();
        }
        Navigator.pop(context, widget.editing ? 'UPDATE' : 'CREATE');
      } catch (e) {
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    name.text = widget.driver.name ?? '';
    phone.text = widget.driver.phone ?? '';
    email.text = widget.driver.email ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Form(
            key: _formKey,
            child: Container(
              padding: EdgeInsets.all(kDefaultPadding),
              width: 350,
              height: 360,
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
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(vertical: kDefaultPadding),
                        child: TextFormField(
                          controller: name,
                          validator: (val) =>
                              val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                          decoration: InputDecoration(
                              labelText: 'NOMBRE',
                              hintText: 'Escribir algo...'),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: kDefaultPadding),
                        child: TextFormField(
                          controller: phone,
                    
                          decoration: InputDecoration(
                              labelText: 'TELEFONO',
                              hintText: 'Escribir algo...'),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: kDefaultPadding),
                        child: TextFormField(
                          controller: email,
                        
                          decoration: InputDecoration(
                              labelText: 'CORREO',
                              hintText: 'Escribir algo...'),
                        ),
                      )
                    ],
                  ))),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _onSubmit, child: Text(btnTitle)),
                  )
                ],
              ),
            )));
  }
}
