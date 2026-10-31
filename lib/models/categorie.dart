import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';

class Category {
  int? id;
  String? name;
  int? parentId;
  DateTime? createdAt;
  Category({
    this.id,
    this.name,
    this.parentId,
    this.createdAt
  });

  static Future<List<Category>> get({String? search, int? parentCategoryId}) async {
    try {
      await User.authClient();
      var params = '';

      var query = [];

      if (search != null) {
        query.add('search=$search');
       
      }

      if(parentCategoryId != null){
        query.add('parentCategoryId=$parentCategoryId');
      }

      params = '?${query.join('&')}';

      var res = await apiUresax.get('/categories/all$params');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Category>.from(
            (data as List).map((x) => Category.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Category?> create() async {
    try {
            await User.authClient();
      var res = await apiUresax.post('/categories/create',data: {
        'name': name,
        'parentId':parentId
      });

      if (res.statusCode == 200) {
        return Category.fromMap(res.data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Category?> update() async {
    try {
            await User.authClient();
      var res =
          await apiUresax.put('/categories/update/$id', data: {'name': name});
      if (res.statusCode == 200) {
        return Category.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Category copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
        id: map['id'],
        name: map['name'],
        parentId: map['parentId'],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt']).toLocal()
            : null);
  }

  String toJson() => json.encode(toMap());

  factory Category.fromJson(String source) =>
      Category.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Category(id: $id, name: $name, parentId: $parentId, createdAt: $createdAt)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Category &&
        o.id == id &&
        o.name == name &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ createdAt.hashCode;
}
