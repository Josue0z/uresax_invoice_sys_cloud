import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:uresax_invoice_sys_cloud/models/event.stock.model.dart';
import 'package:uresax_invoice_sys_cloud/pages/event.stock.editor.page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';

class EventStockPage extends StatefulWidget {
  const EventStockPage({super.key});

  @override
  State<EventStockPage> createState() => _EventStockPageState();
}

class _EventStockPageState extends State<EventStockPage> {
  List<EventStockModel> events = [];

  Future? future;
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
          SvgPicture.asset('assets/svgs/undraw_successful-purchase_p2fz.svg',
              width: 220)
        ],
      ),
    );
  }

  _loadEvents() async {
    try {
      events = await EventStockModel.get();
      setState(() {});
    } catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    setState(() {
      future = _loadEvents();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('TUS EVENTOS DE INVENTARIO (${events.length})'),
          toolbarHeight: kToolbarHeight + 50,
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
                      future = _loadEvents();
                    });
                  },
                );
              }

              if (events.isEmpty) {
                return contentEmpty;
              }
              return ListView.separated(
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (ctx, i) {
                    var event = events[i];
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
                            Icons.inventory_2_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      title: Text('${event.ref}',
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 22,
                              color: Theme.of(context).primaryColor)),
                      subtitle: Text(
                          'EVENTO DE INVENTARIO\n${event.createdAt?.format(payload: 'DD/MM/YYYY LLLL')}'),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runAlignment: WrapAlignment.center,
                        children: [
                          Container(
                            width: 150,
                            padding: EdgeInsets.all(kDefaultPadding / 2),
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(kDefaultPadding),
                                color: event.eventStockTypeId == 1
                                    ? Colors.green.withOpacity(0.04)
                                    : Colors.red.withOpacity(0.04)),
                            child: Text(
                              event.eventTypeName ?? '',
                              style: TextStyle(
                                color: event.eventStockTypeId == 1
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ),
                    );
                  },
                  itemCount: events.length);
            }),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
                heroTag: ValueKey('input'),
                tooltip: 'AGREGAR ENTRADA',
                onPressed: () async {
                  var res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => EventStockEditorPage()));

                  if (res != null) {
                    setState(() {
                      future = _loadEvents();
                    });
                  }
                },
                child: Icon(Icons.arrow_upward_outlined)),
            SizedBox(width: kDefaultPadding),
            FloatingActionButton(
                heroTag: ValueKey('output'),
                tooltip: 'APLICAR SALIDA',
                onPressed: () async {
                  var res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => EventStockEditorPage(
                                eventType: 'output',
                              )));

                  if (res != null) {
                    setState(() {
                      future = _loadEvents();
                    });
                  }
                },
                child: Icon(Icons.arrow_downward_outlined)),
          ],
        ));
  }
}
