import 'dart:ui';

import 'package:postgres/postgres.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.orden.dart';

abstract class WareHouseElement<T> {
  String? id;
  String? ordenId;
  int? ordenNum;
  String? ordenNumString;
  String? entryId;
  String? entryNumString;
  int? entryNum;
  double? net;
  double? discount;
  double? tax;
  double? total;
  DateTime? createdAt;
  DateTime? ncfDate;
  List<T>? items;
  double? amountPaid;
  double? effective;
  double? creditCard;
  double? checkOrTransf;
  double? saleToCredit;
  String? authorId;
  String? authorName;
  bool? applyEntry;
  int? driverId;
  String? driverName;
  String? driverIdentification;
  String? driverPhone;
  String? driverEmail;
  int? providerId;
  String? providerIdentification;
  String? providerName;
  double? debt;
  int? ordenStatusId;
  String? ordenStatus;
  double? netFinal;
  String? ncf;
  String? providerPhone;
  String? providerEmail;
  String? providerAddress;
  int? currencyId;
  String? currencyName;
  DateTime? paymentDate;

  Color get color {
    throw UnimplementedError();
  }

  String get debtStatusLabel {
    throw UnimplementedError();
  }

  Color get ordenStatusColor {
       throw UnimplementedError();
  }

  String get ordenStatusLabel {
        throw UnimplementedError();
  }

  static Future<List<WareHouseElement>> get() async {
    throw UnimplementedError();
  }

  Future<List<WareHouseElementItem>> getItems() async {
    throw UnimplementedError();
  }

  Future<List<PaymentOrden>> getPaymentsOrdens() async {
    throw UnimplementedError();
  }

  Future<WareHouseElement?> create() async {
    throw UnimplementedError();
  }

   Future<void> cancelOrden()async{
      throw UnimplementedError();
 }

  bool get isPaid {
    throw UnimplementedError();
  }
  Future<void> paySale({
    required double amountPaid,
    required double amount,
    required int paymentMethodId,
    required int? bankId,
    required String? transRef
  })async{}
}

abstract class WareHouseElementItem {
  String? id;
  String? ordenId;
  String? entryId;
  int? productId;
  String? productName;
  int? providerId;
  String? providerName;
  double? quantity;
  double? units;
  double? price;
  double? priceUnit;
  double? net;
  double? netFinal;
  double? discount;
  double? tax;
  double? total;
  DateTime? createdAt;
  String? unitName;
  String? unitCode;
  String? unitSymbol;
  double? conversionFactor;
  String? productCode;

  Future<WareHouseElementItem?> create([TxSession? transaction]) async {
    throw UnimplementedError();
  }

  Map<String, dynamic> toDisplay() {
    throw UnimplementedError();
  }

  Map<String, dynamic> toDisplayReceipt() {
    throw UnimplementedError();
  }
  
 Map<String, dynamic> toDisplayItemStore() {
    throw UnimplementedError();
  }


}
