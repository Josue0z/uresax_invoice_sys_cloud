import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/modals/box.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/box.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class BoxesPage extends StatefulWidget {
  const BoxesPage({super.key});

  @override
  State<BoxesPage> createState() => _BoxesPageState();
}

class _BoxesPageState extends State<BoxesPage> {
  List<Box> xboxes = [];
  _showBoxModal({required Box box, bool editing = false}) async {
    var res = await showDialog(
        context: context,
        builder: (ctx) => BoxEditorModal(box: box, editing: editing));

    if (res == 'CREATE' || res == 'UPDATE') {
      _initAsync();
    }
  }

  _initAsync() async {
    try {
      xboxes = await Box.get();
      boxes = [Box(name: 'CAJA'),...xboxes];
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    if (!mounted) return;
    _initAsync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CAJAS (${xboxes.length})'),
        actions: [
          Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                child: IconButton(
                  tooltip: 'AGREGAR CAJA',
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    _showBoxModal(box: Box());
                  },
                ),
              ),
              SizedBox(
                width: kDefaultPadding,
              )
            ],
          )
        ],
      ),
      body: ListView.separated(
          itemBuilder: (ctx, index) {
            final box = xboxes[index];
            return ListTile(
              key: ValueKey(box.id),
              minTileHeight: 60,
              leading: Container(
                 width: 80,
              
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                    color: Theme.of(context).primaryColor.withOpacity(0.04)),
                child: Center(
                  child:  Icon(
                  Icons.shopping_cart_outlined,
                  color: Theme.of(context).primaryColor,
                
                ),
                )
              ),
              title: Text(box.name!),
              trailing: Wrap(
                children: [
                  IconButton(
                      tooltip: 'EDITAR CAJA',
                      onPressed: () {
                        _showBoxModal(box: box, editing: true);
                      },
                      icon: Icon(Icons.edit))
                ],
              ),
            );
          },
          separatorBuilder: (ctx, index) => Divider(),
          itemCount: xboxes.length),
    );
  }
}
