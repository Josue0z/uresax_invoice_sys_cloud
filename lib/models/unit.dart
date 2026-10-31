// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
class Unit {
  int? id;
  String? code;
  String? name;
  String? symbol;
  double? conversionFactor;
  bool? isBaseUnit;
  bool? status;
  DateTime? createdAt;
  Unit({
    this.id,
    this.code,
    this.name,
    this.symbol,
    this.conversionFactor,
    this.isBaseUnit,
    this.status,
    this.createdAt,
  });

  static Future<List<Unit>> get() async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/units/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Unit>.from((data as List).map((x) => Unit.fromMap(x)));
      }
      return [];
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Unit?> create() async {
    try {
            await User.authClient();
      var res = await apiUresax.post('/units/create', data: {
        'code': code,
        'name': name,
        'symbol': symbol,
        'conversionFactor': conversionFactor,
        'isBaseUnit': isBaseUnit,
        'status': status
      });

      if (res.statusCode == 200) {
        var data = res.data;
        return Unit.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Unit?> update() async {
    try {
            await User.authClient();
      var res = await apiUresax.put('/units/update/$id', data: {
        'code': code,
        'name': name,
        'symbol': symbol,
        'conversionFactor': conversionFactor,
        'isBaseUnit': isBaseUnit,
        'status': status
      });

      if(res.statusCode == 200){
        var data = res.data;
        return Unit.fromMap(data);
      }
     
      return null;
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Unit copyWith({
    int? id,
    String? code,
    String? name,
    String? symbol,
    double? conversionFactor,
    bool? isBaseUnit,
    bool? status,
    DateTime? createdAt,
  }) {
    return Unit(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      isBaseUnit: isBaseUnit ?? this.isBaseUnit,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'conversionFactor': conversionFactor,
      'isBaseUnit': isBaseUnit,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] != null ? map['id'] as int : null,
      code: map['code'] != null ? map['code'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      symbol: map['symbol'] != null ? map['symbol'] as String : null,
      conversionFactor: map['conversionFactor'] != null
          ? double.parse(map['conversionFactor'])
          : null,
      isBaseUnit: map['isBaseUnit'] != null ? map['isBaseUnit'] as bool : null,
      status: map['status'] != null ? map['status'] as bool : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt']).toLocal()
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Unit.fromJson(String source) =>
      Unit.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Unit(id: $id, code: $code, name: $name, symbol: $symbol, conversionFactor: $conversionFactor, isBaseUnit: $isBaseUnit, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Unit other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.code == code &&
        other.name == name &&
        other.symbol == symbol &&
        other.conversionFactor == conversionFactor &&
        other.isBaseUnit == isBaseUnit &&
        other.status == status &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        code.hashCode ^
        name.hashCode ^
        symbol.hashCode ^
        conversionFactor.hashCode ^
        isBaseUnit.hashCode ^
        status.hashCode ^
        createdAt.hashCode;
  }
}
