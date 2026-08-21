import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/date.range_widget.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';

class CreditNotesPage extends StatefulWidget {
  const CreditNotesPage({super.key});

  @override
  State<CreditNotesPage> createState() => _CreditNotesPageState();
}

class _CreditNotesPageState extends State<CreditNotesPage> {
  TextEditingController searchController = TextEditingController();
  String? search;

  List<Sale> creditNotes = [];
  DateTime startDate = DateTime.now();
  late List<DateTime?> dates = [
    startDate.startOfMonth(),
    DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59)
        .endOfMonth()
  ];

  List<Map<String, dynamic>> salesOptions = [];

  Future? future;

  ScrollController scrollControllerY = ScrollController();

  _showInvoice(Sale sale) async {
    showLoader(context);
    try {
  
      var items = await sale.getSaleData();
      

      sale.items = items;

   
      pw.Document doc;

      if (enabledVerticalPosInvoice) {
        doc = createVerticalInvoice(sale);
      } else {
        doc = await createInvoice(sale);
      }

      var bytes = await doc.save();
      var dir = await getUresaxInvoiceDir();

      var file = File(path.join(
          dir.path,
          company?.name,
          'NOTAS DE CREDITO',
          sale.createdAt?.format(payload: 'YYYYMM'),
          'PDFS',
          '${sale.clientName}-${sale.ncf}-${company?.name}.PDF'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);

      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(),color: Colors.red);
    }
  }

  _generateXmlFile(Sale sale) async {
    try {
      var dir = await getUresaxInvoiceDir();
      var file = File(path.join(dir.path, company?.name, 'NOTAS DE CREDITO',
          sale.createdAt?.format(payload: 'YYYYMM'), 'XML', '${sale.clientIdentification}${sale.ncf}.xml'));
      await file.create(recursive: true);
      await file.writeAsString(sale.ecfXmlFirmado ?? '');

      await OpenFile.open(file.path);
    } catch (e) {
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _onSelectedSaleOption(int? option, Sale sale) async {
    switch (option) {
      case 1:
        _showInvoice(sale);
        break;

      case 2:
        _generateXmlFile(sale);
        break;

      case 3:
        showLoader(context);
        try {
          var items = await sale.getSaleData();
          sale.items = items;
          var bytes = await createDefaultTicket(sale: sale);
          await PrinterHandler.printBytes(devicePos!, bytes);
          await LogHandler.printEvent(
              'SE IMPRIMIO LA NOTA DE CREDITO ${sale.ncf}');
          Navigator.pop(context);
        } catch (e) {
          Navigator.pop(context);
          showTopSnackBar(context, message: e.toString(), color: Colors.red);
          await LogHandler.printError(e.toString());
        }
        break;

      default:
    }
  }

  _initAsync() async {
    try {
      creditNotes = await getCreditNotes(
          startDate: dates.first!, endDate: dates.last!, search: search);

      setState(() {});
    } catch (e) {
      print(e);
      setState(() {});
      rethrow;
    }
  }

  Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_printing-invoices_osgs.svg',
              width: 320)
        ],
      ),
    );
  }

  Widget get contentFilled {
    return ScrollMoveEventWidget(
        scrollControllerY: scrollControllerY,
        child: ListView.separated(
            controller: scrollControllerY,
            separatorBuilder: (ctx, i) => const Divider(),
            itemCount: creditNotes.length,
            itemBuilder: (ctx, index) {
              var item = creditNotes[index];
              List<Map<String, dynamic>> salesOptions = [
                {'id': 1, 'name': 'Ver Factura'},
              ];

              if (item.ecfXmlFirmado != null) {
                salesOptions
                    .add({'id': 2, 'name': 'Generar Archivo XML ${item.ncf}'});
              }

              if (eCommerceMode) {
                salesOptions.add({'id': 3, 'name': 'Imprimir factura'});
              }
              return ListTile(
                key: ValueKey(item.id),
                minVerticalPadding: kDefaultPadding,
                leading: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    color: Theme.of(context).primaryColor.withOpacity(0.04),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                ),
                title: Text('${item.ncf} - ${item.ncfAffected}',
                    style: Theme.of(context).textTheme.bodyMedium),
                subtitle: Text('${item.clientName}\n${item.createdAt?.format(payload: 'DD/MM/YYYY')}'),
                trailing: Wrap(
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    item.estadoDgii != null
                        ? Container(
                            margin: EdgeInsets.only(
                                left: kDefaultPadding / 2,
                                right: kDefaultPadding),
                            padding: EdgeInsets.all(kDefaultPadding / 2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: item.statusColorDgii.withOpacity(0.04)),
                            child: Text(
                              item.estadoDgiiNombre ?? '',
                              style: TextStyle(color: item.statusColorDgii),
                            ),
                          )
                        : SizedBox(),
                    Text(
                        item.currencyId == 1
                            ? item.total?.toDop()
                            : item.total?.toUS(),
                        style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(width: kDefaultPadding),
                    PopupMenuButton<int>(
                        onSelected: (option) =>
                            _onSelectedSaleOption(option, item),
                        itemBuilder: (ctx) {
                          return List.generate(salesOptions.length, (index) {
                            var option = salesOptions[index];

                            return PopupMenuItem(
                                value: option['id'],
                                child: Text(option['name']));
                          });
                        }),
                    SizedBox(width: kDefaultPadding),
                  ],
                ),
              );
            }));
  }

  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('TUS NOTAS DE CREDITO (${creditNotes.length})'),
          actions: [
            Wrap(
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 190,
                  child: TextFormField(
                    controller: searchController,
                    onFieldSubmitted: (words) {
                      search = words;
                      setState(() {
                        future = _initAsync();
                      });
                    },
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(style: BorderStyle.none, width: 0)),
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'BUSCAR NCF...',
                        suffixIcon: Wrap(
                          runAlignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(Icons.search),
                            SizedBox(width: kDefaultPadding)
                          ],
                        )),
                  ),
                ),
                SizedBox(width: kDefaultPadding),
                SizedBox(
                  width: 290,
                  child: DateRangeWidget(
                      dates: dates,
                      onChanged: (xdates) async {
                        dates = [
                          xdates.first,
                          xdates.last!.copyWith(
                            hour: 23,
                            minute: 59,
                            second: 59,
                          )
                        ];
                        setState(() {
                          future = _initAsync();
                        });
                      }),
                ),
                SizedBox(
                  width: kDefaultPadding,
                ),
              ],
            )
          ],
        ),
        body: FutureBuilder(
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
                  creditNotes.isNotEmpty) {
                return contentFilled;
              }

              return contentEmpty;
            }),
        floatingActionButton: Stack(
          children: [
            Positioned(
              bottom: 20,
              right: kDefaultPadding * 2,
              child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      search = null;
                      future = _initAsync();
                    });
                  },
                  child: Icon(Icons.restore)),
            )
          ],
        ));
  }
}
