import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';

class NcfType {
  String? id;
  String? name;
  int? minLimit;
  int? maxLimit;
  NcfType({this.id, this.name, this.minLimit, this.maxLimit});

  static Future<List<NcfType>> get() async {
    try {
      var res = await apiUresax.get('/ncfs/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<NcfType>.from(
            (data as List).map((x) => NcfType.fromMap(x)));
      }
      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<String> getLastSeq() async {
    try {
      final conne = SqlConector.connection;
      var result =
          await conne?.execute('select last_value from public."${id}_seq"');

      if (result != null && result.isNotEmpty) {
        var el = result.first;
        var obj = el.toColumnMap();
        var lastVal = obj['last_value'];

        return lastVal.toString();
      }
      return '0';
    } catch (e) {
      rethrow;
    }
  }

  NcfType copyWith({
    String? id,
    String? name,
  }) {
    return NcfType(
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

  factory NcfType.fromMap(Map<String, dynamic> map) {
    return NcfType(
        id: map['id'],
        name: map['name'],
        minLimit: map['minLimit'],
        maxLimit: map['maxLimit']);
  }

  String toJson() => json.encode(toMap());

  factory NcfType.fromJson(String source) =>
      NcfType.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'NcfType(id: $id, name: $name, minLimit: $minLimit, maxLimit: $maxLimit)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is NcfType && o.id == id && o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
