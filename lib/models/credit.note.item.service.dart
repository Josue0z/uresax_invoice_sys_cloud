import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';

class CreditNoteService implements SaleItem {
  @override
  String? id;
  @override
  int? serviceId;
  @override
  double? discount;
  @override
  double? net;
  @override
  double? tax;
  @override
  double? total;
  @override
  double? retentionTax;
  @override
  double? retentionIsr;
  @override
  String? saleId;
  @override
  String? creditNoteId;
  @override
  double? quantity;

  CreditNoteService(
      {this.id,
      this.productId,
      this.serviceId,
      this.discountId,
      this.discountName,
      this.discount = 0,
      this.discountRate,
      this.discountSymbol,
      this.net = 0,
      this.netFinal=0,
      this.tax = 0,
      this.total = 0,
      this.retentionTax = 0,
      this.retentionIsr = 0,
      this.saleId,
      this.creditNoteId,
      this.quantity,
      this.serviceName,
      this.productName,
      this.licensePlate,
      this.taxId,
      this.retentionIsrId,
      this.retentionTaxId,
      this.chassis,
      this.enabled = true,
      this.returnQuantity = 0,
      this.tax18 = 0,
      this.tax16 = 0,
      this.tax3 = 0,
      this.net18 = 0,
      this.net16 = 0,
      this.net3 = 0,
      this.exemptAmount,
      this.indicadorFacturacion,
      this.indicadorAgentePercepcion,
      this.price,
      this.law10 = 0,
      this.addedFromEditPrices = false,
      this.serviceCode,
      this.priceItem = 0,
      this.editable = false,
      this.unitSuite,
      this.clientSuite,
      this.priceSuite = 0,
      this.maxDiscount = 90,
      this.isrRate = 0,
      this.taxRate = 0});

  @override
  int? productId;

  @override
  int? discountId;

  @override
  int? taxId;

  @override
  String get imageUrl {
    return '$apiDomain/images/$productImage';
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName':serviceName,
      'discount': discount,
      'discountName':discountName,
      'discountRate':discountRate,
      'discountSymbol':discountSymbol,
      'net': net,
      'tax': tax,
      'total': total,
      'retentionTax': retentionTax,
      'retentionIsr': retentionIsr,
      'creditNoteId': creditNoteId,
      'quantity': quantity,
      'taxId': taxId,
      'retentionTaxId': retentionTaxId,
      'retentionIsrId': retentionIsrId,
      'discountId': discountId,
      'tax18': tax18,
      'tax16': tax16,
      'tax3': tax3,
      'net18': net18,
      'net16': net16,
      'net3': net3,
      'law10': law10,
      'exemptAmount': exemptAmount,
      'indicadorFacturacion': indicadorFacturacion,
      'indicadorAgentePercepcion': indicadorAgentePercepcion,
      'enabled':enabled,
      'priceItem':priceItem,
      'unitSuite':unitSuite,
      'clientSuite':clientSuite,
      'priceSuite': priceSuite,
      'maxDiscount':maxDiscount,
      'isrRate': isrRate,
      'taxRate': taxRate
    };
  }

  @override
  String? retentionIsrId;

  @override
  int? retentionTaxId;
  
  @override
  CreditNoteService copyWith({
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
    double? discount = 0,
    int? discountId,
    String? discountName,
    double? discountRate,
    String? discountSymbol,
    String? unitCode,
    String? unitName,
    String? unitSymbol,
    double? conversionFactor,
    double? net = 0,
    double? net16 = 0,
    double? net18 = 0,
    double? net3 = 0,
    double? netFinal = 0,
    int? taxId,
    double? tax = 0,
    double? tax16 = 0,
    double? tax18 = 0,
    double? tax3 = 0,
    double? law10 = 0,
    double? total = 0,
    double? exemptAmount = 0,
    int? retentionTaxId,
    double? retentionTax = 0,
    String? retentionIsrId,
    double? retentionIsr = 0,
    String? saleId,
    String? creditNoteId,
    double? quantity,
    String? licensePlate,
    String? chassis,
    String? colorName,
    String? serviceCode,
    double? priceItem,
    bool? editable,
    String? unitSuite,
    String? clientSuite,
    double? priceSuite = 0,
    double? maxDiscount = 90,
    double? isrRate = 0,
    double? taxRate = 0
  }) {
    return CreditNoteService(
         id: id ?? this.id,
      indicadorFacturacion: indicadorFacturacion ?? this.indicadorFacturacion,
      indicadorAgentePercepcion: indicadorAgentePercepcion ?? this.indicadorAgentePercepcion,
      serviceName: serviceName,
      serviceId: serviceId ?? this.serviceId,
      discountId: discountId ?? this.discountId,
      discount: discount ?? this.discount,
      discountName: discountName ?? this.discountName,
      discountRate: discountRate ?? this.discountRate,
      discountSymbol: discountSymbol ?? this.discountSymbol,
      price: price,
      net: net,
      net16: net16,
      net18: net18,
      net3: net3,
      netFinal: netFinal,
      taxId: taxId,
      tax: tax,
      tax16: tax16,
      tax18: tax18,
      tax3: tax3,
      law10: law10,
      total: total,
      exemptAmount: exemptAmount, 
      retentionTaxId: retentionTaxId ?? this.retentionTaxId,
      retentionTax: retentionTax ?? this.retentionTax,
      retentionIsrId:  retentionIsrId ?? this.retentionIsrId,
      retentionIsr: retentionIsr ?? this.retentionIsr,
      saleId: saleId ?? this.saleId,
      creditNoteId: creditNoteId ?? this.creditNoteId,
      quantity: quantity ?? this.quantity,
      serviceCode: serviceCode ?? this.serviceCode,
      priceItem: priceItem,
      editable: editable,
      unitSuite: unitSuite,
      clientSuite: clientSuite,
      priceSuite: priceSuite,
      maxDiscount: maxDiscount,
      isrRate: isrRate,
      taxRate: taxRate
    );
  }

  factory CreditNoteService.fromMap(Map<String, dynamic> map) {
    return CreditNoteService(
      id: map['id'],
      serviceId: map['serviceId'],
      serviceName: map['serviceName'],
      productId: map['productId'],
      productName: map['productName'],
      discountId: map['discountId'],
      discountName: map['discountName'],
      discount: map['discount'] != null ? double.parse(map['discount']) : null,
                 discountRate: map['discountRate'] != null ? double.parse(map['discountRate']): null,
        discountSymbol: map['discountSymbol'],
      net: double.parse(map['net']),
            netFinal: map['netFinal'] != null ? double.parse(map['netFinal']) : null,
      tax: double.parse(map['tax']),
      total: double.parse(map['total']),
      retentionTax: double.parse(map['retentionTax']),
      retentionIsr: double.parse(map['retentionIsr']),
      saleId: map['saleId'],
      creditNoteId: map['creditNoteId'],
      quantity:map['quantity'] != null ? double.parse(map['quantity']) :null,
      licensePlate: map['licensePlate'],
      taxId: map['taxId'],
      retentionTaxId: map['retentionTaxId'],
      retentionIsrId: map['retentionIsrId'],
      chassis: map['chassis'],
      enabled: true,
      tax18: map['tax18'] != null ? double.parse(map['tax18']) : null,
      tax16: map['tax16'] != null ? double.parse(map['tax16']) : null,
      tax3: map['tax3'] != null ? double.parse(map['tax3']) : null,
      net18: map['net18'] != null ? double.parse(map['net18']) : null,
      net16: map['net16'] != null ? double.parse(map['net16']) : null,
      net3: map['net3'] != null ? double.parse(map['net3']) : null,
      exemptAmount: map['exemptAmount'] != null
          ? double.parse(map['exemptAmount'])
          : null,
      indicadorFacturacion: map['indicadorFacturacion'],
      indicadorAgentePercepcion: map['indicadorAgentePercepcion'],
      price: double.parse(map['price']),
      law10: map['law10'] != null ? double.parse(map['law10']) : null,
      serviceCode: map['serviceCode'],
      priceItem: map['priceItem'] != null ? double.parse(map['priceItem']) : null,
            unitSuite: map['unitSuite'],
      clientSuite: map['clientSuite'],
      priceSuite: map['priceSuite'] != null? double.parse(map['priceSuite']) : 0.0,
      maxDiscount: map['maxDiscount'] != null ? double.parse(map['maxDiscount']) : 90,
      isrRate: map['isrRate'] != null ? double.parse(map['isrRate']) : 0,
      taxRate: map['taxRate'] != null ? double.parse(map['taxRate']) : 0
      
    );
  }

  String toJson() => json.encode(toMap());

  factory CreditNoteService.fromJson(String source) =>
      CreditNoteService.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CreditNoteService(id: $id, serviceId: $serviceId, discount: $discount, net: $net, tax: $tax, law10: $law10, total: $total, retentionTax: $retentionTax, retentionIsr: $retentionIsr, saleId: $saleId, creditNoteId: $creditNoteId, quantity: $quantity, priceItem: $priceItem, maxDiscount: $maxDiscount,isrRate: $isrRate, taxRate: $taxRate)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CreditNoteService &&
        o.id == id &&
        o.serviceId == serviceId &&
        o.discount == discount &&
        o.net == net &&
        o.tax == tax &&
        o.total == total &&
        o.retentionTax == retentionTax &&
        o.retentionIsr == retentionIsr &&
        o.saleId == saleId &&
        o.creditNoteId == creditNoteId &&
        o.quantity == quantity;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        serviceId.hashCode ^
        discount.hashCode ^
        net.hashCode ^
        tax.hashCode ^
        total.hashCode ^
        retentionTax.hashCode ^
        retentionIsr.hashCode ^
        saleId.hashCode ^
        creditNoteId.hashCode ^
        quantity.hashCode;
  }

  @override
  Map<String, dynamic> toDisplay() {
    return {
      'CANTIDAD': quantity?.toStringAsFixed(2),
      'DESCRIPCIÓN': serviceName,
      'PRECIO': price?.toCoin(),
      'ITBIS': tax?.toCoin(),
      'TOTAL': total?.toCoin() ?? ''
    };
  }

  

    @override
  Map<String, dynamic> toDisplayTecho() {
    return {
      'CANTIDAD': quantity?.toStringAsFixed(2),
      'UNIDAD':unitSuite ?? '-',
      'DESCRIPCIÓN': serviceName,
      'CLIENTE':clientSuite ?? '-',
      'PRECIO':priceSuite != null  && priceSuite! > 0 ? priceSuite?.toCoin() : price?.toCoin(),
      'TOTAL': total?.toCoin() ?? ''
    };
  }

    @override
  Map<String, dynamic> toDisplayItemFreelance() {
    return {
      'DESCRIPCIÓN': serviceName,
      'CANT.': quantity?.toStringAsFixed(2),
      'PRECIO': price?.toCoin(),
      'ITBIS': tax?.toCoin(),
      'TOTAL': total?.toCoin() ?? ''
    };
  }

  @override
  Map<String, dynamic> toDisplayReceipt() {
    return {
      'DESCRIPCION': '${quantity?.toStringAsFixed(2)} x ${price?.toCoin()}\n$serviceName',
      'ITBIS': tax?.toCoin(),
      'TOTAL': total?.toCoin() ?? ''
    };
  }

  
    @override
  Map<String, dynamic> toDisplayItemStore() {
    String description = serviceName ?? '';

  
    return {
      'Código': productCode?.isEmpty == true ?'-' :productCode ?? '-',
      'Cantidad': quantity?.toStringAsFixed(2) ??'',
      'UM.': unitCode?.isEmpty==true? '-' : unitCode ?? '-',
      'Descripción': description,
      'Precio': price?.toCoin(),
      'Descuento': discount?.toCoin() ?? '',
      'ITBIS':tax?.toCoin(),
      'Valor':total?.toCoin()
    };
  }

  @override
  List<pw.Widget> toDisplayItemJulyMotors({required int index}) {
    String description = serviceName ?? '';

   
    return [
      pw.Padding(
          padding: pw.EdgeInsets.all(kDefaultPadding / 2),
          child: pw.Text(quantity?.toStringAsFixed(2) ?? '',
          style: pw.TextStyle(
            fontSize: 8
          ),
              textAlign: pw.TextAlign.center)),
      pw.Padding(
          padding: pw.EdgeInsets.all(kDefaultPadding / 2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
            pw.Text(description, textAlign: pw.TextAlign.left,style: pw.TextStyle(
              fontSize: 8
            )),
           
 
          ])),
       pw.Padding(
          padding: pw.EdgeInsets.all(kDefaultPadding / 2),
          child: pw.Text(price?.toCoin(),
              textAlign: pw.TextAlign.left,style: pw.TextStyle(
                fontSize: 8
              ))),

    

             pw.Padding(
          padding: pw.EdgeInsets.all(kDefaultPadding / 2),
          child: pw.Text(total?.toCoin(),
          style: pw.TextStyle(
            fontSize: 8
          ),
              textAlign: pw.TextAlign.left)),
    ];
  }

    @override
  List<pw.Widget> toDisplayItemIdealTime({required int index}) {
    String description = serviceName ?? '';

   
    return [
      pw.Padding(
          padding: pw.EdgeInsets.all(kDefaultPadding / 3),
          child: pw.Text(quantity?.toStringAsFixed(2) ?? '',
          style: pw.TextStyle(
            fontSize: 9
          ),
              textAlign: pw.TextAlign.center)),

  
      pw.Padding(
          padding: pw.EdgeInsets.all(kDefaultPadding / 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
            pw.Container(
               margin: pw.EdgeInsets.symmetric(
                    vertical: kDefaultPadding/5
                  ),
              child:  pw.Text(description, softWrap: true, textAlign: pw.TextAlign.left,style: pw.TextStyle(
              fontSize: 8
            )),
            ),
          
          ])),
       pw.Padding(
          padding: pw.EdgeInsets.all(kDefaultPadding / 3),
          child: pw.Text(price?.toCoin(),
              textAlign: pw.TextAlign.center,style: pw.TextStyle(
                fontSize: 9
              ))),

     

             pw.Padding(
          padding: pw.EdgeInsets.all(kDefaultPadding / 3),
          child: pw.Text(total?.toCoin(),
          style: pw.TextStyle(
            fontSize: 9
          ),
              textAlign: pw.TextAlign.center)),
    ];
  }
  @override
  String? serviceName;

  @override
  String? productName;

  @override
  String? chassis;

  @override
  String? licensePlate;

  @override
  bool? enabled;

  @override
  double? returnQuantity;

  @override
  double? exemptAmount;

  @override
  int? indicadorAgentePercepcion;

  @override
  int? indicadorFacturacion;

  @override
  double? net16;

  @override
  double? net18;

  @override
  double? net3;

  @override
  double? tax16;

  @override
  double? tax18;

  @override
  double? tax3;

  @override
  double get precio {
    return price ?? 0;
  }

  @override
  double? price;

  @override
  String? discountName;
  
  @override
  double? conversionFactor;
  
  @override
  String? unitCode;
  
  @override
  String? unitName;
  
  @override
  String? unitSymbol;
  
  @override
  double? units;

  @override
  double? priceUnit;

  @override
  bool? isScanProduct;

  @override
  double? law10;

  @override
  double? startQuantity;

  @override
  String? colorName;

  @override
  double? netFinal;
  
  @override
  double? discountRate;
  
  @override
  String? discountSymbol;
  
  @override
  String? productCode;

  @override
  String? productImage;

  @override
  bool? addedFromEditPrices;

  @override
  String? serviceCode;

  @override
  double? priceItem;

  @override
  bool? editable;
  
  @override
  String? clientSuite;
  
  @override
  double? priceSuite;
  
  @override
  String? unitSuite;

  @override
  double? maxDiscount;
  
  @override
  double? isrRate;
  
  @override
  double? taxRate;
  

}
