import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class Bank {
  int? id;
  String? name;
  DateTime? createdAt;
  Bank({this.id, this.name, this.createdAt});

  static Future<List<Bank>> get() async {
    try {
      var res = await apiUresax.get('/banks/all');
      if(res.statusCode == 200) {
        var data = res.data;
        return List<Bank>.from((data as List).map((x) => Bank.fromMap(x)));
      }
      
      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Bank copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Bank(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': createdAt?.toIso8601String()};
  }

  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(id: map['id'], name: map['name'], createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']).toLocal() : null);
  }

  String toJson() => json.encode(toMap());

  factory Bank.fromJson(String source) =>
      Bank.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Bank(id: $id, name: $name, createdAt: $createdAt)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Bank &&
        o.id == id &&
        o.name == name &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdAt.hashCode;
}
