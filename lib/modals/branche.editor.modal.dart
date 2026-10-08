import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/branche.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class BrancheEditorModal extends StatefulWidget {
  BrancheModel branche;
  bool editing;
  BrancheEditorModal({super.key, required this.branche, this.editing = false});

  @override
  State<BrancheEditorModal> createState() => _BrancheEditorModalState();
}

class _BrancheEditorModalState extends State<BrancheEditorModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController phone1 = TextEditingController();
  TextEditingController phone2 = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController email = TextEditingController();
  String get title {
    return widget.editing ? 'EDITAR SUCURSAL' : 'AGREGAR SUCURSAL';
  }

  String get action {
    return widget.editing ? 'GUARDAR' : 'CREAR';
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);

      try {
        widget.branche.name = nameController.text;
        widget.branche.phone1 = phone1.text.isEmpty ? null : phone1.text;
        widget.branche.phone2 = phone2.text.isEmpty ? null : phone2.text;
        widget.branche.address = address.text.isEmpty ? null : address.text;
        widget.branche.email = email.text.isEmpty ? null: email.text;
        widget.branche.createdAt = DateTime.now();
        if (!widget.editing) {
          await widget.branche.create();
        } else {
          await widget.branche.update();
        }
        Navigator.pop(context);
        Navigator.pop(context, widget.editing ? 'UPDATE' : 'CREATE');
      } catch (e) {
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    nameController.text = widget.branche.name ?? '';
    phone1.text = widget.branche.phone1 ?? '';
    phone2.text = widget.branche.phone2 ?? '';
    address.text = widget.branche.address ?? '';
    email.text = widget.branche.email ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: SizedBox(
      width: 380,
      child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.all(kDefaultPadding / 2),
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Theme.of(context).primaryColor),
                  )),
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
                controller: nameController,
                validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                decoration: InputDecoration(
                    labelText: 'NOMBRE DE LA SUCURSAL',
                    hintText: 'Escribir algo...'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              TextFormField(
                controller: phone1,
                validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                decoration: InputDecoration(
                    labelText: 'TELEFONO 1', hintText: '809-000-0000'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              TextFormField(
                controller: phone2,
                decoration: InputDecoration(
                    labelText: 'TELEFONO 2', hintText: '809-000-0000'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              TextFormField(
                controller: address,
                validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: 'DIRECCION', hintText: 'Escribir algo...'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              TextFormField(
                controller: email,
                decoration: InputDecoration(
                    labelText: 'CORREO', hintText: 'user@example.com'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child:
                    ElevatedButton(onPressed: _onSubmit, child: Text(action)),
              )
            ],
          )),
    ));
  }
}
