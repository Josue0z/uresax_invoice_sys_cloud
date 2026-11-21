import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class PasswordEditorWidget extends StatefulWidget {
  TextEditingController controller = TextEditingController();
  String labelText;
  String hintText;
  bool isLogin;
  void Function(String)? onFieldSubmitted;
  PasswordEditorWidget(
      {super.key, required this.controller, this.isLogin = false, this.labelText = 'CONTRASEÑA', this.hintText = 'Escribir algo...', this.onFieldSubmitted});

  @override
  State<PasswordEditorWidget> createState() => _PasswordEditorWidgetState();
}

class _PasswordEditorWidgetState extends State<PasswordEditorWidget> {
  bool visibility = false;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !visibility,
      validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
      onFieldSubmitted: (value) {
        if (widget.onFieldSubmitted != null) {
          widget.onFieldSubmitted!(value);
        }
      },
      decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          suffixIcon: Wrap(
            children: [
              IconButton(
                  onPressed:currentUser?.roleId == 1  && widget.isLogin == false? null : () {
                    setState(() {
                      visibility = !visibility;
                    });
                  },
                  icon: Icon(
                      visibility ? Icons.visibility : Icons.visibility_off)),
              SizedBox(width: kDefaultPadding / 2)
            ],
          )),
    );
  }
}
