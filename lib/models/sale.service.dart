import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.service.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';

class SaleService implements Sale {
  @override
  String? id;
  @override
  String? clientId;
  @override
  String? ncf;
  @override
  String? ncfAffected;
  @override
  double? discount;
  @override
  double? net;
  @override
  double? tax;
  @override
  double? total;
  @override
  double? effective;
  @override
  double? creditCard;
  @override
  double? checkOrTransf;
  @override
  double? saleToCredit;
  @override
  double? law10;
  @override
  String? typeIncomeId;
  @override
  int? clientType;
  @override
  DateTime? createdAt;
  @override
  double? retentionTax;
  @override
  double? retentionIsr;
  @override
  int? paymentMethodId;
  @override
  String? ncfTypeId;
  @override
  String? saleId;
  SaleService(
      {this.id,
      this.clientId,
      this.ncf,
      this.ncfAffected,
      this.discount,
      this.net,
      this.netFinal,
      this.tax,
      this.total,
      this.effective,
      this.creditCard,
      this.checkOrTransf,
      this.saleToCredit,
      this.law10,
      this.typeIncomeId,
      this.clientType,
      this.createdAt,
      this.retentionTax,
      this.retentionIsr,
      this.paymentMethodId,
      this.ncfTypeId,
      this.saleId,
      this.items = const [],
      this.description,
      this.clientName,
      this.retentionDate,
      this.prefix,
      this.clientTypeName,
      this.ncfTypeName,
      this.paymentMethodName,
      this.typeIncomeName,
      this.invoiceTypeId,
      this.paid,
      this.amountPaid,
      this.debt,
      this.bankId,
      this.transfRef,
      this.currencyId,
      this.rate,
      this.maxSequence,
      this.tax18,
      this.tax16,
      this.tax3,
      this.net18,
      this.net16,
      this.net3,
      this.exemptAmount,
      this.authorId,
      this.dgiiURL,
      this.ecfXmlFirmado,
      this.estadoDgii,
      this.estadoDgiiNombre,
      this.expirationDate,
      this.securityCode,
      this.signatureDate,
      this.tipoPago,
      this.authorName,
      this.ncfSeq,
      this.ncfAffectedCreatedAt,
      this.clientAddress,
      this.coinBack,
      this.issueDate,
      this.clientIdentification,
      this.paymentDate,
      this.clientPhone,
      this.clientEmail,
      this.message,
      this.refInvoiceId,
      this.enabledDollarInvoice = false,
      this.netLocal = 0,
      this.discountLocal = 0,
      this.debtLocal = 0,
      this.netFinalLocal = 0,
      this.net18Local = 0,
      this.net16Local = 0,
      this.net3Local = 0,
      this.tax18Local = 0,
      this.tax16Local = 0,
      this.tax3Local = 0,
      this.exemptAmountLocal = 0,
      this.retentionTaxLocal = 0,
      this.retentionIsrLocal = 0,
      this.law10Local = 0,
      this.taxLocal = 0,
      this.totalLocal = 0,
      this.cashShiftId,
      this.creditCardDescription,
      this.brancheId,
      this.brancheName,
      this.branchePhone1,
      this.branchePhone2,
      this.brancheAddress,
      this.brancheEmail
   });

  SaleService copyWith({
    String? id,
    String? clientId,
    String? ncf,
    String? ncfAffected,
    double? discount,
    double? net,
    double? tax,
    double? total,
    double? effective,
    double? creditCard,
    double? checkOrTransf,
    double? saleToCredit,
    double? law10,
    String? typeIncomeId,
    int? clientType,
    DateTime? createdAt,
    double? retentionTax,
    double? retentionIsr,
    int? paymentMethodId,
    String? ncfTypeId,
    String? saleId,
  }) {
    return SaleService(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      ncf: ncf ?? this.ncf,
      ncfAffected: ncfAffected ?? this.ncfAffected,
      discount: discount ?? this.discount,
      net: net ?? this.net,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      effective: effective ?? this.effective,
      creditCard: creditCard ?? this.creditCard,
      checkOrTransf: checkOrTransf ?? this.checkOrTransf,
      saleToCredit: saleToCredit ?? this.saleToCredit,
      law10: law10 ?? this.law10,
      typeIncomeId: typeIncomeId ?? this.typeIncomeId,
      clientType: clientType ?? this.clientType,
      createdAt: createdAt ?? this.createdAt,
      retentionTax: retentionTax ?? this.retentionTax,
      retentionIsr: retentionIsr ?? this.retentionIsr,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      ncfTypeId: ncfTypeId ?? this.ncfTypeId,
      saleId: saleId ?? this.saleId,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'ncf': ncf,
      'ncfAffected': ncfAffected,
      'discount': discount,
      'net': net,
      'tax': tax,
      'total': total,
      'effective': effective,
      'creditCard': creditCard,
      'checkOrTransf': checkOrTransf,
      'saleToCredit': saleToCredit,
      'law10': law10,
      'typeIncomeId': typeIncomeId,
      'clientType': clientType,
      'createdAt': createdAt,
      'issueDate': issueDate,
      'retentionTax': retentionTax,
      'retentionIsr': retentionIsr,
      'paymentMethodId': paymentMethodId,
      'ncfTypeId': ncfTypeId,
      'saleId': saleId,
      'items': items.map((e) => e.toMap()).toList(),
      'description': description,
      'retentionDate': retentionDate,
      'prefix': prefix,
      'invoiceTypeId': invoiceTypeId,
      'amountPaid': amountPaid,
      'debt': debt,
      'currencyId': currencyId,
      'rate': rate,
      'maxSequence': maxSequence,
      'cashShiftId':cashShiftId,
      'creditCardDescription':creditCardDescription,
      'brancheId': brancheId
    };
  }

  @override
  Map<String, dynamic> toDisplay() {
    return {
      'RNC/Cédula o Pasaporte': clientIdentification?.replaceAll('-', ''),
      'Tipo Identificación': clientType.toString(),
      'Número Comprobante Fiscal': ncf,
      'Número Comprobante Fiscal Modificado': ncfAffected ?? 'S/N',
      'Tipo de Ingreso': typeIncomeId,
      'Fecha Comprobante': createdAt?.format(payload: 'YYYYMMDD'),
      'Fecha de Retención': retentionDate?.format(payload: 'YYYYMMDD') ?? 'S/N',
      'Monto Facturado': net?.toStringAsFixed(2) ?? '0.00',
      'ITBIS Facturado': tax?.toStringAsFixed(2) ?? '0.00',
      'ITBIS Retenido por Terceros': retentionTax?.toStringAsFixed(2) ?? '0.00',
      'ITBIS Percibido': '0.00',
      'Retención Renta por Terceros':
          retentionIsr?.toStringAsFixed(2) ?? '0.00',
      'ISR Percibido': '0.00',
      'Impuesto Selectivo al Consumo': '0.00',
      'Otros Impuestos/Tasas': '0.00',
      'Monto Propina Legal': law10?.toStringAsFixed(2) ?? '0.00',
      'Efectivo': effective?.toStringAsFixed(2) ?? '0.00',
      'Cheque/ Transferencia/ Depósito':
          checkOrTransf?.toStringAsFixed(2) ?? '0.00',
      'Tarjeta Débito/Crédito': creditCard?.toStringAsFixed(2) ?? '0.00',
      'Venta a Crédito': saleToCredit?.toStringAsFixed(2) ?? '0.00',
      'Bonos o Certificados de Regalo': '0.00',
      'Permuta': '0.00',
      'Otras Formas de Ventas': '0.00'
    };
  }

  @override
  Map<String, dynamic> toMapInsert() {
    return {
      'clientId': clientId,
      'clientIdentification': clientIdentification,
      'clientName': clientName,
      'discount': discount,
      'net': net,
      'tax': tax,
      'total': total,
      'effective': effective,
      'creditCard': creditCard,
      'checkOrTransf': checkOrTransf,
      'saleToCredit': saleToCredit,
      'law10': law10,
      'typeIncomeId': typeIncomeId,
      'clientType': clientType,
      'retentionTax': retentionTax,
      'retentionIsr': retentionIsr,
      'ncfTypeId': ncfTypeId,
      'description': description,
      'retentionDate': retentionDate?.toIso8601String(),
      'prefix': prefix,
      'invoiceTypeId': invoiceTypeId,
      'currencyId': currencyId,
      'rate': rate,
      'maxSequence': maxSequence,
      'createdAt': createdAt?.toIso8601String(),
      'tax18': tax18,
      'tax16': tax16,
      'tax3': tax3,
      'net18': net18,
      'net16': net16,
      'net3': net3,
      'exemptAmount': exemptAmount,
      'expirationDate': expirationDate?.toIso8601String(),
      'tipoPago': tipoPago,
      'authorId': authorId,
      'paid': paid,
      'coinBack': coinBack,
      'issueDate': issueDate?.toIso8601String(),
      'paidInvoice':paidInvoice,
      'refInvoiceId': refInvoiceId,
      'paymentMethodId':paymentMethodId,
      'bankId':bankId,
      'transfRef':transfRef,
      'paymentDate':paymentDate?.toIso8601String(),
      'cashShiftId':cashShiftId,
      'creditCardDescription':creditCardDescription,
      'brancheId': brancheId
    };
  }

  factory SaleService.fromMap(Map<String, dynamic> map) {

 
    return SaleService(
        id: map['id'],
        refInvoiceId: map['refInvoiceId'],
        clientId: map['clientId'],
        clientIdentification: map['clientIdentification'],
        ncf: map['ncf'],
        ncfAffected: map['ncfAffected'],
        discount:
            map['discount'] != null ? double.parse(map['discount']) : null,
        net: double.parse(map['net']),
        netFinal:
            map['netFinal'] != null ? double.parse(map['netFinal']) : null,
        tax: double.parse(map['tax']),
        total: map['total'] != null ? double.parse(map['total']) : null,
        effective: double.parse(map['effective']),
        creditCard: double.parse(map['creditCard']),
        checkOrTransf: double.parse(map['checkOrTransf']),
        saleToCredit: double.parse(map['saleToCredit']),
        law10: double.parse(map['law10']),
        typeIncomeId: map['typeIncomeId'],
        clientType: map['clientType'],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : null,
        retentionTax: double.parse(map['retentionTax']),
        retentionIsr: double.parse(map['retentionIsr']),
        paymentMethodId: map['paymentMethodId'],
        ncfTypeId: map['ncfTypeId'],
        saleId: map['saleId'],
        description: map['description'],
        retentionDate: map['retentionDate'] != null
            ? DateTime.parse(map['retentionDate'])
            : null,
        prefix: map['prefix'],
        typeIncomeName: map['typeIncomeName'],
        paymentMethodName: map['paymentMethodName'],
        clientTypeName: map['clientTypeName'],
        ncfTypeName: map['ncfTypeName'],
        clientName: map['clientName'],
        invoiceTypeId: map['invoiceTypeId'],
        expirationDate: map['expirationDate'] != null
            ? DateTime.parse(map['expirationDate'])
            : null,
        items: map['items'] != null
            ? List<SaleItemService>.from(
                    map['items']?.map((x) => SaleItemService.fromMap(x)))
                .cast<SaleItemService>()
            : [],
        amountPaid:
            map['amountPaid'] != null ? double.parse(map['amountPaid']) : null,
        debt: map['debt'] != null ? double.parse(map['debt']) : null,
        currencyId: map['currencyId'],
        rate: map['rate'] != null ? double.parse(map['rate']) : null,
        tax18: map['tax18'] != null ? double.parse(map['tax18']) : null,
        tax16: map['tax16'] != null ? double.parse(map['tax16']) : null,
        tax3: map['tax3'] != null ? double.parse(map['tax3']) : null,
        net18: map['net18'] != null ? double.parse(map['net18']) : null,
        net16: map['net16'] != null ? double.parse(map['net16']) : null,
        net3: map['net3'] != null ? double.parse(map['net3']) : null,
        exemptAmount: map['exemptAmount'] != null
            ? double.parse(map['exemptAmount'])
            : null,
        dgiiURL: map['dgiiURL'],
        ecfXmlFirmado: map['ecfXmlFirmado'],
        estadoDgii: map['estadoDgii'],
        estadoDgiiNombre: map['estadoDgiiNombre'],
        securityCode: map['securityCode'],
        signatureDate: map['signatureDate'] != null
            ? DateTime.parse(map['signatureDate'])
            : null,
        tipoPago: map['tipoPago'],
        authorId: map['authorId'],
        authorName: map['authorName'],
        ncfSeq: map['ncfSeq'],
        clientAddress: map['clientAddress'],
        paid: map['paid'] != null ? double.parse(map['paid']) : null,
        coinBack:
            map['coinBack'] != null ? double.parse(map['coinBack']) : null,
        issueDate: map['issueDate'] != null
            ? DateTime.parse(map['issueDate'])
            : null,
        clientPhone: map['clientPhone'],
        clientEmail: map['clientEmail'],
        message: map['message'],
        enabledDollarInvoice: map['enabledDollarInvoice'] ?? false,
        netLocal: map['netLocal'] != null ? double.parse(map['netLocal']) : 0,
        discountLocal: map['discountLocal'] != null
            ? double.parse(map['discountLocal'])
            : 0,
        taxLocal: map['taxLocal'] != null ? double.parse(map['taxLocal']) : 0,
        totalLocal: map['totalLocal'] != null ? double.parse(map['totalLocal']) : 0,
        debtLocal: map['debtLocal'] != null ? double.parse(map['debtLocal']) : 0,
        netFinalLocal: map['netFinalLocal'] != null ? double.parse(map['netFinalLocal']) : 0,
        net18Local: map['net18Local'] != null ? double.parse(map['net18Local']) : 0,
        net16Local: map['net16Local'] != null ? double.parse(map['net16Local']) : 0,
        net3Local: map['net3Local'] != null ? double.parse(map['net3Local']) : 0,
        tax18Local: map['tax18Local'] != null ? double.parse(map['tax18Local']) : 0,
        tax16Local: map['tax16Local'] != null ? double.parse(map['tax16Local']) : 0,
        tax3Local: map['tax3Local'] != null ? double.parse(map['tax3Local']) : 0,
        law10Local: map['law10Local'] != null ? double.parse(map['law10Local']) : 0,
        exemptAmountLocal: map['exemptAmountLocal'] != null
            ? double.parse(map['exemptAmountLocal'])
            : 0,
        retentionTaxLocal: map['retentionTaxLocal'] != null
            ? double.parse(map['retentionTaxLocal'])
            : 0,
        retentionIsrLocal: map['retentionIsrLocal'] != null
            ? double.parse(map['retentionIsrLocal'])
            : 0,
      creditCardDescription: map['creditCardDescription'],
      brancheId: map['brancheId'],
      brancheName: map['brancheName'],
      branchePhone1: map['branchePhone1'],
      branchePhone2: map['branchePhone2'],
      brancheAddress: map['brancheAddress'],
      brancheEmail: map['brancheEmail']
      );
  }

  String toJson() => json.encode(toMap());

  factory SaleService.fromJson(String source) =>
      SaleService.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SaleService(id: $id, clientId: $clientId, ncf: $ncf, ncfAffected: $ncfAffected, discount: $discount, net: $net, tax: $tax, total: $total, effective: $effective, creditCard: $creditCard, checkOrTransf: $checkOrTransf, saleToCredit: $saleToCredit, law10: $law10, typeIncomeId: $typeIncomeId, clientType: $clientType, createdAt: $createdAt, retentionTax: $retentionTax, retentionIsr: $retentionIsr, paymentMethodId: $paymentMethodId, ncfTypeId: $ncfTypeId, saleId: $saleId, clientAddress: $clientAddress, enabledDollarInvoice: $enabledDollarInvoice, creditCardDescription: $creditCardDescription,brancheId: $brancheId, brancheName: $brancheName, branchePhone1: $branchePhone1, branchePhone2: $branchePhone2, brancheAddress: $brancheAddress, brancheEmail: $brancheEmail)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is SaleService &&
        o.id == id &&
        o.clientId == clientId &&
        o.ncf == ncf &&
        o.ncfAffected == ncfAffected &&
        o.discount == discount &&
        o.net == net &&
        o.tax == tax &&
        o.total == total &&
        o.effective == effective &&
        o.creditCard == creditCard &&
        o.checkOrTransf == checkOrTransf &&
        o.saleToCredit == saleToCredit &&
        o.law10 == law10 &&
        o.typeIncomeId == typeIncomeId &&
        o.clientType == clientType &&
        o.createdAt == createdAt &&
        o.retentionTax == retentionTax &&
        o.retentionIsr == retentionIsr &&
        o.paymentMethodId == paymentMethodId &&
        o.ncfTypeId == ncfTypeId &&
        o.saleId == saleId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clientId.hashCode ^
        ncf.hashCode ^
        ncfAffected.hashCode ^
        discount.hashCode ^
        net.hashCode ^
        tax.hashCode ^
        total.hashCode ^
        effective.hashCode ^
        creditCard.hashCode ^
        checkOrTransf.hashCode ^
        saleToCredit.hashCode ^
        law10.hashCode ^
        typeIncomeId.hashCode ^
        clientType.hashCode ^
        createdAt.hashCode ^
        retentionTax.hashCode ^
        retentionIsr.hashCode ^
        paymentMethodId.hashCode ^
        ncfTypeId.hashCode ^
        saleId.hashCode;
  }

  @override
  Future<SaleService?> create() async {
    try {
      var map = toMapInsert();

      var res = await apiUresax.post('/sales/create-sale-service', data: {
        ...map,
        'ncfListId':ncfListId, 
        'boxId': currentUser?.boxId,
        'items': items.map((e) => e.toMap()).toList()
      });

      if (res.statusCode == 200) {
        return SaleService.fromMap(res.data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<bool?> delete() async {
    try {
      var res = await apiUresax.delete('/sales/delete-sale-service/$id',
          data: {'ncfSeq': ncfSeq, 'ncfTypeId': ncfTypeId});

      if (res.statusCode == 200) {
        return true;
      }

      return false;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  static Future<List<SaleService>> getSales607Form(
      {required String period}) async {
    try {
      var res = await apiUresax.get('/sales/get-sales-607?period=$period');

      if(res.statusCode ==200){
       var data = res.data;
         var list = List<SaleService>.from(
            (data as List).map((x) => SaleService.fromMap(x)));
            return list;
      }

      return [];

    }on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<SaleService?> update() async {
    try {
  
      var res = await apiUresax.put('/sales/update-sale-service/$id', data: {
        'description': description,
        'discount': discount,
        'net': net,
        'tax': tax,
        'total': total,
        'retentionTax': retentionTax,
        'retentionIsr': retentionIsr,
        'effective': effective,
        'creditCard': creditCard,
        'checkOrTransf': checkOrTransf,
        'saleToCredit': saleToCredit,
        'retentionDate': retentionDate?.toIso8601String(),
        'currencyId': currencyId,
        'rate': rate,
        'tax18': tax18,
        'tax16': tax16,
        'tax3': tax3,
        'net18': net18,
        'net16': net16,
        'net3': net3,
        'exemptAmount': exemptAmount,
        'paid': paid,
        'coinBack': coinBack,
        'issueDate': issueDate?.toIso8601String(),
        'paymentMethodId':paymentMethodId,
        'bankId':bankId,
        'transfRef':transfRef,
        'paidInvoice':paidInvoice,
        'paymentDate':paymentDate?.toIso8601String(),
        'items': items.map((e) => e.toMap()).toList()
      });

      if (res.statusCode == 200) {
        return SaleService.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<Sale?> paySale(double amount) async {
    try {
      var res =
          await apiUresax.post('/payments/create-pay-sale-service/$id', data: {
        'paymentMethodId': paymentMethodId,
        'bankId': bankId,
        'transfRef': transfRef,
        'amount': amount,
        'paymentDate': paymentDate?.toIso8601String(),
        'effective': effective,
        'creditCard': creditCard,
        'checkOrTransf': checkOrTransf,
        'saleToCredit': saleToCredit,
        'paid': paid,
        'coinBack': coinBack,
        'creditCardDescription':creditCardDescription
      });

      if (res.statusCode == 200) {
        return SaleService.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<Sale?> findById(String id) {
    // TODO: implement findById
    throw UnimplementedError();
  }

  @override
  List<SaleItem> items;

  @override
  String? description;

  @override
  String? clientName;

  @override
  DateTime? retentionDate;

  @override
  String? prefix;

  @override
  String? clientTypeName;

  @override
  String? ncfTypeName;

  @override
  String? paymentMethodName;

  @override
  String? typeIncomeName;

  @override
  Map<String, dynamic> to607() {
    return {
      'RNC/Cédula o Pasaporte': clientId?.replaceAll('-', ''),
      'Tipo Identificación': clientType.toString(),
      'Número Comprobante Fiscal': ncf,
      'Número Comprobante Fiscal Modificado': ncfAffected ?? '',
      'Tipo de Ingreso': typeIncomeId,
      'Fecha Comprobante': createdAt?.format(payload: 'YYYYMMDD'),
      'Fecha de Retención': retentionDate?.format(payload: 'YYYYMMDD') ?? '',
      'Monto Facturado': net?.toStringAsFixed(2) ?? '0.00',
      'ITBIS Facturado': tax?.toStringAsFixed(2) ?? '0.00',
      'ITBIS Retenido por Terceros': retentionTax?.toStringAsFixed(2) ?? '0.00',
      'ITBIS Percibido': '0.00',
      'Retención Renta por Terceros':
          retentionIsr?.toStringAsFixed(2) ?? '0.00',
      'ISR Percibido': '0.00',
      'Impuesto Selectivo al Consumo': '0.00',
      'Otros Impuestos/Tasas': '0.00',
      'Monto Propina Legal': law10?.toStringAsFixed(2) ?? '0.00',
      'Efectivo': effective?.toStringAsFixed(2) ?? '0.00',
      'Cheque/ Transferencia/ Depósito':
          checkOrTransf?.toStringAsFixed(2) ?? '0.00',
      'Tarjeta Débito/Crédito': creditCard?.toStringAsFixed(2) ?? '0.00',
      'Venta a Crédito': saleToCredit?.toStringAsFixed(2) ?? '0.00',
      'Bonos o Certificados de Regalo': '0.00',
      'Permuta': '0.00',
      'Otras Formas de Ventas': '0.00'
    };
  }

  @override
  int? invoiceTypeId;

  @override
  double? paid;

  @override
  double? amountPaid;

  @override
  double? debt;

  @override
  bool get isPaid {
    return debt! <= 0 ? true : false;
  }

  @override
  Color get color {
    if (isPaid) return Colors.green;
    return Colors.red;
  }

  @override
  String get paidLabel {
    if (isPaid) return 'PAGADO';
    return 'PENDIENTE';
  }

  get conne => null;

  @override
  Future<List<SaleItem>> getSaleData() async {
    try {
      var res = await apiUresax.get('/sales/get-sale-items-services/$id');

      if (res.statusCode == 200) {
        var data = res.data;
        var list = List<SaleItemService>.from(
            (data as List).map((x) => SaleItemService.fromMap(x)));
        return list;
      }
      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  int? bankId;

  @override
  String? transfRef;

  @override
  int? currencyId;

  @override
  double? rate;

  @override
  int? maxSequence;

  @override
  String? authorId;

  @override
  String? dgiiURL;

  @override
  String? ecfXmlFirmado;

  @override
  int? estadoDgii;

  @override
  double? exemptAmount;

  @override
  DateTime? expirationDate;

  @override
  double? net16;

  @override
  double? net18;

  @override
  double? net3;

  @override
  String? securityCode;

  @override
  DateTime? signatureDate;

  @override
  double? tax16;

  @override
  double? tax18;

  @override
  double? tax3;

  @override
  int? tipoPago;

  @override
  String? authorName;

  @override
  Future<void> updateEcfInfo() async {
    try {
      var res = await apiUresax.put('/sales/update-ecf-info/$id', data: {
        'signatureDate': signatureDate?.toIso8601String(),
        'securityCode': securityCode,
        'dgiiURL': dgiiURL,
        'ecfXmlFirmado': base64Encode(utf8.encode(ecfXmlFirmado!)),
        'estadoDgii': estadoDgii
      });
      if (res.statusCode == 200) {
        if (res.statusCode == 200) {
          estadoDgiiNombre = res.data['estadoDgiiNombre'];
        }
      }
    }on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  int? ncfSeq;

  @override
  String? estadoDgiiNombre;

  @override
  DateTime? ncfAffectedCreatedAt;

  @override
  String? clientAddress;

  @override
  Color get statusColorDgii {
    if (estadoDgii == 1) {
      return const Color(0xFF368D39);
    } else if (estadoDgii == 3) {
      return Colors.orange;
    } else if (estadoDgii == 2) {
      return Colors.red;
    } else if (estadoDgii == 4) {
      return const Color(0xFF368D39);
    }
    return Colors.grey;
  }

  @override
  Future<void> updateStock() {
    // TODO: implement updateStock
    throw UnimplementedError();
  }

  @override
  double? coinBack;

  @override
  double? paidInvoice;

  @override
  DateTime? issueDate;

  @override
  String? clientIdentification;

  @override
  DateTime? paymentDate;

  @override
  String? clientPhone;

  @override
  String get clientIdentificationFormat {
    return clientIdentification?.length == 11
        ? clientIdentification?.toUpperCase().formatPatterns('###-#######-#') ??
            ''
        : clientIdentification?.toUpperCase().formatPatterns('###-#####-#') ??
            '';
  }

  @override
  double? netFinal;

  @override
  String? clientEmail;

  @override
  String? message;

  @override
  String? refInvoiceId;

  @override
  int? ncfListId;

  @override
  bool? enabledDollarInvoice;

  @override
  double? amountPaidLocal;

  @override
  double? checkOrTransfLocal;

  @override
  double? creditCardLocal;

  @override
  double? debtLocal;

  @override
  double? discountLocal;

  @override
  double? effectiveLocal;

  @override
  double? exemptAmountLocal;

  @override
  double? law10Local;

  @override
  double? net16Local;

  @override
  double? net18Local;

  @override
  double? net3Local;

  @override
  double? netFinalLocal;

  @override
  double? netLocal;

  @override
  double? retentionIsrLocal;

  @override
  double? retentionTaxLocal;

  @override
  double? saleToCreditLocal;

  @override
  double? tax16Local;

  @override
  double? tax18Local;

  @override
  double? tax3Local;

  @override
  double? taxLocal;

  @override
  double? totalLocal;

  @override
  String get amountPaidLabel {
   if(enabledDollarInvoice == true){
       return  (totalLocal! - (retentionIsrLocal! + retentionTaxLocal!)).toDop();
   }

   return  currencyId == 1 ? (total! -(retentionIsr! + retentionTax!)).toDop(): (total! - (retentionIsr! + retentionTax!)).toUS();
  }

  @override
  String get discountLabel {
           if(enabledDollarInvoice == true){
       return discountLocal?.toDop() ?? '';
    }
    return  currencyId == 1 ? discount?.toDop() : discount?.toUS() ?? '';
  }

  @override
  String get netFinalLabel {
           if(enabledDollarInvoice == true){
       return netFinalLocal?.toDop() ?? '';
    }
    return  currencyId == 1 ? netFinal?.toDop() : netFinal?.toUS() ?? '';
  }

  @override
  String get netLabel{
     if(enabledDollarInvoice == true){
       return netLocal?.toDop() ?? '';
   }
   return currencyId == 1 ? net?.toDop() : net?.toUS() ?? '';
  }

  @override
  String get retentionIsrLabel {

    if(enabledDollarInvoice == true){
       return retentionIsrLocal?.toDop() ?? '';
    }
    return  currencyId == 1 ? retentionIsr?.toDop() : retentionIsr?.toUS() ?? '';
  }

  @override
  String get retentionTaxLabel {
       if(enabledDollarInvoice == true){
       return retentionTaxLocal?.toDop() ?? '';
    }
    return  currencyId == 1 ? retentionTax?.toDop() : retentionTax?.toUS() ?? '';
  }

  @override
  String get taxLabel {
       if(enabledDollarInvoice == true){
       return taxLocal?.toDop() ?? '';
    }
    return  currencyId == 1 ? tax?.toDop() : tax?.toUS() ?? '';
  }

  @override
  String get totalLabel {
       if(enabledDollarInvoice == true){
       return totalLocal?.toDop() ?? '';
    }
    return  currencyId == 1 ? total?.toDop() : total?.toUS() ?? '';
  }

    @override
  String get law10Label {
       if(enabledDollarInvoice == true){
       return law10Local?.toDop() ?? '';
    }
    return  currencyId == 1 ? law10?.toDop() : law10?.toUS() ?? '';
  }

      @override
  String get amountxPaidLabel {
       if(enabledDollarInvoice == true){
       return amountPaidLocal?.toDop() ?? '';
    }
    return  currencyId == 1 ? amountPaid?.toDop() : amountPaid?.toUS() ?? '';
  }

  @override
  String? cashShiftId;

  @override
  String? creditCardDescription;

  @override
  String? brancheAddress;

  @override
  String? brancheEmail;

  @override
  int? brancheId;

  @override
  String? brancheName;

  @override
  String? branchePhone1;

  @override
  String? branchePhone2;
}
