import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';

class CreditNoteAsService implements Sale {
  @override
  double? checkOrTransf;

  @override
  String? clientId;

  @override
  String? clientName;

  @override
  int? clientType;

  @override
  DateTime? createdAt;

  @override
  double? creditCard;

  @override
  String? description;

  @override
  double? discount;

  @override
  double? effective;

  @override
  String? id;

  @override
  List<SaleItem> items;

  @override
  double? law10;

  @override
  String? ncf;

  @override
  String? ncfAffected;

  @override
  String? ncfTypeId;

  @override
  double? net;

  @override
  int? paymentMethodId;

  @override
  String? prefix;

  @override
  DateTime? retentionDate;

  @override
  double? retentionIsr;

  @override
  double? retentionTax;

  @override
  String? saleId;

  @override
  double? saleToCredit;

  @override
  double? tax;

  @override
  double? total;

  @override
  String? typeIncomeId;
  CreditNoteAsService(
      {this.checkOrTransf,
      this.clientId,
      this.clientName,
      this.clientType,
      this.createdAt,
      this.creditCard,
      this.description,
      this.discount,
      this.effective,
      this.id,
      this.items = const [],
      this.law10,
      this.ncf,
      this.ncfAffected,
      this.ncfTypeId,
      this.net,
      this.netFinal,
      this.paymentMethodId,
      this.prefix,
      this.retentionDate,
      this.retentionIsr,
      this.retentionTax,
      this.saleId,
      this.saleToCredit,
      this.tax,
      this.total,
      this.typeIncomeId,
      this.ncfTypeName,
      this.paymentMethodName,
      this.clientTypeName,
      this.typeIncomeName,
      this.invoiceTypeId,
      this.paid,
      this.amountPaid,
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
      this.estadoDgiiNombre,
      this.ecfXmlFirmado,
      this.estadoDgii,
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
      this.clientPhone,
      this.clientEmail,
      this.message,
      this.refInvoiceId,
      this.debt});

  @override
  Future<CreditNoteAsService?> create() async {
    try {
    
    var map = toMapInsert();
      var res= await apiUresax.post('/creditnotes/create-creditnote-service',data: {
        ...map,
        'ncfListId':ncfListId,
        'paymentMethodId':paymentMethodId,
        'boxId': currentUser?.boxId,
        'ncfAffected': ncf ?? '',
        'ncfAffectedCreatedAt': ncfAffectedCreatedAt!.toIso8601String(),
        'items': items.map((e)=> e.toMap()).toList()
      });

      if(res.statusCode == 200){
        return CreditNoteAsService.fromMap(res.data);
      }
      
     
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<bool?> delete() async {
    try {
       var res =
          await apiUresax.delete('/creditnotes/delete-creditnote-service/$id',data: {
             'ncfSeq':ncfSeq,
              'ncfTypeId':ncfTypeId
          });

      if (res.statusCode == 200) {
        return true;
      }
      return false;
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
  Map<String, dynamic> toMap() {
    return {
      'checkOrTransf': checkOrTransf,
      'clientId': clientId,
      'clientName': clientName,
      'clientType': clientType,
      'createdAt': createdAt,
      'issueDate': issueDate,
      'creditCard': creditCard,
      'description': description,
      'discount': discount,
      'effective': effective,
      'id': id,
      'items': items.map((x) => x).toList(),
      'law10': law10,
      'ncf': ncf,
      'ncfAffected': ncfAffected,
      'ncfTypeId': ncfTypeId,
      'net': net,
      'paymentMethodId': paymentMethodId,
      'prefix': prefix,
      'retentionDate': retentionDate,
      'retentionIsr': retentionIsr,
      'retentionTax': retentionTax,
      'saleId': saleId,
      'saleToCredit': saleToCredit,
      'tax': tax,
      'total': total,
      'typeIncomeId': typeIncomeId,
      'currencyId': currencyId,
      'rate': rate,
      'maxSequence': maxSequence
    };
  }

  @override
  Map<String, dynamic> toMapInsert() {
    return {
      'clientId': clientId,
      'clientIdentification':clientIdentification,
      'clientName':clientName,
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
      'prefix': prefix,
      'invoiceTypeId': invoiceTypeId,
      'saleId': saleId,
      'currencyId': currencyId,
      'rate': rate,
      'maxSequence': maxSequence,
      'tax18': tax18,
      'tax16': tax16,
      'tax3': tax3,
      'net18': net18,
      'net16': net16,
      'net3': net3,
      'exemptAmount': exemptAmount,
      'expirationDate': expirationDate?.toIso8601String(),
      'authorId': authorId,
      'paid': paidInvoice,
      'coinBack': coinBack,
      'issueDate': issueDate?.toIso8601String(),
      'retentionDate': retentionDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String()
    };
  }

  @override
  Future<Sale?> update() {
    // TODO: implement update
    throw UnimplementedError();
  }

  CreditNoteAsService copyWith({
    double? checkOrTransf,
    String? clientId,
    String? clientName,
    int? clientType,
    DateTime? createdAt,
    double? creditCard,
    String? description,
    double? discount,
    double? effective,
    String? id,
    List<SaleItem>? items,
    double? law10,
    String? ncf,
    String? ncfAffected,
    String? ncfTypeId,
    double? net,
    int? paymentMethodId,
    String? prefix,
    DateTime? retentionDate,
    double? retentionIsr,
    double? retentionTax,
    String? saleId,
    double? saleToCredit,
    double? tax,
    double? total,
    String? typeIncomeId,
  }) {
    return CreditNoteAsService(
      checkOrTransf: checkOrTransf ?? this.checkOrTransf,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientType: clientType ?? this.clientType,
      createdAt: createdAt ?? this.createdAt,
      creditCard: creditCard ?? this.creditCard,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      effective: effective ?? this.effective,
      id: id ?? this.id,
      items: items ?? this.items,
      law10: law10 ?? this.law10,
      ncf: ncf ?? this.ncf,
      ncfAffected: ncfAffected ?? this.ncfAffected,
      ncfTypeId: ncfTypeId ?? this.ncfTypeId,
      net: net ?? this.net,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      prefix: prefix ?? this.prefix,
      retentionDate: retentionDate ?? this.retentionDate,
      retentionIsr: retentionIsr ?? this.retentionIsr,
      retentionTax: retentionTax ?? this.retentionTax,
      saleId: saleId ?? this.saleId,
      saleToCredit: saleToCredit ?? this.saleToCredit,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      typeIncomeId: typeIncomeId ?? this.typeIncomeId,
    );
  }

  factory CreditNoteAsService.fromMap(Map<String, dynamic> map) {
    return CreditNoteAsService(
        id: map['id'],
        clientId: map['clientId'],
        clientIdentification: map['clientIdentification'],
        clientName: map['clientName'],
        clientType: map['clientType'],
        creditCard: double.parse(map['creditCard']),
        description: map['description'],
        discount: double.parse(map['discount']),
        effective: double.parse(map['effective']),
        checkOrTransf: double.parse(map['checkOrTransf']),
        items: map['items'] != null
            ? List<CreditNoteService>.from(
                    map['items']?.map((x) => CreditNoteService.fromMap(x)))
                .cast<CreditNoteService>()
            : [],
        law10: double.parse(map['law10']),
        ncf: map['ncf'],
        ncfAffected: map['ncfAffected'],
        ncfTypeId: map['ncfTypeId'],
        net: double.parse(map['net']),
        netFinal:
            map['netFinal'] != null ? double.parse(map['netFinal']) : null,
        paymentMethodId: map['paymentMethodId'],
        prefix: map['prefix'],
        retentionDate: map['retentionDate'] != null ?  DateTime.parse(map['retentionDate']) : null,
        retentionIsr: double.parse(map['retentionIsr']),
        retentionTax: double.parse(map['retentionTax']),
        saleId: map['saleId'],
        saleToCredit: double.parse(map['saleToCredit']),
        tax: double.parse(map['tax']),
        total: double.parse(map['total']),
        typeIncomeId: map['typeIncomeId'],
        typeIncomeName: map['typeIncomeName'],
        paymentMethodName: map['paymentMethodName'],
        clientTypeName: map['clientTypeName'],
        ncfTypeName: map['ncfTypeName'],
        amountPaid:
            map['amountPaid'] != null ? double.parse(map['amountPaid']) : null,
        createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
        invoiceTypeId: map['invoiceTypeId'],
        currencyId: map['currencyId'],
        rate: map['rate'] != null
            ? double.parse(
                map['rate'],
              )
            : null,
        expirationDate: map['expirationDate'] != null ? DateTime.parse(map['expirationDate']) : null,
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
        signatureDate: map['signatureDate'] != null ? DateTime.parse(map['signatureDate']) : null,
        tipoPago: map['tipoPago'],
        authorId: map['authorId'],
        authorName: map['authorName'],
        ncfSeq: map['ncfSeq'],
        clientAddress: map['clientAddress'],
        paid: map['paid'] != null ? double.parse(map['paid']) : null,
        issueDate: map['issueDate'] != null ? DateTime.parse(map['issueDate']) : null,
        coinBack:
            map['coinBack'] != null ? double.parse(map['coinBack']) : null,
        clientPhone: map['clientPhone'],
        clientEmail: map['clientEmail'],
        message: map['message'],
         debt: double.tryParse(map['debt']?.toString() ?? '0') ?? 0,
        );
  }

  String toJson() => json.encode(toMap());

  factory CreditNoteAsService.fromJson(String source) =>
      CreditNoteAsService.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CreditNote(checkOrTransf: $checkOrTransf, clientId: $clientId, clientName: $clientName, clientType: $clientType, createdAt: $createdAt, creditCard: $creditCard, description: $description, discount: $discount, effective: $effective, id: $id, items: $items, law10: $law10, ncf: $ncf, ncfAffected: $ncfAffected, ncfTypeId: $ncfTypeId, net: $net, paymentMethodId: $paymentMethodId, prefix: $prefix, retentionDate: $retentionDate, retentionIsr: $retentionIsr, retentionTax: $retentionTax, saleId: $saleId, saleToCredit: $saleToCredit, tax: $tax, total: $total, typeIncomeId: $typeIncomeId, clientAddress: $clientAddress)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CreditNoteAsService &&
        o.checkOrTransf == checkOrTransf &&
        o.clientId == clientId &&
        o.clientName == clientName &&
        o.clientType == clientType &&
        o.createdAt == createdAt &&
        o.creditCard == creditCard &&
        o.description == description &&
        o.discount == discount &&
        o.effective == effective &&
        o.id == id &&
        listEquals(o.items, items) &&
        o.law10 == law10 &&
        o.ncf == ncf &&
        o.ncfAffected == ncfAffected &&
        o.ncfTypeId == ncfTypeId &&
        o.net == net &&
        o.paymentMethodId == paymentMethodId &&
        o.prefix == prefix &&
        o.retentionDate == retentionDate &&
        o.retentionIsr == retentionIsr &&
        o.retentionTax == retentionTax &&
        o.saleId == saleId &&
        o.saleToCredit == saleToCredit &&
        o.tax == tax &&
        o.total == total &&
        o.typeIncomeId == typeIncomeId;
  }

  @override
  int get hashCode {
    return checkOrTransf.hashCode ^
        clientId.hashCode ^
        clientName.hashCode ^
        clientType.hashCode ^
        createdAt.hashCode ^
        creditCard.hashCode ^
        description.hashCode ^
        discount.hashCode ^
        effective.hashCode ^
        id.hashCode ^
        items.hashCode ^
        law10.hashCode ^
        ncf.hashCode ^
        ncfAffected.hashCode ^
        ncfTypeId.hashCode ^
        net.hashCode ^
        paymentMethodId.hashCode ^
        prefix.hashCode ^
        retentionDate.hashCode ^
        retentionIsr.hashCode ^
        retentionTax.hashCode ^
        saleId.hashCode ^
        saleToCredit.hashCode ^
        tax.hashCode ^
        total.hashCode ^
        typeIncomeId.hashCode;
  }

  @override
  String? clientTypeName;

  @override
  String? ncfTypeName;

  @override
  String? paymentMethodName;

  @override
  String? typeIncomeName;

  @override
  Map<String, dynamic> toDisplay() {
    // TODO: implement toDisplay
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> to607() {
    // TODO: implement to607
    throw UnimplementedError();
  }

  @override
  int? invoiceTypeId;

  @override
  String? chassis;

  @override
  String? licensePlate;

  @override
  double? paid;

  @override
  double? amountPaid;

  @override
  double? debt;

  @override
  bool get isPaid => throw UnimplementedError();

  @override
  // TODO: implement color
  Color get color => throw UnimplementedError();

  @override
  // TODO: implement paidLabel
  String get paidLabel => throw UnimplementedError();

  @override
  Future<Sale?> paySale(double amount) {
    // TODO: implement paySale
    throw UnimplementedError();
  }

  @override
  Future<List<CreditNoteService>> getSaleData() async {
    try {

      var res = await apiUresax.get('/creditnotes/get-creditnote-items-services/$id');

      if(res.statusCode == 200){
         var data = res.data;
        var list = List<CreditNoteService>.from(
            (data as List).map((x) => CreditNoteService.fromMap(x)));
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
     var res = await apiUresax.put('/creditnotes/update-ecf-info/$id', data: {
        'signatureDate': signatureDate?.toIso8601String(),
        'securityCode': securityCode,
        'dgiiURL': dgiiURL,
        'ecfXmlFirmado':   base64Encode(utf8.encode(ecfXmlFirmado!)),
        'estadoDgii': estadoDgii
      });

       if (res.statusCode == 200) {
        estadoDgiiNombre = res.data['estadoDgiiNombre'];

      }
    } on DioException catch (e) {
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
}
