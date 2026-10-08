// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';



class BrancheModel {
  int? id;
  String? name;
  String? phone1;
  String? phone2;
  String? address;
  String? email;
  String? companyId;
  DateTime? createdAt;
  BrancheModel({
    this.id,
    this.name,
    this.phone1,
    this.phone2,
    this.address,
    this.email,
    this.companyId,
    this.createdAt
  });

    static Future<List<BrancheModel>> get() async {
    try {
      var res = await apiUresax.get('/branches/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<BrancheModel>.from((data as List).map((x) => BrancheModel.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
        throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<BrancheModel?> create() async {
    try {
      var res = await apiUresax.post('/branches/create', data: toMap());

      if (res.statusCode == 200) {
        var data = res.data;
        return BrancheModel.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
    throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<BrancheModel?> update() async {
    try {
      var res = await apiUresax.put('/branches/update/$id', data: toMap());

      if(res.statusCode ==  200) {
        var data = res.data;
        return BrancheModel.fromMap(data);
      }
      
      return null;
    } on DioException catch (e) {
        throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  BrancheModel copyWith({
    int? id,
    String? name,
    String? phone1,
    String? phone2,
    String? address,
    String? email,
  }) {
    return BrancheModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      address: address ?? this.address,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone1': phone1,
      'phone2': phone2,
      'address': address,
      'email': email,
      'createdAt': createdAt?.toIso8601String()
    };
  }

  factory BrancheModel.fromMap(Map<String, dynamic> map) {
    return BrancheModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] != null ? map['name'] as String : null,
      phone1: map['phone1'] != null ? map['phone1'] as String : null,
      phone2: map['phone2'] != null ? map['phone2'] as String : null,
      address: map['address'] != null ? map['address'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      companyId: map['companyId'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null
    );
  }

  String toJson() => json.encode(toMap());

  factory BrancheModel.fromJson(String source) => BrancheModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BrancheModel(id: $id, name: $name, phone1: $phone1, phone2: $phone2, address: $address, email: $email)';
  }

  @override
  bool operator ==(covariant BrancheModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name &&
      other.phone1 == phone1 &&
      other.phone2 == phone2 &&
      other.address == address &&
      other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      phone1.hashCode ^
      phone2.hashCode ^
      address.hashCode ^
      email.hashCode;
  }
}
