import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

Future<T?> showPreConfirmInvoice<T>(
    {required BuildContext context,
    required Sale? sale,
    required String amountPaid,
    required String paid,
    required double debt,
    required String debtString}) {

  bool isSale = sale is SaleService || sale is SaleProduct;
  return showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          
            constraints: BoxConstraints(maxWidth: 400),
            child: Focus(
                autofocus: true,
                onKeyEvent: (focus, event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.enter) {
                      Navigator.pop(context, true);
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.escape) {
                      Navigator.pop(context, false);
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: Container(
                    padding: EdgeInsets.all(kDefaultPadding),
                    child:  ListView(
                        shrinkWrap: true,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child:Column(
                      
                            children: [
                              Icon(Icons.check_circle_outline_outlined,
                                  color: Colors.green, size: 60),
                              SizedBox(
                                height: kDefaultPadding,
                              ),
                              Text('¿DESEAS GENERAR LA FACTURA?',
                              textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge),
                            ],
                          ),
                          ),
                          SizedBox(
                            height: kDefaultPadding,
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isSale ? 'TOTAL A PAGAR' :'TOTAL A DEVOLVER',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .primaryColor)),
                                Text(amountPaid,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium)
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isSale ? 'HA PAGADO' : 'HA DEVUELTO',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .primaryColor)),
                                Text(paid,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium)
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(debt < 0 ? 'DEVUELTA' : 'DEUDA',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .primaryColor)),
                                Text(debtString,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.orange))
                              ],
                            ),
                          ),
                          SizedBox(
                            height: kDefaultPadding,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          WidgetStatePropertyAll(Colors.red),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: Text(
                                      'CANCELAR',
                                      style: TextStyle(color: Colors.white),
                                    )),
                              )),
                              SizedBox(
                                width: kDefaultPadding,
                              ),
                              Expanded(
                                  child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: Text('FINALIZAR')),
                              ))
                            ],
                          )
                        ],
                      ),
                    )));
      });
}
