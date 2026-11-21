import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class ChangePasswordModal extends StatefulWidget {
  User user;
  ChangePasswordModal({super.key, required this.user});

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController password = TextEditingController();

  _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        var user = User(id: widget.user.id);
        user.password = password.text;
        showLoader(context);
        await user.changePassword();
        Navigator.pop(context);
        Navigator.pop(context, true);
      } catch (e) {
        Navigator.pop(context, false);
        showTopSnackBar(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
        key: _formKey,
        child: SizedBox(
          width: 450,
          child: ListView(
            padding: EdgeInsets.all(kDefaultPadding),
            shrinkWrap: true,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'CAMBIANDO CLAVE...',
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: kDefaultPadding),
                child: TextFormField(
                  controller: password,
                  obscureText: true,
                  autofocus: true,
                  validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO': null,
                  onFieldSubmitted: (_) {
                    _submit();
                  },
                  decoration: InputDecoration(
                    labelText: 'NUEVA CONTRASEÑA',
                    hintText: '*************',
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text('APLICAR CAMBIOS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
