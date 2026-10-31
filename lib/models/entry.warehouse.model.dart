import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';
import 'package:uresax_invoice_sys_cloud/models/entry.warehouse.item.model.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.orden.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';
import 'package:uuid/uuid.dart';

class EntryWareHouseModel implements WareHouseElement<EntryWareHouseItemModel> {
  @override
  String? id;
  @override
  String? entryId;
  @override
  int? entryNum;
  @override
  String? ordenId;
  @override
  int? ordenNum;
  @override
  double? net;
  @override
  double? tax;
  @override
  double? total;
  @override
  DateTime? createdAt;
  @override
  List<EntryWareHouseItemModel>? items;
  @override
  double? amountPaid;
  @override
  String? authorId;
  @override
  String? authorName;
  @override
  double? netFinal;
  EntryWareHouseModel(
      {this.id,
      this.entryNum,
      this.entryNumString,
      this.ordenId,
      this.ordenNum,
      this.net,
      this.discount,
      this.netFinal,
      this.tax,
      this.total,
      this.createdAt,
      this.ncfDate,
      this.items,
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
      this.providerPhone,
      this.providerEmail,
      this.providerAddress,
      this.currencyId,
      this.currencyName});

  static Future<List<EntryWareHouseModel>> get(
      {required DateTime? startDate,
      required DateTime? endDate,
      String? search}) async {
    try {
            await User.authClient();
        String params = '';
      List<String> query = [];

      if(search != null){
        query.add('search=$search');
      }

      params+='&${query.join('&')}';
 
      
       var res = await apiUresax.get('/entrieswarehouses/all?startDate=${startDate?.toIso8601String()}&endDate=${endDate?.toIso8601String()}$params');
      
      if(res.statusCode == 200){
         var data = res.data;
        return List<EntryWareHouseModel>.from(
            (data as List).map((x) => EntryWareHouseModel.fromMap(x)));
      }
      return [];
      
    }on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<List<EntryWareHouseItemModel>> getItems([TxSession? tx]) async {
    try {
            await User.authClient();
       var res = await apiUresax.get('/entrieswarehouses/get-entrieswarehouse-items/$id');

      if(res.statusCode==200){
         var data = res.data;
        return List<EntryWareHouseItemModel>.from(
            (data as List).map((x) => EntryWareHouseItemModel.fromMap(x)));
      }
     
     return [];
    }on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  @override
  Future<List<PaymentOrden>> getPaymentsOrdens() async {
    try {
      final conne = SqlConector.connection;

      var result = await conne?.execute(
          Sql.named(
              'select * from public."PaymentsOrdensView" where "ref" = @id  order by "createdAt" desc'),
          parameters: {'id': id ?? ''});
      return result
              ?.map(
                (e) => PaymentOrden.fromMap(e.toColumnMap()),
              )
              .toList() ??
          [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EntryWareHouseModel?> create() async {
    try {
            await User.authClient();
      var parameters = toMap();
      parameters.remove('ordenNum');
      parameters.remove('entryNum');
      parameters.remove('authorName');
      var res = await apiUresax.post(
          '/entrieswarehouses/create-entrieswarehouse',
          data: {...parameters});
      if (res.statusCode == 200) {
        return EntryWareHouseModel.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  EntryWareHouseModel copyWith({
    String? id,
    int? entryNum,
    String? ordenId,
    int? ordenNum,
    double? net,
    double? tax,
    double? total,
    DateTime? createdAt,
    List<EntryWareHouseItemModel>? items,
    double? amountPaid,
    String? authorId,
    String? authorName,
  }) {
    return EntryWareHouseModel(
      id: id ?? this.id,
      entryNum: entryNum ?? this.entryNum,
      ordenId: ordenId ?? this.ordenId,
      ordenNum: ordenNum ?? this.ordenNum,
      net: net ?? this.net,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      amountPaid: amountPaid ?? this.amountPaid,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryNum': entryNum,
      'ordenId': ordenId,
      'ordenNum': ordenNum,
      'net': net,
      'discount': discount,
      'tax': tax,
      'total': total,
      'createdAt': createdAt?.toIso8601String(),
      'ncf': ncf,
      'ncfDate': ncfDate?.toIso8601String(),
      'items': items?.map((x) => x.toMap()).toList(),
      'amountPaid': amountPaid,
      'authorId': authorId,
      'authorName': authorName,
      'driverId': driverId,
      'providerId': providerId,
      'currencyId': currencyId
    };
  }

  factory EntryWareHouseModel.fromMap(Map<String, dynamic> map) {
    return EntryWareHouseModel(
      id: map['id'],
      entryNum: map['entryNum'],
      entryNumString: map['entryNumString'],
      ordenId: map['ordenId'],
      ordenNum: map['ordenNum'],
      net: double.parse(map['net']),
      discount: map['discount'] != null ? double.parse(map['discount']) : 0,
      netFinal: map['netFinal'] != null ? double.parse(map['netFinal']) : null,
      tax: double.parse(map['tax']),
      total: double.parse(map['total']),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt']).toLocal()
          : null,
      ncfDate: map['ncfDate'] != null
          ? DateTime.parse(map['ncfDate']).toLocal()
          : null,
      items: map['items'] != null
          ? (map['items'] as List)
              .map((x) => EntryWareHouseItemModel?.fromMap(x))
              .toList()
              .cast<EntryWareHouseItemModel>()
          : [],
      amountPaid:
          map['amountPaid'] != null ? double.parse(map['amountPaid']) : null,
      authorId: map['authorId'],
      authorName: map['authorName'],
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverIdentification: map['driverIdentification'],
      driverEmail: map['driverEmail'],
      driverPhone: map['driverPhone'],
      providerId: map['providerId'],
      providerIdentification: map['providerIdentification'],
      providerName: map['providerName'],
      debt: map['debt'] != null ? double.parse(map['debt']) : null,
      ordenStatusId: map['ordenStatusId'],
      ordenStatus: map['ordenStatus'],
      ncf: map['ncf'],
      providerEmail: map['providerEmail'],
      providerPhone: map['providerPhone'],
      providerAddress: map['providerAddress'],
      effective: map['effective'] != null ? double.parse(map['effective']) : 0,
      creditCard:
          map['creditCard'] != null ? double.parse(map['creditCard']) : 0,
      checkOrTransf:
          map['checkOrTransf'] != null ? double.parse(map['checkOrTransf']) : 0,
      saleToCredit:
          map['saleToCredit'] != null ? double.parse(map['saleToCredit']) : 0,
      currencyId: map['currencyId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory EntryWareHouseModel.fromJson(String source) =>
      EntryWareHouseModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EntryWareHouseModel(id: $id, entryNum: $entryNum, ordenId: $ordenId, ordenNum: $ordenNum, net: $net, tax: $tax, total: $total, createdAt: $createdAt, items: $items, amountPaid: $amountPaid, authorId: $authorId, authorName: $authorName, driverId: $driverId, driverName: $driverName, driverIdentification: $driverIdentification, driverPhone: $driverPhone, driverEmail: $driverEmail)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is EntryWareHouseModel &&
        o.id == id &&
        o.ordenId == ordenId &&
        o.ordenNum == ordenNum &&
        o.net == net &&
        o.tax == tax &&
        o.total == total &&
        o.createdAt == createdAt &&
        listEquals(o.items, items) &&
        o.amountPaid == amountPaid &&
        o.authorId == authorId &&
        o.authorName == authorName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ordenId.hashCode ^
        ordenNum.hashCode ^
        net.hashCode ^
        tax.hashCode ^
        total.hashCode ^
        createdAt.hashCode ^
        items.hashCode ^
        amountPaid.hashCode ^
        authorId.hashCode ^
        authorName.hashCode;
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

  @override
  Future<void> paySale(
      {required double amountPaid,
      required double amount,
      required int paymentMethodId,
      required int? bankId,
      required String? transRef}) async {
    try {
      var conne = SqlConector.connection;
      await conne?.runTx((tx) async {
        await tx.execute(Sql.named('''
        insert into public."PaymentOrdens"(id,ref,amount, "paymentMethodId", "bankId", "transRef")
        values(@id,@ref,@amount,@paymentMethodId,@bankId,@transRef)
        '''), parameters: {
          'id': Uuid().v4(),
          'ref': id,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          'bankId': bankId,
          'transRef': transRef
        });
        await tx.execute(Sql.named('''
         update public."EntriesWareHouses" set "amountPaid" = "amountPaid" + @amountPaid, "effective" = "effective" + @effective, "creditCard" = "creditCard" + @creditCard, "checkOrTransf" = "checkOrTransf" + @checkOrTransf, "saleToCredit" = "saleToCredit" + @saleToCredit where id = @id
        '''), parameters: {
          'id': id,
          'amountPaid': amountPaid,
          'effective': effective,
          'creditCard': creditCard,
          'checkOrTransf': checkOrTransf,
          'saleToCredit': saleToCredit
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Color get colorStatusPaid {
    return isPaid ? Colors.green : Colors.red;
  }

  @override
  Color get color {
    return applyEntry == true ? Colors.green : Colors.red;
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
  Future<void> cancelOrden() {
    // TODO: implement cancelOrden
    throw UnimplementedError();
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

  @override
  DateTime? paymentDate;
}
