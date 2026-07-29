import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/payment.orden.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/entry.warehouse.model.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';
import 'package:uresax_invoice_sys_cloud/pages/ordens_generator_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/payments.ordens.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/date.range_widget.dart';

class EntriesPurchasesPage extends StatefulWidget {
  const EntriesPurchasesPage({super.key});

  @override
  State<EntriesPurchasesPage> createState() => _EntriesPurchasesPageState();
}

class _EntriesPurchasesPageState extends State<EntriesPurchasesPage> {
    List<DateTime?> dates = [
        DateTime.now().startOfMonth(),
    DateTime.now().endOfMonth()
  ];
  List<EntryWareHouseModel> entries = [];
  
  TextEditingController searchController = TextEditingController();
  Future? future;

  _initAsync() async {
    try {
      entries = await EntryWareHouseModel.get(
        startDate: dates.first,
        endDate: dates.last
      );
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  _showOrdenGeneratorPage({required EntryWareHouseModel entry, bool editing = false}) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => OrdensGeneratorPage(ordenModel: entry),
        )).then((value) {
      if (value != null && value is String) {
        _initAsync();
      }
    });
  }

 

  _printOrden(EntryWareHouseModel entry) async {
    showLoader(context);
    try {
      var items = await entry.getItems();
      entry.items = items;
      var bytes = await createDefaultOrdenTicket(entry: entry);
      await PrinterHandler.printBytes(devicePos ?? '', bytes);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _showPaymentsPage({required EntryWareHouseModel entry}) async {
    try {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => PaymentsOrdensPage(element: entry)));
    } catch (e) {
      print(e);
    }
  }

  _showPaymentEditor({required WareHouseElement entry}) async {
    var res = await showDialog(
        context: context,
        builder: (ctx) => PaymentOrdenEditorModal(element: entry));
    if (res != null) {
      setState(() {
        future = _initAsync();
      });
    }
  }


  _showActionPage(int option, {required EntryWareHouseModel entry}) async {
    entry.items = await entry.getItems();
    switch (option) {
    
      case 1:
        _printOrden(entry);
        break;
      case 2:
        _showPaymentsPage(entry: entry);
        break;
     
      default:
    }
  }

  _showOrdenPurchaseInvoice(EntryWareHouseModel entry) async {
    entry.items = await entry.getItems();
    var doc =await createInvoiceStoreWareHouse(entry);

    var bytes = await doc.save();
    var dir = await getUresaxInvoiceDir();

    var file = File(path.join(
        dir.path,
        'ENTRADAS DE ALMACEN',
        entry.createdAt?.format(payload: 'YYYYMM'),
        'PDFS',
        '${entry.providerName}_${entry.entryNumString}_${company?.name}.PDF'));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

   _reset()async{
    searchController.clear();
   _initAsync();
  }

  Widget get contentFilled {
    return ListView.separated(
        itemBuilder: (ctx, index) {
          var entry = entries[index];

          List<Map<String, dynamic>> options = [
            {'id': 1, 'title': 'Imprimir Entrada ${entry.entryNumString}'},
          ];

          if (entry.ordenStatusId == 1) {
            options.add(
              {'id': 2, 'title': 'Ver Pagos'},
            );
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
            title: Text('${entry.entryNumString} - ${entry.ncf}',
                style: Theme.of(context).textTheme.bodyMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${entry.providerName}\n${entry.createdAt?.format(payload: 'DD/MM/YYYY')}'),
             
              ],
            ),
            trailing: Wrap(
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(entry.currencyId == 1 ? entry.total?.toDop() ?? '' : entry.total?.toUS() ?? ''),
                Container(
                  margin: EdgeInsets.only(left: kDefaultPadding),
                  padding: EdgeInsets.all(kDefaultPadding / 2),
                  decoration: BoxDecoration(
                      color: entry.colorStatusPaid.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(30)),
                  child: Text(
                    entry.debtStatusLabel,
                    style: TextStyle(color: entry.colorStatusPaid),
                  ),
                ),
          
                IconButton(
                    onPressed: () {
                      _showOrdenPurchaseInvoice(entry);
                    },
                    icon: Icon(Icons.visibility)),
                PopupMenuButton<int>(onSelected: (id) {
                  _showActionPage(id, entry: entry);
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
        itemCount: entries.length);
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
        title: Text('ENTRADAS DE ALMACEN (${entries.length})'),
        actions: [
            Wrap(
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                  Container(
                width:230,
                margin: EdgeInsets.only(right: kDefaultPadding),
                child:TextFormField(
                  controller: searchController,
                  onFieldSubmitted: (val)async{
                    var res = await EntryWareHouseModel.get(
                        startDate: dates.first,
                        endDate: dates.last,
                        search: val
                      );
                      entries = res;
                    
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
                entries.isNotEmpty) {
              return contentFilled;
            }

            return contentEmpty;
          }),
    );
  }
}
