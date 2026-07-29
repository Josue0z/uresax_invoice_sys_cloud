import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class RetentionIsr {
  String? id;
  String? name;
  double? rate;
  RetentionIsr({
    this.id,
    this.name,
    this.rate,
  });

  static Future<List<RetentionIsr>> get() async {
    try {
      var res = await apiUresax.get('/retentions-isrs/all');

      if(res.statusCode == 200){
        var data = res.data;
        return List<RetentionIsr>.from((data as List).map((x) => RetentionIsr.fromMap(x)));
      }
     
      return [];
    }on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  RetentionIsr copyWith({
    String? id,
    String? name,
    double? rate,
  }) {
    return RetentionIsr(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'rate': rate};
  }

  factory RetentionIsr.fromMap(Map<String, dynamic> map) {
    return RetentionIsr(id: map['id'], name: map['name'], rate: map['rate'] != null ? double.parse(map['rate']) : 0);
  }

  String toJson() => json.encode(toMap());

  factory RetentionIsr.fromJson(String source) =>
      RetentionIsr.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'RetentionIsr(id: $id, name: $name, rate: $rate)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RetentionIsr && o.id == id && o.name == name && o.rate == rate;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ rate.hashCode;
}
