import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';

class Permission {
  String? name;
  String? displayName;
  Permission({this.name, this.displayName});

  static Future<List<Permission>> get() async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/permissions/all');
      if(res.statusCode == 200){
             var data = res.data;
        var list = List<Permission>.from(
            (data as List).map((x) => Permission.fromMap(x)));
      return list;
      }
      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Permission copyWith({
    String? name,
  }) {
    return Permission(
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(name: map['name'], displayName: map['displayName']);
  }

  String toJson() => json.encode(toMap());

  factory Permission.fromJson(String source) =>
      Permission.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Permission(name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Permission && o.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
