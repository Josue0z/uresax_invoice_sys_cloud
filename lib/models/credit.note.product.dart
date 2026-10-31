import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';

class CreditNoteAsProduct implements Sale {
  @override
  double? amountPaid;

  @override
  double? checkOrTransf;

  @override
  String? clientId;

  @override
  String? clientName;

  @override
  int? clientType;

  @override
  String? clientTypeName;

  @override
  DateTime? createdAt;

  @override
  double? creditCard;

  @override
  double? debt;

  @override
  String? description;

  @override
  double? discount;

  @override
  double? effective;

  @override
  String? id;

  @override
  int? invoiceTypeId;

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
  String? ncfTypeName;

  @override
  double? net;

  @override
  double? paid;

  @override
  int? paymentMethodId;

  @override
  String? paymentMethodName;

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

  @override
  String? typeIncomeName;
  CreditNoteAsProduct(
      {this.amountPaid,
      this.checkOrTransf,
      this.clientId,
      this.clientName,
      this.clientType,
      this.clientTypeName,
      this.createdAt,
      this.creditCard,
      this.debt,
      this.description,
      this.discount,
      this.effective,
      this.id,
      this.invoiceTypeId,
      this.items = const [],
      this.law10,
      this.ncf,
      this.ncfAffected,
      this.ncfTypeId,
      this.ncfTypeName,
      this.net,
      this.netFinal,
      this.paid,
      this.paymentMethodId,
      this.paymentMethodName,
      this.prefix,
      this.retentionDate,
      this.retentionIsr,
      this.retentionTax,
      this.saleId,
      this.saleToCredit,
      this.tax,
      this.total,
      this.typeIncomeId,
      this.typeIncomeName,
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
      this.saleToCreditLocal = 0,
      this.cashShiftId,
      this.creditCardDescription,
      this.brancheId,
      this.brancheName,
      this.branchePhone1,
      this.branchePhone2,
      this.brancheAddress,
      this.brancheEmail
      });

  @override
  // TODO: implement color
  Color get color => throw UnimplementedError();

  @override
  Future<CreditNoteAsProduct?> create() async {
    try {
            await User.authClient();
      var map = toMapInsert();
      var res =
          await apiUresax.post('/creditnotes/create-creditnote-product', data: {
        ...map,
        'ncfListId':ncfListId,
        'paymentMethodId':paymentMethodId,
        'boxId': currentUser?.boxId,
        'ncfAffected': ncf ?? '',
        'ncfAffectedCreatedAt': ncfAffectedCreatedAt!.toIso8601String(),
        'items': items.map((e) => e.toMap()).toList()
      });

      if (res.statusCode == 200) {
        return CreditNoteAsProduct.fromMap(res.data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<bool?> delete() async {
    try {
            await User.authClient();
      var res =
          await apiUresax.delete('/creditnotes/delete-creditnote-product/$id',data: {
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
  // TODO: implement isPaid
  bool get isPaid => throw UnimplementedError();

  @override
  // TODO: implement paidLabel
  String get paidLabel => throw UnimplementedError();

  @override
  Future<Sale?> paySale(double amount) {
    // TODO: implement paySale
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> to607() {
    // TODO: implement to607
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toDisplay() {
    // TODO: implement toDisplay
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'amountPaid': amountPaid,
      'checkOrTransf': checkOrTransf,
      'clientId': clientId,
      'clientName': clientName,
      'clientType': clientType,
      'clientTypeName': clientTypeName,
      'createdAt': createdAt,
      'issueDate': issueDate,
      'creditCard': creditCard,
      'debt': debt,
      'description': description,
      'discount': discount,
      'effective': effective,
      'id': id,
      'invoiceTypeId': invoiceTypeId,
      'items': items.map((x) => x).toList(),
      'law10': law10,
      'ncf': ncf,
      'ncfAffected': ncfAffected,
      'ncfTypeId': ncfTypeId,
      'ncfTypeName': ncfTypeName,
      'net': net,
      'paid': paid,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'prefix': prefix,
      'retentionDate': retentionDate,
      'retentionIsr': retentionIsr,
      'retentionTax': retentionTax,
      'saleId': saleId,
      'saleToCredit': saleToCredit,
      'tax': tax,
      'total': total,
      'typeIncomeId': typeIncomeId,
      'typeIncomeName': typeIncomeName,
      'currencyId': currencyId,
      'rate': rate,
      'maxSequence': maxSequence,
      'cashShiftId':cashShiftId,
      'creditCardDescription':creditCardDescription,
      'brancheId': brancheId
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
      'createdAt': createdAt?.toIso8601String(),
      'cashShiftId':cashShiftId,
      'creditCardDescription':creditCardDescription,
      'brancheId': brancheId
    };
  }

  @override
  Future<Sale?> update() {
    // TODO: implement update
    throw UnimplementedError();
  }

  CreditNoteAsProduct copyWith({
    double? amountPaid,
    double? checkOrTransf,
    String? clientId,
    String? clientName,
    int? clientType,
    String? clientTypeName,
    DateTime? createdAt,
    double? creditCard,
    double? debt,
    String? description,
    double? discount,
    double? effective,
    String? id,
    int? invoiceTypeId,
    List<SaleItem> items = const [],
    double? law10,
    String? ncf,
    String? ncfAffected,
    String? ncfTypeId,
    String? ncfTypeName,
    double? net,
    double? paid,
    int? paymentMethodId,
    String? paymentMethodName,
    String? prefix,
    DateTime? retentionDate,
    double? retentionIsr,
    double? retentionTax,
    String? saleId,
    double? saleToCredit,
    double? tax,
    double? total,
    String? typeIncomeId,
    String? typeIncomeName,
  }) {
    return CreditNoteAsProduct(
      amountPaid: amountPaid ?? this.amountPaid,
      checkOrTransf: checkOrTransf ?? this.checkOrTransf,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientType: clientType ?? this.clientType,
      clientTypeName: clientTypeName ?? this.clientTypeName,
      createdAt: createdAt ?? this.createdAt,
      creditCard: creditCard ?? this.creditCard,
      debt: debt ?? this.debt,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      effective: effective ?? this.effective,
      id: id ?? this.id,
      invoiceTypeId: invoiceTypeId ?? this.invoiceTypeId,
      items: items ?? this.items,
      law10: law10 ?? this.law10,
      ncf: ncf ?? this.ncf,
      ncfAffected: ncfAffected ?? this.ncfAffected,
      ncfTypeId: ncfTypeId ?? this.ncfTypeId,
      ncfTypeName: ncfTypeName ?? this.ncfTypeName,
      net: net ?? this.net,
      paid: paid ?? this.paid,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      prefix: prefix ?? this.prefix,
      retentionDate: retentionDate ?? this.retentionDate,
      retentionIsr: retentionIsr ?? this.retentionIsr,
      retentionTax: retentionTax ?? this.retentionTax,
      saleId: saleId ?? this.saleId,
      saleToCredit: saleToCredit ?? this.saleToCredit,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      typeIncomeId: typeIncomeId ?? this.typeIncomeId,
      typeIncomeName: typeIncomeName ?? this.typeIncomeName,
    );
  }

  factory CreditNoteAsProduct.fromMap(Map<String, dynamic> map) {

    return CreditNoteAsProduct(
      amountPaid: double.tryParse(map['amountPaid']?.toString() ?? '0') ?? 0,
      checkOrTransf:
          double.tryParse(map['checkOrTransf']?.toString() ?? '0') ?? 0,
      clientId: map['clientId']?.toString(),
      clientIdentification: map['clientIdentification'],
      clientName: map['clientName']?.toString(),
      clientType: int.tryParse(map['clientType']?.toString() ?? '0') ?? 0,
      clientTypeName: map['clientTypeName']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      creditCard: double.tryParse(map['creditCard']?.toString() ?? '0') ?? 0,
      debt: double.tryParse(map['debt']?.toString() ?? '0') ?? 0,
      description: map['description']?.toString(),
      discount: double.tryParse(map['discount']?.toString() ?? '0') ?? 0,
      effective: double.tryParse(map['effective']?.toString() ?? '0') ?? 0,
      id: map['id']?.toString(),
      invoiceTypeId: int.tryParse(map['invoiceTypeId']?.toString() ?? '0') ?? 0,
      items: map['items'] != null
          ? List<CreditNoteProduct>.from(
                  map['items']?.map((x) => CreditNoteProduct.fromMap(x)))
              .cast<CreditNoteProduct>()
          : [],
      law10: double.tryParse(map['law10']?.toString() ?? '0') ?? 0,
      ncf: map['ncf']?.toString(),
      ncfAffected: map['ncfAffected']?.toString(),
      ncfTypeId: map['ncfTypeId']?.toString(),
      ncfTypeName: map['ncfTypeName']?.toString(),
      net: double.tryParse(map['net']?.toString() ?? '0') ?? 0,
      netFinal: map['netFinal'] != null ? double.parse(map['netFinal']) : null,
      paid: double.tryParse(map['paid']?.toString() ?? '0') ?? 0,
      paymentMethodId:
          int.tryParse(map['paymentMethodId']?.toString() ?? '0') ?? 0,
      paymentMethodName: map['paymentMethodName']?.toString(),
      prefix: map['prefix']?.toString(),
      retentionDate: map['retentionDate'] != null
          ? DateTime.parse(map['retentionDate'])
          : null,
      retentionIsr:
          double.tryParse(map['retentionIsr']?.toString() ?? '0') ?? 0,
      retentionTax:
          double.tryParse(map['retentionTax']?.toString() ?? '0') ?? 0,
      saleId: map['saleId']?.toString(),
      saleToCredit:
          double.tryParse(map['saleToCredit']?.toString() ?? '0') ?? 0,
      tax: double.tryParse(map['tax']?.toString() ?? '0') ?? 0,
      total: double.tryParse(map['total']?.toString() ?? '0') ?? 0,
      typeIncomeId: map['typeIncomeId']?.toString(),
      typeIncomeName: map['typeIncomeName']?.toString(),
      currencyId: map['currencyId'],
      rate: map['rate'] != null
          ? double.parse(
              map['rate'],
            )
          : null,
      expirationDate: map['expirationDate'] != null
          ? DateTime.parse(map['expirationDate'])
          : null,
      
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
      coinBack: map['coinBack'] != null ? double.parse(map['coinBack']) : null,
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
        debtLocal: map['debtLocal'] != null ? double.parse(map['debtLocal']) : 0,
        netFinalLocal: map['netFinalLocal'] != null ? double.parse(map['netFinalLocal']) : 0,
        net18Local: map['net18Local'] != null ? double.parse(map['net18Local']) : 0,
        net16Local: map['net16Local'] != null ? double.parse(map['net16Local']) : 0,
        net3Local: map['net3Local'] != null ? double.parse(map['net3Local']) : 0,
        tax18Local: map['tax18Local'] != null ? double.parse(map['tax18Local']) : 0,
        tax16Local: map['tax16Local'] != null ? double.parse(map['tax16Local']) : 0,
        tax3Local: map['tax3Local'] != null ? double.parse(map['tax3Local']) : 0,
        exemptAmountLocal: map['exemptAmountLocal'] != null
            ? double.parse(map['exemptAmountLocal'])
            : 0,
        retentionTaxLocal: map['retentionTaxLocal'] != null
            ? double.parse(map['retentionTaxLocal'])
            : 0,
        retentionIsrLocal: map['retentionIsrLocal'] != null
            ? double.parse(map['retentionIsrLocal'])
            : 0,
            law10Local: map['law10Local'] != null ? double.parse(map['law10Local']) : 0,
            taxLocal: map['taxLocal'] != null ? double.parse(map['taxLocal']) : 0,
                    totalLocal: map['totalLocal'] != null ? double.parse(map['totalLocal']) : 0,
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

  factory CreditNoteAsProduct.fromJson(String source) =>
      CreditNoteAsProduct.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CreditNoteAsProduct(amountPaid: $amountPaid, checkOrTransf: $checkOrTransf, clientId: $clientId, clientName: $clientName, clientType: $clientType, clientTypeName: $clientTypeName, createdAt: $createdAt, creditCard: $creditCard, debt: $debt, description: $description, discount: $discount, effective: $effective, id: $id, invoiceTypeId: $invoiceTypeId, items: $items, law10: $law10, ncf: $ncf, ncfAffected: $ncfAffected, ncfTypeId: $ncfTypeId, ncfTypeName: $ncfTypeName, net: $net, paid: $paid, paymentMethodId: $paymentMethodId, paymentMethodName: $paymentMethodName, prefix: $prefix, retentionDate: $retentionDate, retentionIsr: $retentionIsr, retentionTax: $retentionTax, saleId: $saleId, saleToCredit: $saleToCredit, tax: $tax, total: $total, typeIncomeId: $typeIncomeId, typeIncomeName: $typeIncomeName, clientAddress: $clientAddress, creditCardDescription: $creditCardDescription,brancheId: $brancheId, brancheName: $brancheName, branchePhone1: $branchePhone1, branchePhone2: $branchePhone2, brancheAddress: $brancheAddress, brancheEmail: $brancheEmail)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CreditNoteAsProduct &&
        o.amountPaid == amountPaid &&
        o.checkOrTransf == checkOrTransf &&
        o.clientId == clientId &&
        o.clientName == clientName &&
        o.clientType == clientType &&
        o.clientTypeName == clientTypeName &&
        o.createdAt == createdAt &&
        o.creditCard == creditCard &&
        o.debt == debt &&
        o.description == description &&
        o.discount == discount &&
        o.effective == effective &&
        o.id == id &&
        o.invoiceTypeId == invoiceTypeId &&
        listEquals(o.items, items) &&
        o.law10 == law10 &&
        o.ncf == ncf &&
        o.ncfAffected == ncfAffected &&
        o.ncfTypeId == ncfTypeId &&
        o.ncfTypeName == ncfTypeName &&
        o.net == net &&
        o.paid == paid &&
        o.paymentMethodId == paymentMethodId &&
        o.paymentMethodName == paymentMethodName &&
        o.prefix == prefix &&
        o.retentionDate == retentionDate &&
        o.retentionIsr == retentionIsr &&
        o.retentionTax == retentionTax &&
        o.saleId == saleId &&
        o.saleToCredit == saleToCredit &&
        o.tax == tax &&
        o.total == total &&
        o.typeIncomeId == typeIncomeId &&
        o.typeIncomeName == typeIncomeName;
  }

  @override
  int get hashCode {
    return amountPaid.hashCode ^
        checkOrTransf.hashCode ^
        clientId.hashCode ^
        clientName.hashCode ^
        clientType.hashCode ^
        clientTypeName.hashCode ^
        createdAt.hashCode ^
        creditCard.hashCode ^
        debt.hashCode ^
        description.hashCode ^
        discount.hashCode ^
        effective.hashCode ^
        id.hashCode ^
        invoiceTypeId.hashCode ^
        items.hashCode ^
        law10.hashCode ^
        ncf.hashCode ^
        ncfAffected.hashCode ^
        ncfTypeId.hashCode ^
        ncfTypeName.hashCode ^
        net.hashCode ^
        paid.hashCode ^
        paymentMethodId.hashCode ^
        paymentMethodName.hashCode ^
        prefix.hashCode ^
        retentionDate.hashCode ^
        retentionIsr.hashCode ^
        retentionTax.hashCode ^
        saleId.hashCode ^
        saleToCredit.hashCode ^
        tax.hashCode ^
        total.hashCode ^
        typeIncomeId.hashCode ^
        typeIncomeName.hashCode;
  }

  @override
  Future<List<CreditNoteProduct>> getSaleData() async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/creditnotes/get-creditnote-items-products/$id');


      if (res.statusCode == 200) {
        var data = res.data;
     
        var list = List<CreditNoteProduct>.from(
            (data as List).map((x) => CreditNoteProduct.fromMap(x)));
        return list;
      }
      return [];
    } on DioException catch (e) {
      print(e);
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
            await User.authClient();
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
  Future<void> updateStock() async {
    try {
      var conne = SqlConector.connection;
      for (int i = 0; i < items.length; i++) {
        var item = items[i];
        await conne?.execute(
            Sql.named(
                ''' update public."Products" set quantity = quantity + @quantity where id = @id'''),
            parameters: {'id': item.productId, 'quantity': item.quantity});
      }
    } catch (e) {
      rethrow;
    }
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
