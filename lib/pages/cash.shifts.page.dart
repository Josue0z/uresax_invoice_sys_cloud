import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localstorage/localstorage.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/cash.shift.close.modal.dart';
import 'package:uresax_invoice_sys_cloud/modals/cash.shift.modal.details.dart';
import 'package:uresax_invoice_sys_cloud/models/cash.shift.model.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/date.range_widget.dart';

class CashShiftsPage extends StatefulWidget {
  const CashShiftsPage({super.key});

  @override
  State<CashShiftsPage> createState() => _CashShiftsPageState();
}

class _CashShiftsPageState extends State<CashShiftsPage> {
  Future? future;
  List<CashShiftModel> cashShifts = [];
  List<DateTime?> dates = [
    DateTime.now().startOfDay(),
    DateTime.now().endOfDay()
  ];

  TextEditingController searchController = TextEditingController();

  Future<void> _loadCashShifts([String? search]) async {
    cashShifts = await CashShiftModel.get(
        search: search, startDate: dates.first!, endDate: dates.last!);
    setState(() {});
  }

  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  _openCashShiftCloseModal(CashShiftModel cashShiftModel) async {
    showLoader(context);
    try {
      var denominations = await Denominations.get();
      Navigator.pop(context);
      var res = await showDialog(
          context: context,
          builder: (ctx) => CashShiftCloseModal(
              cashShiftModel: cashShiftModel, denominations: denominations));

      if (res != null) {
        setState(() {
          future = _loadCashShifts();
        });
      }
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _printCashShift(CashShiftModel cashShiftModel) async {
    showLoader(context);
    try {
      var bytes = await createTicketCashShift(cashShiftModel: cashShiftModel);
      Navigator.pop(context);
      await PrinterHandler.printBytes(
          localStorage.getItem('devicePos') ?? '', bytes);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _onSelected({required int option, required CashShiftModel cashShiftModel}) {
    switch (option) {
      case 1:
        _openCashShiftCloseModal(cashShiftModel);
        break;
      case 2:
        _printCashShift(cashShiftModel);
        break;
      case 3:
        showCashShiftDialog(context, cashShiftModel);
        break;
      default:
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

  _submit(String? val) async {
    showLoader(context);
    await _loadCashShifts(val);
    Navigator.pop(context);

  }

  @override
  void initState() {
     if(!mounted)return;
     setState(() {
      future = _loadCashShifts();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TURNOS (${cashShifts.length})'),
        toolbarHeight: kToolbarHeight + 30,
        actions: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 290,
                child: DateRangeWidget(
                    dates: dates,
                    onInitRender:false,
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
                        future = _loadCashShifts();
                      });
                    }),
              ),
              SizedBox(width: kDefaultPadding),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: searchController,
                  onFieldSubmitted: _submit,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Turno #000000, Periodo, Usuario, Caja...',
                      suffixIcon: Icon(Icons.search)),
                ),
              ),
              SizedBox(width: kDefaultPadding),
              IconButton(
                  onPressed: () async {
                    showLoader(context);
                    await _loadCashShifts();
                    searchController.clear();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.restore)),
              SizedBox(width: kDefaultPadding),
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
                    future = _loadCashShifts();
                  });
                },
              );
            }

            if (cashShifts.isEmpty) {
              return contentEmpty;
            }

            return ListView.separated(
                itemBuilder: (ctx, i) {
                  var cash = cashShifts[i];
                  var options = [
                    {'id': 2, 'name': 'IMPRIMIR TURNO'}
                  ];

                  if (cash.status != 4) {
                    if(cash.status != 5){
                       if(cash.status != 3){
                          options.insert(0, {'id': 1, 'name': 'APLICAR CIERRE'});
                       }
                    }
                  }

                  if(currentUser!.permissions!.contains('ALLOW_VIEW_CASH_SHIFT_DETAILS')){
                    options.insert(0, {'id': 3, 'name': 'VER DETALLES'});
                  }


                  return ListTile(
                      leading: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(90),
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.04),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      title: Text(cash.cashShiftNumber ?? '',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor)),
                      titleAlignment: ListTileTitleAlignment.center,
                      subtitle: Text(
                          '${cash.description}\n${cash.boxName} - ${cash.periodName} - ${cash.userName} ~ ${cash.createdAt?.format(payload: 'DD/MM/YYYY')}'),
                      trailing: Wrap(
                        runAlignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(kDefaultPadding * 0.6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.green.withOpacity(0.04)),
                            child: Text(cash.transactionsCount.toString(),
                                style: TextStyle(color: Colors.green)),
                          ),
                          SizedBox(width: kDefaultPadding),
                          Container(
                            padding: EdgeInsets.all(kDefaultPadding / 2),
                            decoration: BoxDecoration(
                                color: cash.color.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              cash.statusName ?? '',
                              style: TextStyle(fontSize: 16, color: cash.color),
                            ),
                          ),
                          SizedBox(width: kDefaultPadding),
                          PopupMenuButton<int>(
                              onSelected: (int option) => _onSelected(
                                  option: option, cashShiftModel: cash),
                              itemBuilder: (ctx) {
                                return List.generate(options.length, (i) {
                                  var op = options[i];
                                  return PopupMenuItem(
                                      value: op['id'] as int,
                                      child: Text('${op['name']}'));
                                });
                              }),
                        ],
                      ));
                },
                separatorBuilder: (ctx, i) => const Divider(),
                itemCount: cashShifts.length);
          }),
    );
  }
}
