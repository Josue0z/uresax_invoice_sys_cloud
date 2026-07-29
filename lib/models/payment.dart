import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class Payment {
  String? id;
  String? saleId;
  int? paymentMethodId;
  double? amount;
  DateTime? createdAt;
  String? clientName;
  String? ncf;
  String? paymentMethodName;
  int? bankId;
  String? bankName;
  String? transfRef;
  int? currencyId;

  Payment(
      {this.id,
      this.saleId,
      this.paymentMethodId,
      this.amount,
      this.createdAt,
      this.clientName,
      this.ncf,
      this.paymentMethodName,
      this.bankId,
      this.bankName,
      this.transfRef,
      this.currencyId});

  static Future<List<Payment>> get({required String saleId}) async {
    try {
      var res = await apiUresax.get('/payments/all?saleId=$saleId');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Payment>.from(
            (data as List).map((x) => Payment.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Payment?> create() async {
    try {
      var res = await apiUresax.post('/payments/create', data: {
        'saleId': saleId,
        'paymentMethodId': paymentMethodId,
        'amount': amount
      });

      if (res.statusCode == 200) {
        return Payment.fromMap(res.data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Payment copyWith({
    String? id,
    String? saleId,
    int? paymentMethodId,
    double? amount,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'paymentMethodId': paymentMethodId,
      'amount': amount,
      'createdAt': createdAt?.toIso8601String()
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
        id: map['id'],
        saleId: map['saleId'],
        paymentMethodId: map['paymentMethodId'],
        amount: double.parse(map['amount']),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : null,
        clientName: map['clientName'],
        ncf: map['ncf'],
        paymentMethodName: map['paymentMethodName'],
        bankId: map['bankId'],
        bankName: map['bankName'],
        transfRef: map['transfRef'],
        currencyId: map['currencyId']);
  }

  String toJson() => json.encode(toMap());

  factory Payment.fromJson(String source) =>
      Payment.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Payment(id: $id, saleId: $saleId, paymentMethodId: $paymentMethodId, amount: $amount, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Payment &&
        o.id == id &&
        o.saleId == saleId &&
        o.paymentMethodId == paymentMethodId &&
        o.amount == amount &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        saleId.hashCode ^
        paymentMethodId.hashCode ^
        amount.hashCode ^
        createdAt.hashCode;
  }
}
