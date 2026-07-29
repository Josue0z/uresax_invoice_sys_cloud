import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/modals/unit.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/unit.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class UnitsPage extends StatefulWidget {
    bool selectedMode;
  UnitsPage({super.key,this.selectedMode= false});

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {

  List<Unit> units = [];
  _showUnitModal({required Unit unit, bool editing = false}) async {
    var res = await showDialog(
        context: context,
        builder: (ctx) => UnitEditorModal(unit: unit, editing: editing));

    if (res == 'CREATE' || res == 'UPDATE') {
      _initAsync();
    }
  }

  _initAsync() async {
    try {
      units = await Unit.get();
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
        title: Text('UNIDADES (${units.length})'),
        actions: [
          Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                child: IconButton(
                  tooltip: 'AGREGAR UNIDAD',
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    _showUnitModal(unit: Unit());
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
            final unit = units[index];
            return ListTile(
              key: ValueKey(unit.id),
              minTileHeight: 60,
              onTap: widget.selectedMode
                  ? () {
               
                      Navigator.pop(context, unit);
                    }
                  : null,
              leading: Container(
                 width: 80,
              
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                    color: Theme.of(context).primaryColor.withOpacity(0.04)),
                child: Center(
                  child:  Icon(
                  Icons.emoji_symbols_outlined,
                  color: Theme.of(context).primaryColor,
                
                ),
                )
              ),
              title: Text(unit.name!,style: Theme.of(context).textTheme.bodyMedium),
              trailing: Wrap(
                children: [
                  IconButton(
                      tooltip: 'EDITAR UNIDAD',
                      onPressed: () {
                        _showUnitModal(unit: unit, editing: true);
                      },
                      icon: Icon(Icons.edit))
                ],
              ),
            );
          },
          separatorBuilder: (ctx, index) => Divider(),
          itemCount: units.length),
    );
  }
}