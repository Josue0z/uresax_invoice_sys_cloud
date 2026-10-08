// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class Denominations {
  String? id;
  String? currency;
  double? value;
  String? description;
  bool? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  Denominations({
    this.id,
    this.currency,
    this.value,
    this.description,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  static Future<List<Denominations>> get() async {
    try {
      var res = await apiUresax.get('/cash-shift/denominations');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Denominations>.from(
            (data as List).map((x) => Denominations.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Denominations copyWith({
    String? id,
    String? currency,
    double? value,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Denominations(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      value: value ?? this.value,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'currency': currency,
      'value': value,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Denominations.fromMap(Map<String, dynamic> map) {
    return Denominations(
      id: map['id'] != null ? map['id'] as String : null,
      currency: map['currency'] != null ? map['currency'] as String : null,
      value: map['value'] != null ? double.parse(map['value']) : null,
      description:
          map['description'] != null ? map['description'] as String : null,
      isActive: map['isActive'] != null ? map['isActive'] as bool : null,
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Denominations.fromJson(String source) =>
      Denominations.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Denominations(id: $id, currency: $currency, value: $value, description: $description, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant Denominations other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.currency == currency &&
        other.value == value &&
        other.description == description &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        currency.hashCode ^
        value.hashCode ^
        description.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class CashShiftModel {
  String? id;
  String? description;
  String? cashShiftNumber;
  String? companyId;
  DateTime? shiftDate;
  double? openingAmount;
  double? effective;
  double? creditCard;
  double? checkOrTransf;
  double? saleToCredit;
  double? totalAmount;
  double? totalTax;
  double? effectiveCount;
  int? status;
  String? statusName;
  String? createdBy;
  String? userName;
  int? periodId;
  String? periodName;
  int? boxId;
  String? boxName;
  Map<String, dynamic>? denominations;
  DateTime? updatedAt;
  DateTime? createdAt;
  double? effectiveCalc;
  int? transactionsCount;
  double? missingCash;
  double? effectiveCalcElectronic;
  double? effectiveCalcPreventa;
  int? transactionsCountElectronic;
  int? transactionsCountPreventa;

  double? creditCardCalcElectronic;
  double? creditCardCalcPreventa;

  CashShiftModel(
      {this.id,
      this.description,
      this.cashShiftNumber,
      this.companyId,
      this.shiftDate,
      this.openingAmount,
      this.effective,
      this.creditCard,
      this.checkOrTransf,
      this.saleToCredit,
      this.totalAmount,
      this.totalTax,
      this.effectiveCount,
      this.status,
      this.statusName,
      this.createdBy,
      this.userName,
      this.periodId,
      this.periodName,
      this.boxId,
      this.boxName,
      this.denominations,
      this.updatedAt,
      this.createdAt,
      this.effectiveCalc = 0,
      this.transactionsCount = 0,
      this.missingCash = 0,
      this.effectiveCalcElectronic = 0,
      this.effectiveCalcPreventa = 0,
      this.transactionsCountElectronic = 0,
      this.transactionsCountPreventa = 0,
      this.creditCardCalcElectronic = 0,
      this.creditCardCalcPreventa = 0});

  Color get color {
    if (status == 1 || status == 3 || status == 5) {
      return Colors.green;
    }
    return Colors.red;
  }

  static Future<List<CashShiftModel>> get(
      {required DateTime startDate,
      required DateTime endDate,
      String? search}) async {
    try {
      var params = '';

      var parameters = [];

      if (search != null) {
        parameters.add('search=$search');
      }

      params = '&${parameters.join('&')}';

      var res = await apiUresax.get(
          '/cash-shifts/all?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}$params');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<CashShiftModel>.from(
            (data as List).map((x) => CashShiftModel.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<CashShiftModel?> openCashShift() async {
    try {
      var res = await apiUresax.post('/cash-shift/open', data: toMap());

      if (res.statusCode == 200) {
        var data = res.data;
        return CashShiftModel.fromMap(data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<CashShiftModel?> closeCashShiftReport() async {
    try {
      var res =
          await apiUresax.put('/cash-shift/close-finish/$id', data: toMap());

      if (res.statusCode == 200) {
        var data = res.data;
        return CashShiftModel.fromMap(data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  static Future<bool> closeCashShiftTurno({required String id}) async {
    try {
      var res = await apiUresax.put('/cash-shift/close/$id');

      if (res.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  CashShiftModel copyWith(
      {String? id,
      String? description,
      String? cashShiftNumber,
      String? companyId,
      DateTime? shiftDate,
      double? openingAmount,
      double? effective,
      double? creditCard,
      double? checkOrTransf,
      double? saleToCredit,
      double? totalAmount,
      double? totalTax,
      double? effectiveCount,
      int? status,
      String? statusName,
      String? createdBy,
      String? userName,
      int? periodId,
      String? periodName,
      int? boxId,
      String? boxName,
      Map<String, dynamic>? denominations,
      DateTime? updatedAt,
      DateTime? createdAt}) {
    return CashShiftModel(
        id: id ?? this.id,
        description: description ?? this.description,
        cashShiftNumber: cashShiftNumber ?? this.cashShiftNumber,
        companyId: companyId ?? this.companyId,
        shiftDate: shiftDate ?? this.shiftDate,
        openingAmount: openingAmount ?? this.openingAmount,
        effective: effective ?? this.effective,
        creditCard: creditCard ?? this.creditCard,
        checkOrTransf: checkOrTransf ?? this.checkOrTransf,
        saleToCredit: saleToCredit ?? this.saleToCredit,
        totalAmount: totalAmount ?? this.totalAmount,
        totalTax: totalTax ?? this.totalTax,
        effectiveCount: effectiveCount ?? this.effectiveCount,
        status: status ?? this.status,
        statusName: statusName ?? this.statusName,
        createdBy: createdBy ?? this.createdBy,
        userName: userName ?? this.userName,
        periodId: periodId ?? this.periodId,
        periodName: periodName ?? this.periodName,
        boxId: boxId ?? this.boxId,
        boxName: boxName ?? this.boxName,
        denominations: denominations ?? this.denominations,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'description': description,
      'cashShiftNumber': cashShiftNumber,
      'companyId': companyId,
      'shiftDate': shiftDate?.toIso8601String(),
      'openingAmount': openingAmount,
      'effective': effective,
      'creditCard': creditCard,
      'checkOrTransf': checkOrTransf,
      'saleToCredit': saleToCredit,
      'totalAmount': totalAmount,
      'totalTax': totalTax,
      'effectiveCount': effectiveCount,
      'status': status,
      'statusName': statusName,
      'createdBy': createdBy,
      'userName': userName,
      'periodId': periodId,
      'periodName': periodName,
      'boxId': boxId,
      'boxName': boxName,
      'denominations': denominations,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String()
    };
  }

  factory CashShiftModel.fromMap(Map<String, dynamic> map) {
    return CashShiftModel(
        id: map['id'] != null ? map['id'] as String : null,
        description:
            map['description'] != null ? map['description'] as String : null,
        cashShiftNumber: map['cashShiftNumber'],
        companyId: map['companyId'] != null ? map['companyId'] as String : null,
        shiftDate:
            map['shiftDate'] != null ? DateTime.parse(map['shiftDate']) : null,
        openingAmount: map['openingAmount'] != null
            ? double.parse(map['openingAmount'])
            : null,
        effective:
            map['effective'] != null ? double.parse(map['effective']) : null,
        creditCard:
            map['creditCard'] != null ? double.parse(map['creditCard']) : null,
        checkOrTransf: map['checkOrTransf'] != null
            ? double.parse(map['checkOrTransf'])
            : null,
        saleToCredit: map['saleToCredit'] != null
            ? double.parse(map['saleToCredit'])
            : null,
        totalAmount: map['totalAmount'] != null
            ? double.parse(map['totalAmount'])
            : null,
        totalTax:
            map['totalTax'] != null ? double.parse(map['totalTax']) : null,
        effectiveCount: map['effectiveCount'] != null
            ? double.parse(map['effectiveCount'])
            : null,
        status: map['status'] != null ? map['status'] as int : null,
        statusName:
            map['statusName'] != null ? map['statusName'] as String : null,
        createdBy: map['createdBy'] != null ? map['createdBy'] as String : null,
        userName: map['userName'] != null ? map['userName'] as String : null,
        periodId: map['periodId'] != null ? map['periodId'] as int : null,
        periodName:
            map['periodName'] != null ? map['periodName'] as String : null,
        boxId: map['boxId'] != null ? map['boxId'] as int : null,
        boxName: map['boxName'] != null ? map['boxName'] as String : null,
        denominations: map['denominations'] != null
            ? (map['denominations'] is String
                ? jsonDecode(map['denominations'])
                : map['denominations'])
            : null,
        effectiveCalc: map['effectiveCalc'] != null
            ? double.parse(map['effectiveCalc'])
            : 0,
        updatedAt:
            map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
        createdAt:
            map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
        transactionsCount: map['transactionsCount'],
        transactionsCountElectronic: map['transactionsCountElectronic'],
        transactionsCountPreventa: map['transactionsCountPreventa'],
        missingCash: map['missingCash'] != null
            ? double.parse(map['missingCash'])
            : 0,
        effectiveCalcPreventa: map['effectiveCalcPreventa'] != null
            ? double.parse(map['effectiveCalcPreventa'])
            : 0,
        effectiveCalcElectronic: map['effectiveCalcElectronic'] != null
            ? double.parse(map['effectiveCalcElectronic'])
            : 0,
            creditCardCalcPreventa: map['creditCardCalcPreventa'] != null
                ? double.parse(map['creditCardCalcPreventa'])
                : 0,
            creditCardCalcElectronic: map['creditCardCalcElectronic'] != null
                ? double.parse(map['creditCardCalcElectronic'])
                : 0);
  }

  String toJson() => json.encode(toMap());

  factory CashShiftModel.fromJson(String source) =>
      CashShiftModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CashShiftModel(id: $id, description: $description, cashShiftNumber: $cashShiftNumber, companyId: $companyId, shiftDate: $shiftDate, openingAmount: $openingAmount, effective: $effective, creditCard: $creditCard, checkOrTransf: $checkOrTransf, saleToCredit: $saleToCredit, totalAmount: $totalAmount, totalTax: $totalTax, effectiveCount: $effectiveCount, status: $status, statusName: $statusName, createdBy: $createdBy, userName: $userName, periodId: $periodId, periodName: $periodName, boxId: $boxId, boxName: $boxName, denominations: $denominations, updatedAt: $updatedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant CashShiftModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.description == description &&
        other.cashShiftNumber == cashShiftNumber &&
        other.companyId == companyId &&
        other.shiftDate == shiftDate &&
        other.openingAmount == openingAmount &&
        other.effective == effective &&
        other.creditCard == creditCard &&
        other.checkOrTransf == checkOrTransf &&
        other.saleToCredit == saleToCredit &&
        other.totalAmount == totalAmount &&
        other.totalTax == totalTax &&
        other.effectiveCount == effectiveCount &&
        other.status == status &&
        other.statusName == statusName &&
        other.createdBy == createdBy &&
        other.userName == userName &&
        other.periodId == periodId &&
        other.periodName == periodName &&
        other.boxId == boxId &&
        other.boxName == boxName &&
        other.denominations == denominations &&
        other.updatedAt == updatedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        description.hashCode ^
        cashShiftNumber.hashCode ^
        companyId.hashCode ^
        shiftDate.hashCode ^
        openingAmount.hashCode ^
        effective.hashCode ^
        creditCard.hashCode ^
        checkOrTransf.hashCode ^
        saleToCredit.hashCode ^
        totalAmount.hashCode ^
        totalTax.hashCode ^
        effectiveCount.hashCode ^
        status.hashCode ^
        statusName.hashCode ^
        createdBy.hashCode ^
        userName.hashCode ^
        periodId.hashCode ^
        periodName.hashCode ^
        boxId.hashCode ^
        boxName.hashCode ^
        denominations.hashCode ^
        updatedAt.hashCode ^
        createdAt.hashCode;
  }
}
