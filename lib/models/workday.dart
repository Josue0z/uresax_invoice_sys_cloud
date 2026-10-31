// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';


extension TimeOfDayExtension on TimeOfDay {
  String toFormattedString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return "$h:$m"; // formato HH:mm
  }
}
class WorkdayModel {
  int? id;
  String? name;
  TimeOfDay? startHour;
  TimeOfDay? endHour;
  String? startHourFormatted;
  String? endHourFormatted;
  double? hours;
  String? companyId;
  DateTime? createdAt;
  WorkdayModel({
    this.id,
    this.name,
    this.startHour,
    this.endHour,
    this.startHourFormatted,
    this.endHourFormatted,
    this.hours,
    this.companyId,
    this.createdAt,
  });

  static Future<List<WorkdayModel>> get() async {
    try {
        await User.authClient();
      var res = await apiUresax.get('/workdays/all');

      if (res.statusCode == 200) {
        var data = res.data;

        return List<WorkdayModel>.from(
            (data as List).map((x) => WorkdayModel.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<WorkdayModel?> create() async {
    try {
        await User.authClient();
      var res = await apiUresax.post('/workdays/create', data: toMap());

      if (res.statusCode == 200) {
        var data = res.data;
        return WorkdayModel.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<WorkdayModel?> update() async {
    try {
        await User.authClient();
      var res = await apiUresax.put('/workdays/update/$id', data: toMap());

      if (res.statusCode == 200) {
        var data = res.data;
        return WorkdayModel.fromMap(data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }


  WorkdayModel copyWith({
    int? id,
    String? name,
    TimeOfDay? startHour,
    TimeOfDay? endHour,
    String? startHourFormatted,
    String? endHourFormatted,
    double? hours,
    String? companyId,
    DateTime? createdAt,
  }) {
    return WorkdayModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      startHourFormatted: startHourFormatted ?? this.startHourFormatted,
      endHourFormatted: endHourFormatted ?? this.endHourFormatted,
      hours: hours ?? this.hours,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'startHour': startHour?.toFormattedString(),
      'endHour': endHour?.toFormattedString(),
      'startHourFormatted': startHourFormatted,
      'endHourFormatted': endHourFormatted,
      'hours': hours,
      'companyId': companyId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory WorkdayModel.fromMap(Map<String, dynamic> map) {
    String raw = map['startHour']; // "Time(08:00:00.000)"

// Quitar el prefijo "Time(" y el sufijo ")"
    String cleaned = raw.replaceAll("Time(", "").replaceAll(")", "");
// cleaned = "08:00:00.000"

// Tomar solo HH:MM
    String hhmm = cleaned.substring(0, 5); // "08:00"

// Parsear a TimeOfDay
    final parts = hhmm.split(':');
    final startHour = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    String raw2 = map['endHour']; // "Time(08:00:00.000)"

// Quitar el prefijo "Time(" y el sufijo ")"
    String cleaned2 = raw2.replaceAll("Time(", "").replaceAll(")", "");
// cleaned = "08:00:00.000"

// Tomar solo HH:MM
    String hhmm2 = cleaned2.substring(0, 5); // "08:00"

// Parsear a TimeOfDay
    final parts2 = hhmm2.split(':');
    final endHour = TimeOfDay(
      hour: int.parse(parts2[0]),
      minute: int.parse(parts2[1]),
    );
    return WorkdayModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] != null ? map['name'] as String : null,
      startHour: startHour,
      endHour: endHour,
      startHourFormatted: map['startHourFormatted'] != null
          ? map['startHourFormatted'] as String
          : null,
      endHourFormatted: map['endHourFormatted'] != null
          ? map['endHourFormatted'] as String
          : null,
      hours: map['hours'] != null ? double.parse(map['hours']) : null,
      companyId: map['companyId'] != null ? map['companyId'] as String : null,
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkdayModel.fromJson(String source) =>
      WorkdayModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WorkdayModel(id: $id, name: $name, startHour: $startHour, endHour: $endHour, startHourFormatted: $startHourFormatted, endHourFormatted: $endHourFormatted, hours: $hours, companyId: $companyId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant WorkdayModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.startHourFormatted == startHourFormatted &&
        other.endHourFormatted == endHourFormatted &&
        other.hours == hours &&
        other.companyId == companyId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        startHourFormatted.hashCode ^
        endHourFormatted.hashCode ^
        hours.hashCode ^
        companyId.hashCode ^
        createdAt.hashCode;
  }
}
