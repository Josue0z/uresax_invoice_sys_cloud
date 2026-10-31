import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
class Drivers {
  int? id;
  String? name;
  String? phone;
  String? email;
  DateTime? createdAt;
  Drivers({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.createdAt,
  });

  static Future<List<Drivers>> get({String? search}) async {
    try {
            await User.authClient();
      String params = '?';

      if (search != null) {
        params += 'search=$search';
      }
      var res = await apiUresax.get('/drivers/all$params');
      if (res.statusCode == 200) {
        var data = res.data;
        return List<Drivers>.from(
            (data as List).map((x) => Drivers.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Drivers?> create() async {
    try {
            await User.authClient();
      var res = await apiUresax.post('/drivers/create',
          data: {'name': name, 'phone': phone, 'email': email});

      if (res.statusCode == 200) {
        var data = res.data;
        return Drivers.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Drivers?> update() async {
    try {
            await User.authClient();
      var res = await apiUresax.put('/drivers/update/$id',
          data: {'name': name, 'phone': phone, 'email': email});

      if(res.statusCode == 200) {
        var data = res.data;
        return Drivers.fromMap(data);
      }
     
     return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Drivers copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    DateTime? createdAt,
  }) {
    return Drivers(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': createdAt
    };
  }

  factory Drivers.fromMap(Map<String, dynamic> map) {
    return Drivers(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        email: map['email'],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt']).toLocal()
            : null);
  }

  String toJson() => json.encode(toMap());

  factory Drivers.fromJson(String source) =>
      Drivers.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Drivers(id: $id, name: $name, phone: $phone, email: $email, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Drivers &&
        o.id == id &&
        o.name == name &&
        o.phone == phone &&
        o.email == email &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        createdAt.hashCode;
  }
}
