
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/cash.shift.model.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';



void showCashShiftDialog(BuildContext context, CashShiftModel shift) {

    printCashShift(CashShiftModel cashShiftModel,PrintCashShiftMode mode) async {
    showLoader(context);
    try {
      var bytes = await createTicketCashShift(cashShiftModel: cashShiftModel);
      Navigator.pop(context);
      await PrinterHandler.printBytes(
          localStorage.getItem('devicePos') ?? '', bytes);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title:Row(
          children:[
            Expanded(child:  Text("Turno ${shift.cashShiftNumber ?? '-'}",style: TextStyle( color:Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
            IconButton(onPressed:() => printCashShift(shift,PrintCashShiftMode.all), icon: Icon(Icons.print,color:Theme.of(context).primaryColor),tooltip: "Imprimir"),
            ]
          ),
        
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow("Descripción", shift.description),
              _buildRow("Fecha", shift.shiftDate?.toLocal().toString()),
              _buildRow("Periodo", shift.periodName),
              _buildRow("Usuario", shift.userName),
              _buildRow("Caja", shift.boxName),
              _buildRow("Monto Apertura", shift.openingAmount?.toStringAsFixed(2)),
              _buildRow("Efectivo En Ventas", shift.effectiveCalc?.toStringAsFixed(2)),
              _buildRow("Efectivo", shift.effective?.toStringAsFixed(2)),
             enabledViewCashShiftDetails ? _buildRow("Efectivo Electrónico", shift.effectiveCalcElectronic?.toStringAsFixed(2)) : Container(),
             enabledViewCashShiftDetails ? _buildRow("Efectivo de Preventa", shift.effectiveCalcPreventa?.toStringAsFixed(2)) : Container(),
              _buildRow("Tarjeta", shift.creditCard?.toStringAsFixed(2)),
             enabledViewCashShiftDetails ? _buildRow("Tarjeta Electrónica", shift.creditCardCalcElectronic?.toStringAsFixed(2)) : Container(),
             enabledViewCashShiftDetails ? _buildRow("Tarjeta de Preventa", shift.creditCardCalcPreventa?.toStringAsFixed(2)) : Container(),
              _buildRow("Cheque/Transf.", shift.checkOrTransf?.toStringAsFixed(2)),
              _buildRow("Ventas a Crédito", shift.saleToCredit?.toStringAsFixed(2)),
              _buildRow("Total", shift.totalAmount?.toStringAsFixed(2)),
              _buildRow("Impuestos", shift.totalTax?.toStringAsFixed(2)),
              _buildRow("Transacciones", shift.transactionsCount?.toString()),
              _buildRow("Estado", shift.statusName),
              _buildRow("Efectivo Contado", shift.effectiveCount?.toStringAsFixed(2)),
              _buildRow("Faltante/Sobrante", shift.missingCash?.toStringAsFixed(2)),
            enabledViewCashShiftDetails?   _buildRow("Transacciones Electrónicas", shift.transactionsCountElectronic?.toString()): Container(),
             enabledViewCashShiftDetails ? _buildRow("Transacciones de Preventa", shift.transactionsCountPreventa?.toString()) : Container(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      );
    },
  );
}

Widget _buildRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text(value ?? "-")),
      ],
    ),
  );
}
