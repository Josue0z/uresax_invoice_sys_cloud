abstract class SaleElement {
  int? id;
  String? name;
  double? quantity;
  double? factor;
  double? quantityResultFactor;
  double? price;
  double? total;
  String? chassis;
  String? licensePlate;
  String? colorName;
  int? taxId;
  int? providerId;
  String? providerName;
  int? wareHouseId;
  String? wareHouseName;
  String? code;
  double? cost;
  int? categoryId;
  String? categoryName;
  int? unitId;
  double? units;
  double? conversionFactor;
  String? unitCode;
  String? unitSymbol;
  String? unitName;
  int? parentproductId;
  String? productParentName;
  double? conversionFactorParent;
  int? childproductId;
  String? productChildName;
  double? conversionFactorChild;
  double? quantityChild;
  bool? isBaseUnit;
  String? image;
  int? discountId;
  String? discountName;
  double? discountRate;
  int? discountSymbolId;
  String? discountSymbol;
  String? imageBase64;
  bool? editable;
  double? maxDiscount;
  double? priceSuite;
  double? rateSuite;
  int? parentId;
  bool? isUnique;

 String? get imageUrl {
   throw UnimplementedError();
 }

 Future<SaleElement?> deleteImage()async{
 throw UnimplementedError();
 }

}
