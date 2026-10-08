import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class PaymentEditorModal extends StatefulWidget {
  Sale sale;
  PaymentEditorModal({super.key, required this.sale});

  @override
  State<PaymentEditorModal> createState() => _PaymentEditorModalState();
}

class _PaymentEditorModalState extends State<PaymentEditorModal> {
  int? currentPaymentMethodId;
  int? currentBankId;
  TextEditingController transfRef = TextEditingController();
  TextEditingController creditCardDescription = TextEditingController();
  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  double _debt = 0;

  DateTime paymentDate = DateTime.now();

  double get debt {
    return (_debt - amountInputFormatter.doubleValue);
  }

  _onSaved() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);
      try {
        var amount = amountInputFormatter.doubleValue;
        var amountx = debt < 0 ? widget.sale.debt! : amount;
        if (widget.sale.isPaid) {
          throw 'LA FACTURA YA ESTA PAGADA';
        }
        if (currentPaymentMethodId == 1) {
          widget.sale.effective = widget.sale.effective! + amountx;
        }
        if (currentPaymentMethodId == 2) {
          widget.sale.creditCard = widget.sale.creditCard! + amountx;
        }
        if (currentPaymentMethodId == 3) {
          widget.sale.checkOrTransf = widget.sale.checkOrTransf! + amountx;
        }
        if (currentPaymentMethodId == 4) {
          widget.sale.saleToCredit = widget.sale.saleToCredit! + amountx;
        }

        widget.sale.paymentDate=paymentDate;

        widget.sale.paid = widget.sale.paid! + amount;

        widget.sale.bankId = currentBankId;
        widget.sale.transfRef = transfRef.text;
        widget.sale.creditCardDescription = creditCardDescription.text;

        widget.sale.paymentMethodId = currentPaymentMethodId;

        if (debt < 0) {
          widget.sale.coinBack = debt.abs();
        }

  
        var xsale = await widget.sale.paySale(amountx);
        Navigator.pop(context);

        Navigator.pop(context,xsale);
      } catch (e) {
         Navigator.pop(context);
         showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    _debt = widget.sale.debt ?? 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.all(kDefaultPadding),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('ABONAR PAGO',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                    color: Theme.of(context).primaryColor))),
                    eCommerceMode
                        ? SizedBox()
                        : IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.close))
                  ],
                ),
                SizedBox(
                  height: kDefaultPadding,
                ),
                Row(
                  children: [
                    Expanded(child: Text(debt < 0 ? 'DEVUELTA' : 'DEUDA')),
                    Text(debt.abs().toDop())
                  ],
                ),
                SizedBox(
                  height: kDefaultPadding,
                ),
                DropdownButtonFormField<int>(
                    initialValue: currentPaymentMethodId,
                    isExpanded: true,
                    validator: (val) =>
                        val == null ? 'CAMPO OBLIGATORIO' : null,
                    decoration:
                        InputDecoration(labelText: 'TIPO DE COMPROBANTE'),
                    items: paymentsMethods
                        .map((e) => DropdownMenuItem(
                            value: e.id, child: Text(e.name ?? '')))
                        .toList(),
                    onChanged: (option) {
                      currentPaymentMethodId = option;
                      setState(() {});
                    }),
                currentPaymentMethodId == 3
                    ? Column(
                        children: [
                          SizedBox(height: kDefaultPadding),
                          DropdownButtonFormField(
                              validator: (val) =>
                                  val == null ? 'CAMPO OBLIGATORIO' : null,
                              items: List.generate(banks.length, (index) {
                                var bank = banks[index];
                                return DropdownMenuItem(
                                    value: bank.id,
                                    child: Text(bank.name ?? ''));
                              }),
                              onChanged: (option) {
                                currentBankId = option;
                              }),
                          SizedBox(height: kDefaultPadding),
                          TextFormField(
                            controller: transfRef,
                            validator: (val) =>
                                val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                            decoration: InputDecoration(
                                hintText: 'Escribir algo...',
                                labelText: 'NUMERO DE CHEQUE O REFERENCIA'),
                          ),
                          SizedBox(height: kDefaultPadding)
                        ],
                      )
                    : SizedBox(height: kDefaultPadding),
                
                currentPaymentMethodId == 2 ? Container(
                  margin: EdgeInsets.only(
                    bottom: kDefaultPadding
                  ),
                  child: TextFormField(
                    controller: creditCardDescription,
                    decoration: InputDecoration(
                      labelText: 'REFERENCIA DE TARJETA',
                      hintText: 'VISA XXXX'
                    ),
                  ),
                ):SizedBox(),
                TextFormField(
                  validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                  onChanged: (_) {
                    setState(() {});
                  },
                  inputFormatters: [amountInputFormatter],
                  decoration:
                      InputDecoration(labelText: 'MONTO', hintText: '0.00'),
                ),
                SizedBox(height: kDefaultPadding),
               Row(
                children: [
                  Expanded(child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(onPressed: (){
                      Navigator.pop(context);
                    },style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red)
                    ), child: Text('CERRAR',style: TextStyle(
                      color: Colors.white
                    ),)),
                  )),
                   const Spacer(),

                  Expanded(child:  SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: () => _onSaved(), child: Text('APLICAR')),
                )),
               
                ],
               )
              ],
            ),
          )),
    );
  }
}
