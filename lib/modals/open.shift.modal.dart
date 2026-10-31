import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:uresax_invoice_sys_cloud/models/workday.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class OpenShiftModal extends StatefulWidget {
  int periodId;
  int? workdayId;
  Function(double amount, String description, int period, int? workdayId,
      WorkdayModel? workday) onConfirm;
  OpenShiftModal(
      {super.key,
      required this.periodId,
      required this.workdayId,
      required this.onConfirm});

  @override
  State<OpenShiftModal> createState() => _OpenShiftModalState();
}

class _OpenShiftModalState extends State<OpenShiftModal> {
  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  TextEditingController amount = TextEditingController();
  TextEditingController description = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey();

  WorkdayModel? currentWorkday;

  List<Map<String, dynamic>> jornadas = [
    {'id': 1, 'name': 'MAÑANA'},
    {'id': 2, 'name': 'TARDE'},
    {'id': 3, 'name': 'NOCHE'},
    {'id': 4, 'name': 'DIARIO'}
  ];

 /* _selectTurno() {
     widget.periodId = val ?? 1;
      var jornada =jornadas[widget.periodId - 1]['name'];
       description.text = 'TURNO $jornada ${DateTime.now().format(payload: 'DD/MM/YYYY')}';
  }*/

  @override
  void initState() {
    var jornada = jornadas[widget.periodId - 1]['name'];

    if (widget.workdayId == null) {
      if (workdays.isNotEmpty) {
        currentWorkday = workdays[0];
        widget.workdayId = currentWorkday?.id;
      }
    } else {
      if (workdays.isNotEmpty) {
        currentWorkday = workdays.firstWhere((x) => x.id == widget.workdayId);
      }
    }

    amountInputFormatter = AmountInputFormatter(
        fractionalDigits: 2, initialValue: company?.defaultCashShiftAmount);
    amount.value = amountInputFormatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
            text:
                company?.defaultCashShiftAmount?.toStringAsFixed(2) ?? '0.00'));
    description.text =
        'TURNO $jornada ${DateTime.now().format(payload: 'DD/MM/YYYY')}';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          key: _formKey,
          child: SizedBox(
            width: 580,
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
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close))
                  ],
                ),
                SizedBox(height: kDefaultPadding),
                workdays.isNotEmpty
                    ? Container(
                        margin: EdgeInsets.only(bottom: kDefaultPadding / 2),
                        child: DropdownButtonFormField<int>(
                            initialValue: widget.workdayId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'JORNADA',
                            ),
                            items: List.generate(workdays.length, (i) {
                              var workday = workdays[i];
                              return DropdownMenuItem(
                                  value: workday.id,
                                  child: Text(
                                      '${workday.startHourFormatted} - ${workday.endHourFormatted}'));
                            }),
                            onChanged: (val) {
                              widget.workdayId = val ?? 1;
                              currentWorkday =
                                  workdays.firstWhere((x) => x.id == val);
                            }),
                      )
                    : SizedBox(),
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
                          child: DropdownButtonFormField<int>(
                              initialValue: widget.periodId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'TURNO',
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
                          widget.onConfirm(
                              amountInputFormatter.doubleValue,
                              description.text,
                              widget.periodId,
                              widget.workdayId,
                              currentWorkday);
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
