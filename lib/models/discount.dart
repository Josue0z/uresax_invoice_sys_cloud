import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';

class Discount {
  int? id;
  String? name;
  double? rate;
  int? symbolId;
  String? symbolName;
  Discount({
    this.id,
    this.name,
    this.rate,
    this.symbolId,
    this.symbolName,
  });
  static Future<List<Discount>> get() async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/discounts/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Discount>.from(
            (data as List).map((x) => Discount.fromMap(x)));
      }
      return [];
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Discount?> create() async {
    try {
            await User.authClient();
      var res = await apiUresax.post('/discounts/create',
          data: {'name': name, 'rate': rate, 'symbolId': symbolId});
      if (res.statusCode == 200) {
        var data = res.data;
        return Discount.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Discount?> update() async {
    try {
            await User.authClient();
      var res = await apiUresax.put('/discounts/update/$id',
          data: {'name': name, 'rate': rate, 'symbolId': symbolId});

      if (res.statusCode == 200) {
        var data = res.data;
        return Discount.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Discount copyWith({
    int? id,
    String? name,
    double? rate,
    int? symbolId,
    String? symbolName,
  }) {
    return Discount(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      symbolId: symbolId ?? this.symbolId,
      symbolName: symbolName ?? this.symbolName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
      'symbolId': symbolId,
      'symbolName': symbolName,
    };
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['id'],
      name: map['name'],
      rate: double.parse(map['rate']),
      symbolId: map['symbolId'],
      symbolName: map['symbolName'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Discount.fromJson(String source) =>
      Discount.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Discount(id: $id, name: $name, rate: $rate, symbolId: $symbolId, symbolName: $symbolName)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Discount &&
        o.id == id &&
        o.name == name &&
        o.rate == rate &&
        o.symbolId == symbolId &&
        o.symbolName == symbolName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        rate.hashCode ^
        symbolId.hashCode ^
        symbolName.hashCode;
  }
}
