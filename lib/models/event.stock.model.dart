// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';

class EventStockModel {
  String? id;
  int? eventStockTypeId;
  String? eventTypeName;
  String? companyId;
  String? authorId;
  String? authorName;
  DateTime? createdAt;
  String? ref;
  List<EventStockChild>? items;
  EventStockModel({
    this.id,
    this.eventStockTypeId,
    this.eventTypeName,
    this.companyId,
    this.authorId,
    this.authorName,
    this.createdAt,
    this.ref,
    this.items = const []
  });
   
     static Future<List<EventStockModel>> get() async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/events-stock/all');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<EventStockModel>.from((data as List).map((x) => EventStockModel.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
        throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<bool> create() async {
    try {
            await User.authClient();
      var res = await apiUresax.post('/events-stock/create', data: toMap());

      if (res.statusCode == 200) {
        var data = res.data;
        return true;
      }
     
     return false;
    
    } on DioException catch (e) {
    throw e.response?.data['message'] ?? e.error.toString();
    }
  }
  EventStockModel copyWith({
    String? id,
    int? eventStockTypeId,
    String? eventTypeName,
    String? companyId,
    String? authorId,
    String? authorName,
    String? ref,
    DateTime? createdAt,
  }) {
    return EventStockModel(
      id: id ?? this.id,
      eventStockTypeId: eventStockTypeId ?? this.eventStockTypeId,
      eventTypeName: eventTypeName ?? this.eventTypeName,
      companyId: companyId ?? this.companyId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      ref: ref ?? this.ref,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'eventStockTypeId': eventStockTypeId,
      'eventTypeName': eventTypeName,
      'companyId': companyId,
      'authorId': authorId,
      'authorName': authorName,
      'ref':ref,
      'items': items?.map((e) => e.toMap()).toList() ?? [],
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory EventStockModel.fromMap(Map<String, dynamic> map) {
    return EventStockModel(
      id: map['id'] != null ? map['id'] as String : null,
      eventStockTypeId: map['eventStockTypeId'] != null ? map['eventStockTypeId'] as int : null,
      eventTypeName: map['eventTypeName'] != null ? map['eventTypeName'] as String : null,
      companyId: map['companyId'] != null ? map['companyId'] as String : null,
      authorId: map['authorId'] != null ? map['authorId'] as String : null,
      authorName: map['authorName'] != null ? map['authorName'] as String : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      ref: map['ref']
    );
  }

  String toJson() => json.encode(toMap());

  factory EventStockModel.fromJson(String source) => EventStockModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EventStockModel(id: $id, eventStockTypeId: $eventStockTypeId, eventTypeName: $eventTypeName, companyId: $companyId, authorId: $authorId, authorName: $authorName, ref: $ref, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant EventStockModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.eventStockTypeId == eventStockTypeId &&
      other.eventTypeName == eventTypeName &&
      other.companyId == companyId &&
      other.authorId == authorId &&
      other.authorName == authorName &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      eventStockTypeId.hashCode ^
      eventTypeName.hashCode ^
      companyId.hashCode ^
      authorId.hashCode ^
      authorName.hashCode ^
      createdAt.hashCode;
  }
}


class EventStockChild {
  String? id;
  String? eventStockId;
  int? productId;
  String? productName;
  double? quantity;
  double? units;
  double? conversionFactor;
  String? unitCode;
  String? unitName;
  String? unitSymbol;
  String? companyId;
  DateTime? createdAt;
  EventStockChild({
    this.id,
    this.eventStockId,
    this.productId,
    this.productName,
    this.quantity,
    this.units,
    this.conversionFactor,
    this.unitCode,
    this.unitName,
    this.unitSymbol,
    this.companyId,
    this.createdAt,
  });

  EventStockChild copyWith({
    String? id,
    String? eventStockId,
    int? productId,
    String? productName,
    double? quantity,
    double? units,
    double? conversionFactor,
    String? unitCode,
    String? unitName,
    String? unitSymbol,
    String? companyId,
    DateTime? createdAt,
  }) {
    return EventStockChild(
      id: id ?? this.id,
      eventStockId: eventStockId ?? this.eventStockId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      units: units ?? this.units,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      unitCode: unitCode ?? this.unitCode,
      unitName: unitName ?? this.unitName,
      unitSymbol: unitSymbol ?? this.unitSymbol,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'eventStockId': eventStockId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'units': units,
      'conversionFactor': conversionFactor,
      'unitCode': unitCode,
      'unitName': unitName,
      'unitSymbol': unitSymbol,
      'companyId': companyId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory EventStockChild.fromMap(Map<String, dynamic> map) {
    return EventStockChild(
      id: map['id'] != null ? map['id'] as String : null,
      eventStockId: map['eventStockId'] != null ? map['eventStockId'] as String : null,
      productId: map['productId'] != null ? map['productId'] as int : null,
      productName: map['productName'] != null ? map['productName'] as String : null,
      quantity: map['quantity'] != null ? map['quantity'] as double : null,
      units: map['units'] != null ? map['units'] as double : null,
      conversionFactor: map['conversionFactor'] != null ? map['conversionFactor'] as double : null,
      unitCode: map['unitCode'] != null ? map['unitCode'] as String : null,
      unitName: map['unitName'] != null ? map['unitName'] as String : null,
      unitSymbol: map['unitSymbol'] != null ? map['unitSymbol'] as String : null,
      companyId: map['companyId'] != null ? map['companyId'] as String : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory EventStockChild.fromJson(String source) => EventStockChild.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EventStockChild(id: $id, eventStockId: $eventStockId, productId: $productId, productName: $productName, quantity: $quantity, units: $units, conversionFactor: $conversionFactor, unitCode: $unitCode, unitName: $unitName, unitSymbol: $unitSymbol, companyId: $companyId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant EventStockChild other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.eventStockId == eventStockId &&
      other.productId == productId &&
      other.productName == productName &&
      other.quantity == quantity &&
      other.units == units &&
      other.conversionFactor == conversionFactor &&
      other.unitCode == unitCode &&
      other.unitName == unitName &&
      other.unitSymbol == unitSymbol &&
      other.companyId == companyId &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      eventStockId.hashCode ^
      productId.hashCode ^
      productName.hashCode ^
      quantity.hashCode ^
      units.hashCode ^
      conversionFactor.hashCode ^
      unitCode.hashCode ^
      unitName.hashCode ^
      unitSymbol.hashCode ^
      companyId.hashCode ^
      createdAt.hashCode;
  }
}
