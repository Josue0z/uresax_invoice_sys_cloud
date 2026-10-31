import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
class DgiiState {
  int? id;
  String? name;
  DgiiState({
    this.id,
    this.name,
  });

  static Future<List<DgiiState>> get() async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/dgii-states/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<DgiiState>.from(
            (data as List).map((x) => DgiiState.fromMap(x)));
      }
      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  DgiiState copyWith({
    int? id,
    String? name,
  }) {
    return DgiiState(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory DgiiState.fromMap(Map<String, dynamic> map) {
    return DgiiState(
      id: map['id'],
      name: map['name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DgiiState.fromJson(String source) =>
      DgiiState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'DgiiState(id: $id, name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is DgiiState && o.id == id && o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
