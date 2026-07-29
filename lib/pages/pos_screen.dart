// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui';
import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:ecf_dgii/ecf_dgii.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/payment.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/modals/price.editor.item.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/client.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.product.dart';
import 'package:uresax_invoice_sys_cloud/models/ncf.secuencia.dart';
import 'package:uresax_invoice_sys_cloud/models/ncfList.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/models/service.dart';
import 'package:uresax_invoice_sys_cloud/models/taxpayer.dart';
import 'package:uresax_invoice_sys_cloud/pages/clients_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/login_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/printers_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/products_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/services_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/listen.code.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/rnc.query.widget.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';


enum ActionCart { add, remove, edit }

class PosScreenPage extends StatefulWidget {
  Sale sale;
  List<SaleItem> items;
  bool editing;
  SaleMode? mode;
  bool generateNcfFromProforma;
  PosScreenPage(
      {super.key,
      required this.sale,
      required this.items,
      this.editing = false,
      this.generateNcfFromProforma = false,
      this.mode});

  @override
  State<PosScreenPage> createState() => _PosScreenPageState();
}

class _PosScreenPageState extends State<PosScreenPage> {
  TextEditingController clientName = TextEditingController();
  TextEditingController rncOrId = TextEditingController();
  TaxPayer? taxPayer;
  Client? client;
  String? currentTypeIncomeId = '01';
  int? currentPaymentMethodId;
  int? currentPaymentType;
  int? currentPaymentModeId;
  int? currentOverrideCode;
  String? currentNcfTypeId;
  String? currentPrefix;
  int currentLawMode = 1;
  int? maxSequence;
  List<NcfType> _ncfs = [];
  List<SaleItem> _items = [];
  List<TextEditingController> _controllers = [];
  late OnscreenKeyboardController keyboardController;
  bool showNumericKeyboard = false;

  NcfsList? ncfList;

  TextEditingController description = TextEditingController();
  TextEditingController issueDateController = TextEditingController();
  TextEditingController retentionDateController = TextEditingController();
  TextEditingController fechaVencimientoController = TextEditingController();
  TextEditingController transfRef = TextEditingController();
  DateTime createdAt = DateTime.now();
  DateTime issueDate = DateTime.now();
  DateTime? retentionDate;
  DateTime? paymentDate = DateTime.now();
  DateTime fechaVencimiento = DateTime.now().endOfYear();

  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  TextEditingController amount = TextEditingController();
  Sale? _currentSale;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusKeyboard = FocusNode();
  TextEditingController rate = TextEditingController();
  int currentCurrencyId = 1;
  int? currentBankId;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<FormaDePago> formasDePagos = [];

  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollController2 = ScrollController();

  List<Map<String, dynamic>> law10Modes = [
    {'id': 1, 'value': null, 'name': 'MONTO PROPINA LEGAL'},
    {'id': 2, 'value': 10, 'name': 'APLICAR PROPINA LEGAL'}
  ];

  double get quantity {
    double q = 0;
    for (var item in _items) {
      q += item.quantity ?? 0.0;
    }
    return q;
  }

  bool get isSale {
    return widget.sale is SaleService || widget.sale is SaleProduct;
  }

  double get debt {
    if (widget.sale.amountPaid != null && widget.editing) {
      return (paidAmount - (widget.sale.amountPaid!));
    }

    return (paidAmount - (amountInputFormatter.doubleValue));
  }

  bool get canOverrideTaxes {
    if (_currentSale == null) return false;
    var days = DateTime.now().difference(_currentSale!.createdAt!).inDays;
    return days > 30;
  }

  bool get esGubernamental {
    return currentNcfTypeId == '45' || currentNcfTypeId == '15';
  }

  bool get esNotaCredito {
    return currentNcfTypeId == '34' || currentNcfTypeId == '04';
  }

  bool get esEspecial {
    return currentNcfTypeId == '14' || currentNcfTypeId == '44';
  }

    bool get esMenor {
      return currentNcfTypeId == '13' || currentNcfTypeId == '43';
  }

    bool get esCompra {
      return currentNcfTypeId == '11' || currentNcfTypeId == '41';
  }

  bool get noEsElectronico {
    return currentNcfTypeId == '01' ||
        currentNcfTypeId == '02' ||
        currentNcfTypeId == '15' ||
        currentNcfTypeId == '04' ||
        currentNcfTypeId == '14' ||
        currentNcfTypeId == '50' ||
        currentNcfTypeId == '60';
  }

  List<double> get calcs {
    double net = 0;
    double subtotal = 0;
    double discount = 0;
    double tax = 0;
    double total = 0;
    double retentionTax = 0;
    double retentionIsr = 0;
    double tax18 = 0;
    double tax16 = 0;
    double tax3 = 0;
    double net18 = 0;
    double net16 = 0;
    double net3 = 0;
    double exemptAmount = 0;
    double law10 = 0;

    for (int i = 0; i < _items.length; i++) {
      var item = _items[i];

      net += item.enabled == true ? _items[i].net ?? 0 : 0;
      subtotal += item.enabled == true ? _items[i].netFinal ?? 0 : 0;
      discount += item.enabled == true ? _items[i].discount ?? 0 : 0;

      if (!canOverrideTaxes) {
        tax += item.enabled == true ? _items[i].tax ?? 0 : 0;
      }

      total += item.enabled == true ? _items[i].total ?? 0 : 0;
      retentionIsr += item.enabled == true ? _items[i].retentionIsr ?? 0 : 0;
      retentionTax += item.enabled == true ? _items[i].retentionTax ?? 0 : 0;

      if (!canOverrideTaxes) {
        tax18 += item.enabled == true ? _items[i].tax18 ?? 0 : 0;

        tax16 += item.enabled == true ? _items[i].tax16 ?? 0 : 0;

        tax3 += item.enabled == true ? _items[i].tax3 ?? 0 : 0;
      }

      net18 += item.enabled == true ? _items[i].net18 ?? 0 : 0;

      net16 += item.enabled == true ? _items[i].net16 ?? 0 : 0;

      net3 += item.enabled == true ? _items[i].net3 ?? 0 : 0;

      exemptAmount += item.enabled == true ? _items[i].exemptAmount ?? 0 : 0;
      law10 += item.enabled == true ? _items[i].law10 ?? 0 : 0;
    }

    return [
      net,
      discount,
      tax,
      total,
      retentionIsr,
      retentionTax,
      ((total) - (retentionIsr + retentionTax)),
      tax18,
      tax16,
      tax3,
      net18,
      net16,
      net3,
      exemptAmount,
      subtotal,
      law10
    ];
  }

  double get xrate {
    double xrate = 1;

    double? calcRate = double.tryParse(rate.text);
    if (calcRate != null) {
      xrate = calcRate;
    }
    return xrate;
  }

  List<double> get calcsDollarsToDop {
    return [
      calcs[0] * xrate,
      calcs[1] * xrate,
      calcs[2] * xrate,
      calcs[3] * xrate,
      calcs[4] * xrate,
      calcs[5] * xrate,
      calcs[6] * xrate,
      calcs[7] * xrate,
      calcs[8] * xrate,
      calcs[9] * xrate,
      calcs[10] * xrate,
      calcs[11] * xrate,
      calcs[12] * xrate,
      calcs[13] * xrate,
      calcs[14] * xrate,
      calcs[15] * xrate
    ];
  }

  String get net {
    if (currentCurrencyId == 2) {
      return calcs[0].toUS();
    }

    return calcs[0].toDop();
  }

  String get subtotal {
    if (currentCurrencyId == 2) {
      return calcs[14].toUS();
    }

    return calcs[14].toDop();
  }

  String get discount {
    if (currentCurrencyId == 2) {
      return calcs[1].toUS();
    }

    return calcs[1].toDop();
  }

  String get tax {
    if (currentCurrencyId == 2) {
      return calcs[2].toUS();
    }
    return calcs[2].toDop();
  }

  String get law10 {
    if (currentCurrencyId == 2) {
      return calcs[15].toUS();
    }
    return calcs[15].toDop();
  }

  String get total {
    if (currentCurrencyId == 2) {
      return calcs[3].toUS();
    }
    return calcs[3].toDop();
  }

  String get retentionTax {
    if (currentCurrencyId == 2) {
      return calcs[5].toUS();
    }
    return calcs[5].toDop();
  }

  String get retentionIsr {
    if (currentCurrencyId == 2) {
      return calcs[4].toUS();
    }
    return calcs[4].toDop();
  }

  String get amountPaid {
    if (currentCurrencyId == 2) {
      return calcs[6].toUS();
    }
    return calcs[6].toDop();
  }

  double get montoAPagar {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[6];
    }
    return calcs[6];
  }

  double get montoAPagarReferencia {
    if (currentCurrencyId == 2) {
      return double.parse((calcsDollarsToDop[6] / xrate).toStringAsFixed(2));
    }
    return calcs[6];
  }

  double get totalFacturado {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[3];
    }
    return calcs[3];
  }

  double get itbisGravado {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[2];
    }
    return calcs[2];
  }

  double get itbisGravado18 {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[7];
    }
    return calcs[7];
  }

  double get itbisGravado16 {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[8];
    }
    return calcs[8];
  }

  double get itbisGravado3 {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[9];
    }
    return calcs[9];
  }

  double get law10Calc {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[15];
    }
    return calcs[15];
  }

  double get totalGravado {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[0] - montoExento;
    }

    return calcs[0] - montoExento;
  }

  double get totalGravado18 {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[10];
    }
    return calcs[10];
  }

  double get totalGravado16 {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[11];
    }
    return calcs[11];
  }

  double get totalGravado3 {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[12];
    }
    return calcs[12];
  }

  double get totalRetencionIsr {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[4];
    }
    return calcs[4];
  }

  double get totalRetencionItbis {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[5];
    }
    return calcs[5];
  }

  double get montoExento {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[13];
    }
    return calcs[13];
  }

  double get paidAmount {
    return double.parse(calcs[6].toStringAsFixed(2));
  }

  double get returnCoinOrDebt {
    if (currentCurrencyId == 2) {
      return ((amountInputFormatter.doubleValue - totalFacturado) * xrate)
          .abs();
    }
    return (paidAmount - (amountInputFormatter.doubleValue));
  }

  String get debtString {
    if (currentCurrencyId == 2) {
      return (debt).abs().toUS();
    }
    return debt.abs().toDop();
  }

  _handlerCommands(KeyEvent event) async {
    if (event.logicalKey == LogicalKeyboardKey.f5) {
      if (widget.sale is SaleProduct) {
        _selectElementFromEditor();
      }
      // Aquí puedes poner tu lógica de refresco
    }
    if (event.logicalKey == LogicalKeyboardKey.f6) {
      _showClientsPage();
    }
    if (event.logicalKey == LogicalKeyboardKey.f7) {
      if (widget.sale is SaleProduct) {
        _showProducts();
      }
      if (widget.sale is SaleService) {
        _showServices();
      }
    }
  }

  _showServices() async {
    var service = await Navigator.push<Services?>(context,
        MaterialPageRoute(builder: (ctx) => ServicesPage(selectedMode: true)));

    if (service != null) {
      try {
        if (widget.sale is SaleService) {
          var selectedItem = _items.firstWhere((e) => e.serviceId == service.id,
              orElse: () => SaleItemService());

          if (selectedItem.serviceId == null) {
            service.quantity = 1.0;
            int? indicadorFacturacion = 1;
            double net18 = 0;
            double net16 = 0;
            double tax18 = 0;

            double tax16 = 0;

            double rate = 0;
            double discount = 0;

            double priceAmount = service.price! * service.quantity!;
            double priceAmountx = priceAmount;
            double law10 = 0;

            if (service.discountId != null) {
              if (service.discountSymbolId == 1) {
                rate = service.discountRate ?? 0;
                discount = service.price! * (rate / 100);
              }
              if (service.discountSymbolId == 2) {
                rate = service.discountRate ?? 0;
                discount = rate;
              }
              priceAmountx = priceAmount - discount;
            } else {
              rate = 0;
            }

            if (service.taxId == 1) {
              net16 = priceAmountx;
            }

            if (service.taxId == 2) {
              net18 = priceAmountx;
            }

            double? exemptAmount = service.taxId == null ? priceAmountx : 0;

            if (service.taxId != null) {
              indicadorFacturacion = service.taxId == 1 ? 2 : 1;
              tax18 = service.taxId == 2 ? priceAmountx * 0.18 : 0;
              tax16 = service.taxId == 1 ? priceAmountx * 0.16 : 0;
            } else {
              indicadorFacturacion = 4;
            }

            double? tax = tax18 + tax16;

            if (esEspecial) {
              tax = 0;
              tax16 = 0;
              tax18 = 0;
              net16 = 0;
              net18 = 0;
              indicadorFacturacion = 4;
              exemptAmount = priceAmountx;
            }

            if (currentLawMode == 2) {
              law10 = priceAmountx * 0.10;
            }
            double? total = priceAmountx + tax + law10;

            _focusNode.requestFocus();
            if (_items.length == 1 && _items[0].serviceId == null) {
              setState(() {
                _items = [];
              });
            }
            var controller = TextEditingController();
            controller.text = service.quantity?.toStringAsFixed(2) ?? '';

            _controllers.insert(0, controller);

            _items.insert(
                0,
                SaleItemService(
                    id: Uuid().v4(),
                    quantity: 1,
                    addedFromEditPrices: false,
                    productImage: service.image,
                    discountId: service.discountId,
                    discountName: service.discountName,
                    discountRate: rate,
                    discountSymbol: service.discountSymbol,
                    serviceId: service.id,
                    serviceName: service.name,
                    indicadorFacturacion: indicadorFacturacion,
                    price: service.price,
                    priceItem: service.price,
                    taxId: service.taxId,
                    net: priceAmount,
                    netFinal: priceAmountx,
                    net16: net16,
                    net18: net18,
                    net3: 0,
                    exemptAmount: exemptAmount,
                    tax: tax,
                    tax18: tax18,
                    tax16: tax16,
                    tax3: 0,
                    law10: law10,
                    discount: discount,
                    total: total));
          } else {
            int index =
                _items.indexWhere((e) => e.serviceId == selectedItem.serviceId);
            var item = _items[index];
            item.quantity = item.quantity! + 1;

            int? indicadorFacturacion = 1;
            double priceAmount = item.priceItem! * item.quantity!;
            double net18 = 0;
            double net16 = 0;

            double tax18 = 0;
            double tax16 = 0;

            double rate = 0;
            double discount = 0;
            double law10 = 0;

            double priceAmountx = priceAmount;
            double? exemptAmount = item.taxId == null ? priceAmountx : 0;

            if (service.discountId != null) {
              if (service.discountSymbolId == 1) {
                rate = item.discountRate ?? 0;
                discount = (item.price! * (item.quantity ?? 1)) * (rate / 100);
              }
              if (service.discountSymbolId == 2) {
                rate = item.discountRate ?? 0;
                discount = rate * (item.quantity ?? 1);
              }
              priceAmountx = priceAmount - discount;
            } else {
              rate = 0;
            }

            if (item.taxId == 1) {
              net16 = priceAmountx;
            }

            if (item.taxId == 2) {
              net18 = priceAmountx;
            }

            if (item.taxId != null) {
              indicadorFacturacion = item.taxId == 1 ? 2 : 1;
              tax18 = item.taxId == 2 ? priceAmountx * 0.18 : 0;
              tax16 = item.taxId == 1 ? priceAmountx * 0.16 : 0;
            } else {
              indicadorFacturacion = 4;
            }
            double? tax = tax18 + tax16;

            if (esEspecial) {
              tax = 0;
              tax16 = 0;
              tax18 = 0;
              net16 = 0;
              net18 = 0;
              indicadorFacturacion = 4;
              exemptAmount = priceAmountx;
            }

            if (currentLawMode == 2) {
              law10 = priceAmountx * 0.10;
            }

            double? total = priceAmountx + tax + law10;

            _controllers[index].text = item.quantity?.toStringAsFixed(2) ?? '';

            _items[index] = SaleItemService(
                id: item.id,
                addedFromEditPrices: item.addedFromEditPrices,
                productImage: item.productImage,
                discountId: item.discountId,
                discountName: item.discountName,
                discountRate: rate,
                discountSymbol: item.discountSymbol,
                indicadorFacturacion: indicadorFacturacion,
                quantity: item.quantity!,
                serviceId: item.serviceId,
                serviceName: item.serviceName,
                price: item.price,
                priceItem: item.priceItem,
                taxId: item.taxId,
                net: priceAmount,
                netFinal: priceAmountx,
                net16: net16,
                net18: net18,
                net3: 0,
                exemptAmount: exemptAmount,
                tax: tax,
                tax18: tax18,
                tax16: tax16,
                tax3: 0,
                law10: law10,
                discount: discount,
                total: total);

            _items = List.from(_items);
          }

          setState(() {});
        }
      } catch (e) {
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  _showProducts() async {
    var product = await Navigator.push<Products?>(context,
        MaterialPageRoute(builder: (ctx) => ProductsPage(selectedMode: true)));

    if (product != null) {
      try {
        if (widget.sale is SaleProduct) {
          var selectedItem = _items.firstWhere(
              (e) => e.productId == product?.id,
              orElse: () => SaleItemProduct());

          if (selectedItem.productId == null) {
            product.quantity = 1.0;
            int? indicadorFacturacion = 1;
            double net18 = 0;
            double net16 = 0;
            double tax18 = 0;

            double tax16 = 0;

            double rate = 0;
            double discount = 0;
            double law10 = 0;
            double priceAmount = product.price! * product.quantity!;

            double priceAmountx = priceAmount;

            if (product.discountId != null) {
              if (product.discountSymbolId == 1) {
                rate = product.discountRate ?? 0;
                discount = product.price! * (rate / 100);
              }
              if (product.discountSymbolId == 2) {
                rate = product.discountRate ?? 0;
                discount = rate;
              }
              priceAmountx = priceAmount - discount;
            } else {
              rate = 0;
            }

            if (product.taxId == 1) {
              net16 = priceAmountx;
            }

            if (product.taxId == 2) {
              net18 = priceAmountx;
            }

            double? exemptAmount = product.taxId == null ? priceAmountx : 0;

            if (product.taxId != null) {
              indicadorFacturacion = product.taxId == 1 ? 2 : 1;
              tax18 = product.taxId == 2 ? priceAmountx * 0.18 : 0;
              tax16 = product.taxId == 1 ? priceAmountx * 0.16 : 0;
            } else {
              indicadorFacturacion = 4;
            }

            double? tax = tax18 + tax16;

            if (esEspecial) {
              tax = 0;
              tax16 = 0;
              tax18 = 0;
              net16 = 0;
              net18 = 0;
              indicadorFacturacion = 4;
              exemptAmount = priceAmountx;
            }
            if (currentLawMode == 2) {
              law10 = priceAmountx * 0.10;
            }

            double? total = priceAmountx + tax + law10;

            _focusNode.requestFocus();
            if (_items.length == 1 && _items[0].productId == null) {
              setState(() {
                _items = [];
              });
            }
            var controller = TextEditingController();
            controller.text = product.quantity?.toStringAsFixed(2) ?? '';
            _controllers.insert(0, controller);

            _items.insert(
                0,
                SaleItemProduct(
                    id: Uuid().v4(),
                    addedFromEditPrices: false,
                    productImage: product.image,
                    quantity: 1,
                    discountId: product.discountId,
                    discountName: product.discountName,
                    discountRate: rate,
                    discountSymbol: product.discountSymbol,
                    unitCode: product.unitCode,
                    unitName: product.unitName,
                    unitSymbol: product.unitSymbol,
                    conversionFactor: product.conversionFactor,
                    chassis: product.chassis,
                    licensePlate: product.licensePlate,
                    colorName: product.colorName,
                    productId: product.id,
                    productName: product.name,
                    indicadorFacturacion: indicadorFacturacion,
                    price: selectedItem.addedFromEditPrices == true
                        ? selectedItem.price
                        : product.price,
                    priceItem:selectedItem.addedFromEditPrices == true
                        ? selectedItem.price
                        : product.price,
                    taxId: product.taxId,
                    net: priceAmount,
                    netFinal: priceAmountx,
                    net16: net16,
                    net18: net18,
                    net3: 0,
                    exemptAmount: exemptAmount,
                    tax: tax,
                    tax18: tax18,
                    tax16: tax16,
                    tax3: 0,
                    law10: law10,
                    discount: discount,
                    total: total));
          } else {
            int index =
                _items.indexWhere((e) => e.productId == selectedItem.productId);
            var item = _items[index];
            item.quantity = item.quantity! + 1;

            int? indicadorFacturacion = 1;
            double priceAmount = item.priceItem! * item.quantity!;
            double net18 = 0;
            double net16 = 0;

            double tax18 = 0;
            double tax16 = 0;

            double rate = 0;
            double discount = 0;
            double law10 = 0;

            double priceAmountx = priceAmount;
            double? exemptAmount = item.taxId == null ? priceAmountx : 0;

            if (product.discountId != null) {
              if (product.discountSymbolId == 1) {
                rate = item.discountRate ?? 0;
                discount = (item.price! * (item.quantity ?? 1)) * (rate / 100);
              }
              if (product.discountSymbolId == 2) {
                rate = item.discountRate ?? 0;
                discount = rate * (item.quantity ?? 1);
              }
              priceAmountx = priceAmount - discount;
            } else {
              rate = 0;
            }

            if (item.taxId == 1) {
              net16 = priceAmountx;
            }

            if (item.taxId == 2) {
              net18 = priceAmountx;
            }

            if (item.taxId != null) {
              indicadorFacturacion = item.taxId == 1 ? 2 : 1;
              tax18 = item.taxId == 2 ? priceAmountx * 0.18 : 0;
              tax16 = item.taxId == 1 ? priceAmountx * 0.16 : 0;
            } else {
              indicadorFacturacion = 4;
            }

            double? tax = tax18 + tax16;

            if (esEspecial) {
              tax = 0;
              tax16 = 0;
              tax18 = 0;
              net16 = 0;
              net18 = 0;
              indicadorFacturacion = 4;
              exemptAmount = priceAmountx;
            }
            if (currentLawMode == 2) {
              law10 = priceAmountx * 0.10;
            }
            double? total = priceAmountx + tax + law10;

            _controllers[index].text = item.quantity?.toStringAsFixed(2) ?? '';

            _items[index] = SaleItemProduct(
                id: item.id,
                addedFromEditPrices: item.addedFromEditPrices,
                productImage: item.productImage,
                discountId: item.discountId,
                discountName: item.discountName,
                discountRate: rate,
                discountSymbol: item.discountSymbol,
                indicadorFacturacion: indicadorFacturacion,
                conversionFactor: item.conversionFactor,
                unitCode: item.unitCode,
                unitName: item.unitName,
                unitSymbol: item.unitSymbol,
                chassis: item.chassis,
                licensePlate: item.licensePlate,
                colorName: item.colorName,
                quantity: item.quantity!,
                productId: item.productId,
                productName: item.productName,
                price: item.price,
                priceItem: item.priceItem,
                taxId: item.taxId,
                net: priceAmount,
                netFinal: priceAmountx,
                net16: net16,
                net18: net18,
                net3: 0,
                exemptAmount: exemptAmount,
                tax: tax,
                tax18: tax18,
                tax16: tax16,
                tax3: 0,
                law10: law10,
                discount: discount,
                total: total);

            _items = List.from(_items);
          }
          setState(() {});
        }
      } catch (e) {
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  _showClientsPage() async {
    var xclient = await Navigator.push<Client?>(
        context,
        MaterialPageRoute(
            builder: (ctx) => ClientsPage(
                  selectorMode: true,
                  client: Client(identification: clientName.text),
                )));

    if (xclient != null) {
      clientName.value = TextEditingValue(text: xclient.name ?? '');
      rncOrId.value = TextEditingValue(text: xclient.identification ?? '');

      client = xclient;
      setState(() {});
    }
  }

  _selectElementFromEditor() async {
    var result = await showDialog(
        context: context,
        builder: (ctx) => PriceEditorItemModal(
            sale: widget.sale, saleItem: SaleItemProduct()));

    if (result != null) {
      try {
        if (widget.sale is SaleProduct) {
          var product = result['el'];
          var price = (result['price'] as num).toDouble();

          var selectedItem = _items.firstWhere(
              (e) => e.productId == product?.id,
              orElse: () => SaleItemProduct());

          if (selectedItem.productId != null) {
            throw 'YA FUE AGREGADO EL PRODUCTO ${product.name}';
          }

          if (selectedItem.productId == null) {
            if (product != null) {
              product.quantity = 1.0;
              int? indicadorFacturacion = 1;

              double net18 = 0;
              double net16 = 0;
              double tax18 = 0;

              double tax16 = 0;

              double rate = 0;
              double discount = 0;
              double law10 = 0;

              double priceAmount = price * product.quantity!;
              double priceAmountx = priceAmount;

              if (product.discountId != null) {
                if (product.discountSymbolId == 1) {
                  rate = product.discountRate ?? 0;
                  discount = price * (rate / 100);
                }
                if (product.discountSymbolId == 2) {
                  rate = product.discountRate ?? 0;
                  discount = rate;
                }
                priceAmountx = priceAmount - discount;
              }

              if (product.taxId == 1) {
                net16 = priceAmountx;
              }

              if (product.taxId == 2) {
                net18 = priceAmountx;
              }

              double? exemptAmount = product.taxId == null ? priceAmount : 0;

              if (product.taxId != null) {
                indicadorFacturacion = product.taxId == 1 ? 2 : 1;
                tax18 = product.taxId == 2 ? priceAmountx * 0.18 : 0;
                tax16 = product.taxId == 1 ? priceAmountx * 0.16 : 0;
              } else {
                indicadorFacturacion = 4;
              }
              double? tax = tax18 + tax16;

              if (esEspecial) {
                tax = 0;
                tax16 = 0;
                tax18 = 0;
                net16 = 0;
                net18 = 0;
                indicadorFacturacion = 4;
                exemptAmount = priceAmountx;
              }

              if (currentLawMode == 2) {
                law10 = priceAmountx * 0.10;
              }
              double? total = priceAmountx + tax + law10;

              _focusNode.requestFocus();
              if (_items.length == 1 && _items[0].productId == null) {
                setState(() {
                  _items = [];
                });
              }

              var controller = TextEditingController();
              controller.text = product.quantity?.toStringAsFixed(2) ?? '';
              _controllers.insert(0, controller);

              _items.insert(
                  0,
                  SaleItemProduct(
                      id: Uuid().v4(),
                      quantity: 1,
                      addedFromEditPrices: true,
                      productImage: product.image,
                      discountId: product.discountId,
                      discountName: product.discountName,
                      discountRate: product.discountRate,
                      discountSymbol: product.discountSymbol,
                      unitCode: product.unitCode,
                      unitName: product.unitName,
                      unitSymbol: product.unitSymbol,
                      conversionFactor: product.conversionFactor,
                      productId: product.id,
                      productName: product.name,
                      indicadorFacturacion: indicadorFacturacion,
                      price: price,
                      taxId: product.taxId,
                      net: priceAmount,
                      netFinal: priceAmountx,
                      net16: net16,
                      net18: net18,
                      net3: 0,
                      exemptAmount: exemptAmount,
                      tax: tax,
                      tax18: tax18,
                      tax16: tax16,
                      tax3: 0,
                      discount: discount,
                      total: total));
            } else {}
          } else {
            int index =
                _items.indexWhere((e) => e.productId == selectedItem.productId);
            var item = _items[index];
            item.quantity = item.quantity! + 1;

            int? indicadorFacturacion = 1;
            double discount = 0;
            double ratex = 0;
            double priceAmount = item.price! * item.quantity!;
            double priceAmountx = priceAmount;
            double law10 = 0;

            if (item.discountId != null) {
              if (item.discountSymbol == '%') {
                ratex = item.discountRate ?? 0;
                discount = (item.price! * (item.quantity ?? 1)) * (ratex / 100);
              }
              if (item.discountSymbol == '\$') {
                ratex = item.discountRate ?? 0;
                discount = ratex * (item.quantity ?? 1);
              }
              priceAmountx = priceAmount - discount;
            }

            double net18 = 0;
            double net16 = 0;
            double? exemptAmount = item.taxId == null ? priceAmountx : 0;
            double tax18 = 0;
            double tax16 = 0;

            if (item.taxId == 1) {
              net16 = priceAmountx;
            }

            if (item.taxId == 2) {
              net18 = priceAmountx;
            }

            if (item.taxId != null) {
              indicadorFacturacion = item.taxId == 1 ? 2 : 1;
              tax18 = item.taxId == 2 ? priceAmountx * 0.18 : 0;
              tax16 = item.taxId == 1 ? priceAmountx * 0.16 : 0;
            } else {
              indicadorFacturacion = 4;
            }
            double? tax = tax18 + tax16;

            if (esEspecial) {
              tax = 0;
              tax16 = 0;
              tax18 = 0;
              net16 = 0;
              net18 = 0;
              indicadorFacturacion = 4;
              exemptAmount = priceAmountx;
            }

            if (currentLawMode == 2) {
              law10 = priceAmountx * 0.10;
            }
            double? total = priceAmountx + tax + law10;
            _controllers[index].text = item.quantity?.toStringAsFixed(2) ?? '';

            _items[index] = SaleItemProduct(
                id: item.id,
                addedFromEditPrices: true,
                productImage: item.productImage,
                discountId: item.discountId,
                discountName: item.discountName,
                discountRate: ratex,
                discountSymbol: item.discountSymbol,
                indicadorFacturacion: indicadorFacturacion,
                conversionFactor: item.conversionFactor,
                unitCode: item.unitCode,
                unitName: item.unitName,
                unitSymbol: item.unitSymbol,
                quantity: item.quantity!,
                productId: item.productId,
                productName: item.productName,
                price: item.price,
                taxId: item.taxId,
                net: priceAmount,
                netFinal: priceAmountx,
                net16: net16,
                net18: net18,
                net3: 0,
                exemptAmount: exemptAmount,
                tax: tax,
                tax18: tax18,
                tax16: tax16,
                tax3: 0,
                discount: discount,
                total: total);

            _items = List.from(_items);
          }

          setState(() {});
        }
      } catch (e) {
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  _onScanCode(String code) async {
    var isCode = esCodigoValido(code);

    if (isCode) {
      try {
        if (widget.sale is SaleProduct) {
          var product = await Products.findByCode(code: code);

          var selectedItem = _items.firstWhere(
              (e) => e.productId == product?.id,
              orElse: () => SaleItemProduct());

          if (selectedItem.productId == null) {
            if (product != null) {
              product.quantity = 1.0;
              int? indicadorFacturacion = 1;
              double net18 = 0;
              double net16 = 0;
              double tax18 = 0;

              double tax16 = 0;

              double rate = 0;
              double discount = 0;
              double law10 = 0;

              double priceAmount = product.price! * product.quantity!;
              double priceAmountx = priceAmount;

              if (product.discountId != null) {
                if (product.discountSymbolId == 1) {
                  rate = product.discountRate ?? 0;
                  discount = product.price! * (rate / 100);
                }
                if (product.discountSymbolId == 2) {
                  rate = product.discountRate ?? 0;
                  discount = rate;
                }
                priceAmountx = priceAmount - discount;
              }

              if (product.taxId == 1) {
                net16 = priceAmountx;
              }

              if (product.taxId == 2) {
                net18 = priceAmountx;
              }

              double? exemptAmount = product.taxId == null ? priceAmount : 0;

              if (product.taxId != null) {
                indicadorFacturacion = product.taxId == 1 ? 2 : 1;
                tax18 = product.taxId == 2 ? priceAmountx * 0.18 : 0;
                tax16 = product.taxId == 1 ? priceAmountx * 0.16 : 0;
              } else {
                indicadorFacturacion = 4;
              }
              double? tax = tax18 + tax16;

              if (esEspecial) {
                tax = 0;
                tax16 = 0;
                tax18 = 0;
                net16 = 0;
                net18 = 0;
                indicadorFacturacion = 4;
                exemptAmount = priceAmountx;
              }

              if (currentLawMode == 2) {
                law10 = priceAmountx * 0.10;
              }
              double? total = priceAmountx + tax + law10;

              _focusNode.requestFocus();
              if (_items.length == 1 && _items[0].productId == null) {
                setState(() {
                  _items = [];
                });
              }

              var controller = TextEditingController();
              controller.text = product.quantity?.toStringAsFixed(2) ?? '';
              _controllers.insert(0, controller);

              _items.insert(
                  0,
                  SaleItemProduct(
                      id: Uuid().v4(),
                      quantity: 1,
                      addedFromEditPrices: false,
                      productImage: product.image,
                      discountId: product.discountId,
                      discountName: product.discountName,
                      discountRate: product.discountRate,
                      discountSymbol: product.discountSymbol,
                      unitCode: product.unitCode,
                      unitName: product.unitName,
                      unitSymbol: product.unitSymbol,
                      conversionFactor: product.conversionFactor,
                      chassis: product.chassis,
                      licensePlate: product.licensePlate,
                      colorName: product.colorName,
                      productId: product.id,
                      productName: product.name,
                      indicadorFacturacion: indicadorFacturacion,
                      price: product.price,
                      priceItem: product.price,
                      taxId: product.taxId,
                      net: priceAmount,
                      netFinal: priceAmountx,
                      net16: net16,
                      net18: net18,
                      net3: 0,
                      exemptAmount: exemptAmount,
                      tax: tax,
                      tax18: tax18,
                      tax16: tax16,
                      tax3: 0,
                      discount: discount,
                      total: total));
            } else {}
          } else {
            int index =
                _items.indexWhere((e) => e.productId == selectedItem.productId);
            var item = _items[index];
            item.quantity = item.quantity! + 1;

            int? indicadorFacturacion = 1;
            double discount = 0;
            double ratex = 0;
            double priceAmount = item.price! * item.quantity!;
            double priceAmountx = priceAmount;
            double law10 = 0;

            if (item.discountId != null) {
              if (item.discountSymbol == '%') {
                ratex = item.discountRate ?? 0;
                discount = (item.price! * (item.quantity ?? 1)) * (ratex / 100);
              }
              if (item.discountSymbol == '\$') {
                ratex = item.discountRate ?? 0;
                discount = ratex * (item.quantity ?? 1);
              }
              priceAmountx = priceAmount - discount;
            }

            double net18 = 0;
            double net16 = 0;
            double? exemptAmount = item.taxId == null ? priceAmountx : 0;
            double tax18 = 0;
            double tax16 = 0;

            if (item.taxId == 1) {
              net16 = priceAmountx;
            }

            if (item.taxId == 2) {
              net18 = priceAmountx;
            }

            if (item.taxId != null) {
              indicadorFacturacion = item.taxId == 1 ? 2 : 1;
              tax18 = item.taxId == 2 ? priceAmountx * 0.18 : 0;
              tax16 = item.taxId == 1 ? priceAmountx * 0.16 : 0;
            } else {
              indicadorFacturacion = 4;
            }
            double? tax = tax18 + tax16;

            if (esEspecial) {
              tax = 0;
              tax16 = 0;
              tax18 = 0;
              net16 = 0;
              net18 = 0;
              indicadorFacturacion = 4;
              exemptAmount = priceAmountx;
            }

            if (currentLawMode == 2) {
              law10 = priceAmountx * 0.10;
            }
            double? total = priceAmountx + tax + law10;
            _controllers[index].text = item.quantity?.toStringAsFixed(2) ?? '';

            _items[index] = SaleItemProduct(
                id: item.id,
                addedFromEditPrices: item.addedFromEditPrices,
                productImage: item.productImage,
                discountId: item.discountId,
                discountName: item.discountName,
                discountRate: ratex,
                discountSymbol: item.discountSymbol,
                indicadorFacturacion: indicadorFacturacion,
                conversionFactor: item.conversionFactor,
                chassis: item.chassis,
                licensePlate: item.licensePlate,
                colorName: item.colorName,
                unitCode: item.unitCode,
                unitName: item.unitName,
                unitSymbol: item.unitSymbol,
                quantity: item.quantity!,
                productId: item.productId,
                productName: item.productName,
                price: item.price,
                priceItem: item.priceItem,
                taxId: item.taxId,
                net: priceAmount,
                netFinal: priceAmountx,
                net16: net16,
                net18: net18,
                net3: 0,
                exemptAmount: exemptAmount,
                tax: tax,
                tax18: tax18,
                tax16: tax16,
                tax3: 0,
                discount: discount,
                total: total);

            _items = List.from(_items);
          }

          setState(() {});
        }
      } catch (e) {
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  _onSelectedNcf(String? option) async {
    currentNcfTypeId = option;
    currentPrefix = 'E';
    maxSequence = 10;
    if (option == '60') {
      currentPrefix = 'C';
      currentPaymentMethodId = 4;
      currentPaymentModeId = 2;
      currentPaymentType = 2;
    }

    if (enabledQuotationsSetup && currentNcfTypeId == '60') {
      currentPrefix = 'C';
      currentPaymentMethodId = 4;
      currentPaymentType = 2;
      currentPaymentModeId = 2;
    }

    if (option == '50') {
      currentPrefix = 'P';
      maxSequence = 8;
    }

    if (esGubernamental) {
      currentLawMode = 1;
      retentionDate = null;
      retentionDateController.value = TextEditingValue.empty;
    }

    if (option != null) {
      for (int i = 0; i < _items.length; i++) {
        var item = _items[i];
        SaleItem? newItem;

          if (esGubernamental) {
          newItem = item.copyWith(
              serviceId: item.serviceId,
              productId: item.productId,
              tax: item.tax,
              tax16: item.tax16,
              tax18: item.tax18,
              tax3: item.tax3,
              net16: item.net16,
              net18: item.net18,
              net3: item.net3,
              taxId: item.taxId,
              law10: item.law10,
              price: item.price,
              priceItem: item.priceItem,
              discountId: item.discountId,
              discount: item.discount,
              discountName: item.discountName,
              discountRate: item.discountRate,
              discountSymbol: item.discountSymbol,
              retentionIsrId: null,
              retentionIsr: 0,
              retentionTaxId: null,
              retentionTax: 0,
              indicadorFacturacion: item.indicadorFacturacion,
              exemptAmount: item.netFinal,
              total: item.total);
          _items[i] = newItem;
        }

        if (esEspecial || esMenor) {
          newItem = item.copyWith(
              productId: item.productId,
              serviceId: item.serviceId,
              tax: 0,
              tax16: 0,
              tax18: 0,
              tax3: 0,
              net16: 0,
              net18: 0,
              net3: 0,
              net: item.net,
              law10: item.law10,
              discount: item.discount,
              discountId: item.discountId,
              discountName: item.discountName,
              discountRate: item.discountRate,
              discountSymbol: item.discountSymbol,
              retentionTaxId: item.retentionTaxId,
              retentionTax: item.retentionTax,
              retentionIsrId: item.retentionIsrId,
              retentionIsr: item.retentionIsr,
              netFinal: item.netFinal,
              indicadorFacturacion: 4,
              exemptAmount: item.netFinal,
              total: item.total! - (item.tax ?? 0));
          _items[i] = newItem;
        } else {
          if (item.priceItem != null) {
            var type = item.taxId;
            double tax = 0;
            double tax16 = 0;
            double tax18 = 0;
            double net16 = 0;
            double net18 = 0;
            double discount = 0;
            double netFinal = 0;
            double law10 = 0;
            double total = 0;
            double exemptAmount = 0;

            double priceAmount = item.priceItem! * (item.quantity ?? 1);
            double priceAmountx = priceAmount;
            int indicadorFacturacion = 1;

            if (item.discountSymbol == '%') {
              discount = (item.discountRate! / 100) * priceAmountx;
            }

            if (item.discountSymbol == '\$') {
              discount = item.discountRate ?? 0;
            }

            priceAmountx = priceAmountx - discount;

            if (item.law10 != null && item.law10! > 0) {
              law10 = priceAmountx * 0.10;
            }

            if (type == 1) {
              indicadorFacturacion = 2;
              tax16 = priceAmountx * 0.16;
              net16 = priceAmountx;
            }
            if (type == 2) {
              indicadorFacturacion = 1;
              tax18 = priceAmountx * 0.18;
              net18 = priceAmountx;
            }

            if (type == null) {
              tax16 = 0;
              net16 = 0;
              net18 = 0;
              tax18 = 0;
              indicadorFacturacion = 4;
              exemptAmount = priceAmountx;
            }
            tax = tax16 + tax18;
            netFinal = net16 + net18;
            law10 = item.law10 ?? 0;

            total = netFinal + tax + law10;

            newItem = item.copyWith(
                serviceId: item.serviceId,
                productId: item.productId,
                tax: tax,
                tax16: tax16,
                tax18: tax18,
                net: priceAmount,
                discount: discount,
                discountId: item.discountId,
                discountName: item.discountName,
                discountRate: item.discountRate,
                discountSymbol: item.discountSymbol,
                net16: net16,
                net18: net18,
                law10: law10,
                netFinal: netFinal,
                indicadorFacturacion: indicadorFacturacion,
                exemptAmount: exemptAmount,
                total: total);

            _items[i] = newItem;
          }
        }
      }

      setState(() {
        _items = List.from(_items);
      });
    }
    try {

       if(currentNcfTypeId != null){
         ncfList = await NcfsList(ncfTypeId: currentNcfTypeId).findNcf();

      if (ncfList != null) {
        fechaVencimiento = ncfList!.expirationDate!;
        fechaVencimientoController.value = TextEditingValue(
            text: fechaVencimiento.format(payload: 'DD/MM/YYYY'));

        var msg = await ncfList?.checkIfExistAvailable();
        if (msg != null) {
          var errorMsg = msg['error'];

          if (errorMsg != null) {
            setState(() {
              isValid = false;
            });
            await LogHandler.printError(errorMsg);
            showTopSnackBar(context, message: msg['error'], color: Colors.red);
          }
        }
      }else{
           throw 'NO EXISTEN COMPROBANTES TIPO: $currentNcfTypeId DISPONIBLES';
      }
      int umbral = 1;
      var checkObj =
          await NcfSecuencia(id: currentNcfTypeId).checkNcfs(umbral: umbral);

      if (checkObj != null) {
        for (var item in checkObj) {
          int dif = item['dif'];
          String name = item['name'];
          throw 'QUEDAN $dif $name';
        }
      }

       }
     
    } catch (e) {
          setState(() {
              isValid = false;
            });
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  Future<void> enviarEcf(Sale xsale) async {
    await enviarDgii(
        sale: xsale,
        instanceSale: widget.sale,
        currentSale: _currentSale,
        currentNcfTypeId: currentNcfTypeId,
        clientName: clientName,
        rncOrId: rncOrId,
        xrate: xrate,
        formasDePagos: formasDePagos,
        totalGravado: totalGravado,
        totalGravado18: totalGravado18,
        totalGravado16: totalGravado16,
        totalGravado3: totalGravado3,
        montoExento: montoExento,
        itbisGravado: itbisGravado,
        itbisGravado18: itbisGravado18,
        itbisGravado16: itbisGravado16,
        itbisGravado0: itbisGravado3,
        totalRetencionItbis: totalRetencionItbis,
        totalRetencionIsr: totalRetencionIsr,
        totalFacturado: totalFacturado,
        fechaVencimiento: fechaVencimiento,
        currentPaymentMethodId: currentPaymentMethodId,
        currentPaymentType: currentPaymentType,
        currentTypeIncomeId: currentTypeIncomeId,
        currentOverrideCode: currentOverrideCode,
        canOverrideTaxes: canOverrideTaxes);
  }

  Future<void> _initAsync() async {
    if (isSale &&
        enabledPosAutomaticSetup &&
        widget.generateNcfFromProforma == false) {
      client = await Client.findClientContado();
      clientName.value = TextEditingValue(text: client?.name ?? '');
      rncOrId.value = TextEditingValue(text: client?.identification ?? '');
      isValid = true;
    }
    if (currentNcfTypeId != null) {
      int umbral = 1;
      var checkObj =
          await NcfSecuencia(id: currentNcfTypeId).checkNcfs(umbral: umbral);

      if (checkObj != null) {
        for (var item in checkObj) {
          int dif = item['dif'];
          String name = item['name'];
          showTopSnackBar(context,
              message: 'QUEDAN $dif $name', color: Colors.red);
        }
      }

      ncfList = await NcfsList(ncfTypeId: currentNcfTypeId).findNcf();

      if (ncfList != null) {
        fechaVencimiento = ncfList!.expirationDate!;
        fechaVencimientoController.text =
            fechaVencimiento.format(payload: 'DD/MM/YYYY');
      }
    }

    setState(() {});
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);
      try {
        if (eCommerceMode) {
          if (disabledTicket == false) {
            if (devicePos == null) {
              throw 'EL DISPOSITIVO DE PUNTO DE VENTA NO ESTA CONFIGURADO (CONTACTE CON EL ADMINISTRADOR DEL SISTEMA)';
            }
          }
        }

        var now = DateTime.now();
        //var dateLocal = DateTime(now.year, now.month, now.day);

        createdAt = now;

        widget.sale.ncfTypeId = currentNcfTypeId;
        widget.sale.items = widget.items;
        widget.sale.net = calcs[0];
        widget.sale.discount = calcs[1];
        widget.sale.tax = calcs[2];
        widget.sale.total = calcs[3];
        widget.sale.retentionIsr = calcs[4];
        widget.sale.retentionTax = calcs[5];
        widget.sale.paymentMethodId = currentPaymentMethodId;
        widget.sale.clientId = client?.id ?? taxPayer?.taxPayerId;
        widget.sale.clientIdentification = rncOrId.text.replaceAll('-', '');
        widget.sale.typeIncomeId = currentTypeIncomeId;
        widget.sale.description = description.text;
        widget.sale.clientName = clientName.text;
        widget.sale.retentionDate = retentionDate;
        widget.sale.currencyId = currentCurrencyId;
        widget.sale.createdAt = createdAt;
        widget.sale.tipoPago = currentPaymentType;
        widget.sale.expirationDate = fechaVencimiento;
        widget.sale.rate = 1;
        widget.sale.net18 = calcs[10];
        widget.sale.net16 = calcs[11];
        widget.sale.net3 = calcs[12];
        widget.sale.tax18 = calcs[7];
        widget.sale.tax16 = calcs[8];
        widget.sale.tax3 = calcs[9];
        widget.sale.law10 = calcs[15];
        widget.sale.exemptAmount = calcs[13];
        widget.sale.authorId = currentUser?.id;
        widget.sale.ncfAffectedCreatedAt = _currentSale?.createdAt;
        widget.sale.coinBack = 0;
        widget.sale.paymentDate = paymentDate;
        widget.sale.ncfListId = ncfList?.id;

        if (ncfList == null) {
          throw 'NO TIENE SECUENCIA REGISTRADA PARA EL COMPROBANTE TIPO: $currentNcfTypeId';
        }


        if (widget.generateNcfFromProforma) {
          widget.sale.refInvoiceId = widget.sale.id;
        }

        var amount = amountInputFormatter.doubleValue;
        var amountx = amount;

        if (debt < 0) {
          amountx = montoAPagarReferencia;

          if (widget.editing) {
            amountx = widget.sale.debt!;
          }
        }

        if (currentPaymentModeId == 1) {
          amountx = montoAPagarReferencia;
          amount = montoAPagarReferencia;
        }

        if (currentPaymentModeId == 2) {
          amountx = 0;
          amount = 0;
        }

        if (rate.text.isNotEmpty) {
          widget.sale.rate = double.tryParse(rate.text);
        }

        widget.sale.clientType = rncOrId.text.length == 9
            ? 1
            : rncOrId.text.length == 11
                ? 2
                : null;

        if (widget.sale is SaleService) {
          widget.sale.invoiceTypeId = 1;
        }

        if (widget.sale is SaleProduct) {
          widget.sale.invoiceTypeId = 2;
        }

        widget.items = _items.where((e) => e.enabled == true).toList();
        widget.sale.items = widget.items;

        if (!widget.editing) {
          widget.sale.effective = 0;
          widget.sale.creditCard = 0;
          widget.sale.checkOrTransf = 0;
          widget.sale.saleToCredit = 0;
        }

        widget.sale.paidInvoice = 0;

        widget.sale.bankId = currentBankId;
        widget.sale.transfRef = transfRef.text;
        if (currentNcfTypeId != null &&
            (currentNcfTypeId!.startsWith('3') ||
                currentNcfTypeId!.startsWith('4'))) {
          widget.sale.prefix = 'E';
          widget.sale.maxSequence = 10;
        } else if (currentNcfTypeId != null && currentNcfTypeId == '50') {
          widget.sale.prefix = 'P';
          widget.sale.maxSequence = 8;
        } else if (currentNcfTypeId != null && currentNcfTypeId == '60') {
          widget.sale.prefix = 'C';
          widget.sale.maxSequence = 8;
        } else {
          widget.sale.prefix = 'B';
          widget.sale.maxSequence = 8;
        }

        if (widget.sale.prefix == 'E') {
          await hasInternet();
        }

        if (electronicNcfEnabled == false && widget.sale.prefix == 'E') {
          throw 'NO SE PUEDE REALIZAR LA VENTA, LA FACTURACION ELECTRONICA NO ESTA HABILITADA (CONTACTE CON EL ADMINISTRADOR DEL SISTEMA)';
        }

        if (!widget.editing &&
            (widget.sale.debt == 0 || widget.sale.debt == null)) {
          if (currentPaymentMethodId == 1) {
            widget.sale.effective = amountx;
          }

          if (currentPaymentMethodId == 2) {
            widget.sale.creditCard = amountx;
          }

          if (currentPaymentMethodId == 3) {
            widget.sale.checkOrTransf = amountx;
          }

          if (currentPaymentMethodId == 4) {
            widget.sale.saleToCredit = amountx;
          }
        } else {
          if (currentPaymentMethodId == 1) {
            widget.sale.effective = widget.sale.effective! + amountx;
          }

          if (currentPaymentMethodId == 2) {
            widget.sale.creditCard = widget.sale.creditCard! + amountx;
          }

          if (currentPaymentMethodId == 3) {
            widget.sale.checkOrTransf = widget.sale.checkOrTransf! + amountx;
          }

          if (currentPaymentMethodId == 4) {
            widget.sale.saleToCredit = widget.sale.saleToCredit! + amountx;
          }
        }

        if (widget.sale.paid != null) {
          widget.sale.paid = widget.sale.paid! + amount;
        } else {
          widget.sale.paid = amount;
        }

        widget.sale.paidInvoice = amountx;

        if (debt < 0) {
          widget.sale.coinBack = debt.abs();
        }

        if (amount > itbisGravado || esNotaCredito || automaticSendEcf) {
          issueDate = now;
          widget.sale.issueDate = issueDate;
        }

        Sale? sale;

        if (!widget.editing) {
          sale = await widget.sale.create();

          await LogHandler.printEvent(
              '${sale?.ncfTypeName} ${sale?.ncf} FUE CREADA, RNC/CEDULA: ${sale?.clientId}, EL CLIENTE: ${sale?.clientName}');
        } else {
          sale = await widget.sale.update();
          await LogHandler.printEvent(
              '${sale?.ncfTypeName} ${sale?.ncf} FUE ACTUALIZADA, RNC/CEDULA: ${sale?.clientId}, EL CLIENTE: ${sale?.clientName}');
        }

        if (widget.sale.prefix == 'E' &&
            sale != null &&
            sale.signatureDate == null) {
          widget.sale.paid = amountx * xrate;

          if (sale.debt == 0 && eCommerceMode) {
            sale.issueDate = issueDate;
            await enviarEcf(sale);
          } else if (eCommerceMode == false) {
            sale.issueDate = issueDate;
            await enviarEcf(sale);
          }

          await LogHandler.printEvent(
              '${sale.ncfTypeName} ${sale.ncf} FUE ENVIADA A DGII, RNC/CEDULA: ${sale.clientId}, EL CLIENTE: ${sale.clientName}');
        }

        late File file;

        if (eCommerceMode) {
          if (currentNcfTypeId != '60' && currentNcfTypeId != '50') {
            if (sale!.debt! > 0) {
              Navigator.pop(context);
              var xsale = await showDialog<Sale?>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => PaymentEditorModal(sale: sale!));

              if (widget.sale.prefix == 'E') {
                if (xsale != null) {
                  showLoader(context);
                  await enviarEcf(xsale);
                  sale = xsale;
                } else {
                  showLoader(context);
                  await enviarEcf(sale);
                }
              } else {
                showLoader(context);
              }
            }
          }
          printInvoice() async {
            var bytes = await createDefaultTicket(sale: sale!);

            await PrinterHandler.printBytes(devicePos ?? '', bytes);

            await LogHandler.printEvent('SE IMPRIMIO LA FACTURA ${sale.ncf}');
          }

          if (devicePos != null) {
            printInvoice();
          }
        } else {
          var doc = await createInvoice(sale!);

          var fileName = '${sale.clientName}_${sale.ncf}_${company?.name}.PDF';

          var dir = await getUresaxInvoiceDir();
          var filePath = path.join(
              dir.path,
              esNotaCredito ? 'NOTAS DE CREDITO' : 'VENTAS',
              sale.createdAt!.format(payload: 'YYYYMM'),
              'PDFS',
              fileName);
          file = File(filePath);
          await file.create(recursive: true);
          await LogHandler.printEvent('SE CREO EL ARCHIVO: ${file.path}');
          await file.writeAsBytes(await doc.save());

 

          await LogHandler.printEvent('SE ESCRIBIO EL ARCHIVO: ${file.path}');

          await LogHandler.printEvent('SE ABRIO EL ARCHIVO: ${file.path}');
        }

    
        if (noEsElectronico) {
          if (widget.sale is SaleProduct) {
            await Products.updateMinusStock(
                items: sale!.items, ncfTypeId: sale.ncfTypeId!);
            await LogHandler.printEvent(
                'EL STOCK FUE ACTUALIZADO - ${sale.ncf}');
          }

          if (widget.sale is CreditNoteAsProduct) {
            await Products.updateAddStock(
                items: sale!.items, ncfTypeId: sale.ncfTypeId!);
            await LogHandler.printEvent(
                'EL STOCK FUE ACTUALIZADO - ${sale.ncf}');
          }
        }

        if (widget.generateNcfFromProforma) {
          Navigator.pop(context);
          Navigator.pop(context, 'UPDATE');
        } else {
          _reset();
          Navigator.pop(context);
        }

        if (eCommerceMode == false) {
          await OpenFile.open(file.path);
        }

        showTopSnackBar(context,
            message: widget.editing ? 'FACTURA EDITADA' : 'FACTURA CREADA',
            color: Colors.green);
      } catch (e) {
        _reset();
        print(e);
        await LogHandler.printEvent(e.toString());
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  _reset() async {
    try {
      amount.text = '';
      amountInputFormatter.clear();
      widget.sale.amountPaid = 0;
      description.text = '';
      retentionDate = null;
      retentionDateController.text = '';
      _currentSale = null;
      widget.sale.total = 0;
      widget.sale.net = 0;
      widget.sale.net16 = 0;
      widget.sale.net18 = 0;
      widget.sale.net3 = 0;
      widget.sale.tax = 0;
      widget.sale.tax18 = 0;
      widget.sale.tax16 = 0;
      widget.sale.tax3 = 0;
      widget.sale.exemptAmount =0;
      widget.sale.coinBack = 0;
      widget.sale.paid = 0;
      widget.sale.netFinal = 0;
      widget.sale.discount = 0;
      widget.sale.law10 = 0;
      widget.sale.bankId = null;
      widget.sale.clientAddress = null;
      widget.sale.clientEmail = null;
      widget.sale.clientIdentification = null;
      widget.sale.currencyId = null;
      widget.sale.clientName = null;
      widget.sale.clientPhone = null;
      widget.sale.refInvoiceId = null;
      widget.sale.createdAt = null;
      widget.sale.issueDate = null;
      widget.sale.effective = 0;
      widget.sale.checkOrTransf = 0;
      widget.sale.creditCard = 0;
      widget.sale.saleToCredit = 0;
      widget.sale.retentionDate = null;
      widget.sale.estadoDgii = null;
      widget.sale.debt = 0;
      widget.sale.estadoDgiiNombre = null;
      widget.sale.expirationDate = null;
      widget.sale.description = null;
      widget.sale.paymentDate = null;
      widget.sale.typeIncomeId = null;
      widget.sale.transfRef = null;
  
      widget.items = [];

      if (eCommerceMode && isSale) {
        currentTypeIncomeId = '01';
        if (enabledPosAutomaticSetup) {
          client = await Client.findClientContado();
          clientName.value = TextEditingValue(text: client?.name ?? '');
          rncOrId.value = TextEditingValue(text: client?.identification ?? '');
          isValid = true;
          currentNcfTypeId = '32';
          currentCurrencyId = 1;
          currentPaymentMethodId = 1;
          currentPaymentModeId = 3;
          currentPaymentType = 1;
        } else {
          clientName.text = '';
          rncOrId.text = '';
          currentTypeIncomeId = '01';
          currentNcfTypeId = null;
          currentCurrencyId = 1;
          currentOverrideCode = null;
          currentPaymentMethodId = null;
          currentPaymentType = null;
          currentPaymentModeId = null;
        }
      } else {
        clientName.text = '';
        rncOrId.text = '';
        currentTypeIncomeId = '01';
        currentNcfTypeId = null;
        currentCurrencyId = 1;
        currentOverrideCode = null;
        currentPaymentMethodId = null;
        currentPaymentType = null;
        currentPaymentModeId = null;
      }

      setState(() {
        _items = [];
        _controllers = [];
      });

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
        _scrollController2.jumpTo(0);
      }

      setState(() {});
    } catch (e) {
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _recalcProduct(
      {required SaleItemProduct item,
      required int index,
      required TextEditingController controller,
      String? newQuantity,
      required ActionCart action}) {
    double quantity = 1.0;

    if (action == ActionCart.add) {
      quantity = item.quantity! + 1;
    }

    if (action == ActionCart.remove) {
      quantity = item.quantity! - 1;
    }
    if (action == ActionCart.edit) {
      quantity = double.parse(newQuantity ?? '1');
    }

    item.quantity = quantity;

    int? indicadorFacturacion = 1;
    double priceAmount = item.price! * quantity;
    double net18 = 0;
    double net16 = 0;

    double tax18 = 0;
    double tax16 = 0;

    double rate = 0;
    double discount = 0;
    double law10 = 0;

    double priceAmountx = priceAmount;
    double? exemptAmount = item.taxId == null ? priceAmountx : 0;

    if (item.discountSymbol != null) {
      if (item.discountSymbol == '%') {
        rate = item.discountRate ?? 0;
        discount = (item.price! * (item.quantity ?? 1)) * (rate / 100);
      }
      if (item.discountSymbol == '\$') {
        rate = item.discountRate ?? 0;
        discount = rate * (item.quantity ?? 1);
      }
      priceAmountx = priceAmount - discount;
    } else {
      rate = 0;
    }

    if (item.taxId == 1) {
      net16 = priceAmountx;
    }

    if (item.taxId == 2) {
      net18 = priceAmountx;
    }

    if (item.taxId != null) {
      indicadorFacturacion = item.taxId == 1 ? 2 : 1;
      tax18 = item.taxId == 2 ? priceAmountx * 0.18 : 0;
      tax16 = item.taxId == 1 ? priceAmountx * 0.16 : 0;
    } else {
      indicadorFacturacion = 4;
    }
    if (currentLawMode == 2) {
      law10 = priceAmountx * 0.10;
    }
    double? tax = tax18 + tax16;
    if (esEspecial) {
      tax = 0;
      tax16 = 0;
      tax18 = 0;
      net16 = 0;
      net18 = 0;
      indicadorFacturacion = 4;
      exemptAmount = priceAmountx;
    }

    double? total = priceAmountx + tax + law10;

    var newItem = item.copyWith(
        id: item.id,
        indicadorFacturacion: indicadorFacturacion,
        discountId: item.discountId,
        discountName: item.discountName,
        discountRate: rate,
        discountSymbol: item.discountSymbol,
        conversionFactor: item.conversionFactor,
        unitCode: item.unitCode,
        unitName: item.unitName,
        unitSymbol: item.unitSymbol,
        quantity: item.quantity!,
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        taxId: item.taxId,
        net: priceAmount,
        netFinal: priceAmountx,
        net16: net16,
        net18: net18,
        net3: 0,
        exemptAmount: exemptAmount,
        tax: tax,
        tax18: tax18,
        tax16: tax16,
        tax3: 0,
        law10: law10,
        discount: discount,
        total: total);

    if (action != ActionCart.edit) {
      controller.text = quantity.toStringAsFixed(2);
    }

    _items[index] = newItem;

    setState(() {
      _items = List.from(_items);
    });
  }

  _recalcService(
      {required SaleItemService item,
      required int index,
      required TextEditingController controller,
      String? newQuantity,
      required ActionCart action}) {
    double quantity = 1.0;

    if (action == ActionCart.add) {
      quantity = item.quantity! + 1;
    }

    if (action == ActionCart.remove) {
      quantity = item.quantity! - 1;
    }
    if (action == ActionCart.edit) {
      quantity = double.parse(newQuantity ?? '1');
    }

    item.quantity = quantity;

    int? indicadorFacturacion = 1;
    double priceAmount = item.price! * quantity;
    double net18 = 0;
    double net16 = 0;

    double tax18 = 0;
    double tax16 = 0;

    double rate = 0;
    double discount = 0;
    double law10 = 0;

    double priceAmountx = priceAmount;
    double? exemptAmount = item.taxId == null ? priceAmountx : 0;

    if (item.discountSymbol != null) {
      if (item.discountSymbol == '%') {
        rate = item.discountRate ?? 0;
        discount = (item.price! * (item.quantity ?? 1)) * (rate / 100);
      }
      if (item.discountSymbol == '\$') {
        rate = item.discountRate ?? 0;
        discount = rate * (item.quantity ?? 1);
      }
      priceAmountx = priceAmount - discount;
    } else {
      rate = 0;
    }

    if (item.taxId == 1) {
      net16 = priceAmountx;
    }

    if (item.taxId == 2) {
      net18 = priceAmountx;
    }

    if (item.taxId != null) {
      indicadorFacturacion = item.taxId == 1 ? 2 : 1;
      tax18 = item.taxId == 2 ? priceAmountx * 0.18 : 0;
      tax16 = item.taxId == 1 ? priceAmountx * 0.16 : 0;
    } else {
      indicadorFacturacion = 4;
    }

    if (currentLawMode == 2) {
      law10 = priceAmountx * 0.10;
    }
    double? tax = tax18 + tax16;
    if (esEspecial) {
      tax = 0;
      tax16 = 0;
      tax18 = 0;
      net16 = 0;
      net18 = 0;
      indicadorFacturacion = 4;
      exemptAmount = priceAmountx;
    }

    double? total = priceAmountx + tax + law10;

    var newItem = item.copyWith(
        id: item.id,
        indicadorFacturacion: indicadorFacturacion,
        serviceId: item.serviceId,
        serviceName: item.serviceName,
        discountId: item.discountId,
        discountName: item.discountName,
        discountRate: rate,
        discountSymbol: item.discountSymbol,
        quantity: item.quantity!,
        price: item.price,
        taxId: item.taxId,
        net: priceAmount,
        netFinal: priceAmountx,
        net16: net16,
        net18: net18,
        net3: 0,
        exemptAmount: exemptAmount,
        tax: tax,
        tax18: tax18,
        tax16: tax16,
        tax3: 0,
        law10: law10,
        discount: discount,
        total: total);

    if (action != ActionCart.edit) {
      controller.text = quantity.toStringAsFixed(2);
    }

    _items[index] = newItem;

    setState(() {
      _items = List.from(_items);
    });
  }

  @override
  void initState() {
    keyboardController = OnscreenKeyboard.of(context);
    var now = DateTime.now();
    var dateLocal = now;

    createdAt = now;

    if (!mounted) return;
    _focusNode.requestFocus();
    _items = [...widget.items];

    for (int i = 0; i < _items.length; i++) {
      _controllers.add(TextEditingController(
          text: _items[i].quantity?.toStringAsFixed(2) ?? '1.00'));
    }
    _ncfs = [...ncfs];

    if (widget.generateNcfFromProforma == true) {
      _ncfs.removeWhere((e) => e.id == '60' || e.id == '50');
    }



    if (!isSale) {
      _ncfs.removeWhere((e) =>
          e.id == '01' ||
          e.id == '02' ||
          e.id == '15' ||
          e.id == '31' ||
          e.id == '32' ||
          e.id == '45' ||
          e.id == '44' ||
          e.id == '50');
    }

    if (isSale) {
      _ncfs.removeWhere((e) => e.id == '34' || e.id == '04');
    } else {
      currentNcfTypeId = '34';
      currentPrefix = 'E';
      maxSequence = 10;
    }

    if (!widget.generateNcfFromProforma) {
      createdAt = widget.sale.createdAt ?? dateLocal;
    } else {
      createdAt = dateLocal;
      client = Client(
          id: widget.sale.clientId,
          identification: widget.sale.clientIdentification,
          name: widget.sale.clientName);
      clientName.value = TextEditingValue(text: widget.sale.clientName ?? '');
      rncOrId.value =
          TextEditingValue(text: widget.sale.clientIdentification ?? '');
      isValid = true;
      currentCurrencyId = widget.sale.currencyId ?? 1;
      currentTypeIncomeId = widget.sale.typeIncomeId;
      description.text = widget.sale.description ?? '';
    }

    issueDate = widget.sale.createdAt ?? createdAt;

    issueDateController.value =
        TextEditingValue(text: issueDate.format(payload: 'DD/MM/YYYY'));

    fechaVencimientoController.value =
        TextEditingValue(text: fechaVencimiento.format(payload: 'DD/MM/YYYY'));

    if (eCommerceMode) {
      currentTypeIncomeId = '01';
      if (enabledPosAutomaticSetup) {
        if (isSale && widget.generateNcfFromProforma == false) {
          if (widget.editing == false) {
            currentNcfTypeId = '32';
          }
        }
        currentCurrencyId = 1;
        currentPaymentMethodId = 1;
        currentPaymentModeId = 3;
        currentPaymentType = 1;
      }
    }

    if (widget.editing == false && isSale) {
      if (widget.generateNcfFromProforma == false) {
        if (enabledOnlySeller) {
          _ncfs.removeWhere((e) =>
              e.id == '31' ||
              e.id == '32' ||
              e.id == '34' ||
              e.id == '45' ||
              e.id == '44' ||
              e.id == '43' ||
              e.id == '50');
          currentNcfTypeId = '60';
          currentPrefix = 'C';
          currentPaymentMethodId = 4;
          currentPaymentType = 2;
          currentPaymentModeId = 2;
        }
      }
    }
    setState(() {
      _initAsync();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: KeyboardListener(
            focusNode: _focusKeyboard,
            onKeyEvent: (event) {
              _handlerCommands(event);
            },
            child: Scaffold(
                appBar: AppBar(
                  title: Text('FACTURANDO...'),
                  actions: [
                    CircleAvatar(
                      child: IconButton(
                          onPressed: widget.sale is SaleProduct
                              ? _showProducts
                              : _showServices,
                          icon: Icon(Icons.add)),
                    ),
                    eCommerceMode
                        ? Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: kDefaultPadding),
                            child: IconButton(
                                onPressed: () async {
                                  devicePos = await Navigator.push<String?>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (ctx) => PrintersPage()));
                                },
                                icon: Icon(Icons.print)),
                          )
                        : SizedBox(width: kDefaultPadding),
                    CircleAvatar(
                      child: IconButton(
                          tooltip: 'REINICIAR',
                          onPressed: _reset,
                          icon: Icon(Icons.restore)),
                    ),
                    SizedBox(
                      width: kDefaultPadding,
                    ),
                    CircleAvatar(
                      child: IconButton(
                          onPressed: () async {
                            currentUser = null;
                            await Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (ctx) => LoginPage()),
                                (_) => false);

                            await LogHandler.printEvent(
                                '${currentUser?.name} CERRO SESION');
                          },
                          icon: Icon(Icons.power_settings_new_outlined)),
                    ),
                    SizedBox(
                      width: kDefaultPadding,
                    )
                  ],
                ),
                body: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height,
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Container(
                                  color: const Color(0xFFEFEEEE),
                                  padding: EdgeInsets.all(kDefaultPadding),
                                  height: MediaQuery.of(context).size.height,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListenCodeWidget(
                                          enabled: widget.sale is SaleProduct &&
                                              eCommerceMode,
                                          focusNode: _focusNode,
                                          onScan: _onScanCode,
                                          child: Container()),
                                      _items.isNotEmpty
                                          ? Text(
                                              'ARTICULOS (${quantity.toStringAsFixed(2)})',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .displayMedium
                                                  ?.copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontWeight:
                                                          FontWeight.w500))
                                          : SizedBox(),
                                      SizedBox(
                                        height: kDefaultPadding,
                                      ),
                                      Expanded(
                                          child: _items.isEmpty
                                              ? Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.inventory,
                                                          size: 100,
                                                          color: Theme.of(
                                                                  context)
                                                              .primaryColor),
                                                      SizedBox(
                                                          height:
                                                              kDefaultPadding),
                                                      Text(
                                                          'NO HAY ARTICULOS AGREGADOS',
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .headlineMedium
                                                              ?.copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .primaryColor))
                                                    ],
                                                  ),
                                                )
                                              : SingleChildScrollView(
                                                  controller: _scrollController,
                                                  child: Column(
                                                    children: [
                                                      ...List.generate(
                                                          _items.length,
                                                          (index) {
                                                        var item =
                                                            _items[index];

                                                        var controller =
                                                            _controllers[index];
                                                        return Container(
                                                            key: ValueKey(
                                                                '${item.id}'),
                                                            padding: EdgeInsets.all(
                                                                kDefaultPadding),
                                                            margin: EdgeInsets.only(
                                                                bottom:
                                                                    kDefaultPadding /
                                                                        2),
                                                            decoration: BoxDecoration(
                                                                color: const Color(
                                                                    0xFFDCD9D9),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20)),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                    child: Row(
                                                                  children: [
                                                                    ItemImageWidget(
                                                                        item:
                                                                            item),
                                                                    SizedBox(
                                                                      width:
                                                                          kDefaultPadding /
                                                                              2,
                                                                    ),
                                                                    Expanded(
                                                                        child:
                                                                            Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              kDefaultPadding / 2,
                                                                        ),
                                                                        Text(
                                                                            item.productName ??
                                                                                item.serviceName ??
                                                                                '',
                                                                            softWrap: true),
                                                                        Text.rich(TextSpan(
                                                                            children: [
                                                                              TextSpan(text: '${item.price?.toDop()} x ${item.quantity?.toStringAsFixed(2)} = '),
                                                                              TextSpan(text: '${item.net?.toDop()}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))
                                                                            ])),
                                                                      ],
                                                                    ))
                                                                  ],
                                                                )),
                                                                Column(
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              50,
                                                                          height:
                                                                              50,
                                                                          child:
                                                                              Material(
                                                                            clipBehavior:
                                                                                Clip.hardEdge,
                                                                            borderRadius:
                                                                                BorderRadius.circular(kDefaultPadding),
                                                                            color:
                                                                                Colors.white,
                                                                            child:
                                                                                Ink(
                                                                              child: InkWell(
                                                                                onTap: widget.generateNcfFromProforma == true
                                                                                    ? null
                                                                                    : () {
                                                                                        if (item.quantity! > 1) {
                                                                                          if (item is SaleItemProduct) {
                                                                                            _recalcProduct(item: item, index: index, controller: controller, action: ActionCart.remove);
                                                                                          }
                                                                                          if (item is SaleItemService) {
                                                                                            _recalcService(item: item, index: index, controller: controller, action: ActionCart.remove);
                                                                                          }
                                                                                        }
                                                                                      },
                                                                                child: Icon(Icons.remove, color: Theme.of(context).primaryColor),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              kDefaultPadding,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              80,
                                                                          child:
                                                                              TextFormField(
                                                                            readOnly:
                                                                                widget.generateNcfFromProforma == true,
                                                                            controller:
                                                                                controller,
                                                                            onChanged:
                                                                                (val) {
                                                                              if (item is SaleItemProduct) {
                                                                                _recalcProduct(item: item, index: index, controller: controller, action: ActionCart.edit, newQuantity: val);
                                                                              }
                                                                              if (item is SaleItemService) {
                                                                                _recalcService(item: item, index: index, controller: controller, action: ActionCart.edit, newQuantity: val);
                                                                              }
                                                                            },
                                                                            decoration: InputDecoration(
                                                                                filled: true,
                                                                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kDefaultPadding), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                                                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(kDefaultPadding), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                                                                                fillColor: Colors.white,
                                                                                hintText: '0.00'),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              kDefaultPadding,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              50,
                                                                          height:
                                                                              50,
                                                                          child:
                                                                              Material(
                                                                            clipBehavior:
                                                                                Clip.hardEdge,
                                                                            borderRadius:
                                                                                BorderRadius.circular(kDefaultPadding),
                                                                            color:
                                                                                Colors.white,
                                                                            child:
                                                                                Ink(
                                                                              child: InkWell(
                                                                                onTap: widget.generateNcfFromProforma == true
                                                                                    ? null
                                                                                    : () {
                                                                                        if (item is SaleItemProduct) {
                                                                                          _recalcProduct(item: item, index: index, controller: controller, action: ActionCart.add);
                                                                                        }
                                                                                        if (item is SaleItemService) {
                                                                                          _recalcService(item: item, index: index, controller: controller, action: ActionCart.add);
                                                                                        }
                                                                                      },
                                                                                child: Icon(Icons.add, color: Theme.of(context).primaryColor),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              kDefaultPadding,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              50,
                                                                          height:
                                                                              50,
                                                                          child:
                                                                              Material(
                                                                            borderRadius:
                                                                                BorderRadius.circular(20),
                                                                            color:
                                                                                Colors.white,
                                                                            clipBehavior:
                                                                                Clip.hardEdge,
                                                                            child:
                                                                                Ink(
                                                                              child: InkWell(
                                                                                onTap: widget.generateNcfFromProforma == true
                                                                                    ? null
                                                                                    : () {
                                                                                        _controllers.removeAt(index);
                                                                                        _items.removeAt(index);

                                                                                        setState(() {});
                                                                                      },
                                                                                child: Icon(Icons.delete, color: Colors.red),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ],
                                                                )
                                                              ],
                                                            ));
                                                      })
                                                    ],
                                                  ),
                                                ))
                                    ],
                                  ))),
                          Expanded(
                              child: Container(
                                  padding: EdgeInsets.all(kDefaultPadding),
                                  child: SingleChildScrollView(
                                    controller: _scrollController2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: kDefaultPadding),
                                          child: DropdownButtonFormField(
                                              initialValue: currentNcfTypeId,
                                              isExpanded: true,
                                              validator: (val) => val == null
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : null,
                                              decoration: InputDecoration(
                                                  hintText:
                                                      'SELECCIONA UN TIPO DE COMPROBANTE',
                                                  labelText:
                                                      'TIPO DE COMPROBANTE'),
                                              items: _ncfs
                                                  .map((e) => DropdownMenuItem(
                                                      value: e.id,
                                                      child:
                                                          Text(e.name ?? '')))
                                                  .toList(),
                                              onChanged: _onSelectedNcf),
                                        ),
                                        RncQueryWidget(
                                          clientName: clientName,
                                          editingController: rncOrId,
                                          onChanged:
                                              (xtaxPayer, xclient, xisValid) {
                                            taxPayer = xtaxPayer;
                                            client = xclient;
                                            isValid = xisValid;
                                          },
                                        ),
                                        SizedBox(height: kDefaultPadding),
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 2,
                                                child: Text('SUBTOTAL',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                            Expanded(
                                                child: Text(net,
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)))
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 2,
                                                child: Text('DESCUENTO',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                            Expanded(
                                                child: Text(discount,
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)))
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 2,
                                                child: Text('SUBTOTAL',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                            Expanded(
                                                child: Text(subtotal,
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)))
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 2,
                                                child: Text('TOTAL ITBIS',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                            Expanded(
                                                child: Text(tax,
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)))
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    'MONTO PROPINA LEGAL',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                            Expanded(
                                                child: Text(law10,
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)))
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 2,
                                                child: Text('TOTAL FACTURADO',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                            Expanded(
                                                child: Text(total,
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)))
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 2,
                                                child: Text('TOTAL A PAGAR',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                            Expanded(
                                                child: Text(amountPaid,
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displayMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)))
                                          ],
                                        ),
                                        const Divider(),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: kDefaultPadding / 2),
                                          child: DropdownButtonFormField(
                                              initialValue:
                                                  currentPaymentMethodId,
                                              validator: (val) => val == null
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : null,
                                              decoration: InputDecoration(
                                                  labelText: 'METODO DE PAGO'),
                                              items: paymentsMethods
                                                  .map((e) => DropdownMenuItem(
                                                      value: e.id,
                                                      child:
                                                          Text(e.name ?? '')))
                                                  .toList(),
                                              onChanged: (option) {
                                                currentPaymentMethodId = option;

                                                setState(() {});
                                              }),
                                        ),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: kDefaultPadding / 2),
                                          child: DropdownButtonFormField(
                                              initialValue: currentPaymentType,
                                              isExpanded: true,
                                              validator: (val) => val == null
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : null,
                                              decoration: InputDecoration(
                                                  labelText: 'TIPO DE PAGO'),
                                              items: paymentsTypes
                                                  .map((e) => DropdownMenuItem(
                                                      value: e.id,
                                                      child:
                                                          Text(e.name ?? '')))
                                                  .toList(),
                                              onChanged: (option) {
                                                currentPaymentType = option;
                                                if (currentPaymentMethodId !=
                                                    1) {
                                                  amount.clear();
                                                  amountInputFormatter.clear();
                                                }
                                                setState(() {});
                                              }),
                                        ),
                                        esNotaCredito
                                            ? SizedBox()
                                            : Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical:
                                                        kDefaultPadding / 2),
                                                child: DropdownButtonFormField<
                                                        int?>(
                                                    initialValue:
                                                        currentPaymentModeId,
                                                    isExpanded: true,
                                                    validator: (val) => val ==
                                                            null
                                                        ? 'CAMPO OBLIGATORIO'
                                                        : null,
                                                    decoration: InputDecoration(
                                                        labelText:
                                                            'MODO DE PAGO'),
                                                    items: paymentsModes
                                                        .map((e) =>
                                                            DropdownMenuItem(
                                                                value: e.id,
                                                                child: Text(
                                                                    e.name ??
                                                                        '')))
                                                        .toList(),
                                                    onChanged: widget.editing
                                                        ? null
                                                        : (option) {
                                                            setState(() {
                                                              currentPaymentModeId =
                                                                  option;
                                                              if (currentPaymentModeId ==
                                                                      1 ||
                                                                  currentPaymentModeId ==
                                                                      2) {
                                                                amount.clear();
                                                                amountInputFormatter
                                                                    .clear();
                                                              }
                                                            });
                                                          }),
                                              ),
                                        !enabledRestaurantMode
                                            ? SizedBox()
                                            : Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical:
                                                        kDefaultPadding / 2),
                                                child: DropdownButtonFormField<
                                                        int?>(
                                                    initialValue:
                                                        currentLawMode,
                                                    isExpanded: true,
                                                    decoration: InputDecoration(
                                                        labelText:
                                                            'MONTO PROPINA LEGAL'),
                                                    items: law10Modes
                                                        .map((e) =>
                                                            DropdownMenuItem(
                                                                value: e['id']
                                                                    as int,
                                                                child: Text(
                                                                    e['name'] ??
                                                                        '')))
                                                        .toList(),
                                                    onChanged: widget.editing
                                                        ? null
                                                        : (option) {
                                                            currentLawMode =
                                                                option!;
                                                            if (option == 2) {
                                                              for (int i = 0;
                                                                  i <
                                                                      _items
                                                                          .length;
                                                                  i++) {
                                                                var item =
                                                                    _items[i];
                                                                var law10 =
                                                                    item.netFinal! *
                                                                        0.10;
                                                                item.law10 =
                                                                    law10;
                                                                item.total = item
                                                                        .netFinal! +
                                                                    item.tax! +
                                                                    law10;

                                                                var newItem =
                                                                    item.copyWith(
                                                                        law10:
                                                                            law10);
                                                                _items[i] =
                                                                    newItem;
                                                              }
                                                            } else {
                                                              for (int i = 0;
                                                                  i <
                                                                      _items
                                                                          .length;
                                                                  i++) {
                                                                var item =
                                                                    _items[i];
                                                                var law10 = 0.0;
                                                                item.law10 =
                                                                    law10;
                                                                item.total = item
                                                                        .netFinal! +
                                                                    item.tax!;
                                                                var newItem =
                                                                    item.copyWith(
                                                                        law10:
                                                                            law10);
                                                                _items[i] =
                                                                    newItem;
                                                              }
                                                            }

                                                            setState(() {});
                                                          }),
                                              ),
                                        currentPaymentModeId == 2 ||
                                                currentPaymentModeId == 1
                                            ? SizedBox()
                                            : Listener(
                                                onPointerDown:
                                                    (PointerDownEvent event) {
                                                  if (event.kind ==
                                                      PointerDeviceKind.mouse) {
                                                    // Solo si el evento es de mouse
                                                    setState(() {
                                                      showNumericKeyboard =
                                                          false;
                                                    });
                                                  }

                                                  if (event.kind ==
                                                      PointerDeviceKind.touch) {
                                                    // Solo si el evento es de mouse
                                                    setState(() {
                                                      showNumericKeyboard =
                                                          true;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  margin: EdgeInsets.symmetric(
                                                      vertical:
                                                          kDefaultPadding),
                                                  child: FormField<String>(
                                                    validator: (val) {
                                                      if (amountInputFormatter
                                                              .doubleValue ==
                                                          0) {
                                                        return 'CAMPO OBLIGATORIO';
                                                      } else if (esNotaCredito &&
                                                          amountInputFormatter
                                                                  .doubleValue >
                                                              debt) {
                                                        return 'EL MONTO ES MAYOR';
                                                      } else if (esNotaCredito &&
                                                          debt == 0) {
                                                        return 'NO TIENE PENDIENTE A DEVOLVER';
                                                      }
                                                      return null;
                                                    },
                                                    builder: (field) {
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          OnscreenKeyboardTextField(
                                                            controller: amount,
                                                            enableOnscreenKeyboard:
                                                                showNumericKeyboard,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium,
                                                            onChanged: (_) {
                                                              setState(() {
                                                                field.didChange(
                                                                    amount
                                                                        .text);
                                                              });
                                                            },
                                                            inputFormatters: [
                                                              amountInputFormatter
                                                            ],
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  'MONTO PAGADO',
                                                              hintText: '0.00',
                                                              errorText: field
                                                                  .errorText, // aquí se muestra el error
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                        currentPaymentMethodId == 2 &&
                                                currentPaymentType == 1
                                            ? SizedBox()
                                            : Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: kDefaultPadding),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                        child: Text(
                                                            debt < 0
                                                                ? 'DEVUELTA'
                                                                : 'DEUDA',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .displayMedium
                                                                ?.copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .primaryColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500))),
                                                    Text(debtString,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500))
                                                  ],
                                                ),
                                              ),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: kDefaultPadding),
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                              onPressed: _onSubmit,
                                              child: Text('CREAR FACTURA')),
                                        )
                                      ],
                                    ),
                                  )))
                        ],
                      ),
                    )))));
  }
}

class ItemImageWidget extends StatelessWidget {
  final SaleItem item;
  const ItemImageWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        item.productImage != null
            ? Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                        image: NetworkImage(item.imageUrl), fit: BoxFit.cover)),
              )
            : Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Icon(Icons.inventory,
                      color: Theme.of(context).primaryColor),
                ),
              ),
      ],
    );
  }
}
