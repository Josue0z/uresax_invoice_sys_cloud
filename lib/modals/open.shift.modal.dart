import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class OpenShiftModal extends StatefulWidget {
  int periodId;
  Function(double amount, String description) onConfirm;
  OpenShiftModal({super.key, required this.periodId, required this.onConfirm});

  @override
  State<OpenShiftModal> createState() => _OpenShiftModalState();
}

class _OpenShiftModalState extends State<OpenShiftModal> {
  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  TextEditingController amount = TextEditingController();
  TextEditingController description = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey();

  List<Map<String, dynamic>> jornadas = [
    {'id': 1, 'name': 'MAÑANA'},
    {'id': 2, 'name': 'TARDE'},
    {'id': 3, 'name': 'NOCHE'}
  ];
  @override
  Widget build(BuildContext context) {
    return Dialog(
      
      child: Form(
          key: _formKey,
          child: SizedBox(
            width: 450,
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.all(kDefaultPadding),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(
                      'ABRIENDO TURNO...',
                      style: TextStyle(
                          fontSize: 20, color: Theme.of(context).primaryColor),
                    )),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close))
                  ],
                ),
                SizedBox(height: kDefaultPadding),
                Container(
                  margin: EdgeInsets.only(bottom: kDefaultPadding),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: amount,
                          validator: (val) =>
                              val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                          inputFormatters: [amountInputFormatter],
                          decoration: InputDecoration(
                              labelText: 'MONTO INICIAL', hintText: '0.00'),
                        ),
                      ),
                      SizedBox(width: kDefaultPadding),
                      Expanded(
                          child: DropdownButtonFormField(
                              initialValue: widget.periodId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'JORNADA',
                              ),
                              items: List.generate(jornadas.length, (i) {
                                var jornada = jornadas[i];
                                return DropdownMenuItem(
                                    value: jornada['id'],
                                    child: Text(jornada['name']));
                              }),
                              onChanged: null))
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: kDefaultPadding),
                  child: TextFormField(
                    controller: description,
                    validator: (val) =>
                        val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                    decoration: InputDecoration(
                        labelText: 'DESCRIPCION', hintText: 'Escribir algo...'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onConfirm(amountInputFormatter.doubleValue,
                              description.text);
                        }
                      },
                      child: Text('ABRIR TURNO')),
                )
              ],
            ),
          )),
    );
  }
}
