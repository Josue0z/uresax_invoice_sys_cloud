import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/filter.sales.modal.dart';
import 'package:uresax_invoice_sys_cloud/modals/payment.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/dgiiStates.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/pages/invoice_generator_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/payments.sales_page.dart';
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

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Sale> sales = [];
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
      'id': 7,
      'name': 'Ver Reporte Por Conceptos',
      'icon': './assets/svgs/pdf-file-svgrepo-com.svg'
    },
    {
      'id': 6,
      'name': 'Ver Reporte de Deudas por Cliente',
      'icon': './assets/svgs/pdf-file-svgrepo-com.svg'
    },
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

  List<String> get ncfsSelected {
    return ncfsTypes.map((e) => e.id!).toList();
  }

  List<int> get dgiiStatesSelected {
    return dgiiStates.map((e) => e.id!).toList();
  }

  Future<void> _initAsync() async {
    try {
      sales = await getSales(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfTypeId: ncfTypeId,
          ncfsTypes: ncfsSelected,
          saleStatus: saleStatus,
          estadoDgii: estadoDgii,
          dgiiStates: dgiiStatesSelected,
          search: search);

      setState(() {});
    } catch (e) {
      print(e);
      setState(() {});
      rethrow;
    }
  }

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
          'VENTAS',
          sale.createdAt?.format(payload: 'YYYYMM'),
          'PDFS',
          '${sale.clientName}-${sale.ncf}-${company?.name}.pdf'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);

      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      print(e);
      Navigator.pop(context);
      await LogHandler.printError(e.toString());
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showPaymentModal(Sale sale) async {
    var res = await showDialog(
        context: context, builder: (ctx) => PaymentEditorModal(sale: sale));
    if (res == 'UPDATE') {
      setState(() {
        future = _initAsync();
      });
    }
  }

  _showFiltersModal() async {
    var res = await showDialog(
        context: context,
        builder: (ctx) => FilterSalesModal(
            ncfTypeId: ncfTypeId,
            ncfsTypes: ncfsTypes,
            saleStatus: saleStatus,
            dgiiState: estadoDgii,
            dgiiStates: dgiiStates));
    if (res is Map) {
      ncfTypeId = res['ncfTypeId'];
      ncfsTypes = res['ncfsTypes'];
      saleStatus = res['saleStatus'];
      estadoDgii = res['dgiiState'];
      dgiiStates = res['dgiiStates'];

      setState(() {
        future = _initAsync();
      });
    }
  }

  _showReportByTypeNcf() async {
    showLoader(context);
    try {
      var data = await getSalesReportByTypeNcf(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfTypeId: ncfTypeId,
          ncfsTypes: ncfsSelected,
          estadoDgii: estadoDgii,
          dgiiStates: dgiiStatesSelected,
          saleStatus: saleStatus);

      var bytes = data['bytes'];

      var dir = await getUresaxInvoiceDir();
      var period = dates.first!.format(payload: 'YYYYMM');
      var start = dates.first!.format(payload: 'DD-MM-YYYY');
      var end = dates.last!.format(payload: 'DD-MM-YYYY');
      var file = File(path.join(dir.path, 'REPORTES', 'PDFS', period,
          'REPORTE_POR_TIPO_DE_NCF_${company?.name}_$start - $end.PDF'));

      await file.create(recursive: true);
      await file.writeAsBytes(bytes);

      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showReportByTypeIncome() async {
    showLoader(context);
    try {
      var data = await getSalesTypeIncomesReport(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfTypeId: ncfTypeId,
          ncfsTypes: ncfsSelected,
          estadoDgii: estadoDgii,
          dgiiStates: dgiiStatesSelected,
          saleStatus: saleStatus);

      var bytes = data['bytes'];

      var dir = await getUresaxInvoiceDir();
      var period = dates.first!.format(payload: 'YYYYMM');
      var start = dates.first!.format(payload: 'DD-MM-YYYY');
      var end = dates.last!.format(payload: 'DD-MM-YYYY');
      var file = File(path.join(dir.path, 'REPORTES', 'PDFS', period,
          'REPORTE_POR_TIPO_DE_INGRESO_${company?.name}_$start - $end.PDF'));

      await file.create(recursive: true);
      await file.writeAsBytes(bytes);

      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showReportGlobal() async {
    showLoader(context);
    try {
      var result = await getSalesReportGlobal(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfTypeId: ncfTypeId,
          ncfsTypes: ncfsSelected,
          estadoDgii: estadoDgii,
          dgiiStates: dgiiStatesSelected,
          saleStatus: saleStatus);

      var bytes = result['bytes'];

      String period = dates.last!.format(payload: 'YYYYMM');

      String date1 = dates.first!.format(payload: 'YYYYMMDD');
      String date2 = dates.last!.format(payload: 'YYYYMMDD');

      var dir = await getUresaxInvoiceDir();
      var file = File(path.join(dir.path, 'REPORTES', 'PDFS', period,
          'REPORTE_GLOBAL_${company?.name}_$date1-$date2.PDF'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showExcelReport() async {
    showLoader(context);
    try {
      var result = await generateExcelSalesReport(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfsTypes: ncfsSelected,
          dgiiStates: dgiiStatesSelected,
          saleStatus: saleStatus);

      var bytes = result;

      String period = dates.last!.format(payload: 'YYYYMM');

      String date1 = dates.first!.format(payload: 'YYYYMMDD');
      String date2 = dates.last!.format(payload: 'YYYYMMDD');

      var dir = await getUresaxInvoiceDir();
      var file = File(path.join(dir.path, 'REPORTES', 'EXCEL', period,
          'REPORTE_EXCEL_607_${company?.name}_$date1-$date2.XLS'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes!);
      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showReportBoxes() async {
    showLoader(context);
    try {
      var result = await getSalesReportBoxes(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfTypeId: ncfTypeId,
          ncfsTypes: ncfsSelected,
          estadoDgii: estadoDgii,
          dgiiStates: dgiiStatesSelected,
          saleStatus: saleStatus);

      var bytes = result['bytes'];

      String period = dates.last!.format(payload: 'YYYYMM');

      String date1 = dates.first!.format(payload: 'YYYYMMDD');
      String date2 = dates.last!.format(payload: 'YYYYMMDD');

      var dir = await getUresaxInvoiceDir();
      var file = File(path.join(dir.path, 'REPORTES', 'PDFS', period,
          'REPORTE_CAJAS_${company?.name}_$date1-$date2.PDF'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showReportByConcepts() async {
    showLoader(context);
    try {
      var result = await getSalesReportByConcepts(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfTypeId: ncfTypeId,
          ncfsTypes: ncfsSelected,
          estadoDgii: estadoDgii,
          dgiiStates: dgiiStatesSelected,
          saleStatus: saleStatus);

      var bytes = result['bytes'];

      String period = dates.last!.format(payload: 'YYYYMM');

      String date1 = dates.first!.format(payload: 'YYYYMMDD');
      String date2 = dates.last!.format(payload: 'YYYYMMDD');

      var dir = await getUresaxInvoiceDir();
      var file = File(path.join(dir.path, 'REPORTES', 'PDFS', period,
          'REPORTE_CONCEPTOS_${company?.name}_$date1-$date2.PDF'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showPayments(Sale sale) async {
    Navigator.push(context,
        MaterialPageRoute(builder: (ctx) => PaymentSalesPage(sale: sale)));
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
                  editing: true,
                  sale: sale,
                  items: items,
                  mode: sale is SaleService
                      ? SaleMode.service
                      : SaleMode.product)));
    } else {
      res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => InvoiceGeneratorPage(
                  editing: true,
                  sale: sale,
                  items: items,
                  mode: sale is SaleService
                      ? SaleMode.service
                      : SaleMode.product)));
    }

    if (res == 'UPDATE') {
      setState(() {
        future = _initAsync();
      });
    }
  }

  _showReportDebtsOfClients() async {
    showLoader(context);
    try {
      var result = await getReportDebtsOfClients(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfTypeId: ncfTypeId,
          ncfsTypes: ncfsSelected,
          estadoDgii: estadoDgii,
          dgiiStates: dgiiStatesSelected,
          saleStatus: saleStatus);

      var bytes = result['bytes'];

      String period = dates.last!.format(payload: 'YYYYMM');

      String date1 = dates.first!.format(payload: 'YYYYMMDD');
      String date2 = dates.last!.format(payload: 'YYYYMMDD');

      var dir = await getUresaxInvoiceDir();
      var file = File(path.join(dir.path, 'REPORTES', 'PDFS', period,
          'REPORTE_DEUDAS_POR_CLIENTE_${company?.name}_$date1-$date2.PDF'));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      Navigator.pop(context);
      await OpenFile.open(file.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _onSelectedOption(int? option) async {
    switch (option) {
      case 1:
        _showReportByTypeNcf();
        break;
      case 2:
        _showReportByTypeIncome();
        break;
      case 3:
        _showReportGlobal();
        break;
      case 4:
        _showExcelReport();
        break;
      case 5:
        _showReportBoxes();
        break;
      case 6:
        _showReportDebtsOfClients();
      case 7:
        _showReportByConcepts();
        break;
      default:
    }
  }

  _generateXmlFile(Sale sale) async {
    try {
      var dir = await getUresaxInvoiceDir();
      var file = File(path.join(
          dir.path,
          'VENTAS',
          sale.createdAt?.format(payload: 'YYYYMM'),
          'XML',
          '${sale.clientIdentification}${sale.ncf}.xml'));
      await file.create(recursive: true);
      await file.writeAsString(sale.ecfXmlFirmado ?? '');

      await OpenFile.open(file.path);
    } catch (e) {
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _openInvoiceFolder(Sale sale) async {
    showLoader(context);
    try {
      var dir = await getUresaxInvoiceDir();

      var folderPath = path.join(dir.path, 'VENTAS',
          sale.createdAt?.format(payload: 'YYYYMM'), 'PDFS');
      Navigator.pop(context);
      await launchFile(folderPath);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _onSelectedSaleOption(int? option, Sale sale) async {
    try {
      switch (option) {
        case 1:
          _showInvoice(sale);
          break;
        case 2:
          _showPayments(sale);
          break;
        case 3:
          _showPaymentModal(sale);
        case 4:
          _showInvoicePage(sale);
          break;
        case 5:
          _generateXmlFile(sale);
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

        case 8:
          _openInvoiceFolder(sale);
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

  Map<String, double> get totalSales {
    Map<String, double> map = {};
    var xtotal = 0.0;
    var xtax = 0.0;
    for (int i = 0; i < sales.length; i++) {
      var sale = sales[i];
      var rate = sale.rate ?? 1;
      var retentionTax = sale.retentionTax ?? 0;
      var retentionIsr = sale.retentionIsr ?? 0;
      var total = sale.total ?? 0;

      if (sale.ncfTypeId != '41') {
        if (sale.ncfTypeId != '43') {
          xtotal += (total - (retentionTax + retentionIsr)) * rate;
          xtax += (sale.tax ?? 0) * rate;
        }
      }
    }
    map['total'] = xtotal;
    map['tax'] = xtax;
    return map;
  }

  Widget get contentFilled {
    return Column(
      children: [
        currentUser!.permissions!.contains('ALLOW_VIEW_SALES_TOTALS')
            ? Container(
                padding: EdgeInsets.symmetric(
                    horizontal: kDefaultPadding * 1.5,
                    vertical: kDefaultPadding * 0.6),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12))),
                child: Row(
                  children: [
                    Text(
                      'TOTAL A RECIBIR:',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 17),
                    ),
                    SizedBox(
                      width: kDefaultPadding * 0.6,
                    ),
                    Text(totalSales['total']?.toDop(),
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                            fontSize: 17)),
                    SizedBox(
                      width: kDefaultPadding * 0.6,
                    ),
                    Text(
                      'ITBIS FACTURADO:',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 17),
                    ),
                    SizedBox(
                      width: kDefaultPadding * 0.6,
                    ),
                    Text(totalSales['tax']?.toDop(),
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                            fontSize: 17))
                  ],
                ),
              )
            : SizedBox(),
        Expanded(
            child: ScrollMoveEventWidget(
                scrollControllerY: scrollControllerY,
                child: ListView.separated(
                    controller: scrollControllerY,
                    separatorBuilder: (ctx, i) => const Divider(),
                    itemCount: sales.length,
                    itemBuilder: (ctx, index) {
                      var sale = sales[index];

                      List<Map<String, dynamic>> salesOptions = [
                        {'id': 1, 'name': 'Ver Factura'},
                        {'id': 2, 'name': 'Ver pagos'},
                      ];

                      if (sale.debt! > 0) {
                        if (allowEditInvoice) {
                          salesOptions.add({'id': 4, 'name': 'Editar Factura'});
                        }
                      }

                      if (sale.ecfXmlFirmado != null) {
                        salesOptions.add({
                          'id': 5,
                          'name': 'Generar Archivo XML del ${sale.ncf}'
                        });
                      }

                      if (eCommerceMode) {
                        salesOptions.add({'id': 6, 'name': 'Imprimir factura'});
                      }

                      if (sale.ncfTypeId == '50' || sale.ncfTypeId == '60') {
                        salesOptions
                            .add({'id': 7, 'name': 'Generar Factura Fiscal'});
                      }

                      salesOptions
                          .add({'id': 8, 'name': 'Abrir carpeta de factura'});

                      return ListTile(
                        key: ValueKey(sale.id),
                        minVerticalPadding: kDefaultPadding / 2,
                        leading: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(90),
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.04),
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
                            '${sale.brancheName != null ? '${sale.brancheName}\n': ''}${sale.clientName}\n${sale.createdAt?.format(payload: 'DD/MM/YYYY')}'),
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
                                style:
                                    TextStyle(color: sale.color, fontSize: 18),
                              ),
                            ),
                            SizedBox(width: kDefaultPadding),
                            sale.estadoDgii != null
                                ? Container(
                                    margin: EdgeInsets.only(
                                        left: kDefaultPadding / 2,
                                        right: kDefaultPadding),
                                    padding:
                                        EdgeInsets.all(kDefaultPadding / 2),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: sale.statusColorDgii
                                            .withOpacity(0.04)),
                                    child: Text(
                                      sale.estadoDgiiNombre ?? '',
                                      style: TextStyle(
                                          color: sale.statusColorDgii),
                                    ),
                                  )
                                : SizedBox(),
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
                                return List.generate(
                                    salesOptions.length * 2 - 1, (index) {
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
                    })))
      ],
    );
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
  initState() {
    if (!mounted) return;

    if(enabledFilterInvoicesByDay){
      dates = [
        DateTime.now().startOfDay(),
        DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59)
            .endOfDay()
      ];
    }
    setState(() {
      
      future = _initAsync();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('TUS FACTURAS (${sales.length})'),
          toolbarHeight: kToolbarHeight + 50,
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
                      onInitRender: false,
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
                IconButton(
                    onPressed: _showFiltersModal,
                    icon: Icon(Icons.tune_outlined)),
                SizedBox(
                  width: kDefaultPadding,
                ),
                currentUser!.permissions!
                        .contains('ALLOW_VIEW_MENU_SALES_REPORTS')
                    ? PopupMenuButton<int>(
                        onSelected: _onSelectedOption,
                        itemBuilder: (ctx) {
                          return List.generate(options.length * 2 - 1, (index) {
                            var item = options[index ~/ 2];
                            if (index.isOdd) {
                              return PopupMenuDivider();
                            } else {
                              return PopupMenuItem(
                                  value: item['id'],
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(item['icon'],
                                          width: 30, height: 30),
                                      SizedBox(
                                        width: kDefaultPadding / 2,
                                      ),
                                      Expanded(child: Text(item['name']))
                                    ],
                                  ));
                            }
                          });
                        })
                    : SizedBox(),
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
              if (sales.isNotEmpty) {
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
