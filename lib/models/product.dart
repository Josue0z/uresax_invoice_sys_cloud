import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/apis/sql.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.element.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class Products implements SaleElement {
  @override
  int? id;
  @override
  String? name;
  @override
  double? price;
  @override
  double? quantity;
  DateTime? createdAt;
  @override
  String? chassis;
  @override
  String? licensePlate;
  @override
  int? unitId;
  @override
  double? units;
  @override
  double? conversionFactor;
  @override
  String? unitCode;
  @override
  String? unitSymbol;
  @override
  String? unitName;
  @override
  int? parentproductId;
  @override
  String? productParentName;
  @override
  double? conversionFactorParent;
  @override
  int? childproductId;
  @override
  String? productChildName;
  @override
  double? conversionFactorChild;
  @override
  double? quantityChild;
  @override
  bool? isBaseUnit;
  @override
  String? imageBase64;
  @override
  bool? editable;
  @override
  double? maxDiscount;
  @override
  int? parentId;
  @override
  bool? isUnique;

  Products(
      {this.id,
      this.name,
      this.quantity,
      this.factor,
      this.quantityResultFactor,
      this.price,
      this.total,
      this.createdAt,
      this.chassis,
      this.licensePlate,
      this.colorName,
      this.taxId,
      this.providerId,
      this.providerName,
      this.wareHouseId,
      this.wareHouseName,
      this.code,
      this.cost,
      this.categoryId,
      this.categoryName,
      this.unitId,
      this.units,
      this.unitCode,
      this.unitName,
      this.unitSymbol,
      this.conversionFactor,
      this.parentproductId,
      this.productParentName,
      this.conversionFactorParent,
      this.childproductId,
      this.productChildName,
      this.conversionFactorChild,
      this.quantityChild,
      this.isBaseUnit,
      this.image,
      this.discountId,
      this.discountName,
      this.discountRate,
      this.discountSymbolId,
      this.discountSymbol,
      this.imageBase64,
      this.editable = true,
      this.maxDiscount = 90,
      this.parentId,
      this.isUnique = true});

  Color get color {
    if (quantity == null) Colors.red;

    return quantity! > 0 ? Colors.green : Colors.red;
  }
  @override
  String? get imageUrl {

    if(image == null)return null;
   return '$apiDomainRelease/images/$image';
 }

  Future<Products?> create() async {
    try {
            await User.authClient();
      var res = await apiUresax.post('/products/create', data: {
        'name': name,
        'price': price,
        'quantity': quantity,
        'chassis': chassis,
        'licensePlate': licensePlate,
        'colorName': colorName,
        'taxId': taxId,
        'providerId': providerId,
        'wareHouseId': wareHouseId,
        'code': code,
        'cost': cost,
        'categoryId': categoryId,
        'unitId': unitId,
        'discountId': discountId,
        'imageBase64':imageBase64,
        'editable':editable,
        'parentId': parentId,
        'factor': factor,
        'isUnique': isUnique,
        'maxDiscount': maxDiscount
      });

      if (res.statusCode == 200) {
        return Products.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }
   
   @override
    Future<Products?> deleteImage() async {
    try {
            await User.authClient();
      var res = await apiUresax.delete('/products/delete-image/$id');

      if(res.statusCode == 200){
        return Products.fromMap(res.data);
      }
      return null;
    } on DioException catch (e) {
        throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  createRelation() {
    try {
      final conne = SqlConector.connection;
      return conne?.execute(
          Sql.named(
              '''insert into public."ProductRelations"("parentproductId", "childproductId") values(@parentproductId,@childproductId) RETURNING *'''),
          parameters: {
            'parentproductId': parentproductId,
            'childproductId': childproductId
          });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateMinusStock({
    required List<SaleItem> items,
    required String ncfTypeId,
  }) async {
    if ((ncfTypeId != '50' && ncfTypeId != '60') ||
        enabledProformaUpdateStock) {
      try {
        await User.authClient();
        await apiUresax.put('/products/update-minus-stock',
            data: {'items': items.map((e) => e.toMap()).toList()});
      } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
      }
    }
  }

  static Future<void> updateAddStock({
    required List<SaleItem> items,
    required String ncfTypeId,
  }) async {
    if (ncfTypeId != '50' || enabledProformaUpdateStock || ncfTypeId != '60') {
      try {
        await User.authClient();
        await apiUresax.put('/products/update-add-stock',
            data: {'items': items.map((e) => e.toMap()).toList()});
      } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
      }
    }
  }

  Future<void> updateAddStockFromProductChild() async {
    try {
      var conne = SqlConector.connection;

      // Buscar relación
      var relation = await conne?.execute(
          Sql.named(
              'SELECT "parentproductId", "conversionFactorChild","quantityChild" FROM public."ProductRelationsView" WHERE "childproductId" = @id'),
          parameters: {'id': childproductId});

      if (relation != null && relation.isNotEmpty) {
        var relationData = relation.first.toColumnMap();
        var parentId = relationData['parentproductId'] as int;
        var factor = relationData['conversionFactorChild'] as int;
        var quantityChild = relationData['quantityChild'] as int;
        var realQuantity = quantityChild * factor;

        await conne?.execute(
            Sql.named(
                'UPDATE public."Products" SET quantity = quantity + @realQuantity WHERE id = @parentId'),
            parameters: {'parentId': parentId, 'realQuantity': realQuantity});
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Products?> update() async {
    try {
            await User.authClient();
      var res = await apiUresax.put('/products/update/$id', data: {
        'name': name,
        'price': price,
        'quantity': quantity,
        'chassis': chassis,
        'licensePlate': licensePlate,
        'colorName': colorName,
        'taxId': taxId,
        'providerId': providerId,
        'wareHouseId': wareHouseId,
        'code': code,
        'cost': cost,
        'categoryId': categoryId,
        'unitId': unitId,
        'imageBase64': imageBase64,
        'discountId': discountId,
        'editable':editable,
        'factor': factor,
        'isUnique': isUnique,
        'parentId': parentId,
        'maxDiscount':maxDiscount
      });

      if (res.statusCode == 200) {
        return Products.fromMap(res.data);
      }

      return null;
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<Products?> delete() async {
    try {
            await User.authClient();
      var res = await apiUresax.put('/products/delete/$id');

      if (res.statusCode == 200) {
        return Products.fromMap(res.data);
      }

      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  static Future<List<Products>> get(
      {String? search, List<int>? categories, int? parentId}) async {
    try {
            await User.authClient();
      final queryParams = <String>[];

      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }

      if (categories != null && categories.isNotEmpty) {
        queryParams.add('categories=${categories.join(',')}');
      }

      if(parentId != null){
        queryParams.add('parentId=$parentId');
      }

      var params = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      var res = await apiUresax.get('/products/all$params');

      if (res.statusCode == 200) {
        var data = res.data;
        return List<Products>.from(
            (data as List).map((x) => Products.fromMap(x)));
      }

      return [];
    } on DioException catch (e) {
       throw e.response?.data['message'] ?? e.error.toString();
    }
  }

  Future<List<Products>> getProductsRelations({String? search}) async {
    try {
      final conne = SqlConector.connection;
      var parameters = {};
      String params = '';

      if (search != null) {
        params += 'where lower(name) like lower(@search)';
        parameters.addAll({'search': '%$search%'});
      }

      var result = await conne?.execute(
          Sql.named(
              'select * from public."ProductRelationsView" where "parentproductId" = @parentproductId order by "productChildName" asc'),
          parameters: {'parentproductId': id, ...parameters});
      return result
              ?.map(
                (e) => Products.fromMap(e.toColumnMap()),
              )
              .toList() ??
          [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<Products?> findByCode({required String code}) async {
    try {
            await User.authClient();
      var res = await apiUresax.get('/products/findproductbycode/$code');

      if (res.statusCode == 200) {
        return Products.fromMap(res.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Products copyWith({
    int? id,
    String? name,
    double? price,
    double? quantity,
    DateTime? createdAt,
  }) {
    return Products(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    var map = {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'createdAt': createdAt,
      'taxId': taxId,
      'unitId': unitId,
      'image': image,
      'discountId': discountId
    };
    if (providerId != null) {
      map.addAll({'provideId': providerId});
    }
    if (wareHouseId != null) {
      map.addAll({'wareHouseId': wareHouseId});
    }

    if (code != null) {
      map.addAll({'code': code});
    }

    if (cost != null) {
      map.addAll({'cost': cost});
    }

    return map;
  }

  factory Products.fromMap(Map<String, dynamic> map) {
    return Products(
        id: map['id'],
        name: map['name'],
        quantity:
            map['quantity'] != null ? double.parse(map['quantity']) : null,
        price: map['price'] != null ? double.parse(map['price']) : null,
        total: map['total'] != null ? double.parse(map['total']) : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt']).toLocal()
            : null,
        chassis: map['chassis'],
        licensePlate: map['licensePlate'],
        colorName: map['colorName'],
        taxId: map['taxId'],
        providerId: map['providerId'],
        providerName: map['providerName'],
        wareHouseId: map['wareHouseId'],
        wareHouseName: map['wareHouseName'],
        code: map['code'],
        cost: map['cost'] != null ? double.parse(map['cost']) : null,
        categoryId: map['categoryId'],
        categoryName: map['categoryName'],
        unitId: map['unitId'],
        units: map['units'] != null ? double.parse(map['units']) : null,
        unitCode: map['unitCode'],
        unitName: map['unitName'],
        unitSymbol: map['unitSymbol'],
        conversionFactor: map['conversionFactor'] != null
            ? double.parse(map['conversionFactor'])
            : null,
        parentproductId: map['parentproductId'],
        productParentName: map['productParentName'],
        conversionFactorParent: map['conversionFactorParent'] != null
            ? double.parse(map['conversionFactorParent'])
            : null,
        childproductId: map['childproductId'],
        productChildName: map['productChildName'],
        conversionFactorChild: map['conversionFactorChild'] != null
            ? double.parse(map['conversionFactorChild'])
            : null,
        quantityChild: map['quantityChild'] != null
            ? double.parse(map['quantityChild'])
            : null,
        isBaseUnit: map['isBaseUnit'],
        image: map['image'],
        discountId: map['discountId'],
        discountName: map['discountName'],
        discountRate: map['discountRate'] != null
            ? double.parse(map['discountRate'])
            : null,
        discountSymbolId: map['discountSymbolId'],
        discountSymbol: map['discountSymbol'],
        editable: map['editable'],
        maxDiscount: map['maxDiscount'] != null ? double.parse(map['maxDiscount']) : 90,
        parentId: map['parentId'],
        isUnique: map['isUnique']);
  }

  String toJson() => json.encode(toMap());

  factory Products.fromJson(String source) =>
      Products.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Products(id: $id, name: $name, price: $price, quantity: $quantity, unitId: $unitId, unitName: $unitName, unitSymbol: $unitSymbol, unitCode: $unitCode, conversionFactor: $conversionFactor,editable: $editable, maxDiscount: $maxDiscount, createdAt: $createdAt, parentId: $parentId, isUnique: $isUnique)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Products &&
        o.id == id &&
        o.name == name &&
        o.price == price &&
        o.quantity == quantity &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        price.hashCode ^
        quantity.hashCode ^
        createdAt.hashCode;
  }

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
  
  @override
  double? priceSuite;
  
  @override
  double? rateSuite;
}
