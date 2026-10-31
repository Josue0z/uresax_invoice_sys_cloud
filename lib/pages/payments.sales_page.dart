import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';

class PaymentSalesPage extends StatefulWidget {
  Sale sale;
  PaymentSalesPage({super.key, required this.sale});

  @override
  State<PaymentSalesPage> createState() => _PaymentSalesPageState();
}

class _PaymentSalesPageState extends State<PaymentSalesPage> {
  List<Payment> payments = [];
  Future? future;
  _initAsync() async {
    try {
      payments = await Payment.get(saleId: widget.sale.id ?? '');
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  _showPaymentInvoice(Payment payment) async {
    var doc = await createPaymentInvoice(payment);
    var dir = await getUresaxInvoiceDir();
    var bytes = await doc.save();

    var file = File(path.join(
        dir.path,
        'PAGOS',
        payment.createdAt?.format(payload: 'YYYYMM'),
        'PDFS',
        'PAGO-${payment.id}-${payment.ncf}-${company?.name}.PDF'));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  Widget get contentFilled {
    return ListView.separated(
          separatorBuilder: (ctx, i) => const Divider(),
          itemCount: payments.length,
          itemBuilder: (ctx, index) {
            var pay = payments[index];
            print(pay.createdAt);
            return ListTile(
              key: ValueKey(pay.id),
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
              title: Text(pay.clientName ?? '',
                  style: Theme.of(context).textTheme.bodyMedium),
              subtitle: Text(pay.paymentMethodName ?? ''),
              trailing: Wrap(
                children: [
                  Text(pay.createdAt!
                      .format(payload: 'DD/MM/YYYY')),
                  SizedBox(width: kDefaultPadding),
                  Text(pay.currencyId == 1
                      ? pay.amount?.toDop()
                      : pay.amount?.toUS()),
                  SizedBox(width: kDefaultPadding),
                  IconButton(
                      onPressed: () => _showPaymentInvoice(pay),
                      icon: Icon(Icons.visibility)),
                  SizedBox(width: kDefaultPadding),
                ],
              ),
            );
          });
  }

    Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_wallet_diag.svg', width: 250)
        ],
      ),
    );
  }

  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  void initState() {
   setState(() {
      future =  _initAsync();
   });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sale.ncf} - PAGOS (${payments.length})'),
      ),
      body:  FutureBuilder(
          future: future,
          builder: (ctx, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return contentLoading;
            }

            if (s.hasError) {
              return ContentErrorWidget(
                error: s.error.toString(),
                onRetry: () {
                  setState(() {
                    future = _initAsync();
                  });
                },
              );
            }
            if (s.connectionState == ConnectionState.done &&
                payments.isNotEmpty) {
              return contentFilled;
            }

            return contentEmpty;
          }),
    );
  }
}
