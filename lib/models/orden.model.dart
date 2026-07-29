import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';
import 'package:uresax_invoice_sys_cloud/models/orden.item.model.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.orden.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';


class OrdenModel implements WareHouseElement<OrdenItemModel> {
  @override
  String? id;
  @override
  String? ordenId;
  @override
  int? ordenNum;
  @override
  String? entryId;
  @override
  int? entryNum;
  @override
  double? net;
  @override
  double? tax;
  @override
  double? total;
  @override
  DateTime? createdAt;
  @override
  List<OrdenItemModel>? items;
  @override
  double? amountPaid;
  @override
  String? authorId;
  @override
  String? authorName;
  @override
  double? netFinal;
  @override
  DateTime? paymentDate;
  OrdenModel(
      {this.id,
      this.ordenNum,
      this.ordenNumString,
      this.net,
      this.discount,
      this.netFinal,
      this.tax,
      this.total,
      this.createdAt,
      this.items = const [],
      this.amountPaid = 0,
      this.effective = 0,
      this.creditCard = 0,
      this.checkOrTransf = 0,
      this.saleToCredit = 0,
      this.authorId,
      this.authorName,
      this.applyEntry,
      this.driverId,
      this.driverName,
      this.driverIdentification,
      this.driverPhone,
      this.driverEmail,
      this.providerId,
      this.providerIdentification,
      this.providerName,
      this.debt = 0,
      this.ordenStatusId,
      this.ordenStatus,
      this.ncf,
      this.providerEmail,
      this.providerPhone,
      this.providerAddress,
      this.ncfDate,
      this.currencyId,
      this.currencyName,
      this.paymentDate});

  String get labelText {
    return applyEntry == true ? 'ORDEN APLICADA' : 'ORDEN NO APLICADA';
  }

  static Future<List<OrdenModel>> get(
      {required DateTime? startDate,
      required DateTime? endDate,
      String? search}) async {
    try {
      String params = '';
      List<String> query = [];

      if (search != null) {
        query.add('search=$search');
      }

      params += '&${query.join('&')}';

      var res = await apiUresax.get(
          '/ordenpurchases/all?startDate=${startDate?.toIso8601String()}&endDate=${endDate?.toIso8601String()}$params');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<OrdenModel>.from(
            (data as List).map((x) => OrdenModel.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<List<OrdenItemModel>> getItems([TxSession? tx]) async {
    try {
      var res =
          await apiUresax.get('/ordenpurchases/get-ordenpurchase-items/$id');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<OrdenItemModel>.from(
            (data as List).map((x) => OrdenItemModel.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<List<PaymentOrden>> getPaymentsOrdens() async {
    try {
      var res = await apiUresax.get('/ordenpurchases/get-payments-ordens/$id');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<PaymentOrden>.from(
            (data as List).map((x) => PaymentOrden.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<OrdenModel?> create() async {
    try {
      var parameters = toMap();

      parameters.remove('ordenNum');
      parameters.remove('authorName');
      parameters.remove('applyEntry');

      var res = await apiUresax
          .post('/ordenpurchases/create-ordenpurchase', data: {...parameters});

      if (res.statusCode == 200) {
        return OrdenModel.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<void> cancelOrden() async {
    try {
      await apiUresax.put('/ordenpurchases/cancel-orden/$id');
    } catch (e) {
      rethrow;
    }
  }

  OrdenModel copyWith(
      {String? id,
      int? ordenNum,
      double? net,
      double? tax,
      double? total,
      DateTime? createdAt,
      List<OrdenItemModel>? items,
      double? amountPaid,
      String? authorId,
      String? authorName}) {
    return OrdenModel(
        id: id ?? this.id,
        ordenNum: ordenNum ?? this.ordenNum,
        net: net ?? this.net,
        tax: tax ?? this.tax,
        total: total ?? this.total,
        createdAt: createdAt ?? this.createdAt,
        amountPaid: amountPaid ?? this.amountPaid,
        items: items ?? this.items,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ordenNum': ordenNum,
      'net': net,
      'discount': discount,
      'tax': tax,
      'total': total,
      'createdAt': createdAt?.toIso8601String(),
      'amountPaid': amountPaid,
      'authorId': authorId,
      'authorName': authorName,
      'applyEntry': applyEntry,
      'providerId': providerId,
      'driverId': driverId,
      'ncf': ncf,
      'ncfDate': ncfDate?.toIso8601String(),
      'currencyId': currencyId,
      'items': items?.map((e) => e.toMap()).toList(),
    };
  }

  factory OrdenModel.fromMap(Map<String, dynamic> map) {
    return OrdenModel(
        id: map['id'],
        ordenNum: map['ordenNum'],
        ordenNumString: map['ordenNumString'],
        net: double.parse(map['net']),
        discount: map['discount'] != null ? double.parse(map['discount']) : 0,
        netFinal:
            map['netFinal'] != null ? double.parse(map['netFinal']) : null,
        tax: double.parse(map['tax']),
        total: double.parse(map['total']),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt']).toLocal()
            : null,
        ncfDate: map['ncfDate'] != null
            ? DateTime.parse(map['ncfDate']).toLocal()
            : null,
        amountPaid:
            map['amountPaid'] != null ? double.parse(map['amountPaid']) : 0,
        items: map['items'] != null
            ? List<OrdenItemModel>.from(
                (map['items'] as List).map((x) => OrdenItemModel.fromMap(x)))
            : [],
        authorId: map['authorId'],
        authorName: map['authorName'],
        applyEntry: map['applyEntry'],
        driverId: map['driverId'],
        driverName: map['driverName'],
        driverIdentification: map['driverIdentification'],
        driverPhone: map['driverPhone'],
        driverEmail: map['driverEmail'],
        providerId: map['providerId'],
        providerIdentification: map['providerIdentification'],
        providerName: map['providerName'],
        debt: double.parse(map['debt']),
        ordenStatusId: map['ordenStatusId'],
        ordenStatus: map['ordenStatus'],
        ncf: map['ncf'],
        providerPhone: map['providerPhone'],
        providerEmail: map['providerEmail'],
        providerAddress: map['providerAddress'],
        effective:
            map['effective'] != null ? double.parse(map['effective']) : 0,
        creditCard:
            map['creditCard'] != null ? double.parse(map['creditCard']) : 0,
        checkOrTransf: map['checkOrTransf'] != null
            ? double.parse(map['checkOrTransf'])
            : 0,
        saleToCredit:
            map['saleToCredit'] != null ? double.parse(map['saleToCredit']) : 0,
        currencyId: map['currencyId'],
        currencyName: map['currencyName']);
  }

  String toJson() => json.encode(toMap());

  factory OrdenModel.fromJson(String source) =>
      OrdenModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrdenModel(id: $id, ordenNum: $ordenNum, net: $net, tax: $tax, total: $total, createdAt: $createdAt, items: $items, authorId: $authorId, authorName: $authorName, applyEntry: $applyEntry)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is OrdenModel &&
        o.id == id &&
        o.ordenNum == ordenNum &&
        o.net == net &&
        o.tax == tax &&
        o.total == total &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ordenNum.hashCode ^
        net.hashCode ^
        tax.hashCode ^
        total.hashCode ^
        createdAt.hashCode;
  }

  @override
  bool? applyEntry;

  @override
  String? driverEmail;

  @override
  int? driverId;

  @override
  String? driverIdentification;

  @override
  String? driverName;

  @override
  String? driverPhone;

  @override
  int? providerId;

  @override
  String? providerIdentification;

  @override
  String? providerName;

  @override
  String? ordenNumString;

  @override
  String? entryNumString;

  @override
  double? debt;

  @override
  bool get isPaid {
    return debt == 0;
  }

  @override
  String get debtStatusLabel {
    if (isPaid) {
      return 'PAGADO';
    }
    return 'PENDIENTE';
  }

  Color get colorStatusPaid {
    return isPaid ? Colors.green : Colors.red;
  }

  @override
  Color get color {
    return applyEntry == true ? Colors.green : Colors.red;
  }

  @override
  Future<void> paySale(
      {required double amountPaid,
      required double amount,
      required int paymentMethodId,
      required int? bankId,
      required String? transRef}) async {
    try {

       await apiUresax.post('/ordenpurchases/pay-orden-purchase/$id',data: {
          'amount': amountPaid,
          'amountPaid':amountPaid,
          'paymentMethodId': paymentMethodId,
          'bankId': bankId,
          'transRef': transRef,
          'effective':effective,
          'checkOrTransf':checkOrTransf,
          'creditCard':creditCard,
          'saleToCredit':saleToCredit,
          'paymentDate': paymentDate?.toIso8601String(),
      });
    } on DioException catch (e) {
      throw e.response?.data['message'];
    }
  }

  @override
  String? ordenStatus;

  @override
  int? ordenStatusId;

  @override
  Color get ordenStatusColor {
    if (ordenStatusId == 1) {
      return Colors.green;
    }
    return Colors.red;
  }

  @override
  String get ordenStatusLabel {
    return ordenStatus ?? '';
  }

  @override
  String? ncf;

  @override
  String? providerEmail;

  @override
  String? providerPhone;

  @override
  String? providerAddress;

  @override
  double? discount;

  @override
  double? checkOrTransf;

  @override
  double? creditCard;

  @override
  double? effective;

  @override
  double? saleToCredit;

  @override
  DateTime? ncfDate;

  @override
  int? currencyId;

  @override
  String? currencyName;
}
