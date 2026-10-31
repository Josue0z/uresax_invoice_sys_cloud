import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';

class NcfSecuencia {
  String? id;
  String? name;
  int? lastValue;
  int? minValue;
  int? maxValue;
  NcfSecuencia({
    this.id,
    this.name,
    this.lastValue,
    this.minValue,
    this.maxValue,
  });
  static Future<List<NcfSecuencia>> get({String params = ''}) async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/ncfsecuencias/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<NcfSecuencia>.from(
            (data as List).map((x) => NcfSecuencia.fromMap(x)));
      }
      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<void> update() async {
   /* try {
      final conne = SqlConector.connection;

      await conne?.execute('''
        SELECT setval('public."${id}_seq"',$lastValue, false);
    ''');
    } catch (e) {
      rethrow;
    }*/
  }

  Future<List<Map<String, dynamic>>?> checkNcfs({int umbral = 10}) async {
    try {
            await User.authClient();
      var res =
          await apiUresax.post('/ncfsecuencias/$id', data: {'umbral': umbral});
      List<Map<String, dynamic>> events = [];

      if (res.statusCode == 200) {
        events = List<Map<String, dynamic>>.from((res.data as List).map((e)=> e).toList());
      }
      return events;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  NcfSecuencia copyWith({
    String? id,
    String? name,
    int? lastValue,
    int? minValue,
    int? maxValue,
  }) {
    return NcfSecuencia(
      id: id ?? this.id,
      name: name ?? this.name,
      lastValue: lastValue ?? this.lastValue,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastValue': lastValue,
      'minValue': minValue,
      'maxValue': maxValue
    };
  }

  factory NcfSecuencia.fromMap(Map<String, dynamic> map) {
    return NcfSecuencia(
        id: map['id'],
        name: map['name'],
        lastValue: map['lastValue'],
        minValue: map['minValue'],
        maxValue: map['maxValue']);
  }

  String toJson() => json.encode(toMap());

  factory NcfSecuencia.fromJson(String source) =>
      NcfSecuencia.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'NcfSecuencia(id: $id, name: $name, lastValue: $lastValue, minValue: $minValue, maxValue: $maxValue)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is NcfSecuencia &&
        o.id == id &&
        o.name == name &&
        o.lastValue == lastValue &&
        o.minValue == minValue &&
        o.maxValue == maxValue;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        lastValue.hashCode ^
        minValue.hashCode ^
        maxValue.hashCode;
  }
}
