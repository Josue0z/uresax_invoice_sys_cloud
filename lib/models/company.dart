import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';

class Company {
  String? id;
  String? name;
  String? comercialName;
  String? rncOrId;
  String? phone1;
  String? phone2;
  String? email;
  String? address;
  String? logo;
  DateTime? expirationDate;
  String? message;
  String? bankInfo;
  int? maxPreSales;
  String? instagramLink;
  Company(
      { 
        this.id,
        this.name,
        this.comercialName,
      this.rncOrId,
      this.phone1,
      this.phone2,
      this.email,
      this.address,
      this.logo,
      this.expirationDate,
      this.message,
      this.bankInfo,
      this.maxPreSales = 99999999,
      this.instagramLink});

  static Future<Company?> get() async {
    try {
      final conn = SqlConector.connection;
      var result =
          await conn?.execute('select * from public."Company" LIMIT 1');
      if (result != null) {
        var first = result[0];
        return Company.fromMap(first.toColumnMap());
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Company?> update() async {
    try {
      var res = await apiUresax.put('/companies/$id',data: toMap());

      if(res.statusCode == 200){
          return Company.fromMap(res.data);
      }
      return null;
     
    }on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Company copyWith({
    String? name,
    String? rncOrId,
    String? phone1,
    String? phone2,
    String? email,
    String? address,
    String? logo,
    String? message,
    String? bankInfo,
    int? maxPreSales,
    String? instagramLink
  }) {
    return Company(
      name: name ?? this.name,
      rncOrId: rncOrId ?? this.rncOrId,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      address: address ?? this.address,
      logo: logo ?? this.logo,
      message: message ?? this.message,
      bankInfo: bankInfo ?? this.bankInfo,
      maxPreSales:maxPreSales?? this.maxPreSales,
      instagramLink:instagramLink ?? this.instagramLink
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'comercialName': comercialName,
      'rncOrId': rncOrId,
      'phone1': phone1,
      'phone2': phone2,
      'email': email,
      'address': address,
      'logo': logo,
      'message':message,
      'bankInfo': bankInfo,
      'maxPreSales':maxPreSales,
      'instagramLink':instagramLink
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
        id: map['id'],
        name: map['name'],
        comercialName:Platform.environment['URESAX_INVOICE_COMPANY_COMERCIAL_NAME'] ?? map['comercialName'],
        rncOrId: map['rncOrId'],
        phone1: map['phone1'],
        phone2: map['phone2'],
        email: map['email'],
        address: map['address'],
        logo: map['logo'],
        message: map['message'],
        bankInfo: map['bankInfo'],
        maxPreSales: map['maxPreSales'],
        instagramLink: map['instagramLink']);
  }

  String toJson() => json.encode(toMap());

  factory Company.fromJson(String source) =>
      Company.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Company(id: $id, name: $name,comercialName: $comercialName, rncOrId: $rncOrId, phone1: $phone1, phone2: $phone2, email: $email, address: $address, logo: $logo, message: $message, bankInfo: $bankInfo, maxPreSales: $maxPreSales,instagramLink:$instagramLink)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Company &&
        o.id == id &&
        o.name == name &&
        o.comercialName == comercialName &&
        o.rncOrId == rncOrId &&
        o.phone1 == phone1 &&
        o.phone2 == phone2 &&
        o.email == email &&
        o.address == address &&
        o.logo == logo;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        comercialName.hashCode ^
        rncOrId.hashCode ^
        phone1.hashCode ^
        phone2.hashCode ^
        email.hashCode ^
        address.hashCode ^
        logo.hashCode;
  }
}
