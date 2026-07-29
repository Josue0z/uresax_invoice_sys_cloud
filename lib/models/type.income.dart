import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';


class TypeIncome {
  String? id;
  String? name;
  TypeIncome({
    this.id,
    this.name,
  });

  static Future<List<TypeIncome>> get() async {
    try {
      var res = await apiUresax.get('/typesincomes/all');

      if(res.statusCode == 200){
        var data = res.data;
        return List<TypeIncome>.from((data as List).map((x) => TypeIncome.fromMap(x)));
      }
     return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  TypeIncome copyWith({
    String? id,
    String? name,
  }) {
    return TypeIncome(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory TypeIncome.fromMap(Map<String, dynamic> map) {
    return TypeIncome(
      id: map['id'],
      name: map['name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TypeIncome.fromJson(String source) =>
      TypeIncome.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'TypeIncome(id: $id, name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is TypeIncome && o.id == id && o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
