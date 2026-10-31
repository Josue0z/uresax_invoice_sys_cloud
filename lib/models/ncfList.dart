import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class NcfsList {
  int? id;
  String? ncfTypeId;
  String? ncfTypeName;
  int? start;
  int? end;
  DateTime? expirationDate;
  DateTime? createdAt;
  bool? finish;
  int? lastNumber;
  NcfsList(
      {this.id,
      this.ncfTypeId,
      this.ncfTypeName,
      this.start,
      this.end,
      this.expirationDate,
      this.createdAt,
      this.finish = false,
      this.lastNumber = 1});

  Color get color {
    return finish == true ? Colors.green : Colors.red;
  }

  String get label {
    return finish == false ? 'SIN FINALIZAR' : 'FINALIZADO';
  }

  static Future<List<NcfsList>> get() async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/ncfslist/all');
      if (res.statusCode == 200) {
        var data = res.data;
        ncfsLists = List<NcfsList>.from(
            (data as List).map((x) => NcfsList.fromMap(x)));
      return ncfsLists;
      }

      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<NcfsList?> findNcf() async {
    try {
           await User.authClient();
      var res = await apiUresax.get('/ncfslist/findncf/$ncfTypeId');
      if (res.statusCode == 200) {
        return NcfsList.fromMap(res.data);
      }

   
      if(res.statusCode == 404){
        return null;
      }

      return null;
    } on DioException catch (_) {
         return null;
    }
  }

    Future<NcfsList?> findNcfStatus() async {
    try {
          await User.authClient();
      var res = await apiUresax.post('/ncfslist/find-ncf-status',data: {
        'ncfTypeId':ncfTypeId
      });
      if (res.statusCode == 200) {
  
        return NcfsList.fromMap(res.data);
      }


      return null;
    } on DioException catch (e) {
          throw e.response?.data['message'] ?? e.error.toString();
    }
  }


  Future<NcfsList?> create() async {
    try {
      await User.authClient();
      var res = await apiUresax.post('/ncfslist/create',data:{
        ...toMapInsert(),
        'ncfTypeName':ncfTypeName
      });

      if(res.statusCode == 200){
        return NcfsList.fromMap(res.data);
      }
      
      return null;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }


  Future<NcfsList?> update() async {
    try {
      await User.authClient();
      var res = await apiUresax.put('/ncfslist/update/$id',data:{
        ...toMapInsert(),
        'ncfTypeName':ncfTypeName
      });

      if(res.statusCode == 200){
        return NcfsList.fromMap(res.data);
      }
      
      return null;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<NcfsList?> updateFinish({int? ncfListId = 1, int? currentNcf = 1}) async {
    try {
            await User.authClient();
      var res = await apiUresax.put('/ncfslist/update-finish/$ncfTypeId',data: {
        'ncfListId':ncfListId,
        'currentNcf':currentNcf
      });

      if(res.statusCode == 200){
        return NcfsList.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Map<String, dynamic>?> checkIfExistAvailable() async {
    try {
            await User.authClient();
      var res = await apiUresax.post('/ncfslist/check-if-exist-availables',data: {
        'ncfTypeId':ncfTypeId,
        'ncfTypeName':ncfTypeName
      });
      if(res.statusCode == 200){
        return res.data;
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  NcfsList copyWith({
    int? id,
    String? ncfTypeId,
    int? start,
    int? end,
    DateTime? expirationDate,
    DateTime? createdAt,
  }) {
    return NcfsList(
      id: id ?? this.id,
      ncfTypeId: ncfTypeId ?? this.ncfTypeId,
      start: start ?? this.start,
      end: end ?? this.end,
      expirationDate: expirationDate ?? this.expirationDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ncfTypeId': ncfTypeId,
      'start': start,
      'end': end,
      'expirationDate': expirationDate,
      'lastNumber':lastNumber,
      'createdAt': createdAt
    };
  }

  Map<String, dynamic> toMapInsert() {
    return {
      'ncfTypeId': ncfTypeId,
      'start': start,
      'end': end,
      'lastNumber':lastNumber,
      'expirationDate': expirationDate?.toIso8601String()
    };
  }

  factory NcfsList.fromMap(Map<String, dynamic> map) {
    return NcfsList(
        id: map['id'],
        ncfTypeId: map['ncfTypeId'],
        ncfTypeName: map['ncfTypeName'],
        start: map['start'],
        end: map['end'],
        expirationDate: map['expirationDate'] != null
            ? DateTime.parse(map['expirationDate'])
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt']).toLocal()
            : null,
        lastNumber: map['lastNumber'],
        finish: map['finish']);
  }

  String toJson() => json.encode(toMap());

  factory NcfsList.fromJson(String source) =>
      NcfsList.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'NcfsList(id: $id, ncfTypeId: $ncfTypeId, start: $start, end: $end, lastNumber: $lastNumber, expirationDate: $expirationDate, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is NcfsList &&
        o.id == id &&
        o.ncfTypeId == ncfTypeId &&
        o.start == start &&
        o.end == end &&
        o.expirationDate == expirationDate &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ncfTypeId.hashCode ^
        start.hashCode ^
        end.hashCode ^
        expirationDate.hashCode ^
        createdAt.hashCode;
  }
}
