

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/modals/branche.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/branche.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';

class BranchesPage extends StatefulWidget {
  const BranchesPage({super.key});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {

  List<BrancheModel> xbranches = [];

  Future? future;

  _showBrancheModal({
    required BrancheModel branche,
    bool editing = false
  })async{
     var res = await showDialog(context: context, builder: (ctx)=>BrancheEditorModal(branche: branche,editing: editing));
     if(res != null){
      setState(() {
        future = _loadBranches();
      });
     }
  }

  _loadBranches()async{
    try{
      xbranches = await BrancheModel.get();
      branches = [BrancheModel(name: 'SUCURSAL'),...xbranches];
      setState(() {
        
      });
    }catch(e){
      rethrow;
    }
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
          SvgPicture.asset('assets/svgs/undraw_logistics_xpdj.svg',
              width: 320)
        ],
      ),
    );
  }


  @override
  void initState() {
    if(!mounted)return;
    setState(() {
      future = _loadBranches();
    });
    super.initState();
  }

  @override
  void dispose() {
    xbranches = [];
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TUS SUCURSALES (${xbranches.length})'),
        toolbarHeight: kToolbarHeight + 50,
        actions: [
            Wrap(
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                child: IconButton(
                  tooltip: 'AGREGAR SUCURSAL',
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    _showBrancheModal(branche: BrancheModel());
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

      body: FutureBuilder(future: future, builder: (ctx,s){

           if(s.connectionState == ConnectionState.waiting){
            return contentLoading;
           }

           if (s.hasError) {
                return ContentErrorWidget(
                  error: s.error.toString(),
                  onRetry: () {
                    setState(() {
                      future = _loadBranches();
                    });
                  },
                );
              }

        
        if(xbranches.isEmpty){
          return contentEmpty;
        }

        
        return ListView.separated(
          itemBuilder: (ctx, index) {
            final branche = xbranches[index];
            return ListTile(
              key: ValueKey(branche.id),
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
              title: Text(branche.name!),
              trailing: Wrap(
                children: [
                  IconButton(
                      tooltip: 'EDITAR SUCURSAL',
                      onPressed: () {
                        _showBrancheModal(branche: branche, editing: true);
                      },
                      icon: Icon(Icons.edit))
                ],
              ),
            );
          },
          separatorBuilder: (ctx, index) => Divider(),
          itemCount: xbranches.length);
      }),
    );
  }
}