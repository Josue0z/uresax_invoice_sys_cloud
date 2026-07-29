import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.element.abs.dart';

class Services implements SaleElement {
  @override
  int? id;
  @override
  String? name;
  @override
  double? quantity;
  @override
  double? price;
  @override
  String? imageBase64;
  @override
  bool? editable;
  @override
  double? maxDiscount;
  @override
  double? priceSuite;
  @override
  double? rateSuite;
  Services(
      {this.id,
      this.name,
      this.quantity = 1,
      this.price,
      this.taxId,
      this.image,
      this.categoryId,
      this.categoryName,
      this.discountId,
      this.discountName,
      this.discountRate,
      this.discountSymbolId,
      this.discountSymbol,
      this.imageBase64,
      this.code,
      this.editable = false,
      this.maxDiscount = 90,
      this.priceSuite = 0,
      this.rateSuite = 0});

  @override
  String? get imageUrl {
     if(image == null)return null;
   return '$apiDomainRelease/images/$image';
 }
   static Future<Services?> findByCode({required String code}) async {
    try {
      var res = await apiUresax.get('/services/findservicebycode/$code');

      if (res.statusCode == 200) {
        return Services.fromMap(res.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Services?> create() async {
    try {
      var res= await apiUresax.post('/services/create',data: {
            'name': name,
            'price': price,
            'taxId': taxId,
            'imageBase64': imageBase64,
            'categoryId': categoryId,
            'code': code,
            'editable': editable,
            'maxDiscount':maxDiscount,
            'priceSuite': priceSuite,
            'rateSuite': rateSuite
      });

      if(res.statusCode == 200){
        return Services.fromMap(res.data);
      }
     

      return null;
    } on DioException catch (e) {
    throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Services?> update() async {
    try {
      var res = await apiUresax.put('/services/update/$id',data: {
            'name': name,
            'price': price,
            'id': id,
            'taxId': taxId,
            'imageBase64': imageBase64,
            'categoryId': categoryId,
            'code': code,
            'editable':editable,
            'maxDiscount':maxDiscount,
            'priceSuite': priceSuite,
            'rateSuite': rateSuite
      });

      if(res.statusCode == 200){
        return Services.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }
  
  @override
  Future<Services?> deleteImage() async {
    try {
      var res = await apiUresax.delete('/services/delete-image/$id');

      if(res.statusCode == 200){
        return Services.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  static Future<List<Services>> get(
      {String? search, List<int>? categories}) async {
    try {

      
       final queryParams = <String>[];

      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }

      if (categories != null && categories.isNotEmpty) {
        queryParams.add('categories=${categories.join(',')}');
      }

      var params = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      var res = await apiUresax.get('/services/all$params');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Services>.from(
            (data as List).map((x) => Services.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
     throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Services copyWith({
    int? id,
    String? name,
    double? quantity,
    double? price,
  }) {
    return Services(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'taxId': taxId,
      'image': image,
      'categoryId': categoryId,
      'editable':editable
    };
  }

  factory Services.fromMap(Map<String, dynamic> map) {
    return Services(
        id: map['id'],
        name: map['name'],
        quantity:
            map['quantity'] != null ? double.parse(map['quantity']) : null,
        price: double.parse(
          map['price'],
        ),
        taxId: map['taxId'],
        image: map['image'],
        categoryId: map['categoryId'],
        categoryName: map['categoryName'],
        discountId: map['discountId'],
        discountName: map['discountName'],
        discountRate: map['discountRate'] != null ? double.parse(map['discountRate']): null,
        discountSymbol: map['discountSymbol'],
        discountSymbolId: map['discountSymbolId'],
        code: map['code'],
        editable: map['editable'],
        maxDiscount: map['maxDiscount'] != null ? double.parse(map['maxDiscount']) : 90,
        priceSuite:  map['priceSuite'] != null ? double.parse(map['priceSuite']) : 0.00,
        rateSuite:  map['rateSuite'] != null ? double.parse(map['rateSuite']) : 0.00);
  }

  String toJson() => json.encode(toMap());

  factory Services.fromJson(String source) =>
      Services.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Services(id: $id, name: $name, quantity: $quantity, price: $price, taxId: $taxId, categoryId: $categoryId,editable: $editable, maxDiscount: $maxDiscount)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Services &&
        o.id == id &&
        o.name == name &&
        o.quantity == quantity &&
        o.price == price;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ quantity.hashCode ^ price.hashCode;
  }

  @override
  String? chassis;

  @override
  String? licensePlate;

  @override
  int? taxId;

  @override
  double? factor;

  @override
  int? providerId;

  @override
  String? providerName;

  @override
  double? quantityResultFactor;

  @override
  double? total;

  @override
  int? wareHouseId;

  @override
  String? wareHouseName;

  @override
  String? code;

  @override
  double? cost;

  @override
  int? categoryId;

  @override
  String? categoryName;

  @override
  int? childproductId;

  @override
  double? conversionFactor;

  @override
  double? conversionFactorChild;

  @override
  double? conversionFactorParent;

  @override
  bool? isBaseUnit;

  @override
  int? parentproductId;

  @override
  String? productChildName;

  @override
  String? productParentName;

  @override
  double? quantityChild;

  @override
  String? unitCode;

  @override
  int? unitId;

  @override
  String? unitName;

  @override
  String? unitSymbol;

  @override
  double? units;

  @override
  String? image;

  @override
  String? colorName;
  
  @override
  int? discountId;
  
  @override
  String? discountName;
  
  @override
  double? discountRate;
  
  @override
  int? discountSymbolId;

  @override
  String? discountSymbol;
}
