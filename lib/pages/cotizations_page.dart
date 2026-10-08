import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/dgiiStates.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/pages/invoice_generator_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/pos_screen.dart';
import 'package:uresax_invoice_sys_cloud/pages/table_invoice_generator.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/date.range_widget.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';

class CotizationsPage extends StatefulWidget {
  const CotizationsPage({super.key});

  @override
  State<CotizationsPage> createState() => _CotizationsPageState();
}

class _CotizationsPageState extends State<CotizationsPage> {
  List<Sale> cotizations = [];
  DateTime startDate = DateTime.now();
  late List<DateTime?> dates = [
    startDate.startOfMonth(),
    DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59)
        .endOfMonth()
  ];

  List<Map<String, dynamic>> options = [
    {
      'id': 1,
      'name': 'Ver Reporte Por Tipo de Ncf',
      'icon': './assets/svgs/pdf-file-svgrepo-com.svg'
    },
    {
      'id': 2,
      'name': 'Ver Reporte Por Tipo de Ingreso',
      'icon': './assets/svgs/pdf-file-svgrepo-com.svg'
    },
    {
      'id': 3,
      'name': 'Ver Reporte Global',
      'icon': './assets/svgs/pdf-file-svgrepo-com.svg'
    },
    {
      'id': 4,
      'name': 'Ver Reporte En Excel',
      'icon': './assets/svgs/excel-svgrepo-com.svg'
    },
    {
      'id': 5,
      'name': 'Ver Reporte de Cajas',
      'icon': './assets/svgs/pdf-file-svgrepo-com.svg'
    },
    {
      'id': 6,
      'name': 'Ver Reporte de Deudas por Cliente',
      'icon': './assets/svgs/pdf-file-svgrepo-com.svg'
    }
  ];

  String? ncfTypeId;
  List<NcfType> ncfsTypes = [];
  List<DgiiState> dgiiStates = [];
  String? search;
  SaleStatus? saleStatus = SaleStatus.all;

  int? estadoDgii;

  TextEditingController searchController = TextEditingController();

  Future? future;

  ScrollController scrollControllerY = ScrollController();

  Future<void> _initAsync() async {
    try {
      cotizations = await getCotizations(
          startDate: dates.first!, endDate: dates.last!, search: search);

      setState(() {});
    } catch (e) {
      print(e);
      setState(() {});
      rethrow;
    }
  }

  _showInvoice(Sale sale) async {
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
          'COTIZACIONES',
          sale.createdAt?.format(payload: 'YYYYMM'),
          'PDFS',
          '${sale.clientName}-${sale.ncf}-${company?.name}.PDF'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      //await showPdfView(file: file, context: context);
      await OpenFile.open(file.path);
    } catch (e) {
      print(e);
      await LogHandler.printError(e.toString());
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showInvoicePage(Sale sale) async {
    var items = await sale.getSaleData();
    sale.items = items;

    dynamic res;

    if (enabledTableInvoiceGenerator) {
      res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => TableInvoiceGenerator(
                  editing: false,
                  generateNcfFromProforma: true,
                  sale: sale,
                  items: items,
                  mode: sale is SaleService
                      ? SaleMode.service
                      : SaleMode.product)));
    } else if (enabledInvoiceSimpleGenerator) {
     res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => PosScreenPage(
                  sale: sale,
                  items: items,
                  editing: false,
                  generateNcfFromProforma: true,
                  mode: sale is SaleProduct
                      ? SaleMode.product
                      : SaleMode.service)));
  
    } else {
      res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => InvoiceGeneratorPage(
                  editing: false,
                  sale: sale,
                  items: items,
                  generateNcfFromProforma: true,
                  mode: sale is SaleService
                      ? SaleMode.service
                      : SaleMode.product)));
    }

    if (res!=null) {
      setState(() {
        future = _initAsync();
      });
    }
  }

  _onSelectedSaleOption(int? option, Sale sale) async {
    try {
      switch (option) {
        case 1:
          _showInvoice(sale);
          break;
        case 4:
          _showInvoicePage(sale);
          break;

        case 6:
          showLoader(context);
          try {
            var items = await sale.getSaleData();
            sale.items = items;
            var bytes = await createDefaultTicket(sale: sale);
            await PrinterHandler.printBytes(devicePos!, bytes);
            await LogHandler.printEvent('SE IMPRIMIO LA FACTURA ${sale.ncf}');
            Navigator.pop(context);
          } catch (e) {
            Navigator.pop(context);
            showTopSnackBar(context, message: e.toString(), color: Colors.red);
            await LogHandler.printError(e.toString());
          }
          break;

        case 7:
          _showInvoicePage(sale);
          break;
        default:
      }
    } catch (e) {
      if (option == 6) {
        Navigator.pop(context);
      }
      rethrow;
    }
  }

  Widget get contentFilled {
    return ScrollMoveEventWidget(
        scrollControllerY: scrollControllerY,
        child: ListView.separated(
            controller: scrollControllerY,
            separatorBuilder: (ctx, i) => const Divider(),
            itemCount: cotizations.length,
            itemBuilder: (ctx, index) {
              var sale = cotizations[index];

              List<Map<String, dynamic>> salesOptions = [
                {'id': 1, 'name': 'Ver Factura'},
              ];
              if (eCommerceMode) {
                salesOptions.add({'id': 6, 'name': 'Imprimir factura'});
              }

              if (currentUser!.permissions!
                  .contains('ALLOW_CREATE_FISCAL_INVOICE')) {
                 salesOptions.add({'id': 7, 'name': 'Generar Factura Fiscal'});
              }

              return ListTile(
                key: ValueKey(sale.id),
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
                title: Text(sale.ncf ?? '',
                    style: Theme.of(context).textTheme.bodyMedium),
                subtitle: Text(
                    '${sale.clientName}\n${sale.createdAt?.format(payload: 'DD/MM/YYYY')}'),
                trailing: Wrap(
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(kDefaultPadding / 2),
                      decoration: BoxDecoration(
                        color: sale.color.withOpacity(0.04),
                      ),
                      child: Text(
                        sale.paidLabel,
                        style: TextStyle(color: sale.color, fontSize: 18),
                      ),
                    ),
                    SizedBox(width: kDefaultPadding),
                    Text(
                        sale.currencyId == 1
                            ? sale.total?.toDop()
                            : sale.total?.toUS(),
                        style: Theme.of(context).textTheme.bodyMedium),
                    SizedBox(width: kDefaultPadding),
                    PopupMenuButton<int>(
                      onSelected: (option) =>
                          _onSelectedSaleOption(option, sale),
                      itemBuilder: (ctx) {
                        return List.generate(salesOptions.length * 2 - 1,
                            (index) {
                          if (index.isOdd) {
                            // cada índice impar será un divisor
                            return const PopupMenuDivider();
                          } else {
                            var option = salesOptions[index ~/ 2];
                            return PopupMenuItem<int>(
                              value: option['id'],
                              child: Text(option['name']),
                            );
                          }
                        });
                      },
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('TUS COTIZACIONES (${cotizations.length})'),
          actions: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
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
                        dates = xdates;
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
              if (cotizations.isNotEmpty) {
                return contentFilled;
              }

              return contentEmpty;
            }),
        floatingActionButton: Stack(
          children: [
            Positioned(
              right: kDefaultPadding * 3,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: () {
                  ncfTypeId = null;
                  ncfsTypes = [];
                  dgiiStates = [];
                  saleStatus = SaleStatus.all;
                  estadoDgii = null;
                  search = null;

                  setState(() {
                    future = _initAsync();
                  });

                  searchController.clear();
                },
                child: Icon(Icons.restore),
              ),
            )
          ],
        ));
  }
}
