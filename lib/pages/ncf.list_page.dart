import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:uresax_invoice_sys_cloud/modals/ncf.list.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/ncfList.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';

class NcfListPage extends StatefulWidget {
  const NcfListPage({super.key});

  @override
  State<NcfListPage> createState() => _NcfListPageState();
}

class _NcfListPageState extends State<NcfListPage> {
  List<NcfsList> ncfsList = [];

  Future? future;

  Widget get contentFilled {
    return ListView.separated(
      itemCount: ncfsList.length,
      separatorBuilder: (ctx, i) => const Divider(),
      itemBuilder: (ctx, index) {
        var ncfList = ncfsList[index];
        return ListTile(
          key: ValueKey(ncfList.id),
          minTileHeight: 90,
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
          title: Text(ncfList.ncfTypeName ?? ''),
          subtitle: Text('INICIAL: ${ncfList.start} - FINAL: ${ncfList.end}'),
          trailing: Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                  'Fecha de Vencimiento: ${ncfList.expirationDate?.format(payload: 'DD/MM/YYYY')}'),
              SizedBox(
                width: kDefaultPadding,
              ),
              Container(
                padding: EdgeInsets.all(kDefaultPadding / 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: ncfList.color.withOpacity(0.1),
                ),
                child:
                    Text(ncfList.label, style: TextStyle(color: ncfList.color)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_product-iteration_r2wg.svg',
              width: 250)
        ],
      ),
    );
  }

  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  _initAsync() async {
    try {
      ncfsList = await NcfsList.get();
      setState(() {});
    } catch (e) {
      rethrow;
    }
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
        title: Text('LISTA DE NCFS (${ncfsList.length})'),
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
                ncfsList.isNotEmpty) {
              return contentFilled;
            }

            return contentEmpty;
          }),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            var res = await showDialog(
                context: context,
                builder: (ctx) {
                  return NcfListEditorModal();
                });
            if (res == 'CREATE') {
              setState(() {
                future = _initAsync();
              });
            }
          }),
    );
  }
}
