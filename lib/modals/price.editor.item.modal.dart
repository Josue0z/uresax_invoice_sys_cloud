

import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class PriceEditorItemModal extends StatefulWidget {
  Sale sale;
  SaleItem saleItem;
  bool editing;
  PriceEditorItemModal({super.key,required this.sale, required this.saleItem, this.editing = false});

  @override
  State<PriceEditorItemModal> createState() => _PriceEditorItemModalState();
}

class _PriceEditorItemModalState extends State<PriceEditorItemModal> {
  TextEditingController code = TextEditingController();
  TextEditingController price = TextEditingController();
    AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  _onSubmit()async{
   var xcode = code.text;
    var isCode = esCodigoValido(xcode);

    if (isCode) {
      try {
        if (widget.sale is SaleProduct) {
          var product = await Products.findByCode(code: xcode);
          var xprice = double.tryParse(price.text.replaceAll(',', '')) ?? 0;
         
          if(product != null){
             Navigator.pop(context,{
            'el':product,
            'price': xprice
          });
          }

        }
      } catch (e) {
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child:Container(
        width: 350,
        height: 400,
        padding: EdgeInsets.all(kDefaultPadding),
        child: Form(child:Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('AGREGANDO PRODUCTO...',style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 19
                ),)),
                IconButton(onPressed: (){
                  Navigator.pop(context);
                }, icon:Icon(Icons.close))
              ],
            ),
            Expanded(child: SingleChildScrollView(
              child: Column(
                children: [
                 Container(
                  margin: EdgeInsets.symmetric(
                    vertical: kDefaultPadding/2
                  ),
                  child:  TextFormField(
                    controller: code,
                    validator: (val)=> val!.isEmpty ?'CAMPO OBLIGATORIO': null,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'CODIGO',
                      hintText: '000000'
                    ),
                  ),
                 ),

                  Container(
                  margin: EdgeInsets.symmetric(
                    vertical: kDefaultPadding/2
                  ),
                  child:  TextFormField(
                    controller: price,
                     validator: (val)=> val!.isEmpty ?'CAMPO OBLIGATORIO': null,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_){
                      _onSubmit();
                    },
                     inputFormatters: [
                      amountInputFormatter
                     ],
                    decoration: InputDecoration(
                      labelText: 'PRECIO',
                      hintText: '0.00'
                    ),
                  ),
                 ),

                ],
              ),
            )),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _onSubmit, child: Text('AGREGAR')),
            )
          ],
        ) ),
      ),
    );
  }
}