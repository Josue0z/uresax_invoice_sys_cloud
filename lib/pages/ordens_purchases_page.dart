import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/payment.orden.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/entry.warehouse.item.model.dart';
import 'package:uresax_invoice_sys_cloud/models/entry.warehouse.model.dart';
import 'package:uresax_invoice_sys_cloud/models/orden.item.model.dart';
import 'package:uresax_invoice_sys_cloud/models/orden.model.dart';
import 'package:uresax_invoice_sys_cloud/pages/ordens_generator_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/payments.ordens.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/date.range_widget.dart';
import 'package:uuid/uuid.dart';

class OrdensPurchasesPage extends StatefulWidget {
  const OrdensPurchasesPage({super.key});

  @override
  State<OrdensPurchasesPage> createState() => _OrdensPurchasesPageState();
}

class _OrdensPurchasesPageState extends State<OrdensPurchasesPage> {
  List<DateTime?> dates = [
        DateTime.now().startOfMonth(),
    DateTime.now().endOfMonth()
  ];
  List<OrdenModel> ordens = [];

  Future? future;
  TextEditingController searchController = TextEditingController();

  _initAsync() async {
    try {
    
      ordens = await OrdenModel.get(
        startDate: dates.first,
        endDate: dates.last
      );
      setState(() {});
    } catch (e) {
      print(e);
    }
  }
  _reset()async{
    searchController.clear();
   _initAsync();
  }

  _showOrdenGeneratorPage({required OrdenModel orden}) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => OrdensGeneratorPage(ordenModel: orden),
        )).then((value) {
      if (value != null && value is String) {
        _initAsync();
      }
    });
  }

  _showEntryPurchaseGenerator(OrdenModel orden) async {
  
    var value = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) => OrdensGeneratorPage(
                ordenModel: EntryWareHouseModel(
                    ordenId: orden.id,
                    ncf: orden.ncf,
                    ncfDate: orden.ncfDate,
                    ordenNum: orden.ordenNum,
                    driverId: orden.driverId,
                    driverIdentification: orden.driverIdentification,
                    driverName: orden.driverName,
                    driverEmail: orden.driverEmail,
                    driverPhone: orden.driverPhone,
                    providerId: orden.providerId,
                    providerName: orden.providerName,
                    providerPhone: orden.providerPhone,
                    providerEmail: orden.providerEmail,
                    providerAddress: orden.providerAddress,
                    providerIdentification: orden.providerIdentification,
                    currencyId: orden.currencyId,
                    items: orden.items
                        ?.map((e) => EntryWareHouseItemModel(
                            id: Uuid().v4(),
                            productId: e.productId,
                            productName: e.productName,
                            providerId: e.providerId,
                            providerName: e.providerName,
                            price: e.price,
                            quantity: e.quantity,
                            net: e.net,
                            netFinal: e.netFinal,
                            discount: e.discount,
                            tax: e.tax,
                            priceUnit: e.priceUnit,
                            total: e.total,
                            unitCode: e.unitCode,
                            unitName: e.unitName,
                            unitSymbol: e.unitSymbol,
                            conversionFactor: e.conversionFactor))
                        .toList()))));

    if (value != null && value is String) {
      _initAsync();
    }
  }

  _printOrden(OrdenModel orden) async {
    showLoader(context);
    try {
      var items = await orden.getItems();
      orden.items = items;
      var bytes = await createDefaultOrdenTicket(entry: orden);
      await PrinterHandler.printBytes(devicePos ?? '', bytes);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showPaymentsPage({required OrdenModel orden}) async {
    try {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => PaymentsOrdensPage(element: orden)));
    } catch (e) {
      print(e);
    }
  }

  _showPaymentEditor({required OrdenModel orden}) async {
    var res = await showDialog(
        context: context,
        builder: (ctx) => PaymentOrdenEditorModal(element: orden));
    if (res != null) {
      setState(() {
        future = _initAsync();
      });
    }
  }

  _cancelOrden(OrdenModel orden) async {
    showLoader(context);
    try {
      await orden.cancelOrden();
      setState(() {
        future = _initAsync();
      });
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showActionPage(int option, {required OrdenModel orden}) async {
    orden.items = await orden.getItems();
    switch (option) {
      case 1:
        _showEntryPurchaseGenerator(orden);
        break;
      case 2:
        _printOrden(orden);
        break;
      case 3:
        _showPaymentsPage(orden: orden);
        break;
      case 4:
        _showPaymentEditor(orden: orden);
        break;
      case 5:
        _cancelOrden(orden);
        break;
      default:
    }
  }

  _showOrdenPurchaseInvoice(OrdenModel orden) async {
    orden.items = await orden.getItems();
    var doc =await createInvoiceStoreWareHouse(orden);

    var bytes = await doc.save();
    var dir = await getUresaxInvoiceDir();

    var file = File(path.join(
        dir.path,
        'ORDENES DE COMPRAS',
        orden.createdAt?.format(payload: 'YYYYMM'),
        'PDFS',
        '${orden.providerName}_${orden.ordenNumString}_${company?.name}.PDF'));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  Widget get contentFilled {
    return ListView.separated(
        itemBuilder: (ctx, index) {
          var orden = ordens[index];

          List<Map<String, dynamic>> options = [
            {'id': 2, 'title': 'Imprimir Orden ${orden.ordenNumString}'},
          ];

          if (orden.ordenStatusId == 1) {
            options.add(
              {'id': 3, 'title': 'Ver Pagos'},
            );
          }

          if (orden.applyEntry == false && orden.ordenStatusId == 1) {
            options.add({'id': 1, 'title': 'Generar Entrada de Almacen'});
          }
          if (orden.debt! > 0 && orden.ordenStatusId == 1 && orden.applyEntry == true) {
            options.add({'id': 4, 'title': 'Abonar Pago'});
          }

          if (orden.applyEntry == false && orden.ordenStatusId == 1) {
            options.add(
                {'id': 5, 'title': 'Cancelar Orden ${orden.ordenNumString}'});
          }

          return ListTile(
            minTileHeight: 50,
            contentPadding: EdgeInsets.symmetric(
                vertical: kDefaultPadding, horizontal: kDefaultPadding),
            leading: Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(90)),
              child: Icon(
                Icons.receipt_long,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text('${orden.ordenNumString} - ${orden.ncf}',
                style: Theme.of(context).textTheme.bodyMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${orden.providerName}\n${orden.createdAt?.toLocal().format(payload: 'DD/MM/YYYY')}'),
                SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Container(
                  padding: EdgeInsets.all(kDefaultPadding / 2),
                  decoration: BoxDecoration(
                      color: orden.ordenStatusColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(30)),
                  child: Text(
                    orden.ordenStatusLabel,
                    style:
                        TextStyle(color: orden.ordenStatusColor, fontSize: 16),
                  ),
                )
              ],
            ),
            trailing: Wrap(
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(orden.currencyId == 1 ? orden.total?.toDop() ?? '' : orden.total?.toUS() ?? ''),
                Container(
                  margin: EdgeInsets.only(left: kDefaultPadding),
                  padding: EdgeInsets.all(kDefaultPadding / 2),
                  decoration: BoxDecoration(
                      color: orden.colorStatusPaid.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(30)),
                  child: Text(
                    orden.debtStatusLabel,
                    style: TextStyle(color: orden.colorStatusPaid),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: kDefaultPadding),
                  padding: EdgeInsets.all(kDefaultPadding / 2),
                  decoration: BoxDecoration(
                      color: orden.color.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(30)),
                  child: Text(
                    orden.labelText,
                    style: TextStyle(color: orden.color),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      _showOrdenPurchaseInvoice(orden);
                    },
                    icon: Icon(Icons.visibility)),
                PopupMenuButton<int>(onSelected: (id) {
                  _showActionPage(id, orden: orden);
                }, itemBuilder: (ctx) {
                  return List.generate(options.length, (index) {
                    var item = options[index];
                    return PopupMenuItem(
                        value: item['id'], child: Text(item['title']));
                  });
                })
              ],
            ),
          );
        },
        separatorBuilder: (ctx, i) => const Divider(),
        itemCount: ordens.length);
  }

  Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_logistics_8vri.svg', width: 280)
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
      future = _initAsync();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ORDENES DE COMPRAS (${ordens.length})'),
      
        actions: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              Container(
                width:230,
                margin: EdgeInsets.only(right: kDefaultPadding),
                child:TextFormField(
                  controller: searchController,
                  onFieldSubmitted: (val)async{
                    var res = await OrdenModel.get(
                        startDate: dates.first,
                        endDate: dates.last,
                        search: val
                      );
                      ordens = res;
                    
                      setState(() {
                        
                      });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por NCF, Proveedor, etc...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none
                    ),
                    suffixIcon: Icon(Icons.search),
                    fillColor: Colors.white,
                    filled: true
                  ),
                )
              ),
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
                CircleAvatar(
                  child: IconButton(onPressed:_reset, icon: Icon(Icons.refresh)),
                ),
                SizedBox(
                  width: kDefaultPadding,
                ),
              CircleAvatar(
                child: IconButton(
                    onPressed: () {
                      _showOrdenGeneratorPage(
                          orden: OrdenModel(items: [
                        OrdenItemModel(id: Uuid().v4(), quantity: 1)
                      ]));
                    },
                    icon: Icon(Icons.add)),
              ),
              SizedBox(
                width: kDefaultPadding,
              )
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
                ordens.isNotEmpty) {
              return contentFilled;
            }

            return contentEmpty;
          }),
    );
  }
}
