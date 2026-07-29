import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class PaymentType {
  int? id;
  String? name;
  PaymentType({
    this.id,
    this.name,
  });

  static Future<List<PaymentType>> get() async {
    try {
      var res = await apiUresax.get('/payment-type/all');
      if (res.statusCode == 200) {
        var data = res.data;
        return List<PaymentType>.from(
            (data as List).map((x) => PaymentType.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  PaymentType copyWith({
    int? id,
    String? name,
  }) {
    return PaymentType(
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

  factory PaymentType.fromMap(Map<String, dynamic> map) {
    return PaymentType(id: map['id'], name: map['name']);
  }

  String toJson() => json.encode(toMap());

  factory PaymentType.fromJson(String source) =>
      PaymentType.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PaymentType(id: $id, name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is PaymentType && o.id == id && o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
