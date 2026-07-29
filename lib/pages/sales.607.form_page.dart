import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class Sales607FormPage extends StatefulWidget {
  const Sales607FormPage({super.key});

  @override
  State<Sales607FormPage> createState() => _Sales607FormPageState();
}

class _Sales607FormPageState extends State<Sales607FormPage> {
  List<Sale> sales = [];
  TextEditingController period = TextEditingController();

  List<Map<String, dynamic>> options = [
    {'id': 1, 'name': 'Generar 607'}
  ];

  _generate607() async {
    if (sales.isEmpty) return;
    var items = sales.map((e) => e.to607()).toList();
    String res = '';
    List<List<String>> lists = [];

    for (int i = 0; i < items.length; i++) {
      var item = items[i];
      var values = item.values.map((e) => e.toString()).toList().cast<String>();
      lists.add(values);
    }
    res = const ListToCsvConverter().convert([
      [
        '607',
        company?.rncOrId?.replaceAll('-', '').toString() ?? '',
        items.length,
      ],
      ...lists
    ], fieldDelimiter: '|');

    var dir = await getUresaxInvoiceDir();
    var file = File(path.join(dir.path, '607', period.text,
        'DGII_F_${company?.rncOrId?.replaceAll('-', '')}_${period.text}.TEXT'));
    await file.create(recursive: true);
    await file.writeAsString(res);
    await OpenFile.open(file.path);
  }

  _onSelected(int? option) {
    switch (option) {
      case 1:
        _generate607();
        break;
      default:
    }
  }

  List<String> get columns {
    if (sales.isEmpty) return [];
    var cols = sales[0].toDisplay().keys.toList();
    return cols;
  }

  Widget get contentFilled {
    return Expanded(
        child: SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
              defaultColumnWidth: FixedColumnWidth(150),
              children: [
                TableRow(
                    children: List.generate(columns.length, (index) {
                  var col = columns[index];
                  return Padding(
                    padding: EdgeInsets.all(kDefaultPadding / 2),
                    child: Text(
                      col,
                      style: TextStyle(
                          fontSize: 18, color: Theme.of(context).primaryColor),
                    ),
                  );
                }))
              ],
            ),
            Table(
              defaultColumnWidth: FixedColumnWidth(150),
              children: List.generate(sales.length, (index) {
                var sale = sales[index];
                var values = sale.toDisplay().values.toList();
                return TableRow(
                    decoration: BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: Colors.black12))),
                    children: List.generate(values.length, (i) {
                      var val = values[i];
                      return Padding(
                        padding: EdgeInsets.all(kDefaultPadding),
                        child: Text(val.toString(),
                            style: Theme.of(context).textTheme.bodySmall),
                      );
                    }));
              }),
            )
          ],
        ),
      ),
    ));
  }

  Widget get contentEmpty {
    return Expanded(
        child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_printing-invoices_osgs.svg',
              width: 320)
        ],
      ),
    ));
  }

  Widget get content {
    if (sales.isEmpty) return contentEmpty;

    return contentFilled;
  }

  _onSubmit() async {
    var value = period.text;
    if(value.isNotEmpty){
       try {
      showLoader(context);
      sales = await SaleService.getSales607Form(period: value);

      if(sales.isEmpty) {
         throw 'NO SE ENCONTRO VENTAS PARA EL PERIODO: $value';
      }
      Navigator.pop(context);
      setState(() {});
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('GENERADOR DE 607'),
          actions: [
            PopupMenuButton<int?>(
                onSelected: _onSelected,
                itemBuilder: (ctx) {
                  return List.generate(options.length, (index) {
                    var option = options[index];
                    return PopupMenuItem(
                        value: option['id'], child: Text(option['name']));
                  });
                }),
            SizedBox(
              width: kDefaultPadding,
            )
          ],
        ),
        body: Padding(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(
              children: [
                SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: period,
                            onFieldSubmitted: (_) => _onSubmit(),
                            decoration: InputDecoration(
                                labelText: 'PERIODO', hintText: 'YYYYMM'),
                          ),
                        ),
                        SizedBox(width: kDefaultPadding / 2),
                        SizedBox(
                            height: 50,
                            child: ElevatedButton(
                                onPressed: _onSubmit, child: Text('BUSCAR')))
                      ],
                    )),
                SizedBox(
                  height: kDefaultPadding,
                ),
                content
              ],
            )));
  }
}
