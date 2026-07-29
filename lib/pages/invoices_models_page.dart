import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:uresax_invoice_sys_cloud/models/invoice.model.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class InvoicesModelsPage extends StatefulWidget {
  const InvoicesModelsPage({super.key});

  @override
  State<InvoicesModelsPage> createState() => _InvoicesModelsPageState();
}

class _InvoicesModelsPageState extends State<InvoicesModelsPage> {
  List<InvoiceModel> invoices = [
    InvoiceModel(
        id: 0,
        name: 'PREDETERMINADA',
        imageAsset: 'assets/imgs/DEFAULTINVOICE.png'),
    InvoiceModel(
        id: 1,
        name: 'FREELANCE INVOICE',
        imageAsset: 'assets/imgs/FREELANCEINVOICE.png'),
    InvoiceModel(
        id: 2,
        name: 'EPIC RED INVOICE',
        imageAsset: 'assets/imgs/EPICREDINVOICE.png'),
            InvoiceModel(
        id: 3,
        name: 'EPIC BLUE INVOICE',
        imageAsset: 'assets/imgs/EPICBLUEINVOICE.png'),
     
            InvoiceModel(
        id: 4,
        name: 'JULY MOTORS INVOICE',
        imageAsset: 'assets/imgs/JULYMOTORSINVOICE.png'),
               InvoiceModel(
        id: 5,
        name: 'INVOICE STORE',
        imageAsset: 'assets/imgs/INVOICESTORE.png'),
                       InvoiceModel(
        id: 6,
        name: 'IDEAL TIME INVOICE',
        imageAsset: 'assets/imgs/IDEALTIMEINVOICE.png'),
                             InvoiceModel(
        id: 7,
        name: 'R LOPEZ INVOICE',
        imageAsset: 'assets/imgs/RLOPEZINVOICE.png'),

                                    InvoiceModel(
        id: 8,
        name: 'TECHO INVOICE',
        imageAsset: 'assets/imgs/TECHOINVOICE.png'),
  ];

  int currentSelected = 0;

  @override
  void initState() {
    if (!mounted) return;
    var value = localStorage.getItem('CURRENT_INVOICE_INDEX') ?? '0';

    currentSelected = int.parse(value);
    setState(() {});

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FACTURAS (${invoices.length})'),
      ),
      body: GridView.builder(
          itemCount: invoices.length,
          padding: EdgeInsets.only(
              top: kDefaultPadding,
              left: kDefaultPadding,
              right: kDefaultPadding),
          physics: Theme.of(context).platform == TargetPlatform.iOS ||
                  Theme.of(context).platform == TargetPlatform.macOS
              ? const BouncingScrollPhysics()
              : const ClampingScrollPhysics(),
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemBuilder: (ctx, i) {
            var invoice = invoices[i];
            return GestureDetector(
              onTap: () {
                setState(() {
                  currentSelected = i;
                  localStorage.setItem(
                      'CURRENT_INVOICE_INDEX', currentSelected.toString());
                });
              },
              child: Card(
                shape: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: currentSelected == i
                            ? Theme.of(context).primaryColor
                            : Colors.transparent)),
                child: Center(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(invoice.imageAsset ?? '', width: 180),
                  ],
                )),
              ),
            );
          }),
    );
  }
}
