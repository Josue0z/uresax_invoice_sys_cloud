import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';


class Taxes {
  int? id;
  String? name;
  double? rate;
  Taxes({
    this.id,
    this.name,
    this.rate,
  });

  static Future<List<Taxes>> get() async {
    try {
      var res = await apiUresax.get('/taxes/all');

      if(res.statusCode == 200){
        var data = res.data;
        return List<Taxes>.from((data as List).map((x) => Taxes.fromMap(x)));
      }
       return [];
    } on DioException catch (e) {
    throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Taxes copyWith({
    int? id,
    String? name,
    double? rate,
  }) {
    return Taxes(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
    };
  }

  factory Taxes.fromMap(Map<String, dynamic> map) {
    return Taxes(
      id: map['id'],
      name: map['name'],
      rate: map['rate'] != null ? double.parse(map['rate']) : 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Taxes.fromJson(String source) =>
      Taxes.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Taxes(id: $id, name: $name, rate: $rate)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Taxes && o.id == id && o.name == name && o.rate == rate;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ rate.hashCode;
}
