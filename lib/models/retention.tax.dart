import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';


class RetentionTax {
  int? id;
  String? name;
  double? rate;
  RetentionTax({
    this.id,
    this.name,
    this.rate,
  });

  static Future<List<RetentionTax>> get() async {
    try {
      var res = await apiUresax.get('/retentions-taxes/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<RetentionTax>.from(
            (data as List).map((x) => RetentionTax.fromMap(x)));
      }
      return [];
    }on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  RetentionTax copyWith({
    int? id,
    String? name,
    double? rate,
  }) {
    return RetentionTax(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'rate': rate};
  }

  factory RetentionTax.fromMap(Map<String, dynamic> map) {
    return RetentionTax(
        id: map['id'],
        name: map['name'],
        rate: map['rate'] != null ? double.parse(map['rate']) : 0);
  }

  String toJson() => json.encode(toMap());

  factory RetentionTax.fromJson(String source) =>
      RetentionTax.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'RetentionTax(id: $id, name: $name, rate: $rate)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RetentionTax && o.id == id && o.name == name && o.rate == rate;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ rate.hashCode;
}
