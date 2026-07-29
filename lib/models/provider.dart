import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class Providers {
  int? id;
  String? name;
  String? rncOrId;
  DateTime? createdAt;
  String? phone;
  String? email;
  String? address;
  Providers(
      {this.id,
      this.name,
      this.rncOrId,
      this.phone,
      this.email,
      this.address,
      this.createdAt});
  static Future<List<Providers>> get({String? search}) async {
    try {
      String params = '?';

      if (search != null) {
        params += 'search=$search';
      }
      var res = await apiUresax.get('/providers/all$params');

      if (res.statusCode == 200) {
        var data = res.data;
        var list = List<Providers>.from(
            (data as List).map((x) => Providers.fromMap(x)));

        return [Providers(name: 'SELECCIONAR PROVEEDOR'), ...list];
      }
      return [];
    }on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Providers?> create() async {
    try {
      var parameters = toMap();
      parameters.remove('id');
      parameters.remove('createdAt');

      var res = await apiUresax.post('/providers/create', data: parameters);

      if (res.statusCode == 200) {
        var data = res.data;
        return Providers.fromMap(data);
      }

      return null;
    } on DioException  catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Providers?> update() async {
    try {
      var parameters = toMap();
      parameters.remove('id');
      parameters.remove('createdAt');
      var res = await apiUresax.put('/providers/update/$id', data: parameters);

      if (res.statusCode == 200) {
        var data = res.data;
        return Providers.fromMap(data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Providers copyWith({
    int? id,
    String? name,
    String? rncOrId,
    DateTime? createdAt,
  }) {
    return Providers(
      id: id ?? this.id,
      name: name ?? this.name,
      rncOrId: rncOrId ?? this.rncOrId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rncOrId': rncOrId,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt
    };
  }

  factory Providers.fromMap(Map<String, dynamic> map) {
    return Providers(
        id: map['id'],
        name: map['name'],
        rncOrId: map['rncOrId'],
        phone: map['phone'],
        email: map['email'],
        address: map['address'],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt']).toLocal()
            : null);
  }

  String toJson() => json.encode(toMap());

  factory Providers.fromJson(String source) =>
      Providers.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Providers(id: $id, name: $name, rncOrId: $rncOrId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Providers &&
        o.id == id &&
        o.name == name &&
        o.rncOrId == rncOrId &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ rncOrId.hashCode ^ createdAt.hashCode;
  }
}
