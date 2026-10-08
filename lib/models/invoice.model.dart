// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';



class InvoiceModel {
  int? id;
  String? name;
  String? imageAsset;
  InvoiceModel({
    this.id,
    this.name,
    this.imageAsset,
  });

  static Future<void> updateInvoiceIndex(int index)async{
      try{
        await apiUresax.post('/companies/update-invoice-index', data: {
          'currentInvoiceIndex': index
        });
      }on DioException catch(e){
        throw e.response?.data['message'] ?? e.error?.toString();
      }
  }

  InvoiceModel copyWith({
    int? id,
    String? name,
    String? imageAsset,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'imageAsset': imageAsset,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] != null ? map['name'] as String : null,
      imageAsset: map['imageAsset'] != null ? map['imageAsset'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory InvoiceModel.fromJson(String source) => InvoiceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'InvoiceModel(id: $id, name: $name, imageAsset: $imageAsset)';

  @override
  bool operator ==(covariant InvoiceModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name &&
      other.imageAsset == imageAsset;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ imageAsset.hashCode;
}
