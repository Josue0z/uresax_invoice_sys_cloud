// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class Box {
  int? id;
  String? name;
  DateTime? createdAt;
  Box({
    this.id,
    this.name,
    this.createdAt
  });

  static Future<List<Box>> get() async {
    try {
      var res = await apiUresax.get('/boxes/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Box>.from((data as List).map((x) => Box.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
        throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Box?> create() async {
    try {
      var res = await apiUresax.post('/boxes/create', data: {'name': name});

      if (res.statusCode == 200) {
        var data = res.data;
        return Box.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
    throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Box?> update() async {
    try {
      var res = await apiUresax.put('/boxes/update/$id', data: {'name': name});

      if(res.statusCode ==  200) {
        var data = res.data;
        return Box.fromMap(data);
      }
      
      return null;
    } on DioException catch (e) {
        throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Box copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Box(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'createdAt': createdAt?.toIso8601String()
    };
  }

  factory Box.fromMap(Map<String, dynamic> map) {
    return Box(
      id: map['id'],
      name: map['name'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt']).toLocal()
          : null
    );
  }

  String toJson() => json.encode(toMap());

  factory Box.fromJson(String source) =>
      Box.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Box(id: $id, name: $name, createdAt: $createdAt)';

  @override
  bool operator ==(covariant Box other) {
    if (identical(this, other)) return true;

    return other.id == id && other.name == name && other.createdAt == createdAt;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdAt.hashCode;
}
