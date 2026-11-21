




import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/retention.isr.dart';
import 'package:uresax_invoice_sys_cloud/models/retention.tax.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class RetentionEditorModal extends StatefulWidget {
 RetentionTax? initialRetentionTax;

 RetentionIsr? initialRetentionIsr;

  void Function(RetentionTax?, RetentionIsr?) onChanged;
   RetentionEditorModal({super.key,required this.onChanged,this.initialRetentionTax,this.initialRetentionIsr});

  @override
  State<RetentionEditorModal> createState() => _RetentionEditorModalState();
}

class _RetentionEditorModalState extends State<RetentionEditorModal> {
 

 int? currentRetentionTaxId;
 String? currentRetentionIsrId;

 RetentionTax? currentRetentionTax;

 RetentionIsr? currentRetentionIsr;

 @override
  void initState() {
    if(!mounted)return;
    if(widget.initialRetentionTax != null){
      currentRetentionTax = retentionsTaxes.firstWhere((x) => x.id == widget.initialRetentionTax?.id,orElse: () => RetentionTax());
      currentRetentionTaxId = widget.initialRetentionTax?.id;
    }

       if(widget.initialRetentionIsr != null){
      currentRetentionIsr = retentionsIsrs.firstWhere((x) => x.id == widget.initialRetentionIsr?.id,orElse: () => RetentionIsr());
      currentRetentionIsrId = widget.initialRetentionIsr?.id;
    }
    setState(() {
      
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 450,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(kDefaultPadding),
          children: [

            Row(
              children: [
                Expanded(child: Text('APLICANDO RETENCIONES',style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).primaryColor
                ),)),
                IconButton(onPressed: (){
                  Navigator.pop(context);
                }, icon: Icon(Icons.close))
              ],
            ),
            SizedBox(
               height: kDefaultPadding/2,
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(
                bottom: kDefaultPadding
              ),
              child: DropdownButtonFormField(
                initialValue: currentRetentionTaxId,
                isDense: true,
                isExpanded: true,
                padding: EdgeInsets.all(kDefaultPadding/2),
                decoration: InputDecoration(isCollapsed: true,isDense: true, labelText: 'RETENCION ITBIS',hintText: '0.00'),
                items: List.generate(retentionsTaxes.length, (i){
                var retentionTax = retentionsTaxes[i];
                return DropdownMenuItem(value: retentionTax.id, child: Text(retentionTax.name ?? ''));
              }), onChanged: (value){
                if(value != null){
                  currentRetentionTaxId = value;
                  currentRetentionTax = retentionsTaxes.firstWhere((x) => x.id == value,orElse: () => RetentionTax());
                }else{
                  currentRetentionTax = null;
                }
              }),
            ),

            Container(
              width: double.infinity,
              margin: EdgeInsets.only(
                bottom: kDefaultPadding
              ),
              child: DropdownButtonFormField(
                initialValue:currentRetentionIsrId,
                isDense: true,
                isExpanded: true,
                padding: EdgeInsets.all(kDefaultPadding/2),
                decoration: InputDecoration(isCollapsed: true,isDense: true, labelText: 'RETENCION ISR',hintText: '0.00'),
                items: List.generate(retentionsIsrs.length, (i){
                var retentionIsr = retentionsIsrs[i];
                return DropdownMenuItem(value: retentionIsr.id, child: Text(retentionIsr.name ?? ''));
              }), onChanged: (value){
                   if(value != null){
                  currentRetentionIsrId = value;
                  currentRetentionIsr = retentionsIsrs.firstWhere((x) => x.id == value,orElse: () => RetentionIsr());
                }else{
                  currentRetentionIsr = null;
                }
              }),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: (){
                Navigator.pop(context,{
                  'currentRetentionTax':currentRetentionTax,
                  'currentRetentionIsr':currentRetentionIsr
                });
                widget.onChanged.call(currentRetentionTax,currentRetentionIsr);
              }, child: Text('APLICAR CAMBIOS')),
            )
          ],
        ),
      ),
    );
  }
}


Future<dynamic> showRetentionEditorModal({
  required BuildContext context,
  required void Function(RetentionTax?, RetentionIsr?) onChanged,
  RetentionTax? initialRetentionTax,
  RetentionIsr? initialRetentionIsr

})async{
  return await showDialog(context: context, builder: (ctx) => RetentionEditorModal(
    initialRetentionTax: initialRetentionTax,
    initialRetentionIsr: initialRetentionIsr,
    onChanged: onChanged));
}