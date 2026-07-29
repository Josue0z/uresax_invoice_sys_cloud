import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';

class EntryWareHouseItemModel implements WareHouseElementItem {
  @override
  String? id;
  @override
  String? ordenId;
  @override
  String? entryId;
  @override
  int? productId;
  @override
  String? productName;
  @override
  int? providerId;
  @override
  String? providerName;
  @override
  double? quantity;
  @override
  double? units;
  @override
  double? price;
  @override
  double? net;
  @override
  double? discount;
  @override
  double? tax;
  @override
  double? total;
  @override
  DateTime? createdAt;
  @override
  double? netFinal;
  @override 
  String? productCode;
  EntryWareHouseItemModel({
    this.id,
    this.entryId,
    this.productId,
    this.productName,
    this.providerId,
    this.providerName,
    this.quantity,
    this.units,
    this.price,
    this.priceUnit,
    this.net,
    this.netFinal,
    this.discount,
    this.tax,
    this.total,
    this.createdAt,
    this.unitName,
    this.unitCode,
    this.unitSymbol,
    this.conversionFactor,
    this.productCode
  });

  @override
  Future<EntryWareHouseItemModel?> create([TxSession? transaction]) async {
    try {
      var parameters = toMap();

      parameters.remove('createdAt');
      parameters.remove('productName');
      parameters.remove('providerId');
      parameters.remove('providerName');


      var result = await transaction?.execute(
          Sql.named('insert into public."EntriesWareHouseItems" '
              '(id, "entryId", "productId", quantity, price, net, discount, tax, total, "unitCode", "unitName", "unitSymbol", "conversionFactor") '
              'values (@id,@entryId, @productId, @quantity, @price, @net, @discount, @tax, @total, @unitCode, @unitName, @unitSymbol, @conversionFactor) returning *'),
          parameters: parameters);
   
  
      return EntryWareHouseItemModel.fromMap(result!.first.toColumnMap());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Map<String, dynamic> toDisplay() {
    return {
      'CANTIDAD': quantity?.toStringAsFixed(2),
      'UNIDADES': units?.toStringAsFixed(2),
      'PRODUCTO': productName,
      'UNITARIO': priceUnit?.toDop(),
      'PRECIO': price?.toDop(),
      'NETO': net?.toDop(),
      'TOTAL': total?.toDop()
    };
  }

      @override
  Map<String, dynamic> toDisplayItemStore() {
    String description = productName ?? '';

  
    return {
      'Código':productCode,
      'Cantidad': quantity?.toStringAsFixed(2),
      'Unidades': units?.toStringAsFixed(2) ??'',
      'UM.': unitCode,
      'Descripción': description,
      'Precio': priceUnit?.toCoin(),
      'Descuento': discount?.toCoin() ?? '',
      'ITBIS':tax?.toCoin(),
      'Valor':total?.toCoin()
    };
  }

  @override
  Map<String, dynamic> toDisplayReceipt() {
    return {
      'DESCRIPCION.':
          '${units?.toStringAsFixed(2)} x ${priceUnit?.toCoin()}\n$productName',
      'ITBIS': tax?.toCoin(),
      'TOTAL': total?.toCoin()
    };
  }

  EntryWareHouseItemModel copyWith({
    String? id,
    String? entryId,
    int? productId,
    String? productName,
    int? providerId,
    String? providerName,
    double? quantity,
    double? units,
    double? price,
    double? net,
    double? discount,
    double? tax,
    double? total,
    DateTime? createdAt,
  }) {
    return EntryWareHouseItemModel(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      quantity: quantity ?? this.quantity,
      units: units ?? this.units,
      price: price ?? this.price,
      net: net ?? this.net,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryId': entryId,
      'productId': productId,
      'productName': productName,
      'providerId': providerId,
      'providerName': providerName,
      'quantity': quantity,
      'price': price,
      'net': net,
      'discount': discount,
      'tax': tax,
      'total': total,
      'createdAt': createdAt,
      'unitCode': unitCode,
      'unitName': unitName,
      'unitSymbol': unitSymbol,
      'conversionFactor': conversionFactor
    };
  }

  factory EntryWareHouseItemModel.fromMap(Map<String, dynamic> map) {
    return EntryWareHouseItemModel(
        id: map['id'],
        entryId: map['entryId'],
        productId: map['productId'],
        productName: map['productName'],
        providerId: map['providerId'],
        providerName: map['providerName'],
        quantity: map['quantity'] != null ? double.parse( map['quantity']) : null,
            units:map['units'] != null ? double.parse(map['units']) : null,
        price: double.parse(map['price']),
          priceUnit: map['priceUnit'] != null ? double.parse(map['priceUnit']): null,
        net: double.parse(map['net']),
         netFinal: map['netFinal'] != null ? double.parse(map['netFinal']) : null,
        discount: double.parse(map['discount']),
        tax: double.parse(map['tax']),
        total: double.parse(map['total']),
        createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']).toLocal() : null,
        unitCode: map['unitCode'],
        unitName: map['unitName'],
        unitSymbol: map['unitSymbol'],
        conversionFactor:map['conversionFactor'] != null ? double.parse(map['conversionFactor']): null,
        productCode: map['productCode']);
  }

  String toJson() => json.encode(toMap());

  factory EntryWareHouseItemModel.fromJson(String source) =>
      EntryWareHouseItemModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'EntryWareHouseItemModel(id: $id, entryId: $entryId, productId: $productId, productName: $productName, providerId: $providerId, providerName: $providerName, quantity: $quantity, units: $units, price: $price, net: $net, discount: $discount, tax: $tax, total: $total, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is EntryWareHouseItemModel &&
        o.id == id &&
        o.entryId == entryId &&
        o.productId == productId &&
        o.productName == productName &&
        o.providerId == providerId &&
        o.providerName == providerName &&
        o.quantity == quantity &&
        o.units == units &&
        o.price == price &&
        o.net == net &&
        o.discount == discount &&
        o.tax == tax &&
        o.total == total &&
        o.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        entryId.hashCode ^
        productId.hashCode ^
        productName.hashCode ^
        providerId.hashCode ^
        providerName.hashCode ^
        quantity.hashCode ^
        units.hashCode ^
        price.hashCode ^
        net.hashCode ^
        discount.hashCode ^
        tax.hashCode ^
        total.hashCode ^
        createdAt.hashCode;
  }
  
  @override
  double? conversionFactor;
  
  @override
  String? unitCode;
  
  @override
  String? unitName;
  
  @override
  String? unitSymbol;

  @override
  double? priceUnit;
}
