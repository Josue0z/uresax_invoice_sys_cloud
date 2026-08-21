import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart' hide Border, BorderStyle;
import 'package:flutter/services.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:pdf/pdf.dart';
import 'package:postgres/postgres.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.product.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.service.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

abstract class Sale {
  String? id;
  String? clientId;
  String? ncf;
  String? ncfAffected;
  double? discount;
  double? net;
  double? netFinal;
  double? tax;
  double? total;
  double? effective;
  double? creditCard;
  double? checkOrTransf;
  double? saleToCredit;
  double? law10;
  String? typeIncomeId;
  String? typeIncomeName;
  int? clientType;
  String? clientTypeName;
  DateTime? createdAt;
  double? retentionTax;
  double? retentionIsr;
  int? paymentMethodId;
  String? paymentMethodName;
  String? ncfTypeId;
  String? ncfTypeName;
  String? saleId;
  String? description;
  String? clientIdentification;
  String? clientName;
  DateTime? retentionDate;
  String? prefix;
  int? invoiceTypeId;
  double? amountPaid;
  double? debt;
  double? coinBack;
  List<SaleItem> items = [];

  double? paid;

  int? bankId;
  String? transfRef;

  int? currencyId;
  double? rate;

  int? maxSequence;

  double? tax18;

  double? tax16;

  double? tax3;

  double? net18;

  double? net16;

  double? net3;

  double? exemptAmount;

  DateTime? signatureDate;

  String? securityCode;

  String? dgiiURL;

  String? ecfXmlFirmado;

  int? estadoDgii;

  int? tipoPago;

  DateTime? expirationDate;

  String? authorId;

  String? authorName;

  int? ncfSeq;

  String? estadoDgiiNombre;

  DateTime? ncfAffectedCreatedAt;

  String? clientAddress;

  double? paidInvoice;

  DateTime? issueDate;

  DateTime? paymentDate;

  String? clientPhone;

  String? clientEmail;

  String? message;

  String? refInvoiceId;

  int? ncfListId;

  bool? enabledDollarInvoice;

  double? netLocal;

  double? discountLocal;

  double? taxLocal;

  double? totalLocal;
  

  double? effectiveLocal;

  double? creditCardLocal;

  double? checkOrTransfLocal;

  double? saleToCreditLocal;

  double? law10Local;

  double? amountPaidLocal;

  double? debtLocal;

  double? tax18Local;

  double? tax16Local;

  double? tax3Local;

  double? net18Local;

  double? net16Local;

  double? net3Local;

  double? exemptAmountLocal;

  double? netFinalLocal;

  double? retentionTaxLocal;

  double? retentionIsrLocal;

  String? cashShiftId;

  bool get isPaid {
    throw UnimplementedError();
  }

  String get paidLabel {
    throw UnimplementedError();
  }

  Color get color {
    throw UnimplementedError();
  }

  Color get statusColorDgii {
    throw UnimplementedError();
  }

  String get netLabel {
    throw UnimplementedError();
  }
  String get discountLabel{
    throw UnimplementedError();
  }
  String get netFinalLabel {
    throw UnimplementedError();
  }

  String get taxLabel {
    throw UnimplementedError();
  }

  String get totalLabel {
    throw UnimplementedError();
  }

  String get retentionTaxLabel {
    throw UnimplementedError();
  }

  String get retentionIsrLabel {
    throw UnimplementedError();
  }

  String get amountPaidLabel {
    throw UnimplementedError();
  }

  String get law10Label {
    throw UnimplementedError();
  }

    String get amountxPaidLabel {
    throw UnimplementedError();
  }

  static Future<Sale?> findById(String id) async {
    throw UnimplementedError();
  }

  static Future<List<Sale>> get() async {
    throw UnimplementedError();
  }

  static Future<List<Sale>> getSales607Form() async {
    throw UnimplementedError();
  }

  Future<List<SaleItem>> getSaleData() async {
    throw UnimplementedError();
  }

  Future<Sale?> create() async {
    throw UnimplementedError();
  }

  Future<Sale?> update() async {
    throw UnimplementedError();
  }

  Future<Sale?> paySale(double amount) {
    throw UnimplementedError();
  }

  Future<bool?> delete() async {
    throw UnimplementedError();
  }

  Future<void> updateStock() async {
    throw UnimplementedError();
  }

  Map<String, dynamic> toMap() {
    throw UnimplementedError();
  }

  Map<String, dynamic> toMapInsert() {
    throw UnimplementedError();
  }

  Map<String, dynamic> toDisplay() {
    throw UnimplementedError();
  }

  Map<String, dynamic> to607() {
    throw UnimplementedError();
  }

  String get clientIdentificationFormat {
    throw UnimplementedError();
  }

  Future<void> updateEcfInfo() async {}
}

Future<List<Sale>> getSales(
    {String? ncfTypeId,
    List<String>? ncfsTypes,
    String? search,
    SaleStatus? saleStatus,
    int? estadoDgii,
    List<int>? dgiiStates,
    required DateTime startDate,
    required DateTime endDate}) async {
  try {
    List<String> query = [];
    String params = '';

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (search != null) {
      query.add('search=$search');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    var res = await apiUresax.get(
        '/sales/all?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    if (res.statusCode == 200) {
      var data = res.data;
      var list = List<Sale>.from((data as List).map((x) =>
          x['invoiceTypeId'] == 1
              ? SaleService.fromMap(x)
              : SaleProduct.fromMap(x)));

      return list;
    }
    return [];
  } catch (e) {
    rethrow;
  }
}

Future<List<Sale>> getCotizations(
    {required DateTime startDate,
    required DateTime endDate,
    String? search}) async {
  try {
    List<String> query = [];
    String params = '';

    if (search != null) {
      query.add('search=$search');
    }

    params = '&${query.join('&')}';

    var res = await apiUresax.get(
        '/quotations/all?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    if (res.statusCode == 200) {
      var data = res.data;
      var list = List<Sale>.from((data as List).map((x) =>
          x['invoiceTypeId'] == 1
              ? SaleService.fromMap(x)
              : SaleProduct.fromMap(x)));

      return list;
    }
    return [];
  } catch (e) {
    rethrow;
  }
}

Future<List<Sale>> getCreditNotes(
    {required DateTime startDate,
    required DateTime endDate,
    String? search}) async {
  try {
    List<String> query = [];
    String params = '';

    if (search != null) {
      query.add('search=$search');
    }

    params = '&${query.join('&')}';

    var res = await apiUresax.get(
        '/creditnotes/all?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    if (res.statusCode == 200) {
      var data = res.data;
      var list = List<Sale>.from((data as List).map((x) =>
          x['invoiceTypeId'] == 1
              ? CreditNoteAsService.fromMap(x)
              : CreditNoteAsProduct.fromMap(x)));

      return list;
    }
    return [];
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> getSalesTypeIncomesReport({
  String? ncfTypeId,
  List<String>? ncfsTypes,
  int? estadoDgii,
  List<int>? dgiiStates,
  SaleStatus? saleStatus,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    var grayScaleBytes = await getUresaxLogoAsGrayScale();
    var query = [];
    var params = '';

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    List<Map<String, dynamic>> typesincomes = [];
    var res = await apiUresax.get(
        '/reports/get-sales-report-by-typesincomes?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    if (res.statusCode == 200) {
      var data = res.data;

      typesincomes = List<Map<String, dynamic>>.from(
          (data['typesincomes'] as List).map((e) => e).toList());
    }
    var list = typesincomes;
    var columns = list.first.keys.where((k) => k != 'typeIncomeId').toList();

    var doc = pw.Document();
    PdfColor color = PdfColor.fromHex('#CECECE');

    doc.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.landscape,
          theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 5)),
          header: (ctx) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                    child: pw.Text(company?.name ?? '',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
                    child: pw.Text('REPORTE POR TIPO DE INGRESO',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
                    child: pw.Text(
                        '${company?.name} - ${startDate.format(payload: 'DD/MM/YYYY')} - ${endDate.format(payload: 'DD/MM/YYYY')}',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Table(
                    defaultColumnWidth: pw.FixedColumnWidth(40),
                    children: [
                      pw.TableRow(
                        verticalAlignment: pw.TableCellVerticalAlignment.middle,
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: columns
                            .map((col) => pw.Padding(
                                  padding: pw.EdgeInsets.only(
                                      top: kDefaultPadding / 3,
                                      bottom: kDefaultPadding / 3,
                                      right: kDefaultPadding / 3),
                                  child: pw.Text(col,
                                      textAlign: pw.TextAlign.left,
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold)),
                                ))
                            .toList(),
                      )
                    ],
                  )
                ],
              ),
          build: (ctx) => [
                pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  children: list.map((item) {
                    var index = list.indexOf(item);
                    var values = columns.map((k) => item[k]).toList();
                    bool isTotal = list.length - 1 == index;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color)),
                      ),
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: values
                          .map((el) => pw.Padding(
                                padding: pw.EdgeInsets.symmetric(
                                    vertical: kDefaultPadding / 3),
                                child: pw.Text(el.toString(),
                                    style: pw.TextStyle(
                                      fontWeight: isTotal
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal,
                                    ),
                                    textAlign: pw.TextAlign.left),
                              ))
                          .toList(),
                    );
                  }).toList(),
                )
              ],
          footer: (ctx) {
            return pw.Container(
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                  pw.Expanded(
                      child: pw.Row(children: [
                    pw.Image(pw.MemoryImage(grayScaleBytes),
                        width: 20, height: 20),
                    pw.SizedBox(width: kDefaultPadding / 3),
                    pw.Text('POWER BY URESAX', textAlign: pw.TextAlign.left)
                  ])),
                  pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.Spacer()
                ]));
          }),
    );

    return {'list': list, 'document': doc, 'bytes': await doc.save()};
  } on DioException catch (e) {
    throw e.response?.data['message'];
  }
}

Future<Map<String, dynamic>> getSalesReportByTypeNcf(
    {String? ncfTypeId,
    List<String>? ncfsTypes,
    int? estadoDgii,
    List<int>? dgiiStates,
    SaleStatus? saleStatus,
    required DateTime startDate,
    required DateTime endDate}) async {
  try {
    var grayScaleBytes = await getUresaxLogoAsGrayScale();

    var query = [];
    String params = '';

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    List<Map<String, dynamic>> ncfs = [];

    var res = await apiUresax.get(
        '/reports/get-sales-report-by-ncf?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    if (res.statusCode == 200) {
      var data = res.data;
      ncfs = List<Map<String, dynamic>>.from(
          (data['ncfs'] as List).map((e) => e).toList());
    }
    var list = ncfs;

    var columns = list.first.keys.toList();

    var doc = pw.Document();
    PdfColor color = PdfColor.fromHex('#CECECE');
    doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 5)),
        header: (ctx) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text(company?.name ?? '',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
                  child: pw.Text('REPORTE POR TIPO DE NCF',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
                  child: pw.Text(
                      '${company?.name} - ${startDate.toLocal().format(payload: 'DD/MM/YYYY')} - ${endDate.toLocal().format(payload: 'DD/MM/YYYY')}',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Table(
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  children: [
                    pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      decoration: pw.BoxDecoration(
                          border:
                              pw.Border(bottom: pw.BorderSide(color: color))),
                      children: columns
                          .map((col) => pw.Padding(
                                padding: pw.EdgeInsets.only(
                                    top: kDefaultPadding / 3,
                                    bottom: kDefaultPadding / 3,
                                    right: kDefaultPadding / 3),
                                child: pw.Text(col,
                                    textAlign: pw.TextAlign.left,
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                              ))
                          .toList(),
                    )
                  ],
                )
              ]);
        },
        build: (ctx) {
          return [
            pw.Table(
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.bottom,
                defaultColumnWidth: pw.FixedColumnWidth(40),
                children: List.generate(list.length, (i) {
                  var item = list[i];
                  var values = item.values.toList();
                  return pw.TableRow(
                      decoration: pw.BoxDecoration(
                          border:
                              pw.Border(bottom: pw.BorderSide(color: color))),
                      children: List.generate(values.length, (j) {
                        var el = values[j];
                        return pw.Padding(
                            padding: pw.EdgeInsets.symmetric(
                                vertical: kDefaultPadding / 3),
                            child: pw.Text(el.toString(),
                                style: pw.TextStyle(
                                    fontWeight: i == list.length - 1
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal),
                                textAlign: pw.TextAlign.left));
                      }));
                }))
          ];
        },
        footer: (ctx) {
          return pw.Container(
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                pw.Expanded(
                    child: pw.Row(children: [
                  pw.Image(pw.MemoryImage(grayScaleBytes),
                      width: 20, height: 20),
                  pw.SizedBox(width: kDefaultPadding / 3),
                  pw.Text('POWER BY URESAX', textAlign: pw.TextAlign.left)
                ])),
                pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}',
                    style: pw.TextStyle(fontSize: 10)),
                pw.Spacer()
              ]));
        }));

    return {'list': list, 'document': doc, 'bytes': await doc.save()};
  } on DioException catch (e) {
    throw e.response?.data['message'];
  }
}

Future<List<Sale>> getSalesList({String? search, int? invoiceTypeId}) async {
  try {
    String params = '';

    var parameters = {};

    if (search != null) {
      parameters.addAll({'search': '%$search%'});
      params += ' and ncf like @search';
    }

    if (invoiceTypeId != null) {
      parameters.addAll({'invoiceTypeId': invoiceTypeId});
      params += ' and "invoiceTypeId" = @invoiceTypeId';
    }

    final conne = SqlConector.connection;
    var result = await conne?.execute(
        Sql.named(
            '''select * from public."SalesView" where  ("ncfTypeId" = '01' or "ncfTypeId" = '15') $params order by "ncfTypeId" '''),
        parameters: parameters);
    return result
            ?.map((e) => e.toColumnMap()['invoiceTypeId'] == 1
                ? SaleService.fromMap(e.toColumnMap())
                : SaleProduct.fromMap(e.toColumnMap()))
            .toList() ??
        [];
  } catch (e) {
    rethrow;
  }
}

Future<List<Sale>> getSalesListByIdAndNcf(
    {String? rncOrId, String? ncf, int? invoiceTypeId}) async {
  try {
    List<String> query = [];

    if (rncOrId != null) {
      query.add('rncOrId=$rncOrId');
    }
    if (ncf != null) {
      query.add('ncf=$ncf');
    }

    if (invoiceTypeId != null) {
      query.add('invoiceTypeId=$invoiceTypeId');
    }

    String params = '?${query.join('&')}';

    var res = await apiUresax.get('/sales/get-sales-list-by-id-and-ncf$params');
    if (res.statusCode == 200) {
      var data = res.data;
      var list = List<Sale>.from((data as List).map((x) =>
          x['invoiceTypeId'] == 1
              ? SaleService.fromMap(x)
              : SaleProduct.fromMap(x)));
      return list;
    }

    return [];
  } catch (e) {
    rethrow;
  }
}

Future<void> calcDifOfNetsNcfs(
    {required String ncfAffected,
    required DateTime ncfAffectedCreatedAt,
    required double currentTotal}) async {
  try {
    final conne = SqlConector.connection;
    String date = ncfAffectedCreatedAt.toUtc().format(payload: 'YYYY-MM-DD');

    var ncfOriginal = await conne?.execute(
        Sql.named(
          '''select * from public."SalesView" WHERE ncf = @ncf and to_char("createdAt",'YYYY-MM-DD') = @createdAt''',
        ),
        parameters: {'ncf': ncfAffected, 'createdAt': date});

    var ncfCreditNote = await conne?.execute(Sql.named('''
         select sum(total)  as "total" from public."CreditNotesView" where "ncfAffected" = @ncfAffected and "estadoDgii" != 2
    '''), parameters: {'ncfAffected': ncfAffected});

    if (ncfCreditNote != null && ncfCreditNote.isNotEmpty) {
      var sale = ncfOriginal?.first.toColumnMap();
      var creditNote = ncfCreditNote.first.toColumnMap();

      var saleTotal = sale?['total'] != null ? double.parse(sale?['total']) : 0;
      var creditNoteTotal =
          creditNote['total'] != null ? double.parse(creditNote['total']) : 0;

      var dif = saleTotal - creditNoteTotal;

      if (dif == 0) {
        throw 'EL COMPROBANTE $ncfAffected YA FUE ANULADO COMPLETAMENTE';
      }
    }
  } catch (e) {
    rethrow;
  }
}

Future<double> getCreditNoteAmountByNcf({
  required String saleId,
  required String ncfAffected,
  required DateTime ncfAffectedCreatedAt,
}) async {
  try {
    String date = ncfAffectedCreatedAt.toUtc().format(payload: 'YYYY-MM-DD');

    var res = await apiUresax.get(
        '/creditnotes/get-credit-note-amount-by-ncf?saleId=$saleId&date=$date&ncfAffected=$ncfAffected');

    if (res.statusCode == 200) {
      var data = res.data;
      return double.parse(data['amountPaid'] ?? '0.00');
    }

    return 0.0;
  } on DioException catch (e) {
    throw e.response?.data['message'] ?? e.error.toString();
  }
}

Future<Map<String, dynamic>> getSalesReportGlobal(
    {required DateTime startDate,
    required DateTime endDate,
    String? ncfTypeId,
    List<String>? ncfsTypes,
    int? estadoDgii,
    List<int>? dgiiStates,
    SaleStatus? saleStatus}) async {
  try {
    var grayScaleBytes = await getUresaxLogoAsGrayScale();

    String date1 = startDate.toLocal().format(payload: 'DD/MM/YYYY');
    String date2 = endDate.toLocal().format(payload: 'DD/MM/YYYY');
    var query = [];
    var params = '';

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    var res = await apiUresax.get(
        '/reports/get-sales-report-global?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    var listNcfs = [];
    var listTypeIncomes = [];
    var listTypePayments = [];
    var listGravadas = [];
    var listRetentionTaxes = [];
    var listRetentionIsrs = [];

    if (res.statusCode == 200) {
      var data = res.data;
      listNcfs = data['listNcfs'];
      listTypeIncomes = data['listTypeIncomes'];
      listTypePayments = data['listTypePayments'];
      listGravadas = data['listGravadas'];
      listRetentionTaxes = data['listRetentionTaxes'];
      listRetentionIsrs = data['listRetentionIsrs'];
    }

    var columns1 = listNcfs.first.keys.toList();

    var columns2 = listTypeIncomes.first.keys.toList();

    var columns3 = listTypePayments.first.keys.toList();

    var columns4 = listGravadas.first.keys.toList();

    var columns5 = listRetentionTaxes.first.keys.toList();
    var columns6 = listRetentionIsrs.first.keys.toList();

    var doc = pw.Document();
    PdfColor color = PdfColor.fromHex('#CECECE');
    doc.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 8)),
          header: (ctx) {
            return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: pw.EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    child: pw.Text(company?.name ?? '',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    margin: pw.EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    child: pw.Text('${company?.name} - $date1 - $date2',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ]);
          },
          build: (ctx) {
            return [
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('REPORTE POR NCF',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Table(defaultColumnWidth: pw.FixedColumnWidth(40), children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color))),
                    children: List.generate(columns1.length, (index) {
                      var col = columns1[index];
                      return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(col,
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.left));
                    }))
              ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  children: List.generate(listNcfs.length, (i) {
                    var item = listNcfs[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontWeight: i == listNcfs.length - 1
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('REPORTE POR TIPO DE INGRESO',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Table(defaultColumnWidth: pw.FixedColumnWidth(40), children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color))),
                    children: List.generate(columns2.length, (index) {
                      var col = columns2[index];
                      return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(col,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)));
                    }))
              ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  children: List.generate(listTypeIncomes.length, (i) {
                    var item = listTypeIncomes[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontWeight:
                                          i == listTypeIncomes.length - 1
                                              ? pw.FontWeight.bold
                                              : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('TIPO DE VENTA',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Table(defaultColumnWidth: pw.FixedColumnWidth(40), children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color))),
                    children: List.generate(columns3.length, (index) {
                      var col = columns3[index];
                      return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(col,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)));
                    }))
              ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  children: List.generate(listTypePayments.length, (i) {
                    var item = listTypePayments[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontWeight:
                                          i == listTypePayments.length - 1
                                              ? pw.FontWeight.bold
                                              : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('GRAVADAS',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Table(defaultColumnWidth: pw.FixedColumnWidth(40), children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color))),
                    children: List.generate(columns4.length, (index) {
                      var col = columns4[index];
                      return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(col,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)));
                    }))
              ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  children: List.generate(listGravadas.length, (i) {
                    var item = listGravadas[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontWeight: i == listGravadas.length - 1
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('REPORTE DE RETENCIONES',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold))),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('RETENCION DE ITBIS',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Table(defaultColumnWidth: pw.FixedColumnWidth(40), children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color))),
                    children: List.generate(columns5.length, (index) {
                      var col = columns5[index];
                      return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(col,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)));
                    }))
              ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  children: List.generate(listRetentionTaxes.length, (i) {
                    var item = listRetentionTaxes[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontWeight:
                                          i == listRetentionTaxes.length - 1
                                              ? pw.FontWeight.bold
                                              : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('RETENCION DE ISR',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Table(
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  columnWidths: {
                    0: pw.FixedColumnWidth(150)
                  },
                  children: [
                    pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(columns6.length, (index) {
                          var col = columns6[index];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 3),
                              child: pw.Text(col,
                                  textAlign: pw.TextAlign.left,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)));
                        }))
                  ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FixedColumnWidth(40),
                  columnWidths: {0: pw.FixedColumnWidth(150)},
                  children: List.generate(listRetentionIsrs.length, (i) {
                    var item = listRetentionIsrs[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontWeight:
                                          i == listRetentionIsrs.length - 1
                                              ? pw.FontWeight.bold
                                              : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
            ];
          },
          footer: (ctx) {
            return pw.Container(
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                  pw.Expanded(
                      child: pw.Row(children: [
                    pw.Image(pw.MemoryImage(grayScaleBytes),
                        width: 20, height: 20),
                    pw.SizedBox(width: kDefaultPadding / 3),
                    pw.Text('POWER BY URESAX', textAlign: pw.TextAlign.left)
                  ])),
                  pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}'),
                  pw.Spacer()
                ]));
          }),
    );

    return {'document': doc, 'bytes': await doc.save()};
  } on DioException catch (e) {
    throw e.response?.data['message'];
  }
}

Future<Uint8List> getUresaxLogoAsGrayScale() async {
  try {
    var byteData =
        await rootBundle.load('assets/logos/uresax-invoice-logo.png');
    var uresaxLogoBytes = byteData.buffer.asUint8List();

    final original = img.decodeImage(uresaxLogoBytes);

    final grayscale = img.grayscale(original!);

    final grayscaleBytes = img.encodePng(grayscale);
    return grayscaleBytes;
  } catch (e) {
    rethrow;
  }
}

Future<List<int>?> generateExcelSalesReport(
    {required DateTime startDate,
    required DateTime endDate,
    required List<String>? ncfsTypes,
    required List<int>? dgiiStates,
    required SaleStatus? saleStatus}) async {
  try {
    String params = '';

    var query = [];

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    var sales = [];

    var res = await apiUresax.get(
        '/reports/get-sales-report-of-excel?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    if (res.statusCode == 200) {
      var data = res.data;
      sales = data['sales'];
    }

    var excel = Excel.createExcel();
    excel.delete('Sheet1');
    var shetName =
        '${startDate.toLocal().format(payload: 'YYYYMMDD')}${endDate.toLocal().format(payload: 'YYYYMMDD')}';

    var sheet = excel[shetName];

    var columns = sales[0].keys.toList();

    int spaceY = 8;

    var header =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3));
    header.value = TextCellValue(company?.name ?? '');
    header.cellStyle = CellStyle(fontSize: 30, bold: true);

    var rncCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 4));
    rncCell.value = TextCellValue(company?.rncOrId ?? '');
    rncCell.cellStyle = CellStyle(fontSize: 20, bold: true);

    var date =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 5));
    date.value = TextCellValue(
        '${startDate.format(payload: 'DD/MM/YYYY')} - ${endDate.format(payload: 'DD/MM/YYYY')}');
    date.cellStyle = CellStyle(fontSize: 20, bold: true);

    for (int i = 0; i < columns.length; i++) {
      var col = columns[i];
      sheet.setColumnWidth(i, 25);
      var cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: spaceY));

      cell.value = TextCellValue(col.toString());

      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        verticalAlign: VerticalAlign.Center,
        horizontalAlign: HorizontalAlign.Center,
        textWrapping: TextWrapping.WrapText,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('#419DE7'),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      for (int j = 0; j < sales.length; j++) {
        var item = sales[j];
        var value = item[col];

        var val = double.tryParse(value.toString());

        var cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: i, rowIndex: spaceY + j + 1));
        cell.value = val == null
            ? TextCellValue(value == null ? '' : value.toString())
            : DoubleCellValue(val);
        cell.cellStyle = CellStyle(
          bold: j == sales.length - 1 ? true : false,
          fontSize: 16,
          textWrapping: TextWrapping.WrapText,
          fontColorHex: ExcelColor.black,
          backgroundColorHex: ExcelColor.none,
          bottomBorder: Border(borderStyle: BorderStyle.Thin),
          topBorder: Border(borderStyle: BorderStyle.Thin),
          leftBorder: Border(borderStyle: BorderStyle.Thin),
          rightBorder: Border(borderStyle: BorderStyle.Thin),
        );
      }
    }
    return excel.save();
  } on DioException catch (e) {
    throw e.response?.data['message'];
  }
}

Future<Map<String, dynamic>> getSalesReportBoxes(
    {required DateTime startDate,
    required DateTime endDate,
    String? ncfTypeId,
    List<String>? ncfsTypes,
    int? estadoDgii,
    List<int>? dgiiStates,
    SaleStatus? saleStatus}) async {
  try {
    var grayScaleBytes = await getUresaxLogoAsGrayScale();

    String date1 = startDate.toLocal().format(payload: 'DD/MM/YYYY');
    String date2 = endDate.toLocal().format(payload: 'DD/MM/YYYY');
    var query = [];
    var params = '';

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    var res = await apiUresax.get(
        '/reports/get-sales-report-of-boxes?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    var listBoxes = [];
    var listBoxesUsers = [];

    if (res.statusCode == 200) {
      var data = res.data;

      listBoxes = data['listBoxes'];
      listBoxesUsers = data['listBoxesUsers'];
    }

    var columns1 = listBoxes.first.keys.toList();

    var columns2 = listBoxesUsers.first.keys.toList();

    var doc = pw.Document();
    PdfColor color = PdfColor.fromHex('#CECECE');
    doc.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.landscape,
          margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding, horizontal: kDefaultPadding * 0.8),
          theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 8)),
          header: (ctx) {
            return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: pw.EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    child: pw.Text(company?.name ?? '',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    margin: pw.EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    child: pw.Text('${company?.name} - $date1 - $date2',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ]);
          },
          build: (ctx) {
            return [
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('REPORTE POR CAJA',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold))),
              pw.Table(defaultColumnWidth: pw.FlexColumnWidth(), children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color))),
                    children: List.generate(columns1.length, (index) {
                      var col = columns1[index];
                      return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(col,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)));
                    }))
              ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FlexColumnWidth(),
                  children: List.generate(listBoxes.length, (i) {
                    var item = listBoxes[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: i == listBoxes.length - 1
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('REPORTE DE CAJA POR USUARIO',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold))),
              pw.Table(defaultColumnWidth: pw.FlexColumnWidth(), children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color))),
                    children: List.generate(columns2.length, (index) {
                      var col = columns2[index];
                      return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(col,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)));
                    }))
              ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FlexColumnWidth(),
                  children: List.generate(listBoxesUsers.length, (i) {
                    var item = listBoxesUsers[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: i == listBoxesUsers.length - 1
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
            ];
          },
          footer: (ctx) {
            return pw.Container(
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                  pw.Expanded(
                      child: pw.Row(children: [
                    pw.Image(pw.MemoryImage(grayScaleBytes),
                        width: 20, height: 20),
                    pw.SizedBox(width: kDefaultPadding / 3),
                    pw.Text('POWER BY URESAX', textAlign: pw.TextAlign.left)
                  ])),
                  pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}'),
                  pw.Spacer()
                ]));
          }),
    );

    return {'document': doc, 'bytes': await doc.save()};
  } on DioException catch (e) {
    throw e.response?.data['message'];
  }
}

Future<Map<String, dynamic>> getReportDebtsOfClients({
  String? ncfTypeId,
  List<String>? ncfsTypes,
  int? estadoDgii,
  List<int>? dgiiStates,
  SaleStatus? saleStatus,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    var grayScaleBytes = await getUresaxLogoAsGrayScale();

    var query = [];
    var params = '';

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    List<Map<String, dynamic>> debtsClients = [];
    List<Map<String, dynamic>> debtsNcfs = [];

    var res = await apiUresax.get(
        '/reports/get-sales-report-of-debts?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    if (res.statusCode == 200) {
      var data = res.data;
      debtsClients = List<Map<String, dynamic>>.from(
          (data['debtsClients'] as List).map((e) => e).toList());

      debtsNcfs = List<Map<String, dynamic>>.from(
          (data['debtsNcfs'] as List).map((e) => e).toList());
    }

    var list = debtsClients;
    var columns = list.first.keys.toList();

    var list2 = debtsNcfs;
    var columns2 = list2.first.keys.toList();

    print(columns);

    print(columns2);

    var doc = pw.Document();
    PdfColor color = PdfColor.fromHex('#CECECE');
    dynamic columnsW1 = {
      0: pw.FixedColumnWidth(60),
      1: pw.FlexColumnWidth(),
      2: pw.FlexColumnWidth(),
      3: pw.FlexColumnWidth(),
      4: pw.FlexColumnWidth(),
      5: pw.FlexColumnWidth()
    };

    dynamic columnsW2 = {
      0: pw.FixedColumnWidth(60),
      1: pw.FlexColumnWidth(),
      2: pw.FlexColumnWidth(),
      3: pw.FlexColumnWidth(),
      4: pw.FlexColumnWidth()
    };

    doc.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 8)),
          header: (ctx) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                    child: pw.Text(company?.name ?? '',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
                    child: pw.Text('REPORTE DE CUENTAS POR COBRAR',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    margin:
                        pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
                    child: pw.Text(
                        '${company?.name} - ${startDate.toLocal().format(payload: 'DD/MM/YYYY')} - ${endDate.toLocal().format(payload: 'DD/MM/YYYY')}',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
          build: (ctx) => [
                pw.Table(
                  columnWidths: columnsW1,
                  children: [
                    pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      decoration: pw.BoxDecoration(
                          border:
                              pw.Border(bottom: pw.BorderSide(color: color))),
                      children: columns2
                          .map((col) => pw.Padding(
                                padding: pw.EdgeInsets.only(
                                    top: kDefaultPadding / 3,
                                    bottom: kDefaultPadding / 3,
                                    right: kDefaultPadding / 3),
                                child: pw.Text(col,
                                    textAlign: pw.TextAlign.left,
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                              ))
                          .toList(),
                    )
                  ],
                ),
                pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  columnWidths: columnsW1,
                  children: list2.map((item) {
                    var index = list2.indexOf(item);
                    var values = columns2.map((k) => item[k]).toList();
                    bool isTotal = index == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color)),
                      ),
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: values
                          .map((el) => pw.Padding(
                                padding: pw.EdgeInsets.symmetric(
                                    vertical: kDefaultPadding / 3),
                                child: pw.Text(el.toString(),
                                    style: pw.TextStyle(
                                      fontWeight: isTotal
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal,
                                    ),
                                    textAlign: pw.TextAlign.left),
                              ))
                          .toList(),
                    );
                  }).toList(),
                ),
                pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
                  child: pw.Text('REPORTE DE CUENTAS POR COBRAR POR CLIENTE',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Table(
                  columnWidths: columnsW2,
                  children: [
                    pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      decoration: pw.BoxDecoration(
                          border:
                              pw.Border(bottom: pw.BorderSide(color: color))),
                      children: columns
                          .map((col) => pw.Padding(
                                padding: pw.EdgeInsets.only(
                                    top: kDefaultPadding / 3,
                                    bottom: kDefaultPadding / 3,
                                    right: kDefaultPadding / 3),
                                child: pw.Text(col,
                                    textAlign: pw.TextAlign.left,
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                              ))
                          .toList(),
                    )
                  ],
                ),
                pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  columnWidths: columnsW2,
                  children: list.map((item) {
                    var index = list.indexOf(item);
                    var values = columns.map((k) => item[k]).toList();
                    bool isTotal = index == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color)),
                      ),
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: values
                          .map((el) => pw.Padding(
                                padding: pw.EdgeInsets.symmetric(
                                    vertical: kDefaultPadding / 3),
                                child: pw.Text(el.toString(),
                                    style: pw.TextStyle(
                                      fontWeight: isTotal
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal,
                                    ),
                                    textAlign: pw.TextAlign.left),
                              ))
                          .toList(),
                    );
                  }).toList(),
                ),
              ],
          footer: (ctx) {
            return pw.Container(
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                  pw.Expanded(
                      child: pw.Row(children: [
                    pw.Image(pw.MemoryImage(grayScaleBytes),
                        width: 20, height: 20),
                    pw.SizedBox(width: kDefaultPadding / 3),
                    pw.Text('POWER BY URESAX', textAlign: pw.TextAlign.left)
                  ])),
                  pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.Spacer()
                ]));
          }),
    );

    return {'list': list, 'document': doc, 'bytes': await doc.save()};
  } on DioException catch (e) {
    throw e.response?.data['message'];
  }
}

Future<Map<String, dynamic>> getSalesReportByConcepts(
    {required DateTime startDate,
    required DateTime endDate,
    String? ncfTypeId,
    List<String>? ncfsTypes,
    int? estadoDgii,
    List<int>? dgiiStates,
    SaleStatus? saleStatus}) async {
  try {
    var grayScaleBytes = await getUresaxLogoAsGrayScale();

    String date1 = startDate.toLocal().format(payload: 'DD/MM/YYYY');
    String date2 = endDate.toLocal().format(payload: 'DD/MM/YYYY');
    var query = [];
    var params = '';

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    var res = await apiUresax.get(
        '/reports/get-sales-report-by-concepts?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    var listConcepts = [];

    if (res.statusCode == 200) {
      var data = res.data;

      listConcepts = data['listConcepts'];
    }

    var columns1 = listConcepts.first.keys.toList();

    var doc = pw.Document();
    PdfColor color = PdfColor.fromHex('#CECECE');
    doc.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.landscape,
          margin: pw.EdgeInsets.symmetric(
              vertical: kDefaultPadding, horizontal: kDefaultPadding * 0.8),
          theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 8)),
          header: (ctx) {
            return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: pw.EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    child: pw.Text(company?.name ?? '',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    margin: pw.EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    child: pw.Text('${company?.name} - $date1 - $date2',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ]);
          },
          build: (ctx) {
            return [
              pw.Container(
                  margin:
                      pw.EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                  child: pw.Text('REPORTE POR CONCEPTO',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold))),
              pw.Table(defaultColumnWidth: pw.FlexColumnWidth(), children: [
                pw.TableRow(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: color))),
                    children: List.generate(columns1.length, (index) {
                      var col = columns1[index];
                      return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 3),
                          child: pw.Text(col,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)));
                    }))
              ]),
              pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.bottom,
                  defaultColumnWidth: pw.FlexColumnWidth(),
                  children: List.generate(listConcepts.length, (i) {
                    var item = listConcepts[i];
                    var values = item.values.toList();
                    return pw.TableRow(
                        decoration: pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(color: color))),
                        children: List.generate(values.length, (j) {
                          var el = values[j];
                          return pw.Padding(
                              padding: pw.EdgeInsets.symmetric(
                                  vertical: kDefaultPadding / 2),
                              child: pw.Text(el.toString(),
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: i == listConcepts.length - 1
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal),
                                  textAlign: pw.TextAlign.left));
                        }));
                  })),
            ];
          },
          footer: (ctx) {
            return pw.Container(
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                  pw.Expanded(
                      child: pw.Row(children: [
                    pw.Image(pw.MemoryImage(grayScaleBytes),
                        width: 20, height: 20),
                    pw.SizedBox(width: kDefaultPadding / 3),
                    pw.Text('POWER BY URESAX', textAlign: pw.TextAlign.left)
                  ])),
                  pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}'),
                  pw.Spacer()
                ]));
          }),
    );

    return {'document': doc, 'bytes': await doc.save()};
  } on DioException catch (e) {
    throw e.response?.data['message'];
  }
}

Future<Map<String, dynamic>> getSalesReportBoxesByHour(
    {required DateTime startDate,
    required DateTime endDate,
    String? ncfTypeId,
    List<String>? ncfsTypes,
    int? estadoDgii,
    List<int>? dgiiStates,
    SaleStatus? saleStatus}) async {
  try {
    var grayScaleBytes = await getUresaxLogoAsGrayScale();

    String date1 = startDate.toLocal().format(payload: 'DD/MM/YYYY');
    String date2 = endDate.toLocal().format(payload: 'DD/MM/YYYY');

    var query = [];
    var params = '';

    if (ncfsTypes != null && ncfsTypes.isNotEmpty) {
      query.add('ncfsTypes=${ncfsTypes.join(',')}');
    }

    if (dgiiStates != null && dgiiStates.isNotEmpty) {
      query.add('dgiiStates=${dgiiStates.join(',')}');
    }

    if (saleStatus == SaleStatus.paid) {
      query.add('paidStatus=paid');
    }

    if (saleStatus == SaleStatus.notPaid) {
      query.add('paidStatus=pending');
    }

    params = '&${query.join('&')}';

    var res = await apiUresax.get(
        '/reports/get-sales-report-by-boxes-pos?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

    var listPOS = [];

    if (res.statusCode == 200) {
      var data = res.data;
      listPOS = data['listPOS'];
    }

    var doc = pw.Document();
    PdfColor color = PdfColor.fromHex('#CECECE');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: pw.EdgeInsets.symmetric(
            vertical: kDefaultPadding, horizontal: kDefaultPadding * 0.8),
        theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(fontSize: 9)),
        header: (ctx) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(company?.name ?? '',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('REPORTE DE CAJA POR HORA - $date1 al $date2',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]);
        },
        build: (ctx) {
          return [
            ...listPOS.map((item) {
              return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 10),
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: color, width: 0.5),
                      borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${item["CAJA"]}',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('HORA: ${item["HORA"]}',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(
                            'CANTIDAD FACTURAS: ${item["CANTIDAD FACTURAS"]}'),
                        pw.Text('MONTO NETO: ${item["MONTO NETO"]}'),
                        pw.Text('TOTAL ITBIS: ${item["TOTAL ITBIS"]}'),
                        pw.Text('PROPINA LEGAL: ${item["PROPINA LEGAL"]}'),
                        pw.Text('EXENTO: ${item["EXENTO"]}'),
                        pw.Text('MONTO TOTAL: ${item["MONTO TOTAL"]}'),
                        pw.Text('MONTO PAGADO: ${item["MONTO PAGADO"]}'),
                        pw.SizedBox(height: 5),
                        pw.Text('EFECTIVO: ${item["EFECTIVO"]}'),
                        pw.Text('TARJETA: ${item["TARJETA"]}'),
                        pw.Text(
                            'CHEQUE/TRANSFERENCIA: ${item["CHEQUE/TRANSFERENCIA"]}'),
                        pw.Text('VENTA A CRÉDITO: ${item["VENTA A CRÉDITO"]}'),
                      ]));
            }),
          ];
        },
        footer: (ctx) {
          return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(children: [
                  pw.Image(pw.MemoryImage(grayScaleBytes),
                      width: 20, height: 20),
                  pw.SizedBox(width: 5),
                  pw.Text('POWER BY URESAX')
                ]),
                pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}'),
              ]);
        },
      ),
    );

    return {'document': doc, 'bytes': await doc.save()};
  } on DioException catch (e) {
    throw e.response?.data['message'];
  }
}
