import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/filter.sales.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/dgiiStates.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/date.range_widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;

class ReportsSalesPage extends StatefulWidget {
  const ReportsSalesPage({super.key});

  @override
  State<ReportsSalesPage> createState() => _ReportsSalesPageState();
}

class _ReportsSalesPageState extends State<ReportsSalesPage> {
  List<Sale> sales = [];
  DateTime startDate = DateTime.now();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  late List<DateTime?> dates = [
     startDate
  ];

  List<Map<String, dynamic>> options = [
    {
      'id': 1,
      'name': 'Ver Reporte de Caja De Punto de Venta (Recibo)',
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

  List<String> get ncfsSelected {
    return ncfsTypes.map((e) => e.id!).toList();
  }

  List<int> get dgiiStatesSelected {
    return dgiiStates.map((e) => e.id!).toList();
  }

  _showReportBoxesByHour() async {
    showLoader(context);
    try {
      var result = await createTicketReportBoxesByHour(
          startDate: dates.first!,
          endDate: dates.last!,
          ncfsTypes: ncfsSelected,
          dgiiStates: dgiiStatesSelected,
          saleStatus: saleStatus);

      var bytes = result;
      Navigator.pop(context);
      await PrinterHandler.printBytes(devicePos ?? '', bytes);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _onSelectedOption(int? option) async {
    switch (option) {
      case 1:
        _showReportBoxesByHour();
        break;
      default:
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

  _onSelectedSaleOption(int? option, Sale sale) async {
    try {
      switch (option) {
        case 1:
          _showInvoice(sale);
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

        default:
      }
    } catch (e) {
      if (option == 6) {
        Navigator.pop(context);
      }
      rethrow;
    }
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
   
   @override
   initState(){
    var xncfs = ncfs; 
   ncfsTypes = [...xncfs].where((x) => x.id == '31' || x.id == '32' || x.id == '44' || x.id == '45').toList();
    super.initState();
  }

  Widget get contentFilled {
    return ScrollMoveEventWidget(
        scrollControllerY: scrollControllerY,
        child: ListView.separated(
            controller: scrollControllerY,
            separatorBuilder: (ctx, i) => const Divider(),
            itemCount: sales.length,
            itemBuilder: (ctx, index) {
              var sale = sales[index];

              List<Map<String, dynamic>> salesOptions = [
                {'id': 1, 'name': 'Ver Factura'},
              ];

              if (eCommerceMode) {
                salesOptions.add({'id': 6, 'name': 'Imprimir factura'});
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
                    sale.estadoDgii != null
                        ? Container(
                            margin: EdgeInsets.only(
                                left: kDefaultPadding / 2,
                                right: kDefaultPadding),
                            padding: EdgeInsets.all(kDefaultPadding / 2),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: sale.statusColorDgii.withOpacity(0.04)),
                            child: Text(
                              sale.estadoDgiiNombre ?? '',
                              style: TextStyle(color: sale.statusColorDgii),
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
          title: Text('GENERAR REPORTE DE VENTAS POS (${sales.length})'),
          actions: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
            
                SizedBox(
                  width: 290,
                  child: DateRangeWidget(
                    dates: dates,
                    onInitRender: false,
                    calendarTYpe: CalendarDatePicker2Type.range,
                    onChanged: (xdates) async {
                      // Ajustar fechas seleccionadas
                      dates = [
                        xdates.first,
                        xdates.first!.copyWith(
                          hour: 23,
                          minute: 59,
                          second: 59,
                        )
                      ];

                      // Mostrar selector de hora inicio
                       startTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: startTime?.hour ?? 0, minute: startTime?.minute ?? 0),
                      );

                      // Mostrar selector de hora fin
                      endTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: endTime?.hour ?? 23, minute: endTime?.minute ?? 59),
                      );

                      if (startTime != null && endTime != null) {
                        // Actualizar fechas con rango de horas
                        dates = [
                          dates.first?.copyWith(
                            hour: startTime?.hour,
                            minute: startTime?.minute,
                          ),
                          dates.first!.copyWith(
                            hour: endTime?.hour,
                            minute: endTime?.minute,
                          )
                        ];

                        setState(() {
                          future = _initAsync();
                        });
                      }
                    },
                  ),
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

        );
  }
}
