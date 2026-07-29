import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class Role {
  int? id;
  String? name;
  Role({
    this.id,
    this.name,
  });

  static Future<List<Role>> get() async {
    try {
      var res = await apiUresax.get('/roles/all');
       if(res.statusCode == 200){
             var data = res.data;
        var list = List<Role>.from(
            (data as List).map((x) => Role.fromMap(x)));
      return list;
      }
      return [];
    }on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Role copyWith({
    int? id,
    String? name,
  }) {
    return Role(
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

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'],
      name: map['name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Role.fromJson(String source) =>
      Role.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Role(id: $id, name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Role && o.id == id && o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
