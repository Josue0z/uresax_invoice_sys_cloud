import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/branche.dart';
import 'package:uresax_invoice_sys_cloud/models/company.dart';
import 'package:uresax_invoice_sys_cloud/models/discount.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/models/box.dart' as bx;
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class User {
  String? id;
  String? username;
  String? password;
  String? name;
  String? phone;
  String? email;
  List<String>? permissions;
  DateTime? createdAt;
  int? roleId;
  String? roleName;
  int? boxId;
  String? boxName;
  Company? company;
  User(
      {this.id,
      this.username,
      this.password,
      this.name,
      this.phone,
      this.email,
      this.permissions = const [],
      this.createdAt,
      this.roleId,
      this.roleName,
      this.boxId,
      this.boxName,
      this.company});

  static Future<List<User>> get() async {
    try {
      var res = await apiUresax.get('/users/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<User>.from((data as List).map((x) => User.fromMap(x)));
      }
      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  static Future<User?> login(String username, String password) async {
    try {
      var res = await apiUresax.post('/users/login',
          data: {'username': username, 'password': password});

      if (res.statusCode == 200) {
        var data = res.data;
        var user = User.fromMap(data['user']);


        apiUresax = Dio(
          BaseOptions(
            baseUrl: apiUresax.options.baseUrl,
            contentType: 'application/json',
            headers: {
              'x-companyid': user.company?.id,
              'x-userid': user.id,
              'x-token':Platform.environment['URESAX_INVOICE_API_TOKEN'],
              'Content-Type':'application/json'
            }
          )
        );

     

        await loadMetaData();
       
        wareHouses = await WareHouses.get();
        discounts = [
          Discount(
            name: 'DESCUENTO',
          ),
          ...await Discount.get()
        ];

        boxes = [bx.Box(name: 'CAJA'), ...await bx.Box.get()];

        branches =  [BrancheModel(name:'SUCURSAL'),...await BrancheModel.get()];
    
        return user;
      }

      return null;
    } on DioException catch (e) {
    
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<User?> create() async {
    try {
      var res = await apiUresax.post('/users/create', data: {
        'username': username,
        'password': password,
        'name': name,
        'phone': phone,
        'email': email,
        'permissions': '{${permissions?.map((e) => e).toList().join(',')}}',
        'roleId': roleId,
        'boxId': boxId
      });

      if (res.statusCode == 200) {
        var user = User.fromMap(res.data);
        return user;
      }

      return null;
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<User?> update() async {
    try {
      var res = await apiUresax.put('/users/update/$id', data: {
        'username': username,
        'name': name,
        'phone': phone,
        'email': email,
        'permissions': '{${permissions?.map((e) => e).toList().join(',')}}',
        'roleId': roleId,
        'boxId': boxId
      });

      if (res.statusCode == 200) {
        var user = User.fromMap(res.data);
        return user;
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? name,
    String? phone,
    String? email,
    List<String>? permissions,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'phone': phone,
      'email': email,
      'permissions': permissions?.map((x) => x).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'boxId': boxId
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
        id: map['id'],
        username: map['username'],
        password: map['password'],
        name: map['name'],
        phone: map['phone'],
        email: map['email'],
        permissions: map['permissions'] != null
            ? (map['permissions'] as List).map((x) => x).toList().cast<String>()
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt']).toLocal()
            : null,
        roleId: map['roleId'],
        roleName: map['roleName'],
        boxId:localStorage.getItem('URESAX_INVOICE_CURRENT_BOX_ID_${map['id']}') ??  map['boxId'],
        boxName: map['boxName'],
        company:
            map['company'] != null ? Company.fromMap(map['company']) : null);
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(id: $id, username: $username, password: $password, name: $name, phone: $phone, email: $email, permissions: $permissions, roleId: $roleId, roleName: $roleName, boxId: $boxId, boxName: $boxName, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is User &&
        o.id == id &&
        o.username == username &&
        o.password == password &&
        o.name == name &&
        o.phone == phone &&
        o.email == email &&
        listEquals(o.permissions, permissions) &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        password.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        permissions.hashCode ^
        createdAt.hashCode;
  }
}
