// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class PaymentMode {
  int? id;
  String? name;
  PaymentMode({
    this.id,
    this.name,
  });

  static Future<List<PaymentMode>> get() async {
    try {
      var res = await apiUresax.get('/paymentsmodes/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<PaymentMode>.from(
            (data as List).map((x) => PaymentMode.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  PaymentMode copyWith({
    int? id,
    String? name,
  }) {
    return PaymentMode(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  factory PaymentMode.fromMap(Map<String, dynamic> map) {
    return PaymentMode(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] != null ? map['name'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaymentMode.fromJson(String source) =>
      PaymentMode.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PaymentMode(id: $id, name: $name)';

  @override
  bool operator ==(covariant PaymentMode other) {
    if (identical(this, other)) return true;

    return other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
