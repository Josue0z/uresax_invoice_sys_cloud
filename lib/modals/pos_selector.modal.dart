

import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/pages/pos_screen.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class PosSelectorModal extends StatefulWidget {
  const PosSelectorModal({super.key});

  @override
  State<PosSelectorModal> createState() => _PosSelectorModalState();
}

class _PosSelectorModalState extends State<PosSelectorModal> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? currentOption;

  List<Map<String,dynamic>> options = [
      {
      'id':null,
      'name':'ELEGIR OPCION'
    },
    {
      'id':1,
      'name':'GENERAR FACTURA DE VENTA'
    },
    {
    'id':2,
    'name':'GENERAR NOTA DE CREDITO'
    }
  ];
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SizedBox(
        width: 500,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(kDefaultPadding),
          children: [
            Row(
              children: [
                Expanded(child: Text('OPCIONES',style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Theme.of(context).primaryColor
                ),)),
                IconButton(onPressed: (){
                  Navigator.pop(context);
                }, icon: Icon(Icons.close))
              ],
            ),
            SizedBox(
              height: kDefaultPadding,
            ),
            DropdownButtonFormField<int?>(
              validator: (val) => val == null ?'CAMPO OBLIGATORIO':null,
              items: List.generate(options.length, (index){
              var option = options[index];
              return DropdownMenuItem(value: option['id'], child: Text(option['name']));
            }), onChanged: (val){
              currentOption =val;
            }),
            SizedBox(
              height: kDefaultPadding,
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: ()async{

               if(_formKey.currentState!.validate()){
                  switch(currentOption){
                  case 1:
                      await Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (ctx) => PosScreenPage(
                  sale: SaleProduct(),
                  items: [
                  ],
            )), (_) => false);
                  break;
                  case 2:
                     await Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (ctx) => PosScreenPage(
                  items: [],
                  sale: CreditNoteAsProduct(),
            )), (_) => false);
                  default:
                }
               }
              }, child: Text('CONFIRMAR')),
            )
          ],
        ),
      ))
    );
  }
}