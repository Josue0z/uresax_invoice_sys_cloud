import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uresax_invoice_sys_cloud/models/cash.shift.model.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class CashShiftCloseModal extends StatefulWidget {
  CashShiftModel cashShiftModel;
  List<Denominations> denominations;
  CashShiftCloseModal(
      {super.key, required this.cashShiftModel, required this.denominations});

  @override
  State<CashShiftCloseModal> createState() => _CashShiftCloseModalState();
}

class _CashShiftCloseModalState extends State<CashShiftCloseModal> {
  Map<String, dynamic> denos = {
    '2000': {'total': 0, 'counts': 0},
    '1000': {'total': 0, 'counts': 0},
    '500': {'total': 0, 'counts': 0},
    '200': {'total': 0, 'counts': 0},
    '100': {'total': 0, 'counts': 0},
    '50': {'total': 0, 'counts': 0},
    '25': {'total': 0, 'counts': 0},
    '10': {'total': 0, 'counts': 0},
    '5': {'total': 0, 'counts': 0},
    '1': {'total': 0, 'counts': 0},
  };

  _submit() async {
    showLoader(context);
    try {

      widget.cashShiftModel.effectiveCount = totalSales;

      widget.cashShiftModel.denominations = denos;

      await widget.cashShiftModel.closeCashShiftReport();
      Navigator.pop(context);
      Navigator.pop(context, 'UPDATE');
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  double get totalSales {
    double total = 0;
    var keys = denos.keys.toList();

    for (int i = 0; i < keys.length; i++) {
      var key = keys[i];
      total += denos[key]['total'];
    }
    return total;
  }

  double get dif {
    return totalSales - (widget.cashShiftModel.openingAmount! + widget.cashShiftModel.effectiveCalc!);
  }
  
  String get statusName {
    if(dif == 0)return 'CUADRADO';
    if(dif > 0)return 'SOBRANTE';
    return 'FALTANTE';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          child: Container(
        width: 560,
        height: 700,
        padding: EdgeInsets.all(kDefaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(
                  'CERRANDO TURNO (${widget.cashShiftModel.cashShiftNumber})',
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
            SizedBox(
              height: kDefaultPadding,
            ),
               Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(
                      'FONDO INICIAL',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    )),
                Text('${widget.cashShiftModel.openingAmount?.toCoin()}')
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(
                      'TOTAL VENTAS',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    )),
                Text('${totalSales.toCoin()}')
              ],
            ),
            const Divider(),
               Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(
                      'EFECTIVO EN VENTAS',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    )),
                Text('${widget.cashShiftModel.effectiveCalc?.toCoin()}')
              ],
            ),
            const Divider(),

                Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(
                      'ESTADO',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    )),
                Text('[${dif.toStringAsFixed(2)}]-$statusName')
              ],
            ),
            const Divider(),
            Expanded(
                child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(widget.denominations.length, (i) {
                    var d = widget.denominations[i];
                    var tag = d.value?.toInt().toString();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: kDefaultPadding / 3),
                          child: Row(
                            children: [
                              Expanded(child: Text(d.description ?? '')),
                              SizedBox(
                                width: kDefaultPadding / 2,
                              ),
                              Expanded(
                                  child: TextFormField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  var count = int.tryParse(value) ?? -1;

                                  if (count != -1) {
                                    denos[tag!]['counts'] = count;
                                  } else {
                                    count = 0;
                                    denos[tag!]['counts'] = count;
                                  }

                                  denos[tag]['total'] =
                                      count * d.value!.toInt();
                                },
                                onTapUpOutside: (c) {
                                  setState(() {});
                                },
                                onTap: () {
                                  setState(() {});
                                },
                                validator: (val) {
                                  var n = int.tryParse(val ?? 'x') ?? -1;
                                  var n2 = int.parse(tag!);
                                  if (n != n2) {
                                    return '';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero),
                                    hintText: '0.00'),
                              )),
                              Text(
                                '=',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context).primaryColor),
                              ),
                              Expanded(
                                  child: TextFormField(
                                controller: TextEditingController(
                                    text: denos[tag]['total'].toString()),
                                readOnly: true,
                                decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero),
                                    hintText: '0.00'),
                              )),
                            ],
                          ),
                        ),
                        Divider()
                      ],
                    );
                  }),
                ],
              ),
            )),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                  onPressed: _submit, child: Text('APLICAR CIERRE')),
            )
          ],
        ),
      )),
    );
  }
}
