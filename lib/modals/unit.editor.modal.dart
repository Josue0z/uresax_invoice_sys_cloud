import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:number_text_input_formatter/number_text_input_formatter.dart';
import 'package:uresax_invoice_sys_cloud/models/unit.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class UnitEditorModal extends StatefulWidget {
  Unit unit;
  bool editing;
  UnitEditorModal({super.key, required this.unit, this.editing = false});

  @override
  State<UnitEditorModal> createState() => _UnitEditorModalState();
}

class _UnitEditorModalState extends State<UnitEditorModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController code = TextEditingController();

  TextEditingController name = TextEditingController();

  TextEditingController symbol = TextEditingController();
  TextEditingController conversionFactor = TextEditingController();

  bool isBaseUnit = false;
  bool status = true;

  String get title {
    return widget.editing ? 'EDITAR UNIDAD' : 'AGREGAR UNIDAD';
  }

  String get action {
    return !widget.editing ? 'GUARDAR' : 'EDITAR';
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);

      try {
        widget.unit.name = name.text;
        widget.unit.code = code.text;
        widget.unit.symbol = symbol.text;
        widget.unit.conversionFactor = double.tryParse(conversionFactor.text);
        widget.unit.status = status;
        widget.unit.isBaseUnit = isBaseUnit;
        if (!widget.editing) {
          await widget.unit.create();
        } else {
          await widget.unit.update();
        }
        Navigator.pop(context);
        Navigator.pop(context, widget.editing ? 'UPDATE' : 'CREATE');
        showTopSnackBar(context,
            message: 'UNIDAD ${widget.editing ? 'EDITADA' : 'CREADA'}',
            color: Colors.green);
      } catch (e) {
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    name.text = widget.unit.name ?? '';
    code.text = widget.unit.code ?? '';
    symbol.text = widget.unit.symbol ?? '';
    conversionFactor.text = widget.unit.conversionFactor?.toStringAsFixed(2) ?? '';
    isBaseUnit = widget.unit.isBaseUnit ?? false;
    status = widget.unit.status ?? true;
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
                controller: name,
                validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                decoration: InputDecoration(
                    labelText: 'NOMBRE DE LA UNIDAD', hintText: 'UNIDAD #1'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              TextFormField(
                controller: code,
                validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                decoration:
                    InputDecoration(labelText: 'CODIGO', hintText: 'UND'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              TextFormField(
                controller: symbol,
                validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                decoration:
                    InputDecoration(labelText: 'SIMBOLO', hintText: 'u'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              TextFormField(
                controller: conversionFactor,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                decoration: InputDecoration(
                    labelText: 'FACTOR DE CONVERSION', hintText: '1.00'),
              ),
              SizedBox(
                height: kDefaultPadding,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ES UNIDAD BASE',
                    style: TextStyle(
                        fontSize: 16, color: Theme.of(context).primaryColor),
                  ),
                  SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Switch.adaptive(
                      value: isBaseUnit,
                      onChanged: (val) {
                        setState(() {
                          isBaseUnit = val;
                        });
                      }),
                  SizedBox(
                    height: kDefaultPadding,
                  ),
                  Text(
                    'ESTA UNIDAD ESTA ACTIVA',
                    style: TextStyle(
                        fontSize: 16, color: Theme.of(context).primaryColor),
                  ),
                  SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Switch.adaptive(
                      value: status,
                      onChanged: (val) {
                        setState(() {
                          status = val;
                        });
                      }),
                ],
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
