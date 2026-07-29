import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class PaymentOrdenEditorModal extends StatefulWidget {
  WareHouseElement element;
  PaymentOrdenEditorModal({super.key, required this.element});

  @override
  State<PaymentOrdenEditorModal> createState() =>
      _PaymentOrdenEditorModalState();
}

class _PaymentOrdenEditorModalState extends State<PaymentOrdenEditorModal> {
  int? currentPaymentMethodId;
  int? currentBankId;
  TextEditingController transfRef = TextEditingController();
  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController paymentDateController = TextEditingController();
  DateTime? paymentDate;

  double _debt = 0;

  _showDatePicker() async {
    var result = await showDatePicker(
      context: context,
      initialDate: paymentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      lastDate: DateTime.now(),
    );

    if (result != null) {
      paymentDate = result;
      paymentDateController.text = paymentDate!.format(payload: 'DD/MM/YYYY');
      setState(() {});
    }
  }

  double get debt {
    return (_debt - amountInputFormatter.doubleValue);
  }

  String get debtString {
    if (widget.element.currencyId == 1) {
      return debt.abs().toDop();
    }
    return debt.abs().toUS();
  }

  _onSaved() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);
      try {
        var amount = amountInputFormatter.doubleValue;
        var amountx = debt < 0 ? widget.element.debt! : amount;
        widget.element.effective = 0;
        widget.element.creditCard = 0;
        widget.element.checkOrTransf = 0;
        widget.element.saleToCredit = 0;
        widget.element.paymentDate = paymentDate;
        if (widget.element.isPaid) {
          throw 'LA FACTURA YA ESTA PAGADA';
        }

        if (currentPaymentMethodId == 1) {
          widget.element.effective = amountx;
        }
        if (currentPaymentMethodId == 2) {
          widget.element.creditCard = amountx;
        }

        if (currentPaymentMethodId == 3) {
          widget.element.checkOrTransf = amountx;
        }
        if (currentPaymentMethodId == 4) {
          widget.element.saleToCredit = amountx;
        }

        await widget.element.paySale(
            amountPaid: amountx,
            amount: amount,
            paymentMethodId: currentPaymentMethodId!,
            bankId: currentBankId,
            transRef: transfRef.text.isEmpty ? null : transfRef.text);
        Navigator.pop(context);

        Navigator.pop(context, 'UPDATE');
      } catch (e) {
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  @override
  void initState() {
    _debt = widget.element.debt ?? 0;
    paymentDate = DateTime.now();
    paymentDateController.text = paymentDate!.format(payload: 'DD/MM/YYYY');
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
                    IconButton(
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
                    Text(debtString)
                  ],
                ),
                SizedBox(
                  height: kDefaultPadding,
                ),
                Container(
                  margin: EdgeInsets.only(bottom: kDefaultPadding),
                  child: TextFormField(
                    controller: paymentDateController,
                    readOnly: true,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                        labelText: 'FECHA DE PAGO',
                        hintText: 'DD/MM/YYYY',
                        suffixIcon: IconButton(
                            onPressed: _showDatePicker,
                            icon: Icon(Icons.calendar_month))),
                  ),
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
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: () => _onSaved(), child: Text('APLICAR')),
                )
              ],
            ),
          )),
    );
  }
}
