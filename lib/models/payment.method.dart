import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class PaymentMethod {
  int? id;
  String? name;
  PaymentMethod({
    this.id,
    this.name,
  });

  static Future<List<PaymentMethod>> get() async {
    try {
      var res = await apiUresax.get('/paymentsmethods/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<PaymentMethod>.from(
            (data as List).map((x) => PaymentMethod.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  PaymentMethod copyWith({
    int? id,
    String? name,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'],
      name: map['name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory PaymentMethod.fromJson(String source) =>
      PaymentMethod.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PaymentMethod(id: $id, name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is PaymentMethod && o.id == id && o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
