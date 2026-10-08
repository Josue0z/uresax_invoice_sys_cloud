import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:localstorage/localstorage.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/cash.shift.model.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.product.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.service.dart';
import 'package:uresax_invoice_sys_cloud/models/orden.model.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.orden.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/dashborder.pdf.widget.dart';

List<int> createDivider(Generator generator) {
  List<int> bytes = [];
  final divider = '-' * 48; // Para mm80
  bytes += generator.text(divider, styles: PosStyles(align: PosAlign.center));
  return bytes;
}

Future<pw.Font> loadMaterialIconsFont() async {
  final fontData =
      await rootBundle.load("assets/fonts/MaterialIcons-Regular.ttf");
  return pw.Font.ttf(fontData);
}

pw.Document createDefaultInvoice(Sale sale) {
  var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
    var esCotization = sale.ncfTypeId == '60';

  List<String> columns() {
    return sale.items[0].toDisplay().keys.toList();
  }

  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

  if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }

        final columnWidths = {
  0: pw.FlexColumnWidth(),
  1: pw.FixedColumnWidth(170),
  2: pw.FlexColumnWidth(),
  3: pw.FlexColumnWidth(),
  4: pw.FlexColumnWidth(),
};

  document.addPage(pw.MultiPage(header: (ctx) {
    return pw.Column(children: [
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
            flex: 2,
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                removeInvoiceTitle ? pw.SizedBox(
                  height: kDefaultPadding * 2
                ):  pw.Container(
                  margin: pw.EdgeInsets.symmetric(
                    vertical: kDefaultPadding/3
                  ),
                  child:  pw.Row(children: [
                    company?.logo != null
                        ? pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                                pw.Image(
                                    pw.MemoryImage(
                                        base64Decode(company!.logo!)),
                                    width: 60),
                                pw.SizedBox(width: kDefaultPadding / 2),
                              ])
                        : pw.SizedBox(),
                    pw.Text(company?.name ?? '',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ]),
                ),
         
                  pw.Text(company?.rncOrId ?? '',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: kDefaultPadding / 3),
                  pw.Text(company?.address ?? '',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: kDefaultPadding / 3),
                  pw.Text(company?.phone1 ?? '',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: kDefaultPadding / 3),
                  pw.Text(company?.email ?? '',
                      style: pw.TextStyle(fontSize: 10)),
                 pw.SizedBox(height: kDefaultPadding / 3),
                ])),
      ]),
      pw.Row(
           crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Facturado a:',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: kDefaultPadding / 3),
                pw.Text(sale.clientName ?? '',
                    style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: kDefaultPadding / 3),
                pw.Text('Rnc/Cedula:',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: kDefaultPadding / 3),
                pw.Text(sale.clientIdentificationFormat,
                    style: pw.TextStyle(fontSize: 8)),
                pw.Container(
                    margin: pw.EdgeInsets.only(top: kDefaultPadding / 3),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Dirección:',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: kDefaultPadding / 3),
                          pw.Text(
                              sale.clientAddress == '' ||
                                      sale.clientAddress == null
                                  ? '<Sin dirección>'
                                  : sale.clientAddress.toString(),
                              style: pw.TextStyle(fontSize: 8)),
                        ])),
                pw.Container(
                    margin: pw.EdgeInsets.only(top: kDefaultPadding / 3),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Tel:',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: kDefaultPadding / 3),
                          pw.Text(
                              sale.clientPhone == '' ||
                                      sale.clientPhone == null
                                  ? 'S/N'
                                  : sale.clientPhone.toString(),
                              style: pw.TextStyle(fontSize: 8)),
                        ])),

                  pw.Container(
                    margin: pw.EdgeInsets.only(top: kDefaultPadding / 3),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Correo:',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: kDefaultPadding / 3),
                          pw.Text(
                              sale.clientEmail == '' ||
                                      sale.clientEmail == null
                                  ? 'S/N'
                                  : sale.clientEmail.toString(),
                              style: pw.TextStyle(fontSize: 8)),
                        ])),
              company?.bankInfo != null ?  pw.Container(
                    margin: pw.EdgeInsets.only(top: kDefaultPadding / 3),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Información bancaria:',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: kDefaultPadding / 3),
                          pw.Text(
                               company?.bankInfo.toString() ?? 'S/N',
                              style: pw.TextStyle(fontSize: 8)),
                        ])):pw.SizedBox()
              ]),
        ),
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
              pw.Text(sale.ncfTypeName ?? '',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: kDefaultPadding/2),
              pw.Container(
                margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Factura #',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(width: kDefaultPadding/3),
                      pw.Text(
                        sale.ncf ?? '',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      )
                    ]),
              ),
              sale.ncfAffected != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.only(
                        bottom: kDefaultPadding / 2,
                      ),
                      child: pw.Text(sale.ncfAffected ?? '',
                          style: pw.TextStyle(fontSize: 10)))
                  : pw.SizedBox(),
              pw.Container(
                margin: pw.EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 3,
                ),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Fecha',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(width: kDefaultPadding/3),
                      pw.Text(
                        sale.createdAt?.format(payload: 'DD/MM/YYYY') ?? '',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      )
                    ]),
              ),
              sale.issueDate != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text('Fecha de Emision Ncf',
                                style: pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.right),
                            pw.SizedBox(width: kDefaultPadding/3),
                            pw.Text(
                                sale.issueDate?.format(
                                      payload: 'DD/MM/YYYY',
                                    ) ??
                                    '',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(fontSize: 10)),
                          ]))
                  : pw.SizedBox(),
              sale.retentionDate != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text('Fecha de Retencion',
                                style: pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.right),
                            pw.SizedBox(width: kDefaultPadding),
                            pw.Text(
                                sale.retentionDate?.format(
                                      payload: 'DD/MM/YYYY',
                                    ) ??
                                    '',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(fontSize: 10)),
                          ]))
                  : pw.SizedBox(),
              sale.expirationDate != null && esConsumo == false && esNotaCredito == false && esCotization == false
                  ? pw.Container(
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                          pw.Text('Fecha de Vencimiento',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(width: kDefaultPadding/2),
                          pw.Text(
                              sale.expirationDate
                                      ?.format(payload: 'DD/MM/YYYY') ??
                                  '',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 10))
                        ]))
                  : pw.SizedBox()
            ]))
      ]),
      pw.SizedBox(
        height: kDefaultPadding/2
      ),
      pw.Table(
        columnWidths: columnWidths,
        children: [
            pw.TableRow(
               verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#343a40')),
            children: List.generate(columns().length, (index) {
              var col = columns()[index];

              return pw.Padding(
                  padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                  child: pw.Text(col,
                      style:
                          pw.TextStyle(color: PdfColors.white, fontSize: 7)));
            })),
        ]
      )
    ]);
  }, build: (ctx) {
    return [
    
      pw.Table(columnWidths:columnWidths,
      
       children: [
      
        ...List.generate(sale.items.length, (index) {
          var item = sale.items[index];
          var values = item.toDisplay().values.toList();
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColor.fromHex('#e6e6e6')))),
              children: List.generate(values.length, (i) {
                var val = values[i];
                return pw.Padding(
                    padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                    child: pw.Text(val, style: pw.TextStyle(fontSize: 7)));
              }));
        })
      ]),
      pw.SizedBox(height: kDefaultPadding/2),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
               pw.Container(
                margin: pw.EdgeInsets.only(
                  bottom: kDefaultPadding/2
                ),
                child: pw.Text(sale.description ?? '', style: pw.TextStyle(fontSize: 8)),
               ),
     
              pw.SizedBox(
                  width: 80,
                  height: 80,
                  child: pw.BarcodeWidget(
                      data: sale.dgiiURL != null
                          ? sale.dgiiURL ?? ''
                          : sale.ncf ?? '',
                      barcode: qr)),
              pw.SizedBox(height: kDefaultPadding / 2),
              sale.securityCode != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Codigo de seguridad:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.securityCode ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.signatureDate != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Fecha de Firma:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(
                            sale.signatureDate
                                    ?.format(payload: 'DD-MM-YYYY HH:mm:ss') ??
                                '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.authorName != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Atendido por:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.authorName ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.rate != null && sale.rate! > 1
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Tasa Dolar:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.rate?.toStringAsFixed(2) ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.estadoDgiiNombre != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Estado DGII:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.estadoDgiiNombre ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
            ])),
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.netLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])),
             sale.discount! > 0 ? pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Descuento'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.discountLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])):pw.SizedBox(),
              sale.netFinal! > 0 && sale.net != sale.netFinal ?  pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.netFinalLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])):pw.SizedBox(),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Itbis'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.taxLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])),

                sale.law10! > 0 ? pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Ley 10%'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.law10Label,
                            style: pw.TextStyle(fontSize: 7))
                      ])):pw.SizedBox(),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.totalLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])),
             sale.retentionTax! > 0 ?  pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Retención Itbis'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          sale.retentionTaxLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])):pw.SizedBox(),
             sale.retentionIsr! > 0 ? pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Retención Isr'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.retentionIsrLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])):pw.SizedBox(),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            sale.ncfTypeId!.contains('34')
                                ? 'Total a devolver'.toUpperCase()
                                : 'Total a pagar'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.amountPaidLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Pagado'.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            sale.amountxPaidLabel,
                            style: pw.TextStyle(fontSize: 7))
                      ])),
              pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Text('FORMAS DE PAGO:',
                      style: pw.TextStyle(
                          fontSize: 6, fontWeight: pw.FontWeight.bold))),
              pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: 5),
                child: pw.Text(paymentsWidgets.join(','),
                    style: pw.TextStyle(fontSize: 6)),
              )
            ]))
      ])
    ];
  }, footer: (ctx) {
    return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(children: [
            pw.SizedBox(height: kDefaultPadding),
            pw.Container(width: 150, height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: kDefaultPadding / 2),
            pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8))
          ]),
          pw.SizedBox(width: kDefaultPadding),
          pw.Column(children: [
            pw.SizedBox(height: kDefaultPadding),
            pw.Container(width: 150, height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: kDefaultPadding / 2),
            pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8))
          ]),
        ]);
  }));

  
  return document;
}

pw.Document createDefaultOrdenPurchase(OrdenModel orden) {
  var document = pw.Document(
      theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 8)));
  // Generar código QR
  // final qr = Barcode.qrCode();

  List<String> columns() {
    return orden.items![0].toDisplay().keys.toList();
  }

  document.addPage(pw.MultiPage(header: (ctx) {
    return pw.Column(children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(
            flex: 2,
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(children: [
                    pw.Text(company?.name ?? '',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.SizedBox(height: kDefaultPadding / 2),
                  pw.Text(
                    company?.rncOrId ?? '',
                  ),
                  pw.SizedBox(height: kDefaultPadding / 2),
                  pw.Text(
                    company?.address ?? '',
                  ),
                  pw.SizedBox(height: kDefaultPadding / 2),
                  pw.Text(
                    'TEL: ${company?.phone1}',
                  ),
                  pw.SizedBox(height: kDefaultPadding / 2),
                  pw.Text(
                    '${company?.email}',
                  ),
                  pw.SizedBox(height: kDefaultPadding / 2),
                  pw.Row(children: [
                    pw.Text('PROVEEDOR:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: kDefaultPadding / 3),
                    pw.Text(
                      '${orden.providerName}',
                    )
                  ]),
                  pw.SizedBox(height: kDefaultPadding / 2),
                  pw.Row(children: [
                    pw.Text('RNC/CEDULA:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: kDefaultPadding / 3),
                    pw.Text(
                      '${orden.providerIdentification}',
                    )
                  ]),
                  pw.SizedBox(height: kDefaultPadding / 2),
                  pw.Row(children: [
                    pw.Text('CONDUCTOR:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: kDefaultPadding / 3),
                    pw.Text(
                      '${orden.driverName}',
                    )
                  ]),
                ])),
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
              pw.Text('ORDEN DE COMPRA',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: kDefaultPadding),
              pw.Container(
                margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 2),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Orden #',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(width: kDefaultPadding),
                      pw.Text(
                        orden.ordenNumString.toString(),
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      )
                    ]),
              ),
              pw.Container(
                margin: pw.EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 2,
                ),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Fecha de Orden',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.SizedBox(width: kDefaultPadding / 2),
                      pw.Text(
                        orden.createdAt?.format(payload: 'DD/MM/YYYY') ?? '',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      )
                    ]),
              ),
            ]))
      ]),
    ]);
  }, build: (ctx) {
    return [
      pw.SizedBox(height: kDefaultPadding),
      pw.Table(children: [
        pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#343a40')),
            children: List.generate(columns().length, (index) {
              var col = columns()[index];

              return pw.Padding(
                  padding: pw.EdgeInsets.all(kDefaultPadding / 4),
                  child: pw.Text(col,
                      style:
                          pw.TextStyle(color: PdfColors.white, fontSize: 6)));
            })),
        ...List.generate(orden.items?.length ?? 0, (index) {
          var item = orden.items?[index];
          var values = item?.toDisplay().values.toList();
          return pw.TableRow(
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColor.fromHex('#e6e6e6')))),
              children: List.generate(values?.length ?? 0, (i) {
                var val = values?[i];
                return pw.Padding(
                    padding: pw.EdgeInsets.all(kDefaultPadding / 4),
                    child: pw.Text(val, style: pw.TextStyle(fontSize: 6)));
              }));
        })
      ]),
      pw.SizedBox(height: kDefaultPadding),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(child: pw.Container()),
        pw.Expanded(
            child: pw.Column(children: [
          pw.Container(
              margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColor.fromHex('#e6e6e6')))),
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total a Pagar', style: pw.TextStyle(fontSize: 8)),
                    pw.Text(orden.total?.toDop() ?? '',
                        style: pw.TextStyle(fontSize: 8))
                  ])),
        ]))
      ])
    ];
  }, footer: (ctx) {
    return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(children: [
            pw.Container(width: 150, height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: kDefaultPadding / 2),
            pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8))
          ]),
          pw.SizedBox(width: kDefaultPadding),
          pw.Column(children: [
            pw.Container(width: 150, height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: kDefaultPadding / 2),
            pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8))
          ]),
        ]);
  }));
  return document;
}

Future<pw.Document> createPaymentInvoice(Payment payment) async {
  var document = pw.Document();

  var materialFonts = await loadMaterialIconsFont();

  document.addPage(pw.MultiPage(
      margin: pw.EdgeInsets.all(kDefaultPadding * 3),
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      theme: pw.ThemeData.withFont(
        icons: materialFonts, // Carga la fuente de íconos
      ),
      build: (ctx) {
        return [
          pw.Center(
              child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Column(children: [
                        pw.Icon(
                          pw.IconData(0xe86c),
                          size: 200,
                          color: PdfColor.fromHex('#7BC113'),
                        ),
                        pw.SizedBox(height: kDefaultPadding),
                        pw.Text(
                            payment.currencyId == 1
                                ? payment.amount?.toDop()
                                : payment.amount?.toUS(),
                            style: pw.TextStyle(fontSize: 28)),
                        pw.SizedBox(height: kDefaultPadding),
                        pw.Text('COMPROBANTE DE PAGO',
                            style: pw.TextStyle(fontSize: 24)),
                      ])
                    ]),
                pw.SizedBox(height: kDefaultPadding * 4),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Fecha', style: pw.TextStyle(fontSize: 12)),
                      pw.Text(
                          payment.createdAt
                                 ?.format(payload: 'DD/MM/YYYY') ??
                              '',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Cliente', style: pw.TextStyle(fontSize: 12)),
                      pw.Text(payment.clientName ?? 'S/N',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Banco', style: pw.TextStyle(fontSize: 12)),
                      pw.Text(payment.bankName ?? 'S/N',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Forma de Pago',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text(payment.paymentMethodName ?? '',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Numero de cheque o transferencia',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text(payment.transfRef ?? 'S/N',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
              ]))
        ];
      }));
  return document;
}

pw.Document createVerticalInvoice(Sale sale) {
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  List<String> columns() {
    return sale.items[0].toDisplayReceipt().keys.toList();
  }

  List<pw.Widget> paymentsWidgets = [];

  bool esConsumo250k = (sale.ncfTypeId == '02' || sale.ncfTypeId == '32') &&
      eCommerceMode &&
      sale.total! < 250000;

   bool esConsumo = (sale.ncfTypeId == '02' || sale.ncfTypeId == '32');
   
   bool esCotization = (sale.ncfTypeId == '50' || sale.ncfTypeId == '60');
   bool esNotaCredito = (sale.ncfTypeId == '04' || sale.ncfTypeId == '34');

  if (sale is SaleProduct || sale is SaleService) {
    if (sale.effective != 0) {
      paymentsWidgets.add(pw.Container(
          margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
          child: pw.Text('EFECTIVO')));
    }

    if (sale.creditCard != 0) {
      paymentsWidgets.add(pw.Container(
          margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
          child: pw.Text(
            'TARJETA DE CREDITO O DEBITO\n${sale.creditCardDescription ?? ''}',
          )));
    }

    if (sale.checkOrTransf != 0) {
      paymentsWidgets.add(pw.Container(
          margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
          child: pw.Text(
            'CHEQUE O TRANSFERENCIA',
          )));
    }

    if (sale.saleToCredit != 0) {
      paymentsWidgets.add(pw.Container(
          margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
          child: pw.Text('VENTA A CREDITO')));
    }
  } else {
    paymentsWidgets.add(pw.Container(
        margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
        child: pw.Text('NOTA DE CREDITO')));
  }
  String tels = '';

    
    if(sale.branchePhone1 == null){
       if(company?.phone1 != null){
    if(company?.phone1?.isNotEmpty == true){
            tels+='Tel: ${company?.phone1}';
    }
  }
    }else{
         tels+='Tel: ${sale.branchePhone1}';
    }

   if(sale.branchePhone2 == null){
     if(company?.phone2 != null){

      if(company?.phone2?.isNotEmpty == true){
          tels+='\nCel: ${company?.phone2}';
      }
    
  }
   }else{
      tels+='\nCel: ${sale.branchePhone2}';
   }

  pw.Document document = pw.Document(
      theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 6)));
  document.addPage(pw.MultiPage(
      margin: pw.EdgeInsets.symmetric(horizontal: 190, vertical: 60),
      crossAxisAlignment: pw.CrossAxisAlignment.center,

      orientation: pw.PageOrientation.portrait,
      header: (ctx) {
        return pw
            .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, 
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
            company?.logo != null ?   pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Image(pw.MemoryImage(base64Decode(company?.logo??'')),width: 100,height: 100)
              ):pw.SizedBox(),


          
          pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Column(children: [
               
                enabledFirstComercialName ? pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                sale.brancheName != null ? pw.Text(sale.brancheName ?? '',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)):pw.SizedBox(),
                      pw.Text( company?.name ?? '',
                    style: pw.TextStyle(
                        fontSize:8, fontWeight: pw.FontWeight.bold)),
                  ]
                ): pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                      pw.Text( company?.name ?? '',
                    style: pw.TextStyle(
                        fontSize:11, fontWeight: pw.FontWeight.bold)),

                         sale.brancheName != null ? pw.Text(sale.brancheName ?? '',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)):pw.SizedBox(),
                  ]
                ),
                pw.SizedBox(height: kDefaultPadding / 2),
                pw.Text('RNC: ${company?.rncOrId}'),
                company?.address != null || company?.address?.isNotEmpty == true
                    ? pw.Container(
                        margin: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding / 2),
                        child: pw.Text(company?.address?.toUpperCase() ?? ''))
                    : pw.SizedBox(),
                  tels.isNotEmpty ? pw.Container(
                   child: pw.Text(tels)
                  ):pw.SizedBox()
                
              ])),
          pw.SizedBox(height: kDefaultPadding),
          pw.Container(
                  margin:
                      pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
                  child: pw.Text('Rnc/Cedula: ${sale.clientIdentification}'
                      .toUpperCase())),
          pw.Container(
              margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
              child: pw.Text(
                  'Cliente: ${sale.clientName}'.toUpperCase())),
       
          pw.Container(
              margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
              child: pw.Text(
                  'Fecha Emision: ${sale.issueDate?.format(payload: 'DD/MM/YYYY')}'
                      .toUpperCase())),

          sale.expirationDate != null && esConsumo == false && esNotaCredito == false && esCotization == false
              ? pw.Container(
                  margin:
                      pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
                  child: pw.Text(
                     'Fecha de Vencimiento: ${sale.expirationDate?.format(payload: 'DD/MM/YYYY')}'.toUpperCase()))
              : pw.SizedBox(),
          pw.Container(
              margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
              child: pw.Text('NCF: ${sale.ncf}')),
          sale.ncfAffected != null
              ? pw.Container(
                  margin:
                      pw.EdgeInsets.only(bottom: kDefaultPadding / 3),
                  child: pw.Text(
                      'NCF AFECTADO: ${sale.ncfAffected}'.toUpperCase()))
              : pw.SizedBox(),
          pw.SizedBox(
            width: double.infinity,
            child: DashedBorderPdf(
              color: PdfColors.black,
              dashWidth: 3,
              strokeWidth: 0.2,
              child: pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(sale.ncfTypeName ?? '',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 6))),
              ),
            ),
          )
        ]);
      },
      build: (ctx) {
        return [
        pw.Column(
           
          children: [

         
  pw.SizedBox(
    width: double.infinity,
    child:   pw.CustomPaint(
        painter: (PdfGraphics canvas, PdfPoint size) {
          const dashWidth = 3.0;
          const dashSpace = 2.0;

          canvas.setStrokeColor(PdfColors.black);
          canvas.setLineWidth(0.2);

          double x = 0;
          while (x < size.x) {
            canvas.drawLine(x, 0, x + dashWidth, 0);
            x += dashWidth + dashSpace;
          }

          canvas.strokePath();
        },
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
    children: List.generate(columns().length, (index) {
      var col = columns()[index];

      return  pw.Expanded(
        flex: index == 0 ? 4: 1,
        child: pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
          child: pw.Text(
            col,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontWeight: pw.FontWeight.bold,
              fontSize: 5,
            ),
          ),
        ));


    }),
  ),
      )
  ),

  ...List.generate(sale.items.length, (index) {
    final item = sale.items[index];
    final values = item.toDisplayReceipt().values.toList();

    return pw.SizedBox(
      width: double.infinity,
      child: pw.CustomPaint(
          painter: (PdfGraphics canvas, PdfPoint size) {
            const dashWidth = 3.0;
            const dashSpace = 2.0;

            canvas.setStrokeColor(PdfColors.black);
            canvas.setLineWidth(0.5);

            double x = 0;
            while (x < size.x) {
              canvas.drawLine(x, 0, x + dashWidth, 0);
              x += dashWidth + dashSpace;
            }

            canvas.strokePath();
          },
          child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
      children: List.generate(values.length, (i) {
              final val = values[i];

        return pw.Expanded(
          flex: i == 0 ? 4: 1,
          child:  pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding / 3
            ),
            child: pw.Text(val, style: const pw.TextStyle(fontSize: 5)),
          ));

  

      }),
    )
        )
    );


  }),
]),

          pw.SizedBox(height: kDefaultPadding),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                      pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 2),
                          child: pw.Text('Forma de pagos:'.toUpperCase(),
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      ...paymentsWidgets
                    ])),
                pw.Expanded(
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                      pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(
                              'Subtotal: ${(sale.net!).toCoin()}'
                                  .toUpperCase())),
                      pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text('Descuento: ${sale.discount?.toCoin()}'
                              .toUpperCase())),
                         pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(
                              'Subtotal: ${(sale.netFinal!).toCoin()}'
                                  .toUpperCase())),
                    
                      pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(
                              'Itbis: ${sale.tax?.toCoin()}'.toUpperCase())),
                      pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text('Ley 10%: ${sale.law10?.toCoin()}'
                              .toUpperCase())),
                      pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.RichText(
                              text: pw.TextSpan(children: [
                            pw.TextSpan(
                                text: 'Total: '.toUpperCase(),
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: '${sale.total?.toCoin()}')
                          ]))),

                         pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.RichText(
                              text: pw.TextSpan(children: [
                            pw.TextSpan(
                                text: 'Total Pagado: '.toUpperCase(),
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: '${sale.paid?.toCoin()}')
                          ]))),

                                pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.RichText(
                              text: pw.TextSpan(children: [
                            pw.TextSpan(
                                text: 'Devuelta: '.toUpperCase(),
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: '${sale.coinBack?.toCoin()}')
                          ]))),
                    ]))
              ]),
          pw.SizedBox(height: kDefaultPadding),
          pw.Column(children: [
            pw.Container(
                width: 100,
                height: 100,
                margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding),
                child: pw.BarcodeWidget(
                    data: sale.dgiiURL != null
                        ? sale.dgiiURL ?? ''
                        : sale.ncf ?? '',
                    barcode: qr)),
            sale.securityCode != null
                ? pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('Codigo de seguridad:',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 5),
                          pw.Text(sale.securityCode ?? '',
                              style: pw.TextStyle(fontSize: 9)),
                        ]))
                : pw.SizedBox(),
            sale.signatureDate != null
                ? pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('Fecha de Firma:',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 5),
                          pw.Text(
                              sale.signatureDate?.format(
                                      payload: 'DD-MM-YYYY HH:mm:ss') ??
                                  '',
                              style: pw.TextStyle(fontSize: 9)),
                        ]))
                : pw.SizedBox(),
            sale.authorName != null
                ? pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('Atendido por:',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 5),
                          pw.Text(sale.authorName ?? '',
                              style: pw.TextStyle(fontSize: 9)),
                        ]))
                : pw.SizedBox()
          ])
        ];
      }));

  return document;
}

Future<List<int>> createDefaultTicket(
    {String name = 'default', required Sale sale}) async {
  // Using default profile
  final profile =  await CapabilityProfile.load(name: name);

  final generator = Generator(PaperSize.mm80, profile,spaceBetweenRows: 2,codec: CustomLatinCodec());
  List<int> bytes = [];
  bytes.addAll([27, 97, 0]); // ESC a 0 → izquierda

  generator.setStyles(PosStyles(width: PosTextSize.size6));
    
    var base64String = company?.logo;

    if(base64String != null){
       final data = base64String.contains('base64,')
      ? base64String.split('base64,').last
      : base64String;
  final Uint8List imageBytes = base64.decode(data);

  // 2) Decodificar con package:image
  img.Image? decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    throw Exception('No se pudo decodificar la imagen Base64');
  }

  // 3) Redimensionar si es necesario (ajusta maxWidth según tu papel mm80)
  const int maxWidth = 560; // ejemplo: ancho en px para mm80
  if (decoded.width > maxWidth) {
    decoded = img.copyResize(decoded, width: maxWidth);
  }
  bytes+=generator.image(decoded);
  }

  if(enabledFirstComercialName){

  if(company?.comercialName != null){
     bytes += generator.text(sale.brancheName ??  company?.comercialName ?? '',
      styles: PosStyles(bold: true, fontType: PosFontType.fontA, align: PosAlign.center));
  }

   bytes += generator.text(company?.name ?? '',
      styles: PosStyles(bold: true, fontType: PosFontType.fontA, align: PosAlign.center));
  
  }else{
      bytes += generator.text(company?.name ?? '',
      styles: PosStyles(bold: true, fontType: PosFontType.fontA, align: PosAlign.center));
  
      if(company?.comercialName != null){
     bytes += generator.text(sale.brancheName ??  company?.comercialName ?? '',
      styles: PosStyles(bold: true, fontType: PosFontType.fontA, align: PosAlign.center));
  }
 
  }

 
    bytes += generator.text(company?.rncOrId ?? '',
      styles: PosStyles(align: PosAlign.center));


  if(company?.address != null || company?.address?.isNotEmpty == true || sale.brancheAddress != null){
     bytes += generator.text(sale.brancheAddress ??  company?.address ?? '',
      styles: PosStyles(align: PosAlign.center));
  }

    
    String tels = '';
  if(company?.phone1 != null || company?.phone1?.isNotEmpty == true || sale.branchePhone1 != null){
        tels +='Tel: ${sale.branchePhone1 ??  company?.phone1}';
     }
  if(company?.phone2 != null || company?.phone2?.isNotEmpty == true || sale.branchePhone2 != null){
        tels +='\nCel: ${sale.branchePhone2 ??  company?.phone2}';
  }
     
  if(tels.isNotEmpty){
      bytes += generator.text(tels,
      styles: PosStyles(align: PosAlign.center));
  }



  bytes += generator.emptyLines(1);

  bool esConsumo =
      (sale.ncfTypeId == '02' || sale.ncfTypeId == '32') && eCommerceMode;

  bool esNotaCredito = (sale.ncfTypeId == '04' || sale.ncfTypeId == '34');
  var esCotization = sale.ncfTypeId == '60';

 
 bytes += generator.text('Rnc/Cedula: ${sale.clientIdentification}'.toUpperCase(),
        styles: PosStyles(align: PosAlign.left));
  
  bytes += generator.text('Cliente: ${sale.clientName}'.toUpperCase(),
      styles: PosStyles(align: PosAlign.left));
  bytes +=
      generator.text(sale.ncf ?? '', styles: PosStyles(align: PosAlign.left));

  if (sale.ncfAffected != null) {
    bytes += generator.text(sale.ncfAffected ?? '',
        styles: PosStyles(align: PosAlign.left));
  }
  bytes += generator.text(
      'Fecha de Emision: ${sale.issueDate?.format(payload: 'DD/MM/YYYY')}'.toUpperCase(),

  
  styles: PosStyles(align: PosAlign.left));
   
     if(!esConsumo){
       if(!esNotaCredito){
         if(!esCotization){
      
           bytes += generator.text(
      'Fecha de Vencimiento: ${sale.expirationDate?.format(payload: 'DD/MM/YYYY')}'.toUpperCase(),
      styles: PosStyles(align: PosAlign.left));
         }
       }
     }
   

  bytes += createDivider(generator);

  bytes += generator.text(sale.ncfTypeName ?? '',
      styles: PosStyles(align: PosAlign.center, bold: true));

  bytes += createDivider(generator);

  var cols = sale.items[0].toDisplayReceipt().keys.toList();
  bytes += generator.row(List.generate(cols.length, (i) {
    var e = cols[i];
    return PosColumn(text: e, width: i == 0 ? 6 : 3);
  }));
  bytes += createDivider(generator);

  for (var item in sale.items) {
    var values = item.toDisplayReceipt().values.toList();

    bytes += generator.row(List.generate(values.length, (i) {
      var w = i == 0 ? 6 : 3;
      var e = values[i];

      return PosColumn(text: e, width: w);
    }));

    bytes += createDivider(generator);
  }

  bytes += generator.emptyLines(2);

  List<String> paymentsMethods = [];

  bool isCreditNote =
      sale is CreditNoteAsProduct || sale is CreditNoteAsService;

  List<String> calcs = [
    'SUBTOTAL: ${(sale.net!).toCoin()}',
    'DESCUENTO: ${sale.discount?.toCoin()}',
    'SUBTOTAL: ${(sale.netFinal!).toCoin()}',
    'TOTAL ITBIS: ${sale.tax?.toCoin()}'
  ];

  if (sale.law10! > 0) {
    calcs.addAll({'LEY 10%: ${sale.law10?.toCoin()}'});
  }

  if (isCreditNote) {
    calcs.addAll(['DEVUELTO: ${sale.total!.toCoin()}']);
  } else {
    calcs.addAll(['TOTAL FACTURADO: ${sale.total!.toCoin()}']);
  }
  if (sale.paid != 0 && sale.paid! > 0) {
    calcs.add('TOTAL PAGADO: ${sale.paid!.toCoin()}');
  }
  if (sale.effective != 0) {
    paymentsMethods.add('EFECTIVO');
    if (sale.coinBack != 0 && sale.coinBack! > 0) {
      calcs.add('DEVUELTA: ${sale.coinBack!.toCoin()}');
    }
  }

  if (sale.creditCard != 0) {
    if(sale.creditCardDescription != null){
          paymentsMethods.add('TARJETA\n${sale.creditCardDescription}');
    }else{
          paymentsMethods.add('TARJETA');
    }

  }
  if (sale.checkOrTransf != 0) {
    paymentsMethods.add('CHEQUE O TRANSFERENCIA');
  }

  if (sale.saleToCredit != 0) {
    paymentsMethods.add('VENTA A CREDITO');
  }

  if(esNotaCredito){
    paymentsMethods = ['NOTA DE CREDITO'];
  }

  final maxLines = max(paymentsMethods.length, calcs.length);

  for (int i = 0; i < maxLines; i++) {
    final leftText = i < paymentsMethods.length ? paymentsMethods[i] : '';

    String? label;
    String? value;

    if (i < calcs.length) {
      final parts = calcs[i].split(':');
      label = parts.length > 1 ? parts[0].trim() : calcs[i];
      value = parts.length > 1 ? parts[1].trim() : '';
    }

 
    bytes += generator.row([
      PosColumn(
        text: leftText,
        width: 5,
        styles: PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: label ?? '',
        width: 4,
        styles: PosStyles(align: PosAlign.left,bold: i == 6 ? true: false),
      ),
      PosColumn(
        text: value ?? '',
        width: 3,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);


  }

  bytes += generator.emptyLines(5);

  bytes += generator.qrcode(sale.dgiiURL ?? company?.instagramLink ?? sale.ncf ?? '',
      align: PosAlign.center, size: QRSize.size7);
  bytes += generator.emptyLines(1);

  if (sale.signatureDate != null) {
    bytes += generator.text('Codigo de Seguridad: ${sale.securityCode}',
        styles: PosStyles(align: PosAlign.center));

    bytes += generator.text(
        'Fecha de Firma: ${sale.signatureDate?.format(payload: 'DD-MM-YYYY HH:mm:ss')}',
        styles: PosStyles(align: PosAlign.center));
  }
  bytes+=generator.emptyLines(1);

  if(sale.message != null){
    bytes += generator.text(sale.message ?? '',
        styles: PosStyles(align: PosAlign.center));
  }

  bytes += generator.feed(2);
  bytes += generator.cut();

  return bytes;
}

Future<List<int>> createDefaultOrdenTicket(
    {String name = 'default', required WareHouseElement entry}) async {
  // Using default profile
  final profile = await CapabilityProfile.load(name: name);
  final generator = Generator(PaperSize.mm80, profile);
  List<int> bytes = [];
  generator.setStyles(PosStyles(width: PosTextSize.size6));

  bool isOrden = entry is OrdenModel;
  String num = entry.ordenNumString ?? entry.entryNumString ?? '';

  bytes += generator.text(company?.name ?? '',
      styles: PosStyles(bold: true, align: PosAlign.center));

  bytes += generator.text(company?.rncOrId ?? '',
      styles: PosStyles(align: PosAlign.center));

  String label = isOrden ? 'ORDEN' : 'ENTRADA';
  String labelTag = isOrden ? 'ORDEN DE COMPRA' : 'ENTRADA DE ALMACEN';

  bytes +=
      generator.text('$label: $num', styles: PosStyles(align: PosAlign.left));

  bytes += generator.text(
      'Fecha de Emision: ${entry.createdAt?.format(payload: 'DD/MM/YYYY')}',
      styles: PosStyles(align: PosAlign.left));

  bytes += generator.text('PROVEEDOR: ${entry.providerName}',
      styles: PosStyles(align: PosAlign.left));

  bytes += generator.text('RNC/CEDULA: ${entry.providerIdentification}',
      styles: PosStyles(align: PosAlign.left));

  bytes += generator.text('CONDUCTOR: ${entry.driverName}',
      styles: PosStyles(align: PosAlign.left));

  bytes += createDivider(generator);

  bytes += generator.text(labelTag,
      styles: PosStyles(align: PosAlign.center, bold: true));

  bytes += createDivider(generator);
  var cols = entry.items![0].toDisplayReceipt().keys.toList();
  bytes += generator.row(List.generate(cols.length, (i) {
    var e = cols[i];
    return PosColumn(text: e, width: i == 0 ? 6 : 3);
  }));
  bytes += createDivider(generator);

  for (var item in entry.items!) {
    var values = item.toDisplayReceipt().values.toList();

    bytes += generator.row(List.generate(values.length, (i) {
      var w = i == 0 ? 6 : 3;
      var e = values[i];

      return PosColumn(text: e, width: w);
    }));

    bytes += createDivider(generator);
  }

  bytes += generator.emptyLines(2);

   bytes += generator.text('SUBTOTAL: ${entry.net?.toDop()}',
      styles: PosStyles(align: PosAlign.right));

   bytes += generator.text('DESCUENTO: ${entry.discount?.toDop()}',
      styles: PosStyles(align: PosAlign.right));

  bytes += generator.text('SUBTOTAL: ${entry.netFinal?.toDop()}',
      styles: PosStyles(align: PosAlign.right));

  bytes += generator.text('ITBIS: ${entry.tax?.toDop()}',
      styles: PosStyles(align: PosAlign.right));

  bytes += generator.text('TOTAL FACTURADO: ${entry.total?.toDop()}',
      styles: PosStyles(align: PosAlign.right));

  bytes += generator.text('TOTAL PAGADO: ${entry.amountPaid?.toDop()}',
      styles: PosStyles(align: PosAlign.right));

  bytes += generator.emptyLines(2);

  bytes += generator.qrcode(num.toString(), size: QRSize.size7);

  bytes += generator.feed(2);
  bytes += generator.cut();

  return bytes;
}

pw.Document createFreelanceInvoice(Sale sale) {
  var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  final PdfColor primaryColor = PdfColor.fromHex('#1D678F');

  List<String> columns() {
    return sale.items[0].toDisplayItemFreelance().keys.toList();
  }

  var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
    var esCotization = sale.ncfTypeId == '60';

  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

 if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }


      final columnWidths = {
  0:pw.FixedColumnWidth(170),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(),
  3: pw.FlexColumnWidth(),
  4: pw.FlexColumnWidth(),
};


  document.addPage(pw.MultiPage(
      theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(
              font: pw.Font.helvetica(), color: PdfColor.fromHex('#545658'))),
      /*pageTheme: pw.PageTheme(
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            color: PdfColor.fromHex('#F5FAFD')
          )
        ),
      ),*/
      header: (ctx) {
        return pw.Column(children: [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
                flex: 2,
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        company?.logo != null
                            ? pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: [
                                    pw.Image(
                                        pw.MemoryImage(
                                            base64Decode(company!.logo!)),
                                        width: 80),
                                    pw.SizedBox(width: kDefaultPadding / 2),
                                  ])
                            : pw.SizedBox(),
                        pw.Text(company?.name ?? '',
                            style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                      ]),
                      pw.SizedBox(height: kDefaultPadding / 3),
                      pw.Text(company?.rncOrId ?? '',
                          style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: kDefaultPadding / 3),
                      pw.Text(company?.address ?? '',
                          style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: kDefaultPadding / 3),
                      pw.Text(company?.phone1 ?? '',
                          style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: kDefaultPadding / 3),
                      pw.Text(company?.email ?? '',
                          style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: kDefaultPadding / 3),
                    ])),
          ]),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Facturado a:',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                        pw.SizedBox(height: kDefaultPadding / 3),
                        pw.Text(sale.clientName ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: kDefaultPadding / 3),
                        pw.Text('Rnc/Cedula:',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                        pw.SizedBox(height: kDefaultPadding / 3),
                        pw.Text(sale.clientIdentificationFormat,
                            style: pw.TextStyle(fontSize: 8)),
                        pw.Container(
                            margin:
                                pw.EdgeInsets.only(top: kDefaultPadding / 3),
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Dirección:',
                                      style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold,
                                          color: primaryColor)),
                                  pw.SizedBox(height: kDefaultPadding / 3),
                                  pw.Text(
                                      sale.clientAddress == '' ||
                                              sale.clientAddress == null
                                          ? '<Sin dirección>'
                                          : sale.clientAddress.toString(),
                                      style: pw.TextStyle(fontSize: 8)),
                                ])),
                    pw.Container(
                    margin: pw.EdgeInsets.only(top: kDefaultPadding / 2),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Tel:',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  color: primaryColor,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: kDefaultPadding / 3),
                          pw.Text(
                              sale.clientPhone == '' ||
                                      sale.clientPhone == null
                                  ? 'S/N'
                                  : sale.clientPhone.toString(),
                              style: pw.TextStyle(fontSize: 8)),
                        ])),

                          pw.Container(
                    margin: pw.EdgeInsets.only(top: kDefaultPadding / 3),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Correo:',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  color: primaryColor,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: kDefaultPadding / 3),
                          pw.Text(
                              sale.clientEmail == '' ||
                                      sale.clientEmail == null
                                  ? 'S/N'
                                  : sale.clientEmail.toString(),
                              style: pw.TextStyle(fontSize: 8)),
                        ])),
                    company?.bankInfo != null ?  pw.Container(
                    margin: pw.EdgeInsets.only(top: kDefaultPadding / 3),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Información Bancaria:',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  color: primaryColor,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: kDefaultPadding / 3),
                          pw.Text(
                              company?.bankInfo.toString() ?? 'S/N',
                              style: pw.TextStyle(fontSize: 8)),
                        ])):pw.SizedBox(),
                      ]),
                ),
                pw.Expanded(
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                      pw.Text(sale.ncfTypeName ?? '',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                              fontSize: 14)),
                      pw.SizedBox(height: kDefaultPadding/3),
                      pw.Container(
                        margin: pw.EdgeInsets.only(bottom: kDefaultPadding / 2),
                        child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Factura #',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor),
                                textAlign: pw.TextAlign.right,
                              ),
                              pw.SizedBox(width: kDefaultPadding/3),
                              pw.Text(
                                sale.ncf ?? '',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#145F87')),
                                textAlign: pw.TextAlign.right,
                              )
                            ]),
                      ),
                      sale.ncfAffected != null
                          ? pw.Container(
                              margin: pw.EdgeInsets.only(
                                bottom: kDefaultPadding / 2,
                              ),
                              child: pw.Text(sale.ncfAffected ?? '',
                                  style: pw.TextStyle(fontSize: 10)))
                          : pw.SizedBox(),
                      pw.Container(
                        margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 3,
                        ),
                        child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Fecha',
                                style: pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.right,
                              ),
                              pw.SizedBox(width: kDefaultPadding),
                              pw.Text(
                                sale.createdAt?.format(payload: 'DD/MM/YYYY') ??
                                    '',
                                style: pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.right,
                              )
                            ]),
                      ),
                      sale.issueDate != null
                          ? pw.Container(
                              margin: pw.EdgeInsets.only(
                                  bottom: kDefaultPadding / 3),
                              child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Fecha de Emision Ncf',
                                        style: pw.TextStyle(fontSize: 10),
                                        textAlign: pw.TextAlign.right),
                                    pw.SizedBox(width: kDefaultPadding),
                                    pw.Text(
                                        sale.issueDate?.format(
                                              payload: 'DD/MM/YYYY',
                                            ) ??
                                            '',
                                        textAlign: pw.TextAlign.right,
                                        style: pw.TextStyle(fontSize: 10)),
                                  ]))
                          : pw.SizedBox(),
                      sale.retentionDate != null
                          ? pw.Container(
                              margin: pw.EdgeInsets.only(
                                  bottom: kDefaultPadding / 3),
                              child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Fecha de Retencion',
                                        style: pw.TextStyle(fontSize: 10),
                                        textAlign: pw.TextAlign.right),
                                    pw.SizedBox(width: kDefaultPadding),
                                    pw.Text(
                                        sale.retentionDate?.format(
                                              payload: 'DD/MM/YYYY',
                                            ) ??
                                            '',
                                        textAlign: pw.TextAlign.right,
                                        style: pw.TextStyle(fontSize: 10)),
                                  ]))
                          : pw.SizedBox(),
                      sale.expirationDate != null && esConsumo == false && esNotaCredito == false && esCotization == false
                          ? pw.Container(
                              child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                  pw.Text('Fecha de Vencimiento',
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(fontSize: 10)),
                                  pw.SizedBox(width: kDefaultPadding),
                                  pw.Text(
                                      sale.expirationDate
                                              ?.format(payload: 'DD/MM/YYYY') ??
                                          '',
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(fontSize: 10))
                                ]))
                          : pw.SizedBox()
                    ]))
              ]),
          pw.SizedBox(
            height: kDefaultPadding/2
          ),
          pw.Table(
            columnWidths: columnWidths,
            children: [
                  pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: List.generate(columns().length, (index) {
                  var col = columns()[index];

                  return pw.Padding(
                      padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                      child: pw.Text(col,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 7)));
                })),
            ]
          )
        ]);
      },
      build: (ctx) {
        return [
    
          pw.Table(columnWidths:columnWidths, children: [
        
            ...List.generate(sale.items.length, (index) {
              var item = sale.items[index];
              var values = item.toDisplayItemFreelance().values.toList();
              return pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F6F6F6'),
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  children: List.generate(values.length, (i) {
                    var val = values[i];
                    return pw.Padding(
                        padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                        child: pw.Text(val,
                            style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColor.fromHex('#4E5356'))));
                  }));
            })
          ]),
          pw.SizedBox(height: kDefaultPadding/2),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                  sale.description?.isNotEmpty==true? pw.Container(
                    margin: pw.EdgeInsets.only(
                      bottom: kDefaultPadding/2
                    ),
                    child: pw.Text(sale.description ?? '',
                      style: pw.TextStyle(fontSize: 8))
                  ):pw.SizedBox(),
                  pw.SizedBox(
                      width: 80,
                      height: 80,
                      child: pw.BarcodeWidget(
                          data: sale.dgiiURL != null
                              ? sale.dgiiURL ?? ''
                              : sale.ncf ?? '',
                          barcode: qr)),
                  pw.SizedBox(height: kDefaultPadding / 2),
                  sale.securityCode != null
                      ? pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 5),
                          child: pw.Row(children: [
                            pw.Text('Codigo de seguridad:',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                )),
                            pw.SizedBox(width: 5),
                            pw.Text(sale.securityCode ?? '',
                                style: pw.TextStyle(fontSize: 8)),
                          ]))
                      : pw.SizedBox(),
                  sale.signatureDate != null
                      ? pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 5),
                          child: pw.Row(children: [
                            pw.Text('Fecha de Firma:',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                )),
                            pw.SizedBox(width: 5),
                            pw.Text(
                                sale.signatureDate?.format(
                                        payload: 'DD-MM-YYYY HH:mm:ss') ??
                                    '',
                                style: pw.TextStyle(fontSize: 8)),
                          ]))
                      : pw.SizedBox(),
                  sale.authorName != null
                      ? pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 5),
                          child: pw.Row(children: [
                            pw.Text('Atendido por:',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                )),
                            pw.SizedBox(width: 5),
                            pw.Text(sale.authorName ?? '',
                                style: pw.TextStyle(fontSize: 8)),
                          ]))
                      : pw.SizedBox(),
                  sale.rate != null && sale.rate! > 1
                      ? pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 5),
                          child: pw.Row(children: [
                            pw.Text('Tasa Dolar:',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                )),
                            pw.SizedBox(width: 5),
                            pw.Text(sale.rate?.toStringAsFixed(2) ?? '',
                                style: pw.TextStyle(fontSize: 8)),
                          ]))
                      : pw.SizedBox(),
                  sale.estadoDgiiNombre != null
                      ? pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 5),
                          child: pw.Row(children: [
                            pw.Text('Estado DGII:',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                )),
                            pw.SizedBox(width: 5),
                            pw.Text(sale.estadoDgiiNombre ?? '',
                                style: pw.TextStyle(fontSize: 8)),
                          ]))
                      : pw.SizedBox(),
                ])),
            pw.Expanded(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                  pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.net?.toDop()
                                    : sale.net?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])),
              sale.discount! > 0 ?    pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Descuento'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.discount?.toDop()
                                    : sale.discount?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])):pw.SizedBox(),

                sale.netFinal! > 0 && (sale.net != sale.netFinal) ?  pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.netFinal?.toDop()
                                    : sale.netFinal?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])):pw.SizedBox(),
                  pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Itbis'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.tax?.toDop()
                                    : sale.tax?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])),

                    sale.law10! > 0 ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Ley 10%'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.law10?.toDop()
                                    : sale.law10?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])):pw.SizedBox(),
                  pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.total?.toDop()
                                    : sale.total?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])),
                sale.retentionTax! > 0 ?  pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Retención Itbis'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.retentionTax?.toDop()
                                    : sale.retentionTax?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])):pw.SizedBox(),
                 sale.retentionIsr! > 0 ?  pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Retención Isr'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.retentionIsr?.toDop()
                                    : sale.retentionIsr?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])):pw.SizedBox(),
                  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding / 4),
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 3),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                      ),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                sale.ncfTypeId!.contains('34')
                                    ? 'Total a devolver'.toUpperCase()
                                    : 'Total a pagar'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? (sale.total! -
                                            (sale.retentionIsr! +
                                                sale.retentionTax!))
                                        .toDop()
                                    : (sale.total! -
                                            (sale.retentionIsr! +
                                                sale.retentionTax!))
                                        .toUS(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white))
                          ])),
                  pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4),
                      decoration: pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColor.fromHex('#e6e6e6')))),
                      child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Pagado'.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                            pw.Text(
                                sale.currencyId == 1
                                    ? sale.amountPaid?.toDop()
                                    : sale.amountPaid?.toUS() ?? '',
                                style: pw.TextStyle(fontSize: 7))
                          ])),
                  pw.Container(
                      margin: pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Text('FORMAS DE PAGO:',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                          ))),
                  pw.Container(
                    margin: pw.EdgeInsets.symmetric(vertical: 5),
                    child: pw.Text(paymentsWidgets.join(','),
                        style: pw.TextStyle(fontSize: 6)),
                  )
                ]))
          ])
        ];
      },
      footer: (ctx) {
        return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [
                pw.SizedBox(height: kDefaultPadding),
                pw.Container(width: 150, height: 0.5, color: PdfColors.black),
                pw.SizedBox(height: kDefaultPadding / 2),
                pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8))
              ]),
              pw.SizedBox(width: kDefaultPadding),
              pw.Column(children: [
                pw.SizedBox(height: kDefaultPadding),
                pw.Container(width: 150, height: 0.5, color: PdfColors.black),
                pw.SizedBox(height: kDefaultPadding / 2),
                pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8))
              ]),
            ]);
      }));
  return document;
}

pw.Document createEpicRedInvoice(Sale sale) {
  var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  final PdfColor primaryColor = PdfColor.fromHex('#F55D52');

  List<String> columns() {
    return sale.items[0].toDisplayItemFreelance().keys.toList();
  }

    var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
    var esCotization = sale.ncfTypeId == '60';

  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

  if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }


    final columnWidths = {
  0:pw.FixedColumnWidth(170),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(),
  3: pw.FlexColumnWidth(),
  4: pw.FlexColumnWidth(),
};


  document.addPage(pw.MultiPage(
      margin: pw.EdgeInsets.zero,
      theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(
              font: pw.Font.helvetica(), color: PdfColor.fromHex('#545658'))),
      /*pageTheme: pw.PageTheme(
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            color: PdfColor.fromHex('#F5FAFD')
          )
        ),
      ),*/
      header: (ctx) {
        return pw
            .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.symmetric(
                  vertical: kDefaultPadding, horizontal: kDefaultPadding),
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: primaryColor, width: 8))),
              child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(sale.ncfTypeName ?? 'FACTURA',
                                  textAlign: pw.TextAlign.left,
                                  style: pw.TextStyle(
                                      fontSize: 26,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor)),
                              pw.SizedBox(height: kDefaultPadding / 2),
                              pw.Text(sale.ncf ?? '',
                                  textAlign: pw.TextAlign.left,
                                  style: pw.TextStyle(
                                      color: primaryColor,
                                      fontWeight: pw.FontWeight.bold)),
                              sale.ncfAffected == null
                                  ? pw.SizedBox()
                                  : pw.Container(
                                      margin: pw.EdgeInsets.only(
                                          top: kDefaultPadding / 2),
                                      child: pw.Text(sale.ncfAffected ?? '',
                                          textAlign: pw.TextAlign.left,
                                          style: pw.TextStyle(
                                              color: PdfColors.grey500,
                                              fontWeight: pw.FontWeight.bold))),
                            ])),
                    pw.Expanded(
                        child: pw.Padding(
                      padding: pw.EdgeInsets.all(kDefaultPadding),
                      child: company?.logo != null
                          ? pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [
                                  pw.Image(
                                      pw.MemoryImage(
                                          base64Decode(company!.logo!)),
                                      width: 120),
                                  pw.SizedBox(width: kDefaultPadding / 2),
                                ])
                          : pw.SizedBox(),
                    )),
                  ])),
          pw.Container(
              padding: pw.EdgeInsets.all(kDefaultPadding),
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                          pw.Text(
                              sale.ncfAffected != null
                                  ? 'Emitido por'
                                  : 'Pagado a',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.normal)),
                          pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(company?.name ?? 'S/N',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                          pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(company?.rncOrId ?? 'S/N',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                          company?.phone1?.isNotEmpty == true
                              ? pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text('Tel: ${company?.phone1}',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black)))
                              : pw.SizedBox(),
                          company?.phone2?.isNotEmpty == true
                              ? pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text('Cel: ${company?.phone2}',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black)))
                              : pw.SizedBox(),
                          pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(company?.email ?? 'S/N',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                          pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(company?.address ?? 'S/N',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                      company?.bankInfo != null ? pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(company?.bankInfo ?? 'S/N',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))):pw.SizedBox()
                        ])),
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                          pw.Text('Facturado a:',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.normal)),
                          pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(sale.clientName ?? 'S/N',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                          pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(sale.clientIdentificationFormat,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                          sale.createdAt != null
                              ? pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(
                                      'Creado el ${sale.createdAt?.format(payload: 'dddd DD MMMM YYYY')}',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black)))
                              : pw.SizedBox(),
                          sale.issueDate != null
                              ? pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(
                                      'Emitido el ${sale.issueDate?.format(payload: 'dddd DD MMMM YYYY')}',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black)))
                              : pw.SizedBox(),
                          pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(
                                  sale.clientAddress?.isEmpty == true ||
                                          sale.clientAddress == null
                                      ? 'S/N'
                                      : sale.clientAddress.toString(),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                                pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(
                                  sale.clientPhone?.isEmpty == true ||
                                          sale.clientPhone == null
                                      ? 'S/N'
                                      : 'Tel: ${sale.clientPhone.toString()}',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),

                                  pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(
                                  sale.clientEmail?.isEmpty == true ||
                                          sale.clientEmail == null
                                      ? 'S/N'
                                      : 'Correo: ${sale.clientEmail.toString()}',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                          sale.expirationDate != null && esConsumo == false && esNotaCredito == false && esCotization == false
                              ? pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(
                                      'Valido Hasta ${sale.expirationDate?.format(payload: 'DD/MM/YYYY')}',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black)))
                              : pw.SizedBox(),
                        ]))
                  ])),

          pw.Table(
            columnWidths: columnWidths,
            children: [
               pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: List.generate(columns().length, (index) {
                  var col = columns()[index];

                  return pw.Padding(
                      padding: pw.EdgeInsets.only(
                        left: kDefaultPadding,
                        top: kDefaultPadding/2,
                        bottom: kDefaultPadding/2
                      ),
                      child: pw.Text(col,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 7)));
                })),
            ]
          )


        ]);
      },
      build: (ctx) {
        return [
          pw.Table(columnWidths: columnWidths, children: [
           
            ...List.generate(sale.items.length, (index) {
              var item = sale.items[index];
              var values = item.toDisplayItemFreelance().values.toList();
              return pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F6F6F6'),
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#e6e6e6')))),
                  children: List.generate(values.length, (i) {
                    var val = values[i];
                    return pw.Padding(
                        padding: pw.EdgeInsets.only(
                        left: kDefaultPadding,
                        top: kDefaultPadding/2,
                        bottom: kDefaultPadding/2
                      ),
                        child: pw.Text(val,
                            style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColor.fromHex('#4E5356'))));
                  }));
            })
          ]),
          pw.SizedBox(height: kDefaultPadding/2),
          pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Expanded(
                    child: pw.Padding(
                        padding: pw.EdgeInsets.only(
                          left: kDefaultPadding
                        ),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              sale.description?.isEmpty == true ||
                                      sale.description == null
                                  ? pw.SizedBox()
                                  : pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 2),
                                      child: pw.Text(sale.description ?? '',
                                          style: pw.TextStyle(fontSize: 8)),
                                    ),
                              pw.SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: pw.BarcodeWidget(
                                      data: sale.dgiiURL != null
                                          ? sale.dgiiURL ?? ''
                                          : sale.ncf ?? '',
                                      barcode: qr)),
                              pw.SizedBox(height: kDefaultPadding / 2),
                              sale.securityCode != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Codigo de seguridad:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(sale.securityCode ?? '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                              sale.signatureDate != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Fecha de Firma:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(
                                            sale.signatureDate?.format(
                                                    payload:
                                                        'DD-MM-YYYY HH:mm:ss') ??
                                                '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                              sale.authorName != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Atendido por:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(sale.authorName ?? '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                              sale.rate != null && sale.rate! > 1
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Tasa Dolar:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(
                                            sale.rate?.toStringAsFixed(2) ?? '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                              sale.estadoDgiiNombre != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Estado DGII:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(sale.estadoDgiiNombre ?? '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                            ]))),
                pw.Expanded(
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                      pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Subtotal'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.net?.toDop()
                                        : sale.net?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])),
                     sale.discount! > 0 ? pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Descuento'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.discount?.toDop()
                                        : sale.discount?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])):pw.SizedBox(),

                  sale.netFinal! > 0  && (sale.net != sale.netFinal)?  pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Subtotal'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.netFinal?.toDop()
                                        : sale.netFinal?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])):pw.SizedBox(),
                    
                      pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Itbis'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.tax?.toDop()
                                        : sale.tax?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])),

                       sale.law10! > 0 ? pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Ley 10%'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.law10?.toDop()
                                        : sale.law10?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])):pw.SizedBox(),
                      pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Total'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.total?.toDop()
                                        : sale.total?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])),
                     sale.retentionTax! > 0 ? pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Retención Itbis'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.retentionTax?.toDop()
                                        : sale.retentionTax?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])):pw.SizedBox(),
                    sale.retentionIsr! > 0 ?  pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Retención Isr'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.retentionIsr?.toDop()
                                        : sale.retentionIsr?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])):pw.SizedBox(),
                      pw.Container(
                          padding: pw.EdgeInsets.only(
                              top: kDefaultPadding / 3,
                              bottom: kDefaultPadding / 3,
                              left: kDefaultPadding / 3,
                              right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
                          ),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                    sale.ncfTypeId!.contains('34')
                                        ? 'Total a devolver'.toUpperCase()
                                        : 'Total a pagar'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.white)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? (sale.total! -
                                                (sale.retentionIsr! +
                                                    sale.retentionTax!))
                                            .toDop()
                                        : (sale.total! -
                                                (sale.retentionIsr! +
                                                    sale.retentionTax!))
                                            .toUS(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.white))
                              ])),
                      pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColor.fromHex('#e6e6e6')))),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Total Pagado'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.amountPaid?.toDop()
                                        : sale.amountPaid?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 7))
                              ])),
                      pw.Container(
                          margin: pw.EdgeInsets.symmetric(vertical: 5),
                          child: pw.Text('FORMAS DE PAGO:',
                              style: pw.TextStyle(
                                fontSize: 6,
                                fontWeight: pw.FontWeight.bold,
                              ))),
                      pw.Container(
                        margin: pw.EdgeInsets.symmetric(vertical: 5),
                        child: pw.Text(paymentsWidgets.join(','),
                            style: pw.TextStyle(fontSize: 6)),
                      )
                    ]))
              ])
        ];
      },
      footer: (ctx) {
        return pw.Container(
            padding: pw.EdgeInsets.all(kDefaultPadding),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.SizedBox(height: kDefaultPadding),
                    pw.Container(
                        width: 150, height: 0.5, color: PdfColors.black),
                    pw.SizedBox(height: kDefaultPadding / 2),
                    pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8))
                  ]),
                  pw.SizedBox(width: kDefaultPadding),
                  pw.Column(children: [
                    pw.SizedBox(height: kDefaultPadding),
                    pw.Container(
                        width: 150, height: 0.5, color: PdfColors.black),
                    pw.SizedBox(height: kDefaultPadding / 2),
                    pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8))
                  ]),
                ]));
      }));
  return document;
}

pw.Document createEpicBlueInvoice(Sale sale) {
  var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  final PdfColor primaryColor = PdfColor.fromHex('#252E83');
  final PdfColor secondaryColor = PdfColor.fromHex('#32C4D6');
  final PdfColor otherColor = PdfColor.fromHex('#E0F7FA');

  List<String> columns() {
    return sale.items[0].toDisplayItemFreelance().keys.toList();
  }

      var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
    var esCotization = sale.ncfTypeId == '60';

  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

   if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }


  final columnWidths = {
  0:pw.FixedColumnWidth(170),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(),
  3: pw.FlexColumnWidth(),
  4: pw.FlexColumnWidth(),
};

  document.addPage(pw.MultiPage(
      margin: pw.EdgeInsets.zero,
      theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(
              font: pw.Font.helvetica(), color: PdfColor.fromHex('#545658'))),
      /*pageTheme: pw.PageTheme(
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            color: PdfColor.fromHex('#F5FAFD')
          )
        ),
      ),*/
      header: (ctx) {
        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.symmetric(
                      vertical: kDefaultPadding, horizontal: kDefaultPadding),
                  decoration: pw.BoxDecoration(
                      color: primaryColor,
                      border: pw.Border(
                          top: pw.BorderSide(color: secondaryColor, width: 5),
                          bottom:
                              pw.BorderSide(color: primaryColor, width: 8))),
                  child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Expanded(
                            child: pw.Padding(
                          padding: pw.EdgeInsets.all(kDefaultPadding/2),
                          child: company?.logo != null
                              ? pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.start,
                                  children: [
                                      pw.Image(
                                          pw.MemoryImage(
                                              base64Decode(company!.logo!)),
                                          width: 120),
                                      pw.SizedBox(width: kDefaultPadding / 2),
                                    ])
                              : pw.SizedBox(),
                        )),
                        pw.Expanded(
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                              pw.Text(sale.ncfTypeName ?? 'FACTURA',
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.white)),
                              pw.SizedBox(height: kDefaultPadding / 2),
                              pw.Text(sale.ncf ?? '',
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold)),
                              sale.ncfAffected == null
                                  ? pw.SizedBox()
                                  : pw.Container(
                                      margin: pw.EdgeInsets.only(
                                          top: kDefaultPadding / 2),
                                      child: pw.Text(sale.ncfAffected ?? '',
                                          textAlign: pw.TextAlign.left,
                                          style: pw.TextStyle(
                                              color: PdfColors.white,
                                              fontWeight: pw.FontWeight.bold)))
                            ]))
                      ])),
              pw.Container(
                  padding: pw.EdgeInsets.all(kDefaultPadding),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                              pw.Text(
                                  sale.ncfAffected != null
                                      ? 'Emitido por'
                                      : 'Pagado a',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.normal)),
                              pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(company?.name ?? 'S/N',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black))),
                              pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(company?.rncOrId ?? 'S/N',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black))),
                              company?.phone1?.isNotEmpty == true
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 4),
                                      child: pw.Text('Tel: ${company?.phone1}',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 8,
                                              color: PdfColors.black)))
                                  : pw.SizedBox(),
                              company?.phone2?.isNotEmpty == true
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 4),
                                      child: pw.Text('Cel: ${company?.phone2}',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 8,
                                              color: PdfColors.black)))
                                  : pw.SizedBox(),
                              pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(company?.email ?? 'S/N',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black))),
                              pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(company?.address ?? 'S/N',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black))),
                            company?.bankInfo != null ?  pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(company?.bankInfo ?? 'S/N',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black))):pw.SizedBox(),
                      
                            ])),
                        pw.Expanded(
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                              pw.Text('Facturado a:',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.normal)),
                              pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(sale.clientName ?? 'S/N',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black))),
                              pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(
                                      sale.clientIdentificationFormat,
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black))),
                              sale.createdAt != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 4),
                                      child: pw.Text(
                                          'Creado el ${sale.createdAt?.format(payload: 'dddd DD MMMM YYYY')}',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 8,
                                              color: PdfColors.black)))
                                  : pw.SizedBox(),
                              sale.issueDate != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 4),
                                      child: pw.Text(
                                          'Emitido el ${sale.issueDate?.format(payload: 'dddd DD MMMM YYYY')}',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 8,
                                              color: PdfColors.black)))
                                  : pw.SizedBox(),
                              pw.Container(
                                  margin: pw.EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 4),
                                  child: pw.Text(
                                      sale.clientAddress?.isEmpty == true ||
                                              sale.clientAddress == null
                                          ? 'S/N'
                                          : sale.clientAddress.toString(),
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 8,
                                          color: PdfColors.black))),

                           pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(
                                  sale.clientPhone?.isEmpty == true ||
                                          sale.clientPhone == null
                                      ? 'S/N'
                                      : 'Tel: ${sale.clientPhone.toString()}',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                                   pw.Container(
                              margin: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 4),
                              child: pw.Text(
                                  sale.clientEmail?.isEmpty == true ||
                                          sale.clientEmail == null
                                      ? 'S/N'
                                      : 'Correo: ${sale.clientEmail.toString()}',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color: PdfColors.black))),
                              sale.expirationDate != null && esConsumo == false && esNotaCredito == false && esCotization == false
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 4),
                                      child: pw.Text(
                                          'Valido Hasta ${sale.expirationDate?.format(payload: 'DD/MM/YYYY')}',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 8,
                                              color: PdfColors.black)))
                                  : pw.SizedBox(),
                            ]))
                      ])),

           pw.Padding(padding: pw.EdgeInsets.symmetric(
            horizontal: kDefaultPadding
           ),child:  pw.Table(
              columnWidths: columnWidths,
              children: [
                   pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      decoration: pw.BoxDecoration(color: otherColor),
                      children: List.generate(columns().length, (index) {
                        var col = columns()[index];

                        return pw.Padding(
                            padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                            child: pw.Text(col,
                                style: pw.TextStyle(
                                    color: PdfColors.black,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 7)));
                      })),
              ]
            ))
            ]
            );
      },
      build: (ctx) {
        return [
          pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: kDefaultPadding),
              child: pw.Table(
                columnWidths: columnWidths,
                children: [
               
                  ...List.generate(sale.items.length, (index) {
                    var item = sale.items[index];
                    var values = item.toDisplayItemFreelance().values.toList();
                    return pw.TableRow(
                        verticalAlignment: pw.TableCellVerticalAlignment.middle,
                        decoration: pw.BoxDecoration(
                          color: index.isOdd ? otherColor : PdfColors.white,
                        ),
                        children: List.generate(values.length, (i) {
                          var val = values[i];
                          return pw.Padding(
                              padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                              child: pw.Text(val,
                                  style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: index.isOdd
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal,
                                      color: PdfColors.black)));
                        }));
                  })
                ],
              )),
          pw.SizedBox(height: kDefaultPadding/2),
          pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Expanded(
                    child: pw.Padding(
                        padding: pw.EdgeInsets.only(
                          left: kDefaultPadding
                        ),
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              sale.description?.isEmpty == true ||
                                      sale.description == null
                                  ? pw.SizedBox()
                                  : pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 2),
                                      child: pw.Text(sale.description ?? '',
                                          style: pw.TextStyle(fontSize: 8)),
                                    ),
                              pw.SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: pw.BarcodeWidget(
                                      data: sale.dgiiURL != null
                                          ? sale.dgiiURL ?? ''
                                          : sale.ncf ?? '',
                                      barcode: qr)),
                              pw.SizedBox(height: kDefaultPadding / 2),
                              sale.securityCode != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Codigo de seguridad:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(sale.securityCode ?? '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                              sale.signatureDate != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Fecha de Firma:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(
                                            sale.signatureDate?.format(
                                                    payload:
                                                        'DD-MM-YYYY HH:mm:ss') ??
                                                '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                              sale.authorName != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Atendido por:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(sale.authorName ?? '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                              sale.rate != null && sale.rate! > 1
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Tasa Dolar:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(
                                            sale.rate?.toStringAsFixed(2) ?? '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                              sale.estadoDgiiNombre != null
                                  ? pw.Container(
                                      margin: pw.EdgeInsets.symmetric(
                                          vertical: kDefaultPadding / 5),
                                      child: pw.Row(children: [
                                        pw.Text('Estado DGII:',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                            )),
                                        pw.SizedBox(width: 5),
                                        pw.Text(sale.estadoDgiiNombre ?? '',
                                            style: pw.TextStyle(fontSize: 8)),
                                      ]))
                                  : pw.SizedBox(),
                            ]))),
                pw.Expanded(
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                      pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Subtotal'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.net?.toDop()
                                        : sale.net?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])),
                     sale.discount! > 0 ?  pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Descuento'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.discount?.toDop()
                                        : sale.discount?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])):pw.SizedBox(),

                       sale.netFinal! > 0 && (sale.net != sale.netFinal) ?   pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Subtotal'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.netFinal?.toDop()
                                        : sale.netFinal?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])):pw.SizedBox(),
                      pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Itbis'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.tax?.toDop()
                                        : sale.tax?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])),

                      sale.law10! > 0 ?   pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Ley 10%'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.law10?.toDop()
                                        : sale.law10?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])):pw.SizedBox(),
                      pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Total'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.total?.toDop()
                                        : sale.total?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])),
                     sale.retentionTax! > 0 ? pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Retención Itbis'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.retentionTax?.toDop()
                                        : sale.retentionTax?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])):pw.SizedBox(),
                    sale.retentionIsr! > 0 ?  pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Retención Isr'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.retentionIsr?.toDop()
                                        : sale.retentionIsr?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])):pw.SizedBox(),
                      pw.Container(
                          padding: pw.EdgeInsets.only(
                              top: kDefaultPadding / 3,
                              bottom: kDefaultPadding / 3,
                              left: kDefaultPadding / 3,
                              right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          decoration: pw.BoxDecoration(
                            color: otherColor,
                          ),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                    sale.ncfTypeId!.contains('34')
                                        ? 'Total a devolver'.toUpperCase()
                                        : 'Total a pagar'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.black)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? (sale.total! -
                                                (sale.retentionIsr! +
                                                    sale.retentionTax!))
                                            .toDop()
                                        : (sale.total! -
                                                (sale.retentionIsr! +
                                                    sale.retentionTax!))
                                            .toUS(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.black))
                              ])),
                      pw.Container(
                          padding: pw.EdgeInsets.only(right: kDefaultPadding),
                          margin: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Total Pagado'.toUpperCase(),
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor)),
                                pw.Text(
                                    sale.currencyId == 1
                                        ? sale.amountPaid?.toDop()
                                        : sale.amountPaid?.toUS() ?? '',
                                    style: pw.TextStyle(fontSize: 8))
                              ])),
                      pw.Container(
                          margin: pw.EdgeInsets.symmetric(vertical: 5),
                          child: pw.Text('FORMAS DE PAGO:',
                              style: pw.TextStyle(
                                fontSize: 6,
                                fontWeight: pw.FontWeight.bold,
                              ))),
                      pw.Container(
                        margin: pw.EdgeInsets.symmetric(vertical: 5),
                        child: pw.Text(paymentsWidgets.join(','),
                            style: pw.TextStyle(fontSize: 6)),
                      )
                    ]))
              ])
        ];
      },
      footer: (ctx) {
        return pw.Container(
            padding: pw.EdgeInsets.all(kDefaultPadding),
            decoration: pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(color: primaryColor, width: 30))),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.SizedBox(height: kDefaultPadding),
                    pw.Container(
                        width: 150, height: 0.5, color: PdfColors.black),
                    pw.SizedBox(height: kDefaultPadding / 2),
                    pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: kDefaultPadding / 2),
                  ]),
                  pw.SizedBox(width: kDefaultPadding),
                  pw.Column(children: [
                    pw.SizedBox(height: kDefaultPadding),
                    pw.Container(
                        width: 150, height: 0.5, color: PdfColors.black),
                    pw.SizedBox(height: kDefaultPadding / 2),
                    pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: kDefaultPadding / 2),
                  ]),
                ]));
      }));
  return document;
}


Future<pw.Document> createJulyMotorsInvoice(Sale sale)async {
  var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
  var esCotization = sale.ncfTypeId == '60';
  var isSaleProduct = sale is SaleProduct || sale is CreditNoteAsProduct;


  List<String> columns() {
   var list = sale.items[0].toDisplay().keys.toList();
   list.removeAt(3);
   return list;
  }

  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

  if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }


  var primaryColor = PdfColor.fromHex('#88FF7A');

 var textColor = PdfColor.fromHex('#1e3662');

  // Cargar la fuente desde assets
  final fontData = await rootBundle.load("assets/fonts/Montserrat-Bold.ttf");
  final ttfB = pw.Font.ttf(fontData);

    // Cargar la fuente desde assets
  final fontData2 = await rootBundle.load("assets/fonts/Montserrat-Medium.ttf");
  final ttf = pw.Font.ttf(fontData2);

  
    // Cargar la fuente desde assets
  final fontData3 = await rootBundle.load("assets/fonts/Montserrat-Italic.ttf");
  final ttf3 = pw.Font.ttf(fontData3);


  var w1 = {
  0: pw.FlexColumnWidth(2),
  1: pw.FlexColumnWidth(4),
  2: pw.FlexColumnWidth(2),
  3: pw.FlexColumnWidth(2)
};
/*var w2 = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(3),
  3: pw.FlexColumnWidth(2),
  4: pw.FlexColumnWidth(2)
};*/

var ww1 = {
           0: pw.FlexColumnWidth(6),
           1: pw.FlexColumnWidth(4)
        };

/*var ww2 = {
           0: pw.FlexColumnWidth(5),
           1: pw.FlexColumnWidth(4)
        };*/

var columnWidths =w1;
var columnWidths2 = ww1;

/*if(isSaleProduct){
columnWidths = w2;
columnWidths2 = ww2;
}*/

  document.addPage(pw.MultiPage(
    margin: pw.EdgeInsets.only(
        left: kDefaultPadding * 2,
        right: kDefaultPadding * 2,
        top: kDefaultPadding * 2,
        bottom: kDefaultPadding*2
    ),
    theme: pw.ThemeData(
     defaultTextStyle: pw.TextStyle(
      fontSize: 10,
      font:ttf,
      fontBold: ttfB,
      fontItalic: ttf3
     )
    ),
    header: (ctx) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Expanded(child:  pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   company?.logo != null
                        ? pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                                pw.Image(
                                    pw.MemoryImage(
                                        base64Decode(company!.logo!)),
                                    width: 170),
                          
                              ])
                        : pw.Container(
                          width: 110,
                          height: 110,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black
                            )
                          ),
                          child: pw.Center(
                             child: pw.Text('LOGO',style: pw.TextStyle(
                                fontSize: 15
                             ))
                          )
                        ),
               
                ])),
        pw.Expanded(child:pw.Column(
          children: [
             pw.Container(
                width: double.infinity,
              padding: pw.EdgeInsets.all(kDefaultPadding/3),
               decoration: pw.BoxDecoration(
                border: pw.Border.all(
                color: PdfColors.black
              ),
            ),
          child: pw.Column(
            children: [
              pw.Text(sale.ncfTypeName??'',textAlign: pw.TextAlign.center),
              pw.Text('NO. ${sale.ncf}',textAlign: pw.TextAlign.center),
             esNotaCredito ? pw.Column(
                children: [
                    pw.Text('AFECTADO: ${sale.ncfAffected}',textAlign: pw.TextAlign.center)
                ]
              ):pw.SizedBox()
            ]
          )
          ),
          pw.SizedBox(
            height: kDefaultPadding/4
          ),
          pw.Container(
             
               decoration: pw.BoxDecoration(
                border: pw.Border.all(
                color: PdfColors.black
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Container(
                     padding: pw.EdgeInsets.all(kDefaultPadding/3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(
                        color: PdfColors.black
                      )
                    )
                  ),
                  child: pw.Text('Válida Hasta',textAlign: pw.TextAlign.center)
                )),
                pw.SizedBox(
                  width: kDefaultPadding/3
                ),
                pw.Expanded(child: pw.Container(
                  child: pw.Text(esConsumo || esNotaCredito || esCotization? 'NO VENCE': sale.expirationDate?.format(payload: 'DD-MM-YYYY') ??'',textAlign: pw.TextAlign.center)
                ))
              ]
            )
          )
        
          ]
        ))
      ]),
      pw.SizedBox(height: kDefaultPadding/3),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(flex: 2, child: pw.Text('FECHA DE EMISIÓN: ${sale.issueDate?.format(payload: 'DD-MM-YYYY')}',style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold
          ))),
          pw.Expanded(child: pw.Text('Tipo de Impresión: ORIGINAL'))
        ]
      ),
    
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: pw.EdgeInsets.all(kDefaultPadding/3),
                margin: pw.EdgeInsets.symmetric(
                  vertical: kDefaultPadding/4
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child: pw.Text('DATOS DEL CLIENTE',style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize:9
                  
                ))
              ),
              pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                      
                      child: pw.Text('NOMBRE:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                     decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientName?.toUpperCase()??'',style: pw.TextStyle(
                      
                      ))
                    ),)
                  ]
                )
              ),

              pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                    
                      child: pw.Text('RNC/CEDULA:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                    pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                        decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientIdentificationFormat,style: pw.TextStyle(
                      
                      ))
                    ))
                  ]
                )
              ),
             pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                    
                      child: pw.Center(child: pw.Text('DIRECCIÓN:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      )))
                    )),
                   pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                      decoration: pw.BoxDecoration(
                         border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientAddress?.toUpperCase()??'S/N',softWrap: true, style: pw.TextStyle(
                        
                    
                      ))
                    ))
                  ]
                )
              ),

                pw.Container(
 
                width: double.infinity,
               
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                     
                      child: pw.Text('TELÉFONOS:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                   pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                     decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientPhone?.isNotEmpty == true ? 'TEL: ${sale.clientPhone}' : 'NO DISPONIBLE',style: pw.TextStyle(
                    
                      ))
                    ),)
                  ]
                )
              ),
            ]
          )),
          pw.SizedBox(
            width: kDefaultPadding
          ),
          pw.Expanded(child: pw.Column(
            children: [
                pw.Text('NOMBRE DEL\nVENDEDOR:',style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold
                )),
                pw.Text(sale.authorName?.toUpperCase() ??'',style: pw.TextStyle(
                    decoration: pw.TextDecoration.underline
                ))
            ]
          ))
        ]
      ),
     pw.SizedBox(height: kDefaultPadding),
     pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: columnWidths,
      children: [
           pw.TableRow(
            decoration: pw.BoxDecoration(color:primaryColor),
            children: List.generate(columns().length, (index) {
              var col = columns()[index];

              return pw.Padding(
                  padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                  child: pw.Text(col,
                  textAlign:  pw.TextAlign.center,
                      style:
                          pw.TextStyle(color: PdfColors.black, fontSize: 8, fontWeight: pw.FontWeight.bold)));
            })),
      ]
     )
    ]
    );
  }, build: (ctx) {
    return [
      pw.Table(
         border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: columnWidths, children: [
      
        ...List.generate(sale.items.length, (index) {
          var item = sale.items[index];
          var values = item.toDisplayItemJulyMotors(index: index);
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColor.fromHex('#e6e6e6')))),
              children: List.generate(values.length, (i) {
                var widget = values[i];
                return widget;
              }));
        })
      ]),
      pw.SizedBox(height: kDefaultPadding),
      pw.Table(
        columnWidths: columnWidths2,
        children: [
          pw.TableRow(children: [
               pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
             sale.description?.isNotEmpty == true ? pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 5),
                child:  pw.Text(sale.description ?? '', style: pw.TextStyle(fontSize: 8)),
              ):pw.SizedBox(),
    
              pw.SizedBox(
                  width: 70,
                  height: 70,
                  child: pw.BarcodeWidget(
                      data: sale.dgiiURL != null
                          ? sale.dgiiURL ?? ''
                          : sale.ncf ?? '',
                      barcode: qr)),
              pw.SizedBox(height: kDefaultPadding / 2),
              sale.securityCode != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Codigo de seguridad:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.securityCode ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
              sale.signatureDate != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Fecha de Firma:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(
                            sale.signatureDate
                                    ?.format(payload: 'DD-MM-YYYY HH:mm:ss') ??
                                '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
              sale.authorName != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Atendido por:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.authorName ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
              sale.rate != null && sale.rate! > 1
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Tasa Dolar:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.rate?.toStringAsFixed(2) ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
              sale.estadoDgiiNombre != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Estado DGII:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.estadoDgiiNombre ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),

            
            ]),

      
      
             pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                                padding: pw.EdgeInsets.symmetric(
                        
                            horizontal: kDefaultPadding/2
                        ),
                        child:  pw.Text('Subtotal',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                    
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.net?.toDop()
                                : sale.net?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),

        sale.discount == 0  ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                            padding: pw.EdgeInsets.symmetric(
                           
                            horizontal: kDefaultPadding/2
                        ),
                        child: pw.Container(
                          child:  pw.Text('Descuento',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                        )
                       )),
                     
                        pw.Expanded(child:pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.discount?.toDop()
                                : sale.discount?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
           
               sale.netFinal! > 0 && (sale.net != sale.netFinal) ?   pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                 
                        child:  pw.Text('Subtotal',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.netFinal?.toDop()
                                : sale.netFinal?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

                pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                             width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                           
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text('Itbis',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child:pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.tax?.toDop()
                                : sale.tax?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
               sale.law10! > 0 ? pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                             width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text('Ley 10%',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.law10?.toDop()
                                : sale.law10?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),


              pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5,
                         
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                       
                            horizontal: kDefaultPadding/2
                        ),
                      
                        child:  pw.Text('Total'.toUpperCase(),
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                    
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.total?.toDop()
                                : sale.total?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.center)
                        ))
                      ])),
             
            sale.retentionTax! > 0 ? pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                          
                            horizontal: kDefaultPadding/2
                        ),
                      
                        child:  pw.Text('Retención Itbis',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child:pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.retentionTax?.toDop()
                                : sale.retentionTax?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

         sale.retentionIsr! > 0 ?  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                      
                            horizontal: kDefaultPadding/2
                        ),
                     
                        child:  pw.Text('Retención Isr',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.retentionIsr?.toDop()
                                : sale.retentionIsr?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

       enabledTotalsConfigSimple ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                           width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                      
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text(  sale.ncfTypeId!.contains('34')
                                ? 'Total a devolver'
                                : 'Total a pagar',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                                padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                              
                            ))
                        ),
                          child: pw.Text(
                              sale.currencyId == 1
                                ? (sale.total! -
                                        (sale.retentionIsr! +
                                            sale.retentionTax!))
                                    .toDop()
                                : (sale.total! -
                                        (sale.retentionIsr! +
                                            sale.retentionTax!))
                                    .toUS(),
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
          
         enabledTotalsConfigSimple ? pw.SizedBox(): pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                        width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                  
                        child:  pw.Text(esNotaCredito ? 'Devuelto'.toUpperCase():'Pagado'.toUpperCase(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child:pw.Container(
                             padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.amountPaid?.toDop()
                                : sale.amountPaid?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.center)
                        ))
                      ])),
             
              pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding/3),
                  child: pw.Text('FORMAS DE PAGO:',
                      style: pw.TextStyle(
                          fontSize: 6, fontWeight: pw.FontWeight.bold))),
              pw.Container(
            
                child: pw.Text(paymentsWidgets.join(','),
                    style: pw.TextStyle(fontSize: 6)),
              )
            ])
          ])
        ]
      ),
    ];
  }, footer: (ctx) {
    return pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
           
            pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(children: [  
          pw.Container(width: 150, height:0.7, color: PdfColors.black),
          pw.SizedBox(height: 3),
          pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
          ]),
          pw.SizedBox(width: kDefaultPadding),
          pw.Column(children: [
         
           pw.Container(width: 150, height: 0.7, color: PdfColors.black),
           pw.SizedBox(height: 3),
           pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
            
          ]),
        ]),
              pw.SizedBox(height: kDefaultPadding),
        pw.Column(
            children: [
                pw.Text('${company?.address}, Tel: ${company?.phone1}, Cel: ${company?.phone2},\nEmail: ${company?.email}',softWrap: true,style: pw.TextStyle(
                    color: textColor,
                ),textAlign: pw.TextAlign.center),
                pw.Text('RNC: ${company?.rncOrId}',style:  pw.TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold
                ))
            ]
        )
        ]
    );
  }));
  return document;
}

Future<pw.Document> createInvoiceStore(Sale sale)async{
   var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
  var esCotization = sale.ncfTypeId == '60';

  List<String> columns() {
   var list = sale.items[0].toDisplayItemStore().keys.toList();
   return list;
  }

  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

  if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }


  var primaryColor = PdfColor.fromHex('#88FF7A');

 var textColor = PdfColor.fromHex('#1e3662');

  // Cargar la fuente desde assets
  final fontData = await rootBundle.load("assets/fonts/CONSOLAB.ttf");
  final ttfB = pw.Font.ttf(fontData);

    // Cargar la fuente desde assets
  final fontData2 = await rootBundle.load("assets/fonts/CONSOLA.ttf");
  final ttf = pw.Font.ttf(fontData2);

  
    // Cargar la fuente desde assets
  final fontData3 = await rootBundle.load("assets/fonts/consolai.ttf");
  final ttf3 = pw.Font.ttf(fontData3);

final columnWidths = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(),
  3: pw.FixedColumnWidth(100),
  4: pw.FlexColumnWidth(),
  5: pw.FlexColumnWidth(),
  6: pw.FlexColumnWidth(),
  7: pw.FlexColumnWidth(),
};

  document.addPage(pw.MultiPage(
    margin: pw.EdgeInsets.only(
        left: kDefaultPadding * 2,
        right: kDefaultPadding * 2,
        top: kDefaultPadding * 2,
        bottom: kDefaultPadding*2
    ),
    theme: pw.ThemeData(
     defaultTextStyle: pw.TextStyle(
      fontSize: 8,
      font:ttf,
      fontBold: ttfB,
      fontItalic: ttf3
     )
    ),
    header: (ctx) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Expanded(child:  pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   company?.logo != null
                        ? pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                                pw.Image(
                                    pw.MemoryImage(
                                        base64Decode(company!.logo!)),
                                    width: 120),
                          
                              ])
                        : pw.Container(
                          width: 100,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black
                            )
                          ),
                          child: pw.Center(
                             child: pw.Text('LOGO',style: pw.TextStyle(
                                fontSize: 15
                             ))
                          )
                        ),
               
                ])),
        pw.Expanded(child:pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
          
          pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:  pw.Text(sale.ncfTypeName ?? '',style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold
           )),
          ),
         pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/6
            ),
            child:  pw.Text('eNCF ${sale.ncf}',style: pw.TextStyle(
           
           )),
          ),

          sale.ncfAffected != null ?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/6
            ),
            child:  pw.Text('eNCF Afectado ${sale.ncfAffected}',style: pw.TextStyle(
           
           )),
          ):pw.SizedBox(),

         esConsumo == false && esNotaCredito == false  && esCotization == false?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:  pw.Text('Fecha de vencimiento: ${sale.expirationDate?.format(
              payload: 'DD-MM-YYYY'
            )}',style: pw.TextStyle(
            
           )),
          ):pw.SizedBox(),
        
          ]
        ))
      ]),
  
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
             
             pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/3
              ),
              child: pw.Text(company?.name??'',style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold
              ))
             ),
               pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('RNC: ${company?.rncOrId}')
             ),
                pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text(company?.address ?? '')
             ),
                 pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('Teléfono: ${company?.phone1}')
             ),
              pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('Correo electrónico: ${company?.email}')
             ),
             company?.bankInfo != null ? pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('Información Bancaria: ${company?.bankInfo}')
             ):pw.SizedBox(),
             
                pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('Fecha de emisión: ${sale.issueDate?.format(
                payload: 'DD-MM-YYYY'
              )}')
             )
             
            ]
          )),
         
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Página ${ctx.pageNumber}')
            ]
          ))
        ]
      ),
     pw.Divider(),
     pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
       pw.Container(
           margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Row(
          children: [
            pw.Text('Razón social cliente: '),
             pw.Text(sale.clientName?.toUpperCase() ?? '',style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold
             ))
          ]
        )
       ),
          pw.Container(
           margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Text('RNC/Cedula Cliente: ${sale.clientIdentification}')
       ),
        sale.clientEmail != null ?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Text('Email: ${sale.clientEmail}'),

        
       ):pw.SizedBox(),

        sale.clientPhone != null ?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Text('Teléfono: ${sale.clientPhone}')
       ):pw.SizedBox(),
           sale.clientAddress != null ?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Text('Dirección: ${sale.clientAddress}',softWrap: true)
       ):pw.SizedBox(),
      
       
      ]
     ),
    pw.Divider(),

     pw.Table(
          border: pw.TableBorder.symmetric(
          
            outside: pw.BorderSide(
              width: 1.5
            )
          ),
        columnWidths: columnWidths,
      children: [
           pw.TableRow(
          
            children: List.generate(columns().length, (index) {
              var col = columns()[index];

              return pw.Padding(
                  padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                  child: pw.Text(col,
                  textAlign:  pw.TextAlign.left,
                      style:
                          pw.TextStyle(color: PdfColors.black,fontSize: 6, fontWeight: pw.FontWeight.bold)));
            })),
      ]
     )
    ]
    );
  }, build: (ctx) {
    return [
      pw.Table(
       
        columnWidths: columnWidths, children: [
      
        ...List.generate(sale.items.length, (index) {
          var item = sale.items[index];
          var values = item.toDisplayItemStore().values.toList();
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
              decoration: pw.BoxDecoration(
                border: index == sale.items.length-1 ? pw.Border(
                  bottom: pw.BorderSide(
                    width: 1
                  )
                ):null
              ),
              children: List.generate(values.length, (i) {
                var col = values[i];
                 return pw.Padding(
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: i == 0 || i == values.length-1? 0: kDefaultPadding/3,
                    vertical:kDefaultPadding / 3
                  ),
                  child: pw.Text(col,
                  textAlign:  pw.TextAlign.left,
                      style:
                          pw.TextStyle(color: PdfColors.black,fontSize: 6)));
              }));
        })
      ]),

      pw.SizedBox(height: kDefaultPadding/2),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
            flex: 2,
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
             sale.description?.isNotEmpty == true ? pw.Container(
                child:  pw.Text(sale.description ?? '', style: pw.TextStyle(fontSize: 8)),
              ):pw.SizedBox(),
    
              pw.SizedBox(
                  width: 70,
                  height: 70,
                  child: pw.BarcodeWidget(
                      data: sale.dgiiURL != null
                          ? sale.dgiiURL ?? ''
                          : sale.ncf ?? '',
                      barcode: qr)),
              pw.SizedBox(height: kDefaultPadding / 2),
              sale.securityCode != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Codigo de seguridad:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.securityCode ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
              sale.signatureDate != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Fecha de Firma:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(
                            sale.signatureDate
                                    ?.format(payload: 'DD-MM-YYYY HH:mm:ss') ??
                                '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
              sale.authorName != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Atendido por:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.authorName ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
              sale.rate != null && sale.rate! > 1
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Tasa Dolar:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.rate?.toStringAsFixed(2) ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
              sale.estadoDgiiNombre != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Estado DGII:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.estadoDgiiNombre ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
            ])),
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
           pw.Container(
             margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('SUBTOTAL:  ${ sale.currencyId == 1
                                ? sale.net?.toDop()
                                : sale.net?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ),
      
        sale.discount == 0  ? pw.SizedBox():     pw.Container(
           margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('DESCUENTO:  ${ sale.currencyId == 1
                                ? sale.discount?.toDop()
                                : sale.discount?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ),
           
               sale.netFinal! > 0 && (sale.net != sale.netFinal) ?   pw.Container(
                 margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('SUBTOTAL:  ${ sale.currencyId == 1
                                ? sale.netFinal?.toDop()
                                : sale.netFinal?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ):pw.SizedBox(),

               pw.Container(
                 margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('TOTAL ITBIS:  ${ sale.currencyId == 1
                                ? sale.tax?.toDop()
                                : sale.tax?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ),
      sale.law10! > 0 ?  pw.Container(
                 margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('LEY 10%:  ${ sale.currencyId == 1
                                ? sale.law10?.toDop()
                                : sale.law10?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ):pw.SizedBox(),

                 pw.Container(
                   margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('TOTAL FACTURADO:  ${ sale.currencyId == 1
                                ? sale.total?.toDop()
                                : sale.total?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.right),
                       ),
            sale.retentionTax! > 0 ?  pw.Container(
               margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('RETENCION ITBIS:  ${ sale.currencyId == 1
                                ? sale.retentionTax?.toDop()
                                : sale.retentionTax?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right)):pw.SizedBox(),

         sale.retentionIsr! > 0 ?  pw.Container(
           margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('RETENCION ISR:  ${ sale.currencyId == 1
                                ? sale.retentionIsr?.toDop()
                                : sale.retentionIsr?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right)):pw.SizedBox(),

      

       enabledTotalsConfigSimple ?    pw.SizedBox():  pw.Container(
         margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('${
              sale.ncfTypeId!.contains('34')
                                ? 'TOTAL A DEVOLVER'
                                : 'TOTAL A PAGAR'
            }  ${  sale.currencyId == 1
                                ? (sale.total! -
                                        (sale.retentionIsr! +
                                            sale.retentionTax!))
                                    .toDop()
                                : (sale.total! -
                                        (sale.retentionIsr! +
                                            sale.retentionTax!))
                                    .toUS()}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ),
          
         enabledTotalsConfigSimple ? pw.SizedBox(): pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('${esNotaCredito ? 'Devuelto'.toUpperCase():'Pagado'.toUpperCase()} : ${ sale.currencyId == 1
                                ? sale.amountPaid?.toDop()
                                : sale.amountPaid?.toUS() ?? ''}',
                            style: pw.TextStyle(
                                fontSize: 7,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.right)),

               
             
              pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding/3),
                  child: pw.Text('FORMAS DE PAGO:',
                      style: pw.TextStyle(
                          fontSize: 6, fontWeight: pw.FontWeight.bold))),
              pw.Container(
            
                child: pw.Text(paymentsWidgets.join(','),
                    style: pw.TextStyle(fontSize: 6)),
              )
            ]))
      ])
    ];
  },));
  return document;
}



Future<pw.Document> createInvoiceStoreWareHouse(WareHouseElement orden)async{
   var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();


  List<String> columns() {
   var list = orden.items![0].toDisplayItemStore().keys.toList();
   return list;
  }

  List<String> paymentsWidgets = [];

 /* if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

  if (sale.saleToCredit != null && sale.saleToCredit! > 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }*/

  var isOrden = orden is OrdenModel ? true: false;
  var numSeq = orden.ordenNumString ?? orden.entryNumString;
  var label = isOrden ? 'ORDEN DE COMPRA': 'ENTRADA DE ALMACEN';


  var primaryColor = PdfColor.fromHex('#88FF7A');

 var textColor = PdfColor.fromHex('#1e3662');

  // Cargar la fuente desde assets
  final fontData = await rootBundle.load("assets/fonts/CONSOLAB.ttf");
  final ttfB = pw.Font.ttf(fontData);

    // Cargar la fuente desde assets
  final fontData2 = await rootBundle.load("assets/fonts/CONSOLA.ttf");
  final ttf = pw.Font.ttf(fontData2);

  
    // Cargar la fuente desde assets
  final fontData3 = await rootBundle.load("assets/fonts/consolai.ttf");
  final ttf3 = pw.Font.ttf(fontData3);

final columnWidths = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(),
  3: pw.FlexColumnWidth(),
  4: pw.FixedColumnWidth(100),
  5: pw.FlexColumnWidth(),
  6: pw.FlexColumnWidth(),
  7: pw.FlexColumnWidth(),
  8: pw.FlexColumnWidth(),
};

  document.addPage(pw.MultiPage(
    margin: pw.EdgeInsets.only(
        left: kDefaultPadding * 2,
        right: kDefaultPadding * 2,
        top: kDefaultPadding * 2,
        bottom: kDefaultPadding*2
    ),
    theme: pw.ThemeData(
     defaultTextStyle: pw.TextStyle(
      fontSize: 8,
      font:ttf,
      fontBold: ttfB,
      fontItalic: ttf3
     )
    ),
    header: (ctx) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Expanded(child:  pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   company?.logo != null
                        ? pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                                pw.Image(
                                    pw.MemoryImage(
                                        base64Decode(company!.logo!)),
                                    width: 120),
                          
                              ])
                        : pw.Container(
                          width: 100,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black
                            )
                          ),
                          child: pw.Center(
                             child: pw.Text('LOGO',style: pw.TextStyle(
                                fontSize: 15
                             ))
                          )
                        ),
               
                ])),
        pw.Expanded(child:pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
          
          pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:  pw.Text(label,style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12
           )),
          ),
         pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/6
            ),
            child:  pw.Text('$numSeq',style: pw.TextStyle(
           
           )),
          ),

          orden.ncf != null ?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/6
            ),
            child:  pw.Text('eNCF: ${orden.ncf}',style: pw.TextStyle(
           
           )),
          ):pw.SizedBox(),

     
        
          ]
        ))
      ]),
  
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
             
             pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/3
              ),
              child: pw.Text(company?.name??'',style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold
              ))
             ),
               pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('RNC: ${company?.rncOrId}')
             ),
                pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text(company?.address ?? '')
             ),
                 pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('Teléfono: ${company?.phone1}')
             ),
              pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('Correo electrónico: ${company?.email}')
             ),
                pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('Fecha de emisión de ${isOrden ? 'Orden':'Entrada'}: ${orden.createdAt?.format(
                payload: 'DD-MM-YYYY'
              )}')
             ),
               orden.ncfDate != null ?      pw.Container(
              margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
              child: pw.Text('Fecha de emisión de Ncf: ${orden.ncfDate?.format(
                payload: 'DD-MM-YYYY'
              )}')
             ):pw.SizedBox()
             
            ]
          )),
         
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Página ${ctx.pageNumber}')
            ]
          ))
        ]
      ),
     pw.Divider(),
     pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
       pw.Container(
           margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Row(
          children: [
            pw.Text('Proveedor: '),
             pw.Text(orden.providerName?.toUpperCase() ?? '',style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold
             ))
          ]
        )
       ),
          pw.Container(
           margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Text('RNC/Cedula Proveedor: ${orden.providerIdentification}')
       ),
        orden.providerEmail != null ?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Text('Email: ${orden.providerEmail}'),

        
       ):pw.SizedBox(),

        orden.providerPhone != null ?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Text('Teléfono: ${orden.providerPhone}')
       ):pw.SizedBox(),
           orden.providerAddress != null ?  pw.Container(
            margin: pw.EdgeInsets.symmetric(
                vertical: kDefaultPadding/5
              ),
        child:  pw.Text('Dirección: ${orden.providerAddress}',softWrap: true)
       ):pw.SizedBox(),
      
       
      ]
     ),
    pw.Divider(),

     pw.Table(
          border: pw.TableBorder.symmetric(
          
            outside: pw.BorderSide(
              width: 1.5
            )
          ),
        columnWidths: columnWidths,
      children: [
           pw.TableRow(
          
            children: List.generate(columns().length, (index) {
              var col = columns()[index];

              return pw.Padding(
                  padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                  child: pw.Text(col,
                  textAlign:  pw.TextAlign.left,
                      style:
                          pw.TextStyle(color: PdfColors.black,fontSize: 7, fontWeight: pw.FontWeight.bold)));
            })),
      ]
     )
    ]
    );
  }, build: (ctx) {
    return [
      pw.Table(
       
        columnWidths: columnWidths, children: [
      
        ...List.generate(orden.items!.length, (index) {
          var item = orden.items![index];
          var values = item.toDisplayItemStore().values.toList();
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
              decoration: pw.BoxDecoration(
                border: index == orden.items!.length-1 ? pw.Border(
                  bottom: pw.BorderSide(
                    width: 1
                  )
                ):null
              ),
              children: List.generate(values.length, (i) {
                var col = values[i];
                 return pw.Padding(
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: i == 0 || i == values.length-1? 0: kDefaultPadding/4,
                    vertical:kDefaultPadding * 0.50
                  ),
                  child: pw.Text(col,
                  textAlign:  pw.TextAlign.left,
                      style:
                          pw.TextStyle(color: PdfColors.black,fontSize: 7)));
              }));
        })
      ]),

      pw.SizedBox(height: kDefaultPadding/2),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
            flex: 2,
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
         
              pw.SizedBox(
                  width: 70,
                  height: 70,
                  child: pw.BarcodeWidget(
                      data:numSeq ?? '',
                      barcode: qr)),
              pw.SizedBox(height: kDefaultPadding / 2),
      
              orden.authorName != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Atendido por:',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(orden.authorName ?? '',
                            style: pw.TextStyle(fontSize: 9)),
                      ]))
                  : pw.SizedBox(),
        
         
            ])),
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
           pw.Container(
             margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('SUBTOTAL: ${orden.currencyId == 1 ? orden.net?.toDop() : orden.net?.toUS()}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ),
      
         pw.Container(
           margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('DESCUENTO:  ${orden.currencyId == 1 ? orden.discount?.toDop() : orden.discount?.toUS()}',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ),

                    pw.Container(
             margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('SUBTOTAL:  ${ orden.currencyId == 1 ? orden.netFinal?.toDop() : orden.netFinal?.toUS()
                              }',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ),
           
     
               pw.Container(
                 margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('TOTAL ITBIS:  ${ orden.currencyId == 1 ? orden.tax?.toDop() : orden.tax?.toUS()
                              }',
                            style: pw.TextStyle(
                                fontSize: 7),textAlign: pw.TextAlign.right),
                       ),


                 pw.Container(
                   margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('TOTAL FACTURADO:  ${ orden.currencyId == 1 ? orden.total?.toDop() : orden.total?.toUS()
                               }',
                            style: pw.TextStyle(
                                fontSize: 7,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.right),
                       ),
      

   

   
         pw.Container(
            margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding/5
            ),
            child:pw.Text('${'Pagado'.toUpperCase()} : ${ orden.currencyId == 1 ? orden.amountPaid?.toDop() : orden.amountPaid?.toUS()
                              }',
                            style: pw.TextStyle(
                                fontSize: 7,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.right)),

               
      
            ]))
      ])
    ];
  },));
  return document;
}



Future<pw.Document> createIdealTimeInvoice(Sale sale)async {
  var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
  var esCotization = sale.ncfTypeId == '60';
  var isSaleProduct = sale is SaleProduct || sale is CreditNoteAsProduct;

  List<String> columns() {
    var list = ['CANTIDAD','DESCRIPCIÓN','PRECIO','TOTAL'];
    if(isSaleProduct) {
      list.insert(1, 'CODIGO');
    }
  
   return list;
  }

  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

  if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }


  var primaryColor = PdfColor.fromHex('#F0CC99FF');

  var textColor = PdfColor.fromHex('#212120FF');

  // Cargar la fuente desde assets
  final fontData = await rootBundle.load("assets/fonts/Montserrat-Bold.ttf");
  final ttfB = pw.Font.ttf(fontData);

    // Cargar la fuente desde assets
  final fontData2 = await rootBundle.load("assets/fonts/Montserrat-Medium.ttf");
  final ttf = pw.Font.ttf(fontData2);

  
    // Cargar la fuente desde assets
  final fontData3 = await rootBundle.load("assets/fonts/Montserrat-Italic.ttf");
  final ttf3 = pw.Font.ttf(fontData3);

  var w1 = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(3),
  2: pw.FlexColumnWidth(2),
  3: pw.FlexColumnWidth(2)
};
var w2 = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(3),
  3: pw.FlexColumnWidth(2),
  4: pw.FlexColumnWidth(2)
};

var ww1 = {
           0: pw.FlexColumnWidth(3),
           1: pw.FlexColumnWidth(3)
        };

var ww2 = {
           0: pw.FlexColumnWidth(5),
           1: pw.FlexColumnWidth(4)
        };

var columnWidths =w1;
var columnWidths2 = ww1;

if(isSaleProduct){
columnWidths = w2;
columnWidths2 = ww2;
}

  document.addPage(pw.MultiPage(
    margin: pw.EdgeInsets.only(
        left: kDefaultPadding * 2,
        right: kDefaultPadding * 2,
        top: kDefaultPadding * 2,
        bottom: kDefaultPadding*2
    ),
    theme: pw.ThemeData(
     defaultTextStyle: pw.TextStyle(
      fontSize: 10,
      font:ttf,
      fontBold: ttfB,
      fontItalic: ttf3
     )
    ),
    header: (ctx) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Expanded(child:  pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   company?.logo != null
                        ? pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                                pw.Image(
                                    pw.MemoryImage(
                                        base64Decode(company!.logo!)),
                                    width: 170),
                          
                              ])
                        : pw.Container(
                          width: 110,
                          height: 110,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black
                            )
                          ),
                          child: pw.Center(
                             child: pw.Text('LOGO',style: pw.TextStyle(
                                fontSize: 15
                             ))
                          )
                        ),
                  pw.Text(company?.name ?? '',style: pw.TextStyle(
                    fontSize: 8
                  ))
               
                ])),
        pw.Expanded(child:pw.Column(
          children: [
             pw.Container(
                width: double.infinity,
              padding: pw.EdgeInsets.all(kDefaultPadding/3),
               decoration: pw.BoxDecoration(
                border: pw.Border.all(
                color: PdfColors.black
              ),
            ),
          child: pw.Column(
            children: [
              pw.Text(sale.ncfTypeName??'',textAlign: pw.TextAlign.center),
              pw.Text('NO. ${sale.ncf}',textAlign: pw.TextAlign.center),
             esNotaCredito ? pw.Column(
                children: [
                    pw.Text('AFECTADO: ${sale.ncfAffected}',textAlign: pw.TextAlign.center)
                ]
              ):pw.SizedBox()
            ]
          )
          ),
          pw.SizedBox(
            height: kDefaultPadding/4
          ),
          pw.Container(
             
               decoration: pw.BoxDecoration(
                border: pw.Border.all(
                color: PdfColors.black
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Container(
                     padding: pw.EdgeInsets.all(kDefaultPadding/3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(
                        color: PdfColors.black
                      )
                    )
                  ),
                  child: pw.Text('Válida Hasta',textAlign: pw.TextAlign.center)
                )),
                pw.SizedBox(
                  width: kDefaultPadding/3
                ),
                pw.Expanded(child: pw.Container(
                  child: pw.Text(esConsumo || esNotaCredito || esCotization? 'NO VENCE': sale.expirationDate?.format(payload: 'DD-MM-YYYY') ??'',textAlign: pw.TextAlign.center)
                ))
              ]
            )
          )
        
          ]
        ))
      ]),
      pw.SizedBox(height: kDefaultPadding/3),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(flex: 2, child: pw.Text('FECHA DE EMISIÓN: ${sale.issueDate?.format(payload: 'DD-MM-YYYY')}',style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold
          ))),
          pw.Expanded(child: pw.Text('Tipo de Impresión: ORIGINAL'))
        ]
      ),
    
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: pw.EdgeInsets.all(kDefaultPadding/3),
                margin: pw.EdgeInsets.symmetric(
                  vertical: kDefaultPadding/4
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child: pw.Text('DATOS DEL CLIENTE',style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize:9
                  
                ))
              ),
              pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                      
                      child: pw.Text('NOMBRE:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                     decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientName?.toUpperCase()??'',style: pw.TextStyle(
                      
                      ))
                    ),)
                  ]
                )
              ),

              pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                    
                      child: pw.Text('RNC/CEDULA:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                    pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                        decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientIdentificationFormat,style: pw.TextStyle(
                      
                      ))
                    ))
                  ]
                )
              ),
             pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                    
                      child: pw.Center(child: pw.Text('DIRECCIÓN:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      )))
                    )),
                   pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                      decoration: pw.BoxDecoration(
                         border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientAddress?.toUpperCase()??'S/N',softWrap: true, style: pw.TextStyle(
                        
                    
                      ))
                    ))
                  ]
                )
              ),

                pw.Container(
 
                width: double.infinity,
               
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                     
                      child: pw.Text('TELÉFONOS:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                   pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                     decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientPhone?.isNotEmpty == true ? 'TEL: ${sale.clientPhone}' : 'NO DISPONIBLE',style: pw.TextStyle(
                    
                      ))
                    ),)
                  ]
                )
              ),
            ]
          )),
          pw.SizedBox(
            width: kDefaultPadding
          ),
          pw.Expanded(child: pw.Column(
            children: [
                pw.Text('NOMBRE DEL\nVENDEDOR:',style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold
                )),
                pw.Text(sale.authorName?.toUpperCase() ??'',style: pw.TextStyle(
                    decoration: pw.TextDecoration.underline
                ))
            ]
          ))
        ]
      ),
     pw.SizedBox(height: kDefaultPadding),
     pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: columnWidths,
      children: [
           pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(color:primaryColor),
            children: List.generate(columns().length, (index) {
              var col = columns()[index];

              return pw.Padding(
                  padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                  child: pw.Text(col,
                  textAlign:  pw.TextAlign.center,
                      style:
                          pw.TextStyle(color: PdfColors.black, fontSize: 7, fontWeight: pw.FontWeight.bold)));
            })),
      ]
     )
    ]
    );
  }, build: (ctx) {
    return [
      pw.Table(
         border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: columnWidths, children: [
      
        ...List.generate(sale.items.length, (index) {
          var item = sale.items[index];
          var values = item.toDisplayItemIdealTime(index: index);
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColor.fromHex('#e6e6e6')))),
              children: List.generate(values.length, (i) {
                var widget = values[i];
                return widget;
              }));
        })
      ]),
      pw.SizedBox(height: kDefaultPadding),
      pw.Table(
        columnWidths: columnWidths2,
        children: [
          pw.TableRow(children: [
               pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                 
                     pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [

            company?.bankInfo != null ?  pw.Container(
                            margin: pw.EdgeInsets.only(
                              top: kDefaultPadding/2
                            ),
                            child:   pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('DEPOSITAR:',style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              fontSize: 7,
              fontWeight: pw.FontWeight.bold
             )),
             pw.SizedBox(
              height: kDefaultPadding/3
             ),
              pw.Text('RNC ${company?.rncOrId}:',softWrap:true,  style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold
             )),

              pw.Text(company?.bankInfo??'', style: pw.TextStyle(
              fontSize: 7
             )),
          ]
         )):pw.SizedBox(),
                ]
              ),
                pw.SizedBox(
              height: kDefaultPadding/3
             ),
             sale.description?.isNotEmpty == true ? pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 5),
                child:  pw.Text(sale.description ?? '', style: pw.TextStyle(fontSize: 8)),
              ):pw.SizedBox(),
    
              pw.SizedBox(
                  width: 60,
                  height: 60,
                  child: pw.BarcodeWidget(
                      data: sale.dgiiURL != null
                          ? sale.dgiiURL ?? ''
                          : sale.ncf ?? '',
                      barcode: qr)),
            
              sale.securityCode != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Codigo de seguridad:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.securityCode ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.signatureDate != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Fecha de Firma:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(
                            sale.signatureDate
                                    ?.format(payload: 'DD-MM-YYYY HH:mm:ss') ??
                                '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.authorName != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Atendido por:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.authorName ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.rate != null && sale.rate! > 1
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Tasa Dolar:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.rate?.toStringAsFixed(2) ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.estadoDgiiNombre != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Estado DGII:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.estadoDgiiNombre ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),

            
            ]),

      
      
             pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                                padding: pw.EdgeInsets.symmetric(
                        
                            horizontal: kDefaultPadding/2
                        ),
                        child:  pw.Text('Subtotal',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                    
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.net?.toDop()
                                : sale.net?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),

        sale.discount == 0  ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                            padding: pw.EdgeInsets.symmetric(
                           
                            horizontal: kDefaultPadding/2
                        ),
                        child: pw.Container(
                          child:  pw.Text('Descuento',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                        )
                       )),
                     
                        pw.Expanded(child:pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.discount?.toDop()
                                : sale.discount?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
           
               sale.netFinal! > 0 && (sale.net != sale.netFinal) ?   pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                 
                        child:  pw.Text('Subtotal',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.netFinal?.toDop()
                                : sale.netFinal?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

                pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                             width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                           
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text('Itbis',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child:pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.tax?.toDop()
                                : sale.tax?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
               sale.law10! > 0 ? pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                             width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text('Ley 10%',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.law10?.toDop()
                                : sale.law10?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),


              pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5,
                         
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                       
                            horizontal: kDefaultPadding/2
                        ),
                      
                        child:  pw.Text('Total'.toUpperCase(),
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                    
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.total?.toDop()
                                : sale.total?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.center)
                        ))
                      ])),
             
            sale.retentionTax! > 0 ? pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                          
                            horizontal: kDefaultPadding/2
                        ),
                      
                        child:  pw.Text('Retención Itbis',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child:pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.retentionTax?.toDop()
                                : sale.retentionTax?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

         sale.retentionIsr! > 0 ?  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                      
                            horizontal: kDefaultPadding/2
                        ),
                     
                        child:  pw.Text('Retención Isr',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.retentionIsr?.toDop()
                                : sale.retentionIsr?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

       enabledTotalsConfigSimple ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                           width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                      
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text(  sale.ncfTypeId!.contains('34')
                                ? 'Total a devolver'
                                : 'Total a pagar',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                                padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                              
                            ))
                        ),
                          child: pw.Text(
                              sale.currencyId == 1
                                ? (sale.total! -
                                        (sale.retentionIsr! +
                                            sale.retentionTax!))
                                    .toDop()
                                : (sale.total! -
                                        (sale.retentionIsr! +
                                            sale.retentionTax!))
                                    .toUS(),
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
          
         enabledTotalsConfigSimple ? pw.SizedBox(): pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                        width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                  
                        child:  pw.Text(esNotaCredito ? 'Devuelto'.toUpperCase():'Pagado'.toUpperCase(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child:pw.Container(
                             padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.amountPaid?.toDop()
                                : sale.amountPaid?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.center)
                        ))
                      ])),
             
              pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding/3),
                  child: pw.Text('FORMAS DE PAGO:',
                      style: pw.TextStyle(
                          fontSize: 6, fontWeight: pw.FontWeight.bold))),
              pw.Container(
            
                child: pw.Text(paymentsWidgets.join(','),
                    style: pw.TextStyle(fontSize: 6)),
              )
            ])
          ])
        ]
      ),
   
    
    ];
  }, footer: (ctx) {
    return pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
           
            pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(children: [  
          pw.Container(width: 150, height:0.7, color: PdfColors.black),
          pw.SizedBox(height: 3),
          pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
          ]),
          pw.SizedBox(width: kDefaultPadding),
          pw.Column(children: [
         
           pw.Container(width: 150, height: 0.7, color: PdfColors.black),
           pw.SizedBox(height: 3),
           pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
            
          ]),
        ]),
              pw.SizedBox(height: kDefaultPadding),
        pw.Column(
            children: [
                pw.Text('${company?.address}, Tel: ${company?.phone1}, Cel: ${company?.phone2},\nEmail: ${company?.email}',softWrap: true,style: pw.TextStyle(
                    color: textColor,
                ),textAlign: pw.TextAlign.center),
                pw.Text('RNC: ${company?.rncOrId}',style:  pw.TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold
                ))
            ]
        )
        ]
    );
  }));
  return document;
}





Future<pw.Document> createRLopezInvoice(Sale sale)async {
  var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
  var esCotization = sale.ncfTypeId == '60';
  var isSaleProduct = sale is SaleProduct || sale is CreditNoteAsProduct;

 
  List<String> columns() {
    var list = ['CANTIDAD','DESCRIPCIÓN','PRECIO','TOTAL'];
    if(isSaleProduct) {
      list.insert(1, 'CODIGO');
    }
  
   return list;
  }


  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

  if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }


  var primaryColor = PdfColor.fromHex('#F5F0F0FF');

  var textColor = PdfColor.fromHex('#212120FF');

  // Cargar la fuente desde assets
  final fontData = await rootBundle.load("assets/fonts/Montserrat-Bold.ttf");
  final ttfB = pw.Font.ttf(fontData);

    // Cargar la fuente desde assets
  final fontData2 = await rootBundle.load("assets/fonts/Montserrat-Medium.ttf");
  final ttf = pw.Font.ttf(fontData2);

  
    // Cargar la fuente desde assets
  final fontData3 = await rootBundle.load("assets/fonts/Montserrat-Italic.ttf");
  final ttf3 = pw.Font.ttf(fontData3);


  var w1 = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(3),
  2: pw.FlexColumnWidth(2),
  3: pw.FlexColumnWidth(2)
};
var w2 = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(3),
  3: pw.FlexColumnWidth(2),
  4: pw.FlexColumnWidth(2)
};

var ww1 = {
           0: pw.FlexColumnWidth(3),
           1: pw.FlexColumnWidth(3)
        };

var ww2 = {
           0: pw.FlexColumnWidth(5),
           1: pw.FlexColumnWidth(4)
        };

var columnWidths =w1;
var columnWidths2 = ww1;

if(isSaleProduct){
columnWidths = w2;
columnWidths2 = ww2;
}
  document.addPage(pw.MultiPage(
    margin: pw.EdgeInsets.only(
        left: kDefaultPadding * 2,
        right: kDefaultPadding * 2,
        top: kDefaultPadding * 2,
        bottom: kDefaultPadding*2
    ),
    theme: pw.ThemeData(
     defaultTextStyle: pw.TextStyle(
      fontSize: 10,
      font:ttf,
      fontBold: ttfB,
      fontItalic: ttf3
     )
    ),
    header: (ctx) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Expanded(child:  pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   company?.logo != null
                        ? pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                                pw.Image(
                                    pw.MemoryImage(
                                        base64Decode(company!.logo!)),
                                    width: 130),
                          
                              ])
                        : pw.Container(
                          width: 110,
                          height: 110,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black
                            )
                          ),
                          child: pw.Center(
                             child: pw.Text('LOGO',style: pw.TextStyle(
                                fontSize: 15
                             ))
                          )
                        ),
               
                ])),
        pw.Expanded(child:pw.Column(
          children: [
             pw.Container(
                width: double.infinity,
              padding: pw.EdgeInsets.all(kDefaultPadding/3),
               decoration: pw.BoxDecoration(
                border: pw.Border.all(
                color: PdfColors.black
              ),
            ),
          child: pw.Column(
            children: [
              pw.Text(sale.ncfTypeName??'',textAlign: pw.TextAlign.center),
              pw.Text('NO. ${sale.ncf}',textAlign: pw.TextAlign.center),
             esNotaCredito ? pw.Column(
                children: [
                    pw.Text('AFECTADO: ${sale.ncfAffected}',textAlign: pw.TextAlign.center)
                ]
              ):pw.SizedBox()
            ]
          )
          ),
          pw.SizedBox(
            height: kDefaultPadding/4
          ),
          pw.Container(
             
               decoration: pw.BoxDecoration(
                border: pw.Border.all(
                color: PdfColors.black
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Container(
                     padding: pw.EdgeInsets.all(kDefaultPadding/3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(
                        color: PdfColors.black
                      )
                    )
                  ),
                  child: pw.Text('Válida Hasta',textAlign: pw.TextAlign.center)
                )),
                pw.SizedBox(
                  width: kDefaultPadding/3
                ),
                pw.Expanded(child: pw.Container(
                  child: pw.Text(esConsumo || esNotaCredito || esCotization? 'NO VENCE': sale.expirationDate?.format(payload: 'DD-MM-YYYY') ??'',textAlign: pw.TextAlign.center)
                ))
              ]
            )
          )
        
          ]
        ))
      ]),
      pw.SizedBox(height: kDefaultPadding/3),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(flex: 2, child: pw.Text('FECHA DE EMISIÓN: ${sale.issueDate?.format(payload: 'DD-MM-YYYY')}',style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold
          ))),
          pw.Expanded(child: pw.Text('Tipo de Impresión: ORIGINAL'))
        ]
      ),
    
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: pw.EdgeInsets.all(kDefaultPadding/3),
                margin: pw.EdgeInsets.symmetric(
                  vertical: kDefaultPadding/4
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child: pw.Text('DATOS DEL CLIENTE',style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize:9
                  
                ))
              ),
              pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                      
                      child: pw.Text('NOMBRE:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                     decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientName?.toUpperCase()??'',style: pw.TextStyle(
                      
                      ))
                    ),)
                  ]
                )
              ),

              pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                    
                      child: pw.Text('RNC/CEDULA:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                    pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                        decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientIdentificationFormat,style: pw.TextStyle(
                      
                      ))
                    ))
                  ]
                )
              ),
             pw.Container(
 
                width: double.infinity,
              
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                    
                      child: pw.Center(child: pw.Text('DIRECCIÓN:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      )))
                    )),
                   pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                      decoration: pw.BoxDecoration(
                         border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientAddress?.toUpperCase()??'S/N',softWrap: true, style: pw.TextStyle(
                        
                    
                      ))
                    ))
                  ]
                )
              ),

                pw.Container(
 
                width: double.infinity,
               
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                       width: 0.5
                  )
                ),
                child:pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(child: pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/4),
                     
                      child: pw.Text('TELÉFONOS:',textAlign: pw.TextAlign.center, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9
                      ))
                    )),
                   pw.Expanded(flex: 3, child:  pw.Container(
                      padding: pw.EdgeInsets.all(kDefaultPadding/3),
                     decoration: pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.black,   width: 0.5)
                        )
                      ),
                      child: pw.Text(sale.clientPhone?.isNotEmpty == true ? 'TEL: ${sale.clientPhone}' : 'NO DISPONIBLE',style: pw.TextStyle(
                    
                      ))
                    ),)
                  ]
                )
              ),
            ]
          )),
          pw.SizedBox(
            width: kDefaultPadding
          ),
          pw.Expanded(child: pw.Column(
            children: [
                pw.Text('NOMBRE DEL\nVENDEDOR:',style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold
                )),
                pw.Text(sale.authorName?.toUpperCase() ??'',style: pw.TextStyle(
                    decoration: pw.TextDecoration.underline
                ))
            ]
          ))
        ]
      ),
     pw.SizedBox(height: kDefaultPadding),
     pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: columnWidths,
      children: [
           pw.TableRow(
            decoration: pw.BoxDecoration(color:primaryColor),
            children: List.generate(columns().length, (index) {
              var col = columns()[index];

              return pw.Padding(
                  padding: pw.EdgeInsets.all(kDefaultPadding / 3),
                  child: pw.Text(col,
                  textAlign:  pw.TextAlign.center,
                      style:
                          pw.TextStyle(color: PdfColors.black, fontSize: 7, fontWeight: pw.FontWeight.bold)));
            })),
      ]
     )
    ]
    );
  }, build: (ctx) {
    return [
      pw.Table(
         border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: columnWidths, children: [
      
        ...List.generate(sale.items.length, (index) {
          var item = sale.items[index];
          var values = item.toDisplayItemIdealTime(index: index);
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColor.fromHex('#e6e6e6')))),
              children: List.generate(values.length, (i) {
                var widget = values[i];
                return widget;
              }));
        })
      ]),
      pw.SizedBox(height: kDefaultPadding),
            pw.Table(
        columnWidths: columnWidths2,
        children: [
          pw.TableRow(children: [
               pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [

                     pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [

            company?.bankInfo != null ?  pw.Container(
                            margin: pw.EdgeInsets.only(
                              top: kDefaultPadding/2
                            ),
                            child:   pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('DEPOSITAR:',style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              fontSize: 7,
              fontWeight: pw.FontWeight.bold
             )),
             pw.SizedBox(
              height: kDefaultPadding/3
             ),
              pw.Text('RNC ${company?.rncOrId}:',softWrap:true,  style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold
             )),

              pw.Text(company?.bankInfo??'', style: pw.TextStyle(
              fontSize: 7
             )),
          ]
         )):pw.SizedBox(),
                ]
              ),
                pw.SizedBox(
              height: kDefaultPadding/3
             ),
             sale.description?.isNotEmpty == true ? pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 5),
                child:  pw.Text(sale.description ?? '', style: pw.TextStyle(fontSize: 8)),
              ):pw.SizedBox(),
    
              pw.SizedBox(
                  width: 60,
                  height: 60,
                  child: pw.BarcodeWidget(
                      data: sale.dgiiURL != null
                          ? sale.dgiiURL ?? ''
                          : sale.ncf ?? '',
                      barcode: qr)),
            
              sale.securityCode != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Codigo de seguridad:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.securityCode ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.signatureDate != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Fecha de Firma:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(
                            sale.signatureDate
                                    ?.format(payload: 'DD-MM-YYYY HH:mm:ss') ??
                                '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.authorName != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Atendido por:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.authorName ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.rate != null && sale.rate! > 1
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Tasa Dolar:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.rate?.toStringAsFixed(2) ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),
              sale.estadoDgiiNombre != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 5),
                      child: pw.Row(children: [
                        pw.Text('Estado DGII:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.estadoDgiiNombre ?? '',
                            style: pw.TextStyle(fontSize: 8)),
                      ]))
                  : pw.SizedBox(),

            
            ]),

      
      
             pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                                padding: pw.EdgeInsets.symmetric(
                        
                            horizontal: kDefaultPadding/2
                        ),
                        child:  pw.Text('Subtotal',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                    
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.net?.toDop()
                                : sale.net?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),

        sale.discount == 0  ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                            padding: pw.EdgeInsets.symmetric(
                           
                            horizontal: kDefaultPadding/2
                        ),
                        child: pw.Container(
                          child:  pw.Text('Descuento',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                        )
                       )),
                     
                        pw.Expanded(child:pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.discount?.toDop()
                                : sale.discount?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
           
               sale.netFinal! > 0 && (sale.net != sale.netFinal) ?   pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                 
                        child:  pw.Text('Subtotal',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.netFinal?.toDop()
                                : sale.netFinal?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

                pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                             width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                           
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text('Itbis',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child:pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.tax?.toDop()
                                : sale.tax?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
               sale.law10! > 0 ? pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                             width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text('Ley 10%',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.law10?.toDop()
                                : sale.law10?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),


              pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5,
                         
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                       
                            horizontal: kDefaultPadding/2
                        ),
                      
                        child:  pw.Text('Total'.toUpperCase(),
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                    
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.total?.toDop()
                                : sale.total?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.center)
                        ))
                      ])),
             
            sale.retentionTax! > 0 ? pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                          
                            horizontal: kDefaultPadding/2
                        ),
                      
                        child:  pw.Text('Retención Itbis',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child:pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.retentionTax?.toDop()
                                : sale.retentionTax?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

         sale.retentionIsr! > 0 ?  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                      
                            horizontal: kDefaultPadding/2
                        ),
                     
                        child:  pw.Text('Retención Isr',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child: pw.Text(
                            sale.currencyId == 1
                                ? sale.retentionIsr?.toDop()
                                : sale.retentionIsr?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

       enabledTotalsConfigSimple ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                           width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                      
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text(  sale.ncfTypeId!.contains('34')
                                ? 'Total a devolver'
                                : 'Total a pagar',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                                padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                              
                            ))
                        ),
                          child: pw.Text(
                              sale.currencyId == 1
                                ? (sale.total! -
                                        (sale.retentionIsr! +
                                            sale.retentionTax!))
                                    .toDop()
                                : (sale.total! -
                                        (sale.retentionIsr! +
                                            sale.retentionTax!))
                                    .toUS(),
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
          
         enabledTotalsConfigSimple ? pw.SizedBox(): pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                        width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                  
                        child:  pw.Text(esNotaCredito ? 'Devuelto'.toUpperCase():'Pagado'.toUpperCase(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child:pw.Container(
                             padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child:  pw.Text(
                            sale.currencyId == 1
                                ? sale.amountPaid?.toDop()
                                : sale.amountPaid?.toUS() ?? '',
                            style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.center)
                        ))
                      ])),
             
              pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding/3),
                  child: pw.Text('FORMAS DE PAGO:',
                      style: pw.TextStyle(
                          fontSize: 6, fontWeight: pw.FontWeight.bold))),
              pw.Container(
            
                child: pw.Text(paymentsWidgets.join(','),
                    style: pw.TextStyle(fontSize: 6)),
              )
            ])
          ])
        ]
      ),
    ];
  }, footer: (ctx) {
    return pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
           
            pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(children: [  
          pw.Container(width: 150, height:0.7, color: PdfColors.black),
          pw.SizedBox(height: 3),
          pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
          ]),
          pw.SizedBox(width: kDefaultPadding),
          pw.Column(children: [
         
           pw.Container(width: 150, height: 0.7, color: PdfColors.black),
           pw.SizedBox(height: 3),
           pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
            
          ]),
        ]),
              pw.SizedBox(height: kDefaultPadding),
        pw.Column(
            children: [
                pw.Text('${company?.address}, Tel: ${company?.phone1}, Cel: ${company?.phone2},\nEmail: ${company?.email}',softWrap: true,style: pw.TextStyle(
                    color: textColor,
                ),textAlign: pw.TextAlign.center),
                pw.Text('RNC: ${company?.rncOrId}',style:  pw.TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold
                ))
            ]
        )
        ]
    );
  }));
  return document;
}


Future<pw.Document> createTechoInvoice(Sale sale)async {
  var document = pw.Document();
  // Generar código QR
  final qr = pw.Barcode.qrCode();

  var esConsumo = sale.ncfTypeId == '02' || sale.ncfTypeId == '32';
  var esNotaCredito = sale.ncfTypeId == '04' || sale.ncfTypeId == '34';
  var esCotization = sale.ncfTypeId == '60';
  var isSaleProduct = sale is SaleProduct || sale is CreditNoteAsProduct;

 
  List<String> columns() {
    var list = ['CANTIDAD','UNIDAD','DESCRIPCIÓN','CLIENTE','PRECIO','TOTAL'];
    if(isSaleProduct) {
      list.removeAt(1);
      list.removeAt(2);
      list.insert(1,'CODIGO');
    }
  
   return list;
  }


  List<String> paymentsWidgets = [];

  if (sale.effective != null && sale.effective! > 0) {
    paymentsWidgets.add('EFECTIVO');
  }

  if (sale.creditCard != null && sale.creditCard! > 0) {
    paymentsWidgets.add('TARJETA DE CREDITO O DEBITO');
  }

  if (sale.checkOrTransf != null && sale.checkOrTransf! > 0) {
    paymentsWidgets.add('CHEQUE O TRANSFERENCIA');
  }

  if ((sale.saleToCredit != null && sale.saleToCredit! > 0) || sale.amountPaid == 0) {
    paymentsWidgets.add('VENTA A CREDITO');
  }


  var primaryColor = PdfColor.fromHex('#F5F0F0FF');

  var textColor = PdfColor.fromHex('#212120FF');

  // Cargar la fuente desde assets
  final fontData = await rootBundle.load("assets/fonts/Montserrat-Bold.ttf");
  final ttfB = pw.Font.ttf(fontData);

    // Cargar la fuente desde assets
  final fontData2 = await rootBundle.load("assets/fonts/Montserrat-Medium.ttf");
  final ttf = pw.Font.ttf(fontData2);

  
    // Cargar la fuente desde assets
  final fontData3 = await rootBundle.load("assets/fonts/Montserrat-Italic.ttf");
  final ttf3 = pw.Font.ttf(fontData3);


  var w1 = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(2),
  3: pw.FlexColumnWidth(2),
  4: pw.FlexColumnWidth(2),
  5: pw.FlexColumnWidth(2),
};
var w2 = {
  0: pw.FlexColumnWidth(),
  1: pw.FlexColumnWidth(),
  2: pw.FlexColumnWidth(4),
  3: pw.FlexColumnWidth(2),
  4: pw.FlexColumnWidth(2),
};

var ww1 = {
           0: pw.FlexColumnWidth(3),
           1: pw.FlexColumnWidth(2)
        };

var ww2 = {
           0: pw.FlexColumnWidth(3),
           1: pw.FlexColumnWidth(2)
        };

var columnWidths =w1;
var columnWidths2 = ww1;

if(isSaleProduct){
columnWidths = w2;
columnWidths2 = ww2;
}

var tels = [];

if(company?.phone1 != null){
  tels.add('${company?.phone1}');
}

if(company?.phone2 != null){
  tels.add('${company?.phone2}');
}

var telsMessage = '';

if(tels.isNotEmpty){
  telsMessage = 'Telefonos: ${tels.join(',')}';
}


// Número mínimo de filas por defecto
const minRows = 4;

// Filas dinámicas con datos
final itemRows = List.generate(sale.items.length, (index) {
  var item = sale.items[index];
  var values = item.toDisplayTecho().values.toList();

  return pw.TableRow(
    verticalAlignment: pw.TableCellVerticalAlignment.middle,
    decoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColor.fromHex('#e6e6e6')),
      ),
    ),
    children: List.generate(values.length, (i) {
      var val = values[i];
      return pw.Padding(
        padding: pw.EdgeInsets.all(kDefaultPadding / 4),
        child: pw.Text(
          val,
          textAlign: i >= 3 || i == 0 || (sale.invoiceTypeId == 1 && i >= 4)
              ? pw.TextAlign.center
              : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: i > 3 ? 8 : 7,
            fontWeight: i == 1 ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }),
  );
});

// Calcular cuántas filas vacías faltan
final emptyRowsCount = (minRows - sale.items.length).clamp(0, minRows);

// Filas vacías
final emptyRows = List.generate(emptyRowsCount, (_) {
  return pw.TableRow(
    children: List.generate(columnWidths.length, (_) {
      return pw.Padding(
        padding: pw.EdgeInsets.all(kDefaultPadding/2),
        child: pw.Text(''), // celda vacía
      );
    }),
  );
});


  document.addPage(pw.MultiPage(
    margin: pw.EdgeInsets.only(
        left: kDefaultPadding * 2,
        right: kDefaultPadding * 2,
        top: kDefaultPadding * 1.5,
        bottom: kDefaultPadding* 0.5
    ),
    theme: pw.ThemeData(
     defaultTextStyle: pw.TextStyle(
      fontSize: 10,
      font:ttf,
      fontBold: ttfB,
      fontItalic: ttf3
     )
    ),
    header: (ctx) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
    pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   company?.logo != null
                        ?   pw.Container(
                          margin: pw.EdgeInsets.only(
                            bottom: kDefaultPadding * 0.60
                          ),
                          child:  pw.Image(
                                    pw.MemoryImage(
                                        base64Decode(company!.logo!)),
                                    width: 130)
                        )
                        : pw.Container(
                          width: 110,
                          height: 110,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black
                            )
                          ),
                          child: pw.Center(
                             child: pw.Text('LOGO',style: pw.TextStyle(
                                fontSize: 15
                             ))
                          )
                        ),
               
                ]),

      pw.Row(
           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex:3,
            child: pw.Column(
                         mainAxisAlignment: pw.MainAxisAlignment.start,
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.Container(
                margin: pw.EdgeInsets.only(
                  bottom: kDefaultPadding/4
                ),
                child:pw.Text('RNC ${company?.rncOrId}',style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold
              )),
               ),
            
            pw.Container(
                margin: pw.EdgeInsets.only(
                  bottom: kDefaultPadding/5
                ),
              child:pw.Text(company?.address ?? '',style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold
              )),
            ),

            tels.isNotEmpty ?  pw.Text(telsMessage,style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold
              )):pw.SizedBox(),

            company?.email  != null ? pw.Text('Correo: ${company?.email}',style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold
              )) : pw.Container()
            ]
          )),

          pw.Expanded(
            flex:2,
            child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [

            pw.Text(sale.ncfTypeName ?? '',style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold
            )),
            pw.SizedBox(
              height:kDefaultPadding/2
            ),
          
            pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                 pw.Expanded(
                
                  child: pw.Text('NCF:',style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold
            ))),
                
               pw.Expanded(
                flex:2,
                child: pw.Text(sale.ncf ?? '',style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold
            )))
              ]
            ),
            esNotaCredito ?      pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                 pw.Expanded(child: pw.Text('NCF AFECTADO:',style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold
            ))),
               
                pw.Expanded(
                  flex:2,
                  child:  pw.Text(sale.ncfAffected ?? '',style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold
            )))
              ]
            ):pw.SizedBox(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children:[
               pw.Expanded(child: pw.Text('Fecha:',style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold
            ))),
             
                pw.Expanded(
                  flex:2,
                  child:  pw.Text(sale.createdAt?.format(payload:'LL') ?? '',style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold
            )))
            ]
          ),

           esCotization  || esNotaCredito? pw.SizedBox():    pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children:[
               pw.Expanded(child: pw.Text('Fecha de Vencimiento:',style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold
            ))),
             
                pw.Expanded(
                  flex:2,
                  child:  pw.Text(sale.expirationDate?.format(payload:'LL') ?? '',style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold
            )))
            ]
          ),

          pw.SizedBox(
               height: kDefaultPadding
          ),
              pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text('Facturar a:',style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold
                  ))),
               
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(sale.clientName ?? '',style: pw.TextStyle(
                    fontSize: 7,
                     fontWeight: pw.FontWeight.bold
                  )))
                ]
              ),
              pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text('Direccion:',softWrap: true, style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  
                  ))),
                 
                  
                  pw.Expanded(
                    flex: 2,
                    child:  pw.Text(sale.clientAddress ?? 'S/N',softWrap: true, style: pw.TextStyle(
                    fontSize: 7,
                     fontWeight: pw.FontWeight.bold
                  )),)
               
                  
                ]
              ),
           
              pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text('Rnc/Cedula:',style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold
                  ))),
                
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(sale.clientIdentificationFormat,textAlign: pw.TextAlign.left, style: pw.TextStyle(
                    fontSize: 7,
                     fontWeight: pw.FontWeight.bold
                  )))
                ]
              ),
              pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text('Teléfono:',style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold
                  ))),
                 
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(sale.clientPhone ??'S/N',style: pw.TextStyle(
                    fontSize: 7,
                     fontWeight: pw.FontWeight.bold
                  )))
                ]
              ),

                sale.clientEmail != null ?   pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text('Correo:',style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold
                  ))),
                 
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(sale.clientEmail ??'S/N',style: pw.TextStyle(
                    fontSize: 7,
                     fontWeight: pw.FontWeight.bold
                  )))
                ]
              ):pw.SizedBox()
            ]
          )
          ),
        
     
        ]
      ),
  
       pw.SizedBox(height: kDefaultPadding/2),
     pw.Table(
          border: pw.TableBorder.symmetric(outside: pw.BorderSide(
            color: PdfColors.black, width: 0.5
          )),
      columnWidths: columnWidths,
      children: [
           pw.TableRow(
         
            children: List.generate(columns().length, (index) {
              var col = columns()[index];

             

              return pw.Padding(
                  padding: pw.EdgeInsets.all(kDefaultPadding / 4),
                  child: pw.Text(col,
                  textAlign:  pw.TextAlign.center,
                      style:
                          pw.TextStyle(color: PdfColors.black, fontSize: 7, fontWeight: pw.FontWeight.bold)));
            })),
      ]
     )
    ]
    );
  }, build: (ctx) {
    return [
      pw.Table(
         border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: columnWidths, children: [
       ...itemRows,
    ...emptyRows,
      ]),

            pw.Table(
        columnWidths: columnWidths2,
        children: [
          pw.TableRow(children: [

         
               pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [

        company?.bankInfo != null ?    pw.Container(
                            margin: pw.EdgeInsets.only(
                              top: kDefaultPadding/2
                            ),
                            child:   pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('DEPOSITAR:',style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              fontSize: 7,
              fontWeight: pw.FontWeight.bold
             )),
             pw.SizedBox(
              height: kDefaultPadding/2
             ),
              pw.Text('RNC ${company?.rncOrId}:',style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold
             )),

              pw.Text(company?.bankInfo??'',style: pw.TextStyle(
              fontSize: 7,

             )),

             
          ]
         ),
            ):pw.SizedBox(),
           
            ]),

             pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                                padding: pw.EdgeInsets.symmetric(
                        
                            horizontal: kDefaultPadding/2
                        ),
                        child:  pw.Text('Subtotal',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                    
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child: pw.Text(
                            sale.netLabel,
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])
                      ),

        sale.discount == 0  ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                            padding: pw.EdgeInsets.symmetric(
                           
                            horizontal: kDefaultPadding/2
                        ),
                        child: pw.Container(
                          child:  pw.Text('Descuento',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                        )
                       )),
                     
                        pw.Expanded(child:pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child:  pw.Text(
                            sale.discountLabel,
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
           
               (sale.netFinal ?? 0) > 0 && (sale.net != sale.netFinal) ?   pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                 
                        child:  pw.Text('Subtotal',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                                
                            ))
                        ),
                          child: pw.Text(
                            sale.netFinalLabel,
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

                pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                             width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                           
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text('Itbis',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child:pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            
                            ))
                        ),
                          child:  pw.Text(
                            sale.taxLabel,
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),

                   (sale.retentionTax ?? 0) > 0 ? pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                          
                            horizontal: kDefaultPadding/2
                        ),
                      
                        child:  pw.Text('Retención Itbis',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                      
                        pw.Expanded(child:pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child:  pw.Text(
                            sale.retentionTaxLabel,
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

         (sale.retentionIsr ?? 0) > 0 ?  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                      
                            horizontal: kDefaultPadding/2
                        ),
                     
                        child:  pw.Text('Retención Isr',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child: pw.Text(
                            sale.retentionIsrLabel,
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),

               (sale.law10 ?? 0) > 0 ? pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                             width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text('Ley 10%',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                               padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            
                            ))
                        ),
                          child: pw.Text(
                            sale.law10Label,
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])):pw.SizedBox(),


              pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                         width: 0.5,
                         
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                       
                            horizontal: kDefaultPadding/2
                        ),
                      
                        child:  pw.Text('Total'.toUpperCase(),
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                    
                        pw.Expanded(child: pw.Container(
                              padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child: pw.Text(
                            enabledTotalsConfigSimple ? sale.amountPaidLabel :sale.totalLabel,
                            style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.center)
                        ))
                      ])),
             
         
       enabledTotalsConfigSimple ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                           width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                      
                            horizontal: kDefaultPadding/2
                        ),
                    
                        child:  pw.Text(  sale.ncfTypeId!.contains('34')
                                ? 'Total a devolver'
                                : 'Total a pagar',
                            style: pw.TextStyle(
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child: pw.Container(
                                padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                              
                            ))
                        ),
                          child: pw.Text(
                              sale.amountPaidLabel,
                            style: pw.TextStyle(fontSize: 8),textAlign: pw.TextAlign.center)
                        ))
                      ])),
          
               (sale.amountPaid ?? 0) <= 0 ? pw.SizedBox():  pw.Container(
                 
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                        width: 0.5
                      )),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                       pw.Expanded(child: pw.Container(
                        padding: pw.EdgeInsets.symmetric(
                         
                            horizontal: kDefaultPadding/2
                        ),
                  
                        child:  pw.Text(esNotaCredito ? 'Devuelto'.toUpperCase():'Pagado'.toUpperCase(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                                fontSize: 8),textAlign: pw.TextAlign.right),
                       )),
                     
                        pw.Expanded(child:pw.Container(
                             padding: pw.EdgeInsets.symmetric(
                            vertical: kDefaultPadding/5,
                            horizontal: kDefaultPadding/2
                        ),
                        decoration: pw.BoxDecoration(
                            border: pw.Border(left: pw.BorderSide(
                                color: PdfColors.black,
                                   width: 0.5
                            ))
                        ),
                          child:  pw.Text(
                            sale.amountxPaidLabel,
                            style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold),textAlign: pw.TextAlign.center)
                        ))
                      ])),
             
            (sale.amountPaid??0) > 0 ?  pw.Container(
                  margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding/3),
                  child: pw.Text('FORMAS DE PAGO:',
                      style: pw.TextStyle(
                          fontSize: 6, fontWeight: pw.FontWeight.bold))) :pw.SizedBox(),
            (sale.amountPaid??0) > 0 ?  pw.Container(
            
                child: pw.Text(paymentsWidgets.join(','),
                    style: pw.TextStyle(fontSize: 6)),

              
              ):pw.SizedBox()

             
            ])
          ])
        ]
      ),

      pw.Spacer(),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children:[
            pw.Container(
                  width: 30,
                  height: 30,
                  margin: pw.EdgeInsets.only(
                    top: kDefaultPadding/2
                  ),
                  child: pw.BarcodeWidget(
                      data: sale.dgiiURL != null
                          ? sale.dgiiURL ?? ''
                          : sale.ncf ?? '',
                      barcode: qr)),
            
              sale.securityCode != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 7),
                      child: pw.Row(children: [
                        pw.Text('Codigo de seguridad:',
                            style: pw.TextStyle(
                                fontSize: 5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.securityCode ?? '',
                            style: pw.TextStyle(fontSize: 5)),
                      ]))
                  : pw.SizedBox(),
              sale.signatureDate != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 7),
                      child: pw.Row(children: [
                        pw.Text('Fecha de Firma:',
                            style: pw.TextStyle(
                                fontSize: 5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(
                            sale.signatureDate
                                    ?.format(payload: 'DD-MM-YYYY HH:mm:ss') ??
                                '',
                            style: pw.TextStyle(fontSize: 5)),
                      ]))
                  : pw.SizedBox(),
            
              sale.rate != null && sale.rate! > 1
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 7),
                      child: pw.Row(children: [
                        pw.Text('Tasa Dolar:',
                            style: pw.TextStyle(
                                fontSize: 5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.rate?.toStringAsFixed(2) ?? '',
                            style: pw.TextStyle(fontSize: 5)),
                      ]))
                  : pw.SizedBox(),
              sale.estadoDgiiNombre != null
                  ? pw.Container(
                      margin: pw.EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 7),
                      child: pw.Row(children: [
                        pw.Text('Estado DGII:',
                            style: pw.TextStyle(
                                fontSize: 5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 5),
                        pw.Text(sale.estadoDgiiNombre ?? '',
                            style: pw.TextStyle(fontSize: 5)),
                      ]))
                  : pw.SizedBox(),
            sale.description?.isNotEmpty == true ? pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 6),
                child:  pw.Text( sale.description ?? '', style: pw.TextStyle(fontSize: 7)),
              ):pw.SizedBox(),
        ]
      )
    ];
  }, footer: (ctx) {
    return pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
           
            pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(children: [  
          pw.Container(width: 150, height:0.7, color: PdfColors.black),
          pw.SizedBox(height: 3),
          pw.Text('Entregado por', style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
          ]),
          pw.SizedBox(width: kDefaultPadding),
          pw.Column(children: [
         
           pw.Container(width: 150, height: 0.7, color: PdfColors.black),
           pw.SizedBox(height: 3),
           pw.Text('Recibido por', style: pw.TextStyle(fontSize: 8,fontWeight: pw.FontWeight.bold)),
            
          ]),
        ]),
    
        ]
    );
  }));

  return document;
}



Future<pw.Document> createInvoice(Sale sale) async{
  int option = currentInvoiceIndex ?? 0;
  switch (option) {
    case 0:
      return createDefaultInvoice(sale);
    case 1:
      return createFreelanceInvoice(sale);
    case 2:
      return createEpicRedInvoice(sale);
    case 3:
      return createEpicBlueInvoice(sale);
    case 4:
     return await createJulyMotorsInvoice(sale);
    case 5:
    return await createInvoiceStore(sale);
    case 6:
     return await createIdealTimeInvoice(sale);

    case 7:
     return await createRLopezInvoice(sale);

    case 8:
     return await createTechoInvoice(sale);
    default:
      return pw.Document();
  }
}



Future<pw.Document> createPaymentOrdenInvoice(PaymentOrden payment) async {
  var document = pw.Document();

  var materialFonts = await loadMaterialIconsFont();

  document.addPage(pw.MultiPage(
      margin: pw.EdgeInsets.all(kDefaultPadding * 3),
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      theme: pw.ThemeData.withFont(
        icons: materialFonts, // Carga la fuente de íconos
      ),
      build: (ctx) {
        return [
          pw.Center(
              child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Column(children: [
                        pw.Icon(
                          pw.IconData(0xe86c),
                          size: 200,
                          color: PdfColor.fromHex('#7BC113'),
                        ),
                        pw.SizedBox(height: kDefaultPadding),
                        pw.Text(
                            payment.currencyId == 1
                                ? payment.amount?.toDop()
                                : payment.amount?.toUS(),
                            style: pw.TextStyle(fontSize: 28)),
                        pw.SizedBox(height: kDefaultPadding),
                        pw.Text('COMPROBANTE DE PAGO',
                            style: pw.TextStyle(fontSize: 24)),
                      ])
                    ]),
                pw.SizedBox(height: kDefaultPadding * 4),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Fecha', style: pw.TextStyle(fontSize: 12)),
                      pw.Text(
                          payment.createdAt
                                  ?.toLocal()
                                  .format(payload: 'DD/MM/YYYY') ??
                              '',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Proveedor', style: pw.TextStyle(fontSize: 12)),
                      pw.Text(payment.providerName ?? 'S/N',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Banco', style: pw.TextStyle(fontSize: 12)),
                      pw.Text(payment.bankName ?? 'S/N',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Forma de Pago',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text(payment.paymentMethodName ?? '',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Numero de cheque o transferencia',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text(payment.transRef ?? 'S/N',
                          style: pw.TextStyle(fontSize: 12)),
                    ]),
                pw.Divider(),
              ]))
        ];
      }));
  return document;
}

Future<List<int>> createTicketCashShift(
    {String name = 'default',
    required CashShiftModel cashShiftModel,PrintCashShiftMode mode = PrintCashShiftMode.all}) async {
  
  final profile = await CapabilityProfile.load(name: name);
  final generator = Generator(PaperSize.mm80, profile,
      spaceBetweenRows: 2, codec: CustomLatinCodec());
  DateTime now = DateTime.now();
  List<int> bytes = [];
  bytes.addAll([27, 97, 0]); // ESC a 0 → izquierda

  generator.setStyles(PosStyles(width: PosTextSize.size6));

  // Encabezado
  bytes += generator.text(company?.name ?? '',
      styles: PosStyles(bold: true, align: PosAlign.center));
  if (company?.comercialName != null) {
    bytes += generator.text(company?.comercialName ?? '',
        styles: PosStyles(bold: true, align: PosAlign.center));
  }
  bytes += generator.text('TURNO: ${cashShiftModel.cashShiftNumber}',
      styles: PosStyles(align: PosAlign.center, bold: true));

  bytes += generator.text('JORNADA: ${cashShiftModel.periodName}',
      styles: PosStyles(align: PosAlign.center));
  bytes += generator.text('${cashShiftModel.boxName}',
       styles: PosStyles(align: PosAlign.left));
  bytes += generator.text('CAJERO: ${cashShiftModel.userName}',
       styles: PosStyles(align: PosAlign.left));

  bytes += generator.text('ESTADO: ${cashShiftModel.statusName}',
       styles: PosStyles(bold: false, align: PosAlign.left));
  bytes += generator.emptyLines(1);
  bytes += generator.text('FONDO INICIAL: ${cashShiftModel.openingAmount?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));
  bytes += generator.text('EFECTIVO CONTADO: ${cashShiftModel.effectiveCount?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));
      
  bytes += generator.text('FALTANTE: ${cashShiftModel.missingCash?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));

   bytes += generator.text('TRANSACCIONES: ${cashShiftModel.transactionsCount?.toStringAsFixed(2)}',
        styles: PosStyles(align: PosAlign.left));
   
    bytes += createDivider(generator);

    bytes += generator.text('TOTAL FACTURADO: ${cashShiftModel.totalAmount?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));
    bytes += generator.text('TOTAL ITBIS: ${cashShiftModel.totalTax?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));

    // Métodos de pago
    bytes += generator.text('EFECTIVO: ${cashShiftModel.effective?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));
    bytes += generator.text('TARJETA: ${cashShiftModel.creditCard?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));
    bytes += generator.text('CHEQUE/TRANSFERENCIA: ${cashShiftModel.checkOrTransf?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));
    bytes += generator.text('VENTA A CREDITO: ${cashShiftModel.saleToCredit?.toCoin()}',
        styles: PosStyles(align: PosAlign.left));
      bytes += generator.emptyLines(1);
     bytes += generator.text('DENOMINACIONES',
        styles: PosStyles(align: PosAlign.left));
    var keys = cashShiftModel.denominations!.keys.toList();

    for(int i = 0; i < keys.length;i++){  
      var key = keys[i];
      var map = cashShiftModel.denominations![key];
      var total = map['total'];
      var counts = map['counts'];
       bytes += generator.text('TIPO:$key\nCANTIDAD:$counts TOTAL: $total',
        styles: PosStyles(align: PosAlign.left));
      bytes += generator.emptyLines(1);
    }
    
  
    bytes += generator.emptyLines(2);

    bytes += generator.text('GENERADO POR: ${currentUser?.name}',
  styles: PosStyles(align: PosAlign.center, bold: true));
  bytes += generator.text('GENERADO: ${now.toIso8601String()}',
      styles: PosStyles(align: PosAlign.center, bold: true));

  bytes += createDivider(generator);
  bytes += generator.text('FIN DEL REPORTE',
      styles: PosStyles(align: PosAlign.center, bold: true));

  
  bytes += generator.feed(2);
  bytes += generator.cut();

  return bytes;
}
