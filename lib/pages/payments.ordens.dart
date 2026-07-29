import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.orden.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:path/path.dart' as path;

class PaymentsOrdensPage extends StatefulWidget {
  WareHouseElement element;
  PaymentsOrdensPage({super.key, required this.element});

  @override
  State<PaymentsOrdensPage> createState() => _PaymentsOrdensPageState();
}

class _PaymentsOrdensPageState extends State<PaymentsOrdensPage> {
  List<PaymentOrden> payments = [];

  _initAsync() async {
    try {
      payments = await widget.element.getPaymentsOrdens();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    if (!mounted) return;
    _initAsync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.element.ordenNumString ?? widget.element.entryNumString} - PAGOS (${payments.length})'),
      ),
      body: ListView.separated(
          itemBuilder: (ctx, i) {
            var payment = payments[i];
            return ListTile(
              key: ValueKey(payment.id),
              minVerticalPadding: kDefaultPadding,
              leading: Container(
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(90),
                  color: Theme.of(context).primaryColor.withOpacity(0.04),
                ),
                child: Center(
                  child: Icon(
                    Icons.attach_money_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
              ),
              title: Text(payment.providerName ?? '',
                  style: Theme.of(context).textTheme.bodyMedium),
              subtitle: Text(payment.paymentMethodName ?? ''),
              trailing: Wrap(
                children: [
                  Text(payment.createdAt!
                      .toLocal()
                      .format(payload: 'DD/MM/YYYY')),
                  SizedBox(width: kDefaultPadding),
                  Text(payment.currencyId == 1 ? payment.amount?.toDop() : payment.amount?.toUS()),
                  SizedBox(width: kDefaultPadding),
                  IconButton(
                      onPressed: () async {
                        var doc = await createPaymentOrdenInvoice(payment);
                        var dir = await getUresaxInvoiceDir();
                        var bytes = await doc.save();

                        var file = File(path.join(
                            dir.path,
                            'PAGOS',
                            payment.createdAt?.format(payload: 'YYYYMM'),
                            'PDFS',
                            'PAGO-${payment.id}-${payment.ordenNumString}-${company?.name}.PDF'));
                        await file.create(recursive: true);
                        await file.writeAsBytes(bytes);
                        await OpenFile.open(file.path);
                      },
                      icon: Icon(Icons.visibility)),
                  SizedBox(width: kDefaultPadding),
                ],
              ),
            );
          },
          separatorBuilder: (ctx, i) => const Divider(),
          itemCount: payments.length),
    );
  }
}
