import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/box.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class BoxEditorModal extends StatefulWidget {
  Box box;
  bool editing;
  BoxEditorModal({super.key, required this.box, this.editing = false});

  @override
  State<BoxEditorModal> createState() => _BoxEditorModalState();
}

class _BoxEditorModalState extends State<BoxEditorModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();

  String get title {
    return widget.editing ? 'EDITAR CAJA' : 'AGREGAR CAJA';
  }

  String get action {
    return widget.editing ? 'GUARDAR' : 'CREAR';
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);

      try {
        widget.box.name = nameController.text;
        if (!widget.editing) {
         await widget.box.create();
        }else{
          await widget.box.update();
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
    nameController.text = widget.box.name ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child:SizedBox(
        width: 380,
        child:  Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.all(kDefaultPadding/2),
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
                autofocus: true,
                validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                decoration: InputDecoration(
                    labelText: 'NOMBRE DE LA CAJA', hintText: 'CAJA #1'),
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
      )
    );
  }
}
