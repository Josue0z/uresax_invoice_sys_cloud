import 'package:pdf/widgets.dart' as pw;
abstract class SaleItem {
  String? id;
  int? serviceId;
  int? productId;
  double? discount;
  String? discountName;
  double? discountRate;
  String? discountSymbol;
  double? net;
  double? netFinal;
  double? tax;
  double? total;
  double? retentionTax;
  double? retentionIsr;
  String? saleId;
  String? creditNoteId;
  double? quantity;
  int? taxId;
  int? discountId;
  int? retentionTaxId;
  String? retentionIsrId;
  String? serviceName;
  String? productName;
  String? chassis;
  String? licensePlate;
  String? colorName;
  bool? enabled;
  double? returnQuantity;

  double? tax18;

  double? tax16;

  double? tax3;

  double? net18;

  double? net16;

  double? net3;

  double? exemptAmount;

  int? indicadorFacturacion;

  int? indicadorAgentePercepcion;

  double? price;

  double? priceUnit;

  double? units;

  String? unitCode;

  String? unitName;

  String? unitSymbol;

  double? conversionFactor;

  bool? isScanProduct;

  double? law10;

  double? startQuantity;

  String? productCode;

  String? productImage;
  
  bool? addedFromEditPrices;

  String? serviceCode;

  double? priceItem;

  bool? editable;

  String? unitSuite;
  String? clientSuite;
  double? priceSuite;
  double? maxDiscount;
  double? taxRate;
  double? isrRate;

  String get imageUrl {
    throw UnimplementedError();
  }

  Map<String, dynamic> toMap() {
    throw UnimplementedError();
  }

  Map<String, dynamic> toDisplay() {
    throw UnimplementedError();
  }
  

    Map<String, dynamic> toDisplayTecho() {
    throw UnimplementedError();
  }
 
   Map<String, dynamic> toDisplayItemFreelance() {
    throw UnimplementedError();
  }

  Map<String, dynamic> toDisplayReceipt() {
    throw UnimplementedError();
  }
  List<pw.Widget> toDisplayItemJulyMotors({required int index}){
     throw UnimplementedError();
  }

    List<pw.Widget> toDisplayItemIdealTime({required int index}){
     throw UnimplementedError();
  }



   Map<String, dynamic> toDisplayItemStore() {
    throw UnimplementedError();
  }

  double get precio {
    throw UnimplementedError();
  }
   SaleItem copyWith({
    String? id,
    int? indicadorFacturacion,
    int? productId,
    int? indicadorAgentePercepcion,
    String? productCode,
    String? productImage,
    String? productName,
    String? serviceName,
    int? serviceId,
    double? price,
    double? priceUnit,
    double? discount,
    int? discountId,
    String? discountName,
    double? discountRate,
    String? discountSymbol,
    String? unitCode,
    String? unitName,
    String? unitSymbol,
    double? conversionFactor,
    double? net,
    double? net16,
    double? net18,
    double? net3,
    double? netFinal,
    int? taxId,
    double? tax,
    double? tax16,
    double? tax18,
    double? tax3,
    double? law10,
    double? total,
    double? exemptAmount,
    int? retentionTaxId,
    double? retentionTax,
    String? retentionIsrId,
    double? retentionIsr,
    String? saleId,
    String? creditNoteId,
    double? quantity,
    String? serviceCode,
    double? priceItem,
    String? chassis,
    String? licensePlate,
    String? colorName,
    bool? editable,
    String? unitSuite,
    String? clientSuite,
    double? priceSuite,
    double? maxDiscount,
    double? isrRate,
    double? taxRate
   }){
  throw UnimplementedError();
   }
}
