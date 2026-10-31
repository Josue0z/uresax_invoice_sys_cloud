import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';

class Currency {
  int? id;
  String? name;
  String? code;
  Currency({
    this.id,
    this.name,
    this.code,
  });
  static Future<List<Currency>> get() async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/currencies/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Currency>.from(
            (data as List).map((x) => Currency.fromMap(x)));
      }
      return [];
    } on DioException catch (e) {
        throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Currency copyWith({
    int? id,
    String? name,
    String? code,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      id: map['id'],
      name: map['name'],
      code: map['code'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Currency.fromJson(String source) =>
      Currency.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Currency(id: $id, name: $name, code: $code)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Currency && o.id == id && o.name == name && o.code == code;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ code.hashCode;
}
