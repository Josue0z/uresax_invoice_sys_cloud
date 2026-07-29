import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/discount.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/retention.isr.dart';
import 'package:uresax_invoice_sys_cloud/models/retention.tax.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.element.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/service.dart';
import 'package:uresax_invoice_sys_cloud/models/taxes.dart';
import 'package:uresax_invoice_sys_cloud/models/unit.dart';
import 'package:uresax_invoice_sys_cloud/pages/discounts_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/products_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/services_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/units_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/selector.item.widget.dart';

class InvoiceItemGeneratorWidget extends StatefulWidget {
  Sale sale;

  SaleItem saleItem;

  List<SaleItem> saleItems;

  List<SaleItem> enableds;

  bool editing;
  bool isProForma;

  bool canOverrideTaxes;

  bool esGubernamental;
  bool esEspecial;
  bool esMenor;
  bool esCompra;

  int index;

  DateTime? retentionDate;

  double? totalRetentionTax;
  double? totalRetentionIsr;

  Function(int) onDelete;

  Function(SaleItem) onChanged;

  bool enabledEditing;

  InvoiceItemGeneratorWidget(
      {super.key,
      this.editing = false,
      this.canOverrideTaxes = false,
      this.esGubernamental = false,
      this.esEspecial = false,
      this.isProForma = false,
      this.esMenor = false,
      this.esCompra = false,
      required this.sale,
      required this.saleItem,
      required this.saleItems,
      required this.enableds,
      required this.onChanged,
      required this.onDelete,
      required this.index,
      required this.retentionDate,
      required this.totalRetentionIsr,
      required this.totalRetentionTax,
      this.enabledEditing = false});

  @override
  State<InvoiceItemGeneratorWidget> createState() =>
      _InvoiceItemGeneratorWidgetState();
}

class _InvoiceItemGeneratorWidgetState
    extends State<InvoiceItemGeneratorWidget> {
  TextEditingController net = TextEditingController();
  TextEditingController tax = TextEditingController();
  TextEditingController total = TextEditingController();
  TextEditingController totalToPay = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController law10 = TextEditingController();
  TextEditingController unitSuite = TextEditingController();
  TextEditingController clientSuite = TextEditingController();
  TextEditingController priceSuite = TextEditingController();
  AmountInputFormatter priceSuiteFormatter =
      AmountInputFormatter(fractionalDigits: 2);

  bool calculated = false;

  int? currenId;
  int? currentTaxId;
  int? currentRetentionTaxId;
  String? currentRetentionIsrId;
  int? discountId;

  FocusNode netFocus = FocusNode();

  SaleElement? el;
  RetentionTax? retentionTax;
  RetentionIsr? retentionIsr;
  Discount? discountEl;
  Taxes? currentTax;
  Unit? currentUnit;
  TextEditingController descriptionController = TextEditingController();
  FocusNode focusNode = FocusNode();

  double startQuantity = 0;
  double price = 0;
  bool editingField = false;

  String get title {
    if (widget.saleItem is SaleItemService) {
      return 'SERVICIO';
    }

    if (widget.saleItem is SaleItemProduct) {
      return 'PRODUCTO';
    }
    if (widget.saleItem is CreditNoteService) {
      return 'SERVICIO';
    }
    if (widget.saleItem is CreditNoteProduct) {
      return 'PRODUCTO';
    }
    return '';
  }

  void _onSelected(SaleElement? element) {
    currenId = element?.id;

    if (widget.saleItem is SaleItemService) {
      widget.saleItem.serviceId = currenId;
    }

    if (widget.saleItem is SaleItemProduct) {
      widget.saleItem.productId = currenId;
    }

    el = element;

    currentTaxId = el?.taxId;

    currentTax = taxes.firstWhere((e) => e.id == currentTaxId);

    widget.saleItem.taxId = currentTaxId;

    widget.saleItem.productName = el?.name;
    widget.saleItem.serviceName = el?.name;

    if (currenId != null) {
    } else {
      widget.saleItem.total = null;
      widget.saleItem.tax = null;
      widget.saleItem.taxId = null;
      widget.saleItem.discount = null;
      widget.saleItem.discountId = null;
      currentTaxId = null;
      currentRetentionTaxId = null;
    }
    _calc();
  }

  _onSelectedTax(int? option) {
    currentTaxId = option;

    _calc();
  }

  _onSelectedRetentionTax(int? option) {
    currentRetentionTaxId = option;
    retentionTax = retentionsTaxes.firstWhere((e) => e.id == option);

    widget.saleItem.retentionTaxId = option;
    widget.saleItem.taxRate = retentionTax?.rate ?? 0;

    _calc();
  }

  _onSelectedRetentionIsr(String? option) {
    currentRetentionIsrId = option;
    retentionIsr = retentionsIsrs.firstWhere((e) => e.id == option);

    widget.saleItem.retentionIsrId = option;
    widget.saleItem.isrRate = retentionIsr?.rate ?? 0;

    _calc();
  }

  _onChangedQuantity(String value) {
    widget.saleItem.quantity = double.tryParse(value);
    _calc();
  }

  _calc() {
    double xnet = 0;
    double net16 = 0;
    double net18 = 0;
    double net3 = 0;
    double netFinal = 0;
    double xtax = 0;
    double tax16 = 0;
    double tax18 = 0;
    double tax3 = 0;
    double xlaw10 = 0;
    double discount = 0;
    double exemptAmount = 0;
    double xretentionIsr = 0;
    double xretentionTax = 0;
    double xtotal = 0;
    int indicadorFacturacion = 1;

    double price = el?.price ?? widget.saleItem.priceItem ?? 0;
    double xquantity = widget.saleItem.quantity ?? 1;

    double priceAmount = price * xquantity;
    int? taxId = el?.taxId ?? widget.saleItem.taxId;

    if (discountEl?.symbolName != null) {
      if (discountEl?.symbolName == '%') {
        discount = (discountEl!.rate! / 100) * widget.saleItem.net!;
      }

      if (discountEl?.symbolName == '\$') {
        discount = discountEl!.rate ?? 0;
      }
    }

    if (currentTaxId != null) {
      currentTax = taxes.firstWhere((e) => e.id == currentTaxId);
    }

    if (taxId == 1) {
      indicadorFacturacion = 2;
      xnet = priceAmount;
      netFinal = xnet - discount;
      net16 = netFinal;
      net18 = 0;
      net3 = 0;
      xtax = netFinal * ((currentTax?.rate ?? 0) / 100);
      tax16 = xtax;
      tax18 = 0;
      tax3 = 0;
    }

    if (taxId == 2) {
      indicadorFacturacion = 1;
      xnet = priceAmount;
      net16 = 0;
      net3 = 0;
      netFinal = xnet - discount;
      net18 = netFinal;
      xtax = netFinal * ((currentTax?.rate ?? 0) / 100);
      tax18 = xtax;
      tax16 = 0;
      tax3 = 0;
    }

    if (taxId == null) {
      indicadorFacturacion = 4;
      xnet = priceAmount;
      netFinal = xnet - discount;
      net16 = 0;
      net18 = 0;
      net3 = 0;
      xtax = 0;
      tax16 = 0;
      tax18 = 0;
      tax3 = 0;
      exemptAmount = netFinal;
    }

    if (widget.canOverrideTaxes) {
      indicadorFacturacion = 3;
      xnet = priceAmount;
      netFinal = xnet - discount;
      net18 = 0;
      net16 = 0;
      net3 = netFinal;
      xtax = 0;
      tax16 = 0;
      tax18 = 0;
      tax3 = xtax;
      exemptAmount = 0;
    }
    if (widget.esEspecial || widget.esMenor) {
      indicadorFacturacion = 4;
      xnet = priceAmount;
      netFinal = xnet - discount;
      net16 = 0;
      net18 = 0;
      net3 = 0;
      xtax = 0;
      tax16 = 0;
      tax18 = 0;
      tax3 = 0;
      exemptAmount = netFinal;
    }

    if (widget.esGubernamental) {
      widget.saleItem.retentionIsrId = null;
      xretentionIsr = 0;
      widget.saleItem.retentionTaxId = null;
      xretentionTax = 0;
    }
    if (widget.saleItem.retentionIsrId != null ||
        widget.saleItem.retentionTaxId != null) {
      widget.saleItem.indicadorAgentePercepcion = 1;
    }

    if ((widget.saleItem.law10 ?? 0) > 0) {
      xlaw10 = netFinal * 0.10;
    }

    if (currentRetentionTaxId != null) {
      var rate = widget.saleItem.taxRate ?? retentionTax?.rate ?? 0;
      var percent = rate / 100;
      xretentionTax = percent * xtax;
    }

    if (currentRetentionIsrId != null) {
      var rate = widget.saleItem.isrRate ?? (retentionIsr?.rate ?? 0);
      var percent = rate / 100;
      xretentionIsr = percent * netFinal;
    }

    xtotal = netFinal + xtax + xlaw10;
    widget.saleItem.indicadorFacturacion = indicadorFacturacion;
    widget.saleItem.serviceName = el?.name ?? widget.saleItem.serviceName;
    widget.saleItem.productName = el?.name ?? widget.saleItem.productName;
    widget.saleItem.price = el?.price;
    widget.saleItem.priceItem = el?.price;
    widget.saleItem.chassis = el?.chassis;
    widget.saleItem.licensePlate = el?.licensePlate;
    widget.saleItem.colorName = el?.colorName;
    widget.saleItem.net = xnet;
    widget.saleItem.discount = discount;
    widget.saleItem.discountSymbol = discountEl?.symbolName;
    widget.saleItem.discountName = discountEl?.name;
    widget.saleItem.discountRate = discountEl?.rate;
    widget.saleItem.netFinal = netFinal;
    widget.saleItem.net16 = net16;
    widget.saleItem.net18 = net18;
    widget.saleItem.net3 = net3;
    widget.saleItem.taxId = currentTaxId;
    widget.saleItem.tax = xtax;
    widget.saleItem.tax16 = tax16;
    widget.saleItem.tax18 = tax18;
    widget.saleItem.tax3 = tax3;
    widget.saleItem.exemptAmount = exemptAmount;
    widget.saleItem.retentionTax = xretentionTax;
    widget.saleItem.retentionIsr = xretentionIsr;
    widget.saleItem.total = xtotal;

    if (widget.editing) {
      quantity.value = TextEditingValue(
        text: widget.saleItem.quantity?.toStringAsFixed(2) ?? '',
        selection: TextSelection.collapsed(
          offset: (widget.saleItem.quantity?.toStringAsFixed(2) ?? '').length,
        ),
      );
    }

    widget.saleItem.productName = el?.name ?? widget.saleItem.productName;
    widget.saleItem.serviceName = el?.name ?? widget.saleItem.serviceName;

    widget.saleItem.unitName = el?.unitName ?? widget.saleItem.unitName;
    widget.saleItem.unitCode = el?.unitCode ?? widget.saleItem.unitCode;
    widget.saleItem.unitSymbol = el?.unitSymbol ?? widget.saleItem.unitSymbol;
    widget.saleItem.conversionFactor =
        el?.conversionFactor ?? widget.saleItem.conversionFactor;

    net.text = widget.saleItem.net?.toStringAsFixed(2) ?? '0.00';
    tax.text = widget.saleItem.tax?.toStringAsFixed(2) ?? '0.00';
    unitSuite.text = widget.saleItem.unitSuite ?? '';
    clientSuite.text = widget.saleItem.clientSuite ?? '';
    priceSuite.value = priceSuiteFormatter.formatEditUpdate(
        priceSuite.value,
        TextEditingValue(
            text: widget.saleItem.priceSuite?.toStringAsFixed(2) ?? ''));
    law10.text = widget.saleItem.law10?.toStringAsFixed(2) ?? '0.00';
    total.text = widget.saleItem.total?.toStringAsFixed(2) ?? '0.00';
    totalToPay.text = amountPaid.toStringAsFixed(2);

 
    widget.onChanged(widget.saleItem);
  }

  double get amountPaid {
    if (widget.saleItem.total == null || widget.saleItem.total == 0) {
      return 0;
    }

    return widget.saleItem.total! -
        ((widget.saleItem.retentionTax ?? 0) +
            (widget.saleItem.retentionIsr ?? 0)) +
        (widget.saleItem.law10 ?? 0);
  }

  bool get enabledOnlyEcommerce {
    return (eCommerceMode ||
        (widget.saleItem is SaleItemProduct ||
            widget.saleItem is CreditNoteProduct));
  }

  @override
  void initState() {
    startQuantity = widget.saleItem.quantity ?? 1;
    widget.saleItem.startQuantity = startQuantity;
    widget.saleItem.returnQuantity = widget.saleItem.quantity ?? 1;
    descriptionController.text =
        widget.saleItem.serviceName ?? widget.saleItem.productName ?? '';

    descriptionController.addListener(() {
      widget.saleItem.productName = descriptionController.text;
      widget.saleItem.serviceName = descriptionController.text;
    });

    quantity.value = TextEditingValue(
      text: widget.saleItem.quantity?.toStringAsFixed(2) ?? '',
      selection: TextSelection.collapsed(
        offset: (widget.saleItem.quantity?.toString() ?? '').length,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncControllersWithSaleItem();
      }
    });

    super.initState();
  }

  void _syncControllersWithSaleItem() {
    currenId = widget.saleItem.serviceId ?? widget.saleItem.productId;

    el = widget.saleItem is SaleItemService ||
            widget.saleItem is CreditNoteService
        ? Services(
            id: widget.saleItem.serviceId,
            name: widget.saleItem.serviceName,
            price: widget.saleItem.priceItem,
            discountName: widget.saleItem.discountName,
            discountRate: widget.saleItem.discountRate,
            discountSymbol: widget.saleItem.discountSymbol)
        : Products(
            id: widget.saleItem.productId,
            name: widget.saleItem.productName,
            price: widget.saleItem.priceItem,
            conversionFactor: widget.saleItem.conversionFactor,
            unitCode: widget.saleItem.unitCode,
            unitName: widget.saleItem.unitName,
            unitSymbol: widget.saleItem.unitSymbol,
            discountName: widget.saleItem.discountName,
            discountRate: widget.saleItem.discountRate,
            discountSymbol: widget.saleItem.discountSymbol,
            chassis: widget.saleItem.chassis,
            licensePlate: widget.saleItem.licensePlate,
            colorName: widget.saleItem.colorName);

    if (!widget.enabledEditing || el?.id != null) {
      currentUnit = Unit(
          id: el?.unitId,
          name: el?.unitName,
          code: el?.unitCode,
          symbol: el?.unitSymbol,
          status: true,
          isBaseUnit: el?.isBaseUnit,
          conversionFactor: el?.conversionFactor ?? 1.0);
    }
    discountId = widget.saleItem.discountId;

    discountEl = Discount(
        id: widget.saleItem.discountId,
        name: widget.saleItem.discountName,
        rate: widget.saleItem.discountRate,
        symbolName: widget.saleItem.discountSymbol);

    widget.saleItem.discountName = discountEl?.name;
    widget.saleItem.discountRate = discountEl?.rate;
    widget.saleItem.discountSymbol = discountEl?.symbolName;

    currentTaxId = widget.saleItem.taxId;
    currentRetentionIsrId = widget.saleItem.retentionIsrId;
    currentRetentionTaxId = widget.saleItem.retentionTaxId;

    if (currentRetentionTaxId != null) {
      retentionTax =
          retentionsTaxes.firstWhere((e) => e.id == currentRetentionTaxId);
    }
    if (currentRetentionIsrId != null) {
      retentionIsr =
          retentionsIsrs.firstWhere((e) => e.id == currentRetentionIsrId);
    }

    law10.text = widget.saleItem.law10?.toStringAsFixed(2) ?? '0.00';

    price = widget.saleItem.priceItem ?? 0;

    _calc();
  }

  @override
  void didUpdateWidget(covariant InvoiceItemGeneratorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.saleItem != widget.saleItem) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncControllersWithSaleItem();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12))),
      child: Row(
        children: [
          widget.editing ||
                  widget.saleItem is CreditNoteProduct ||
                  widget.saleItem is CreditNoteService
              ? SizedBox()
              : Container(
                  margin: EdgeInsets.only(right: kDefaultPadding),
                  child: GestureDetector(
                    onTap: () {
                      widget.onDelete(widget.index);
                    },
                    child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: const Color(0xFFE3E2E2)),
                        child: Icon(Icons.delete, color: Colors.red)),
                  ),
                ),
          Row(
            children: [
              widget.saleItem is CreditNoteProduct ||
                      widget.saleItem is CreditNoteService
                  ? Container(
                      margin: EdgeInsets.only(right: kDefaultPadding),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.saleItem is CreditNoteProduct ||
                              widget.saleItem is CreditNoteService) {
                            if (widget.saleItem.enabled == true) {
                              if (widget.enableds.length > 1) {
                                widget.saleItem.enabled = false;
                              }
                            } else {
                              widget.saleItem.enabled = true;
                            }

                            widget.onChanged(widget.saleItem);
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.black12),
                          child: widget.saleItem.enabled == true
                              ? Icon(Icons.remove)
                              : Icon(Icons.add),
                        ),
                      ),
                    )
                  : SizedBox(),
            ],
          ),
          SizedBox(
            width: 150,
            child: TextFormField(
              key: ValueKey('editortext_${widget.saleItem.id}'),
              controller: quantity,
              readOnly: widget.editing ||
                  widget.isProForma |
                      (!enabledProductQuantityEditor &&
                          widget.saleItem is SaleItemProduct),
              validator: (val) => val!.isEmpty
                  ? 'CAMPO OBLIGATORIO'
                  : double.parse(val) > startQuantity &&
                          (widget.sale is CreditNoteService ||
                              widget.sale is CreditNoteProduct)
                      ? 'LA CANTIDAD ES MAYOR'
                      : double.parse(val) == 0
                          ? 'LA CANTIDAD ES 0'
                          : null,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              onChanged: _onChangedQuantity,
              decoration: InputDecoration(
                  labelText: 'CANTIDAD',
                  hintText: '0',
                  suffixIcon: widget.saleItem is SaleItemProduct ||
                          widget.saleItem is SaleItemService
                      ? SizedBox()
                      : Wrap(
                          children: [
                            IconButton(
                                onPressed: widget.editing || widget.isProForma
                                    ? null
                                    : () {
                                        if (widget.saleItem.quantity == 1) {
                                          return;
                                        }

                                        widget.saleItem.quantity =
                                            widget.saleItem.quantity! - 1;
                                        widget.saleItem.returnQuantity =
                                            widget.saleItem.returnQuantity! - 1;
                                        quantity.text = widget.saleItem.quantity
                                                ?.toStringAsFixed(2) ??
                                            '0.00';
                                        _calc();
                                      },
                                icon: Icon(Icons.remove)),
                            SizedBox(
                              width: kDefaultPadding / 2,
                            ),
                            IconButton(
                                onPressed: widget.editing || widget.isProForma
                                    ? null
                                    : () {
                                        if (widget.saleItem.quantity! ==
                                            startQuantity) {
                                          return;
                                        }
                                        widget.saleItem.quantity =
                                            widget.saleItem.quantity! + 1;

                                        widget.saleItem.returnQuantity =
                                            widget.saleItem.returnQuantity! + 1;
                                        quantity.text = widget.saleItem.quantity
                                                ?.toStringAsFixed(2) ??
                                            '0.00';
                                        _calc();
                                      },
                                icon: Icon(Icons.add)),
                            SizedBox(
                              width: kDefaultPadding / 2,
                            )
                          ],
                        )),
            ),
          ),
          SizedBox(
            width: kDefaultPadding,
          ),
          SizedBox(
            width: 250,
            child: SelectorItemWidget<SaleElement>(
                context: context,
                title: title,
                initialValue: el,
                enabledModeEditor: true,
                editingController: descriptionController,
                focusNode: focusNode,
                hintText: title,
                enabled: !widget.editing &&
                    !widget.isProForma &&
                    (widget.saleItem is SaleItemProduct ||
                        widget.saleItem is SaleItemService),
                validator: (val) {
                  return (descriptionController.text.isNotEmpty) ||
                          el?.id != null
                      ? null
                      : 'CAMPO OBLIGATORIO';
                },
                screen: widget.saleItem is SaleItemService
                    ? ServicesPage(selectedMode: true)
                    : ProductsPage(selectedMode: true, items: widget.saleItems),
                onEditing: (val) {
                  el?.name = val;
                  widget.saleItem.productName = el?.name;
                  widget.saleItem.serviceName = el?.name;
                },
                onChanged: (element, isEditing) {
                  setState(() {
                    el = element;
                    priceSuite.value = priceSuiteFormatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(
                      text: el?.priceSuite?.toStringAsFixed(2) ?? '0.00'
                    ));
                     widget.saleItem.priceSuite =
                          priceSuiteFormatter.doubleValue;

         
                    if (el?.discountId != null) {
                      discountEl = Discount(
                        id: el?.discountId,
                        name: el?.discountName ?? '',
                        rate: el?.discountRate,
                        symbolId: el?.discountSymbolId,
                        symbolName: el?.discountSymbol,
                      );
                    }

                    editingField = false;
                    currentUnit = Unit(
                        code: el?.unitCode,
                        name: el?.unitName,
                        symbol: el?.unitSymbol,
                        isBaseUnit: el?.isBaseUnit,
                        conversionFactor: el?.conversionFactor);
                  });
                  descriptionController.text = el?.name ?? '';
                  _onSelected(el);
                }),
          ),
          widget.saleItem is SaleItemService ||
                  widget.saleItem is CreditNoteService
              ? SizedBox(
                  width: kDefaultPadding / 2,
                )
              : Container(
                  width: 250,
                  margin: EdgeInsets.symmetric(horizontal: kDefaultPadding),
                  child: SelectorItemWidget<Unit>(
                      key: ValueKey(
                          '${widget.saleItem.id}_${currentUnit?.code}'),
                      context: context,
                      title: 'UNIDAD',
                      initialValue: currentUnit,
                      enabled: !widget.editing &&
                          !widget.isProForma &&
                          (widget.saleItem is SaleItemProduct),
                      validator: (val) {
                        return currentUnit?.conversionFactor == null
                            ? 'CAMPO OBLIGATORIO'
                            : null;
                      },
                      screen: UnitsPage(selectedMode: true),
                      onChanged: (element, _) {
                        setState(() {
                          currentUnit = element;

                          el?.unitName = currentUnit?.name;
                          el?.unitCode = currentUnit?.code;
                          el?.unitSymbol = currentUnit?.symbol;
                          el?.isBaseUnit = currentUnit?.isBaseUnit;
                          el?.conversionFactor = currentUnit?.conversionFactor;
                        });

                        _onSelected(el);
                      }),
                ),
          SizedBox(
            width: 150,
            child: TextFormField(
              controller: net,
              readOnly: widget.editing ||
                  widget.isProForma ||
                  widget.saleItem is CreditNoteService ||
                  widget.saleItem is CreditNoteProduct ||
                  !enabledTextEditor,
              focusNode: netFocus,
              onChanged: (val) {
                price = double.tryParse(val) ?? 0;
                widget.saleItem.net = 0;

                _calc();
              },
              decoration: InputDecoration(labelText: 'NETO', hintText: '0.00'),
            ),
          ),
          SizedBox(
            width: kDefaultPadding,
          ),
          enabledRealEstateAgency
              ? Container(
                  width: 150,
                  margin: EdgeInsets.only(right: kDefaultPadding),
                  child: TextFormField(
                    controller: unitSuite,
                    readOnly: widget.editing ||
                        widget.isProForma ||
                        widget.saleItem is CreditNoteService ||
                        widget.saleItem is CreditNoteProduct,
                    onChanged: (val) {
                      widget.saleItem.unitSuite = val.isNotEmpty ? val : null;
                    },
                    decoration:
                        InputDecoration(labelText: 'UNIDAD', hintText: '3A'),
                  ),
                )
              : SizedBox(),
          enabledRealEstateAgency
              ? Container(
                  width: 150,
                  margin: EdgeInsets.only(right: kDefaultPadding),
                  child: TextFormField(
                    controller: clientSuite,
                    readOnly: widget.editing ||
                        widget.isProForma ||
                        widget.saleItem is CreditNoteService ||
                        widget.saleItem is CreditNoteProduct,
                    onChanged: (val) {
                      widget.saleItem.clientSuite = val.isNotEmpty ? val : null;
                    },
                    decoration: InputDecoration(
                        labelText: 'CLIENTE', hintText: 'Escribir algo...'),
                  ),
                )
              : SizedBox(),
          enabledRealEstateAgency
              ? Container(
                  width: 150,
                  margin: EdgeInsets.only(right: kDefaultPadding),
                  child: TextFormField(
                    controller: priceSuite,
                    readOnly: widget.editing ||
                        widget.isProForma ||
                        widget.saleItem is CreditNoteService ||
                        widget.saleItem is CreditNoteProduct,
                    inputFormatters: [priceSuiteFormatter],
                    onChanged: (val) {
                      widget.saleItem.priceSuite =
                          priceSuiteFormatter.doubleValue;
                    },
                    decoration: InputDecoration(
                        labelText: 'PRECIO UNIDAD', hintText: '0.00'),
                  ),
                )
              : SizedBox(),
          SizedBox(
            width: 250,
            child: SelectorItemWidget<Discount>(
                context: context,
                initialValue: discountEl,
                title: 'DESCUENTO',
                enabled: !widget.editing &&
                    !widget.isProForma &&
                    (widget.saleItem is SaleItemProduct ||
                        widget.saleItem is SaleItemService),
                screen: DiscountsPage(selectorMode: true),
                onChanged: widget.saleItem is CreditNoteProduct ||
                        widget.saleItem is CreditNoteService
                    ? null
                    : (xdiscount, _) {
                        discountEl = xdiscount;
                        discountId = xdiscount?.id;
                        widget.saleItem.discountId = discountEl?.id;

                        _calc();
                      }),
          ),
          SizedBox(
            width: kDefaultPadding,
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField(
                initialValue: currentTaxId,
                decoration: InputDecoration(labelText: 'ITBIS'),
                items: taxes
                    .map((e) => DropdownMenuItem(
                        value: e.id, child: Text(e.name ?? '')))
                    .toList(),
                onChanged: widget.saleItem is CreditNoteProduct ||
                        widget.saleItem is CreditNoteService ||
                        widget.editing ||
                        widget.isProForma ||
                        enabledOnlyEcommerce
                    ? null
                    : _onSelectedTax),
          ),
          SizedBox(
            width: kDefaultPadding,
          ),
          SizedBox(
            width: 150,
            child: TextFormField(
              controller: total,
              readOnly: true,
              decoration: InputDecoration(labelText: 'TOTAL', hintText: '0.00'),
            ),
          ),
          Container(
            width: 200,
            margin: EdgeInsets.only(left: kDefaultPadding),
            child: DropdownButtonFormField(
                key: ValueKey(
                    '${widget.retentionDate}_${widget.totalRetentionTax}_${widget.totalRetentionIsr}'),
                isExpanded: true,
                initialValue: currentRetentionTaxId,
                decoration: InputDecoration(
                  labelText: 'RETENCION ITBIS',
                ),
                validator: widget.totalRetentionTax! > 0 ||
                        widget.totalRetentionIsr! > 0
                    ? null
                    : (val) {
                        if (widget.retentionDate != null) {
                          if (currentRetentionTaxId == null &&
                              currentRetentionIsrId == null &&
                              val == null) {
                            return 'Debe seleccionar tipo de retención';
                          }
                        }
                        return null;
                      },
                items: retentionsTaxes
                    .map((e) => DropdownMenuItem(
                        value: e.id, child: Text(e.name ?? '')))
                    .toList(),
                onChanged: widget.esGubernamental ||
                        widget.esEspecial ||
                        widget.esMenor ||
                        widget.saleItem is CreditNoteProduct ||
                        widget.saleItem is CreditNoteService ||
                        widget.isProForma ||
                        (widget.editing &&
                            widget.saleItem.retentionTaxId != null) ||
                        (widget.sale.retentionTax != null &&
                            widget.sale.retentionTax! > 0 &&
                            widget.sale.estadoDgii != null) ||
                        (!enabledRetentions ||
                            widget.saleItem is SaleItemProduct) ||
                        eCommerceMode
                    ? null
                    : _onSelectedRetentionTax),
          ),
          Container(
            width: 200,
            margin: EdgeInsets.only(left: kDefaultPadding),
            child: DropdownButtonFormField(
                key: ValueKey(
                    '${widget.retentionDate}_${widget.totalRetentionIsr}_${widget.totalRetentionTax}'),
                initialValue: currentRetentionIsrId,
                isExpanded: true,
                validator: widget.totalRetentionTax! > 0 ||
                        widget.totalRetentionIsr! > 0
                    ? null
                    : (val) {
                        if (widget.retentionDate != null) {
                          if (currentRetentionTaxId == null &&
                              currentRetentionIsrId == null &&
                              val == null) {
                            return 'Debe seleccionar tipo de retención';
                          }
                        }
                        return null;
                      },
                decoration: InputDecoration(
                  labelText: 'RETENCION ISR',
                ),
                items: retentionsIsrs
                    .map((e) => DropdownMenuItem(
                        value: e.id, child: Text(e.name ?? '')))
                    .toList(),
                onChanged: widget.esGubernamental ||
                        widget.esEspecial ||
                        widget.esMenor ||
                        widget.saleItem is CreditNoteProduct ||
                        widget.saleItem is CreditNoteService ||
                        widget.isProForma ||
                        (widget.editing &&
                            widget.saleItem.retentionIsrId != null) ||
                        (widget.sale.retentionIsr != null &&
                            widget.sale.retentionIsr! > 0 &&
                            widget.sale.estadoDgii != null) ||
                        (!enabledRetentions ||
                            widget.saleItem is SaleItemProduct) ||
                        eCommerceMode
                    ? null
                    : _onSelectedRetentionIsr),
          ),
          Container(
            width: 150,
            margin: EdgeInsets.only(left: kDefaultPadding),
            child: TextFormField(
              controller: law10,
              readOnly: true,
              decoration: InputDecoration(
                  labelText: 'MONTO PROPINA LEGAL',
                  hintText: '0.00',
                  suffixIcon: Wrap(
                    children: [
                      IconButton(
                          onPressed: widget.saleItem is CreditNoteProduct ||
                                  widget.saleItem is CreditNoteService ||
                                  widget.editing ||
                                  widget.isProForma
                              ? null
                              : () {
                                  if (!calculated) {
                                    var law10Calc =
                                        widget.saleItem.netFinal! * 0.10;
                                    law10.text = law10Calc.toStringAsFixed(2);
                                    widget.saleItem.law10 = law10Calc;
                                    calculated = true;
                                  } else {
                                    widget.saleItem.law10 = 0;
                                    law10.text = widget.saleItem.law10
                                            ?.toStringAsFixed(2) ??
                                        '0.00';
                                    calculated = false;
                                  }
                                  _calc();
                                },
                          icon: Icon(Icons.arrow_right)),
                      SizedBox(width: kDefaultPadding / 2)
                    ],
                  )),
            ),
          ),
          Container(
            width: 150,
            margin: EdgeInsets.only(left: kDefaultPadding),
            child: TextFormField(
              controller: totalToPay,
              readOnly: true,
              decoration:
                  InputDecoration(labelText: 'TOTAL A PAGAR', hintText: '0.00'),
            ),
          )
        ],
      ),
    );
  }
}

class CustomDropdownFormField extends FormField<int> {
  CustomDropdownFormField({
    super.key,
    required String title,
    required SaleItem saleItem,
    required List<SaleElement> elements,
    required void Function(SaleElement, int? option) onChanged,
    super.enabled,
    super.initialValue,
    super.validator,
    super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          builder: (FormFieldState<int> state) {
            var value = initialValue ?? state.value;

            return _CustomDropdownButton(
              title: title,
              saleItem: saleItem,
              elements: elements,
              currentValue: value,
              enabled: enabled,
              errorText: state.errorText,
              onChanged: (element, id) {
                state.didChange(element.id);
                state.save();
                state.validate();
                onChanged(element, id);
              },
            );
          },
        );
}

class _CustomDropdownButton extends StatefulWidget {
  final String title;
  final SaleItem saleItem;
  List<SaleElement> elements;
  final Function(SaleElement, int? option) onChanged;
  int? currentValue;
  bool enabled;
  final String? errorText;

  _CustomDropdownButton({
    required this.title,
    required this.saleItem,
    required this.elements,
    required this.onChanged,
    this.currentValue,
    this.enabled = false,
    this.errorText,
  });

  @override
  State<_CustomDropdownButton> createState() => _CustomDropdownButtonState();
}

class _CustomDropdownButtonState extends State<_CustomDropdownButton>
    with TickerProviderStateMixin {
  final GlobalKey _targetKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  final LayerLink _layerLink = LayerLink();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  SaleElement? _saleElement;

  List<SaleElement> _elements = [];

  TextEditingController search = TextEditingController();

  _removeOverlay() async {
    Navigator.pop(context);
    search.clear();
    await _fadeController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showContextMenu() {
    if (!widget.enabled) return;

    _elements = widget.elements;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox =
          _targetKey.currentContext!.findRenderObject() as RenderBox;

      final Size size = renderBox.size;

      showElements() async {
        if (widget.saleItem is SaleItemService) {
          var service = await showDialog(
              context: context,
              builder: (ctx) => ServicesPage(selectedMode: true));
          _saleElement = service;
          if (service != null) {
            if (!_elements.any((e) => e.id == service.id)) {
              _elements.add(service);
              int index = _elements.indexWhere((e) => e.id == service.id);
              _elements[index] = _saleElement!;
            } else {
              int index = _elements.indexWhere((e) => e.id == service.id);
              _elements[index] = _saleElement!;
            }

            widget.currentValue = _saleElement?.id;

            widget.onChanged(_saleElement!, widget.currentValue);
          }
        }
        if (widget.saleItem is SaleItemProduct) {
          var product = await showDialog(
              context: context,
              builder: (ctx) => ProductsPage(selectedMode: true));

          _saleElement = product;

          if (product != null) {
            if (!_elements.any((e) => e.id == product.id)) {
              _elements.add(product);
              int index = _elements.indexWhere((e) => e.id == product.id);
              _elements[index] = _saleElement!;
            } else {
              int index = _elements.indexWhere((e) => e.id == product.id);
              _elements[index] = _saleElement!;
            }
          }
          widget.currentValue = _saleElement?.id;
          widget.onChanged(_saleElement!, widget.currentValue);
        }
      }

      _overlayEntry = OverlayEntry(
        builder: (context) => StatefulBuilder(
          builder: (context, localSetState) => Stack(
            children: [
              GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.translucent,
              ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + (kDefaultPadding + 10)),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: size.width + (kDefaultPadding * 2),
                        maxHeight: 300,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(kDefaultPadding),
                            child: TextFormField(
                              controller: search,
                              decoration: InputDecoration(
                                labelText: 'Buscar',
                                hintText: 'Escribir algo...',
                              ),
                              onChanged: (value) async {
                                List<SaleElement> results = [];
                                if (widget.saleItem is SaleItemService) {
                                  results = [
                                    Services(name: 'SERVICIO'),
                                    ...await Services.get(search: value)
                                  ];
                                } else if (widget.saleItem is SaleItemProduct) {
                                  results = [
                                    Products(name: 'PRODUCTO'),
                                    ...await Products.get(search: value)
                                  ];
                                }
                                localSetState(() {
                                  _elements = results;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              children: [
                                ..._elements.map((item) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ListTile(
                                          title: Text(item.name ?? ''),
                                          onTap: () {
                                            widget.currentValue = item.id;
                                            widget.onChanged(item, item.id);
                                            _removeOverlay();
                                            setState(() {});
                                          },
                                        ),
                                        const Divider(),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                          _buildMenuItem(
                            widget.saleItem is SaleItemService
                                ? 'Agregar Servicio'
                                : 'Agregar Producto',
                            Icons.add,
                            showElements,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => Material(
            color: Colors.transparent,
            child: Overlay(
              initialEntries: [_overlayEntry!],
            ),
          ),
        ),
      );

      // Overlay.of(context).insert(_overlayEntry!);
      _fadeController.forward();
    });
  }

  Widget _buildMenuItem(String text, IconData icon, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(text),
      onTap: () {
        _removeOverlay();
        onTap();
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    search.clear();
    _fadeController.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentValue != null) {
      _saleElement = widget.elements
          .firstWhere((e) => e.id == widget.currentValue, orElse: () {
        return Services();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(_saleElement!, widget.currentValue);
        }
      });
    }
    return CompositedTransformTarget(
        link: _layerLink,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: _targetKey,
              width: 250,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: widget.saleItem is CreditNoteService ||
                          widget.saleItem is CreditNoteProduct
                      ? null
                      : () {
                          _showContextMenu();
                        },
                  child: IgnorePointer(
                    child: TextFormField(
                      readOnly: true,
                      mouseCursor: SystemMouseCursors.click,
                      controller: TextEditingController(
                        text: _saleElement != null
                            ? _saleElement!.name!
                            : widget.title,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.title,
                        hintText: 'Selecciona algo...',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            widget.errorText != null
                ? Padding(
                    padding: const EdgeInsets.only(
                        top: kDefaultPadding / 3, left: 12),
                    child: Text(
                      widget.errorText!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 15),
                    ),
                  )
                : SizedBox()
          ],
        ));
  }
}
