import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class OverrideCode {
  int? id;
  String? name;
  OverrideCode({
    this.id,
    this.name,
  });
  static Future<List<OverrideCode>> get() async {
    try {
      var res = await apiUresax.get('/overridecodes/all');

      if(res.statusCode == 200) {
        var data = res.data;
        return List<OverrideCode>.from((data as List).map((x) => OverrideCode.fromMap(x)));
      }
      
      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  OverrideCode copyWith({
    int? id,
    String? name,
  }) {
    return OverrideCode(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory OverrideCode.fromMap(Map<String, dynamic> map) {
    return OverrideCode(
      id: map['id'],
      name: map['name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory OverrideCode.fromJson(String source) =>
      OverrideCode.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'OverrideCode(id: $id, name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is OverrideCode && o.id == id && o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
