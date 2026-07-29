// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PaymentOrden {
  String? id;
  String? ref;
  String? refString;
  String? providerIdentification;
  String? providerName;
  int? paymentMethodId;
  String? paymentMethodName;
  int? bankId;
  String? bankName;
  String? transRef;
  double? amount;
  int? currencyId;
  String? ordenNumString;
  DateTime? createdAt;
  PaymentOrden({
    this.id,
    this.ref,
    this.refString,
    this.providerIdentification,
    this.providerName,
    this.paymentMethodId,
    this.paymentMethodName,
    this.bankId,
    this.bankName,
    this.transRef,
    this.amount,
    this.currencyId,
    this.ordenNumString,
    this.createdAt,
  });

  PaymentOrden copyWith({
    String? id,
    String? ref,
    String? refString,
    int? paymentMethodId,
    String? paymentMethodName,
    int? bankId,
    String? bankName,
    String? transRef,
    double? amount,
    DateTime? createdAt,
  }) {
    return PaymentOrden(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      refString: refString ?? this.refString,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      bankId: bankId ?? this.bankId,
      bankName: bankName ?? this.bankName,
      transRef: transRef ?? this.transRef,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ref': ref,
      'refString': refString,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'bankId': bankId,
      'bankName': bankName,
      'transRef': transRef,
      'amount': amount,
      'currencyId':currencyId,
      'ordenNumString':ordenNumString,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory PaymentOrden.fromMap(Map<String, dynamic> map) {
    return PaymentOrden(
      id: map['id'] != null ? map['id'] as String : null,
      ref: map['ref'] != null ? map['ref'] as String : null,
      refString: map['refString'] != null ? map['refString'] as String : null,
      providerIdentification: map['providerIdentification'],
      providerName: map['providerName'],
      paymentMethodId: map['paymentMethodId'] != null ? map['paymentMethodId'] as int : null,
      paymentMethodName: map['paymentMethodName'] != null ? map['paymentMethodName'] as String : null,
      bankId: map['bankId'] != null ? map['bankId'] as int : null,
      bankName: map['bankName'] != null ? map['bankName'] as String : null,
      transRef: map['transRef'] != null ? map['transRef'] as String : null,
      amount: map['amount'] != null ? double.parse(map['amount']) : null,
      currencyId: map['currencyId'],
      ordenNumString: map['ordenNumString'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']).toLocal() : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaymentOrden.fromJson(String source) => PaymentOrden.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaymentOrden(id: $id, ref: $ref, refString: $refString, paymentMethodId: $paymentMethodId, paymentMethodName: $paymentMethodName, bankId: $bankId, bankName: $bankName, transRef: $transRef, amount: $amount, currencyId: $currencyId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant PaymentOrden other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.ref == ref &&
      other.refString == refString &&
      other.paymentMethodId == paymentMethodId &&
      other.paymentMethodName == paymentMethodName &&
      other.bankId == bankId &&
      other.bankName == bankName &&
      other.transRef == transRef &&
      other.amount == amount &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      ref.hashCode ^
      refString.hashCode ^
      paymentMethodId.hashCode ^
      paymentMethodName.hashCode ^
      bankId.hashCode ^
      bankName.hashCode ^
      transRef.hashCode ^
      amount.hashCode ^
      createdAt.hashCode;
  }
}
