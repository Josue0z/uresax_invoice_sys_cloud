import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class WareHouses {
  int? id;
  String? name;
  DateTime? createdAt;
  WareHouses({
    this.id,
    this.name,
    this.createdAt,
  });
  static Future<List<WareHouses>> get({String? search}) async {
    try {
      String params = '?';
      if (search != null) {
        params += 'search=$search';
      }

      var res = await apiUresax.get('/warehouses/all$params');
      if (res.statusCode == 200) {
        var data = res.data;
        var list = List<WareHouses>.from(
            (data as List).map((x) => WareHouses.fromMap(x)));
        return [WareHouses(name: 'SELECCIONAR ALMACEN'), ...list];
      }

      return [];
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<WareHouses?> create() async {
    try {
      var parameters = toMap();
      parameters.remove('id');
      parameters.remove('createdAt');

      var res = await apiUresax.post('/warehouses/create', data: parameters);

      if (res.statusCode == 200) {
        var data = res.data;
        return WareHouses.fromMap(data);
      }
      return null;
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<WareHouses?> update() async {
    try {
      var parameters = toMap();

      parameters.remove('createdAt');

      var res = await apiUresax.put('/warehouses/update/$id', data: parameters);

      if (res.statusCode == 200) {
        var data = res.data;
        return WareHouses.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  WareHouses copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return WareHouses(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': createdAt?.toIso8601String()};
  }

  factory WareHouses.fromMap(Map<String, dynamic> map) {
    return WareHouses(
      id: map['id'],
      name: map['name'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt']).toLocal()
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WareHouses.fromJson(String source) =>
      WareHouses.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'WareHouses(id: $id, name: $name, createdAt: $createdAt)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is WareHouses &&
        o.id == id &&
        o.name == name &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdAt.hashCode;
}
