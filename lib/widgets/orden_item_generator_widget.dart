import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uresax_invoice_sys_cloud/models/entry.warehouse.item.model.dart';
import 'package:uresax_invoice_sys_cloud/models/orden.item.model.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/unit.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';
import 'package:uresax_invoice_sys_cloud/pages/products_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/units_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/selector.item.widget.dart';

class OrdenItemGeneratorWidget extends StatefulWidget {
  final WareHouseElementItem ordenItemModel;
  int index;
  List<WareHouseElementItem> items;
  Function(WareHouseElementItem) onChanged;
  Function(WareHouseElementItem) onDelete;
  OrdenItemGeneratorWidget(
      {super.key,
      required this.items,
      required this.ordenItemModel,
      required this.index,
      required this.onChanged,
      required this.onDelete});

  @override
  State<OrdenItemGeneratorWidget> createState() =>
      _OrdenItemGeneratorWidgetState();
}

class _OrdenItemGeneratorWidgetState extends State<OrdenItemGeneratorWidget> {
  TextEditingController quantity = TextEditingController();
  TextEditingController units = TextEditingController();
  TextEditingController price = TextEditingController();
  TextEditingController discount = TextEditingController();
  TextEditingController net = TextEditingController();
  TextEditingController total = TextEditingController();
  TextEditingController totalAmount = TextEditingController();

  Products? selectedProduct;
  Unit? currentUnit;
  double cost = 0;

  bool get isOrdenItem {
    return widget.ordenItemModel is OrdenItemModel;
  }

  void _calc() {
    currentUnit = Unit(
        name: selectedProduct?.unitName,
        code: selectedProduct?.unitCode,
        symbol: selectedProduct?.unitSymbol,
        conversionFactor: selectedProduct?.conversionFactor ?? 1,
        isBaseUnit: selectedProduct?.isBaseUnit);

    cost = selectedProduct?.cost ?? 0;

    cost = double.tryParse(price.text) ?? cost;

    var xquantity = widget.ordenItemModel.quantity ?? 1;

    var factor = selectedProduct?.conversionFactor ?? 1;
    var xunits = xquantity * factor;

    if (widget.ordenItemModel is OrdenItemModel) {
      widget.ordenItemModel.discount = (double.tryParse(discount.text) ?? 0);
    }
    cost = (double.tryParse(price.text) ?? cost);
    var costCalc = cost;

    widget.ordenItemModel.productId = selectedProduct?.id;

    var net = costCalc * xunits;
    var netFinal = 0.0;
    var tax = 0.0;

    if (widget.ordenItemModel is EntryWareHouseItemModel) {
      net = widget.ordenItemModel.net ?? 0;
      netFinal = widget.ordenItemModel.netFinal ?? 0;
      tax = widget.ordenItemModel.tax ?? 0;
    }

    if (widget.ordenItemModel is OrdenItemModel) {
      costCalc = cost;

      widget.ordenItemModel.price = cost;
      widget.ordenItemModel.quantity = xquantity;
      widget.ordenItemModel.net = net;

      if (selectedProduct?.taxId == 1) {
        var costNet = net;
        var discount = widget.ordenItemModel.discount ?? 0;

        netFinal = costNet / 1.16;
         widget.ordenItemModel.net = netFinal;
        netFinal = netFinal - discount;
        tax = netFinal * 0.16;

        widget.ordenItemModel.tax = tax;
        widget.ordenItemModel.netFinal = netFinal;
      }
      if (selectedProduct?.taxId == 2) {
        var costNet = net;
      
        var discount = widget.ordenItemModel.discount ?? 0;
        netFinal = costNet / 1.18;
        widget.ordenItemModel.net = netFinal;

        netFinal = netFinal - discount;
        tax = netFinal * 0.18;

        widget.ordenItemModel.tax = tax;
        widget.ordenItemModel.netFinal = netFinal;
      }
    }

    widget.ordenItemModel.tax = widget.ordenItemModel.tax ?? 0;

    var xtotal =
        widget.ordenItemModel.netFinal! + (widget.ordenItemModel.tax ?? 0);

    widget.ordenItemModel.total = xtotal;

    widget.ordenItemModel.conversionFactor = factor;
    widget.ordenItemModel.unitName = selectedProduct?.unitName;
    widget.ordenItemModel.unitCode = selectedProduct?.unitCode;
    widget.ordenItemModel.unitSymbol = selectedProduct?.unitSymbol;

    if (widget.ordenItemModel is EntryWareHouseItemModel) {
      quantity.value = TextEditingValue(
        text: xquantity.toString(),
        selection: TextSelection.collapsed(
          offset: (xquantity.toString()).length,
        ),
      );
      price.text = widget.ordenItemModel.price?.toStringAsFixed(2) ?? '';
      discount.text = widget.ordenItemModel.discount?.toStringAsFixed(2) ?? '';
    }

    units.text = xunits.toStringAsFixed(2);
    total.text = net.toStringAsFixed(2);
    totalAmount.text = xtotal.toStringAsFixed(2);
    setState(() {});
    widget.onChanged(widget.ordenItemModel);
  }

  @override
  void initState() {
    if (widget.ordenItemModel.id != null ||
        widget.ordenItemModel.productId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        var xquantity = widget.ordenItemModel.quantity ?? 1;
        if (mounted) {
          quantity.value = TextEditingValue(
            text: xquantity.toStringAsFixed(2),
            selection: TextSelection.collapsed(
              offset: (xquantity.toStringAsFixed(2)).length,
            ),
          );
          selectedProduct = Products(
              id: widget.ordenItemModel.productId,
              name: widget.ordenItemModel.productName,
              cost: widget.ordenItemModel.price ?? 0,
              unitCode: widget.ordenItemModel.unitCode,
              unitName: widget.ordenItemModel.unitName,
              unitSymbol: widget.ordenItemModel.unitSymbol,
              conversionFactor: widget.ordenItemModel.conversionFactor);

          currentUnit = Unit(
              name: selectedProduct?.unitName,
              code: selectedProduct?.unitCode,
              symbol: selectedProduct?.unitSymbol,
              conversionFactor: selectedProduct?.conversionFactor ?? 1,
              isBaseUnit: selectedProduct?.isBaseUnit);

          selectedProduct?.conversionFactor = currentUnit?.conversionFactor;
          selectedProduct?.unitCode = currentUnit?.code;
          selectedProduct?.unitName = currentUnit?.name;
          selectedProduct?.unitSymbol = currentUnit?.symbol;
          selectedProduct?.isBaseUnit = currentUnit?.isBaseUnit;

          _calc();
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: kDefaultPadding),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: const Color(0xFFF1EEEE),
                borderRadius: BorderRadius.circular(100)),
            margin: EdgeInsets.only(right: kDefaultPadding),
            child: GestureDetector(
              onTap: () {
                if (widget.items.length > 1) {
                  widget.onDelete(widget.ordenItemModel);
                }
              },
              child: Icon(Icons.delete, color: Colors.red),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: kDefaultPadding),
            width: 150,
            child: TextFormField(
              controller: quantity,
              readOnly: !isOrdenItem,
              validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              onChanged: (val) {
                var xquantity = double.tryParse(val) ?? 1;
                widget.ordenItemModel.quantity = xquantity;

                _calc();
                price.text = cost.toStringAsFixed(2);
              },
              decoration: InputDecoration(labelText: 'CANTIDAD', hintText: '0'),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: kDefaultPadding),
            width: 150,
            child: TextFormField(
              controller: units,
              validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
              readOnly: true,
              decoration: InputDecoration(labelText: 'UNIDADES', hintText: '0'),
            ),
          ),
          Container(
            width: 320,
            margin: EdgeInsets.only(right: kDefaultPadding),
            child: SelectorItemWidget<Products>(
                context: context,
                title: 'SELECCIONAR PRODUCTO',
                initialValue: selectedProduct,
                enabled: isOrdenItem,
                validator: isOrdenItem
                    ? (val) => val?.id == null ? 'CAMPO OBLIGATORIO' : null
                    : (val) => selectedProduct?.id == null
                        ? 'CAMPO OBLIGATORIO'
                        : null,
                screen:
                    ProductsPage(selectedMode: true, isOrdenGenerator: true),
                onChanged: (xproduct, _) {
                  selectedProduct = xproduct;
                  var xquantity = widget.ordenItemModel.quantity ?? 1;
                  quantity.value = TextEditingValue(
                    text: xquantity.toStringAsFixed(2),
                    selection: TextSelection.collapsed(
                      offset: (xquantity.toStringAsFixed(2)).length,
                    ),
                  );

                  cost = selectedProduct?.cost ?? 0;

                  price.text = cost.toStringAsFixed(2);
                  _calc();
                }),
          ),
          Container(
            width: 320,
            margin: EdgeInsets.only(right: kDefaultPadding),
            child: SelectorItemWidget<Unit>(
                context: context,
                key: ValueKey(
                    '${widget.ordenItemModel.id}_${currentUnit?.code}'),
                title: 'SELECCIONAR UNIDAD',
                initialValue: currentUnit,
                enabled: isOrdenItem,
                validator: isOrdenItem
                    ? (val) => val?.conversionFactor == null
                        ? 'CAMPO OBLIGATORIO'
                        : null
                    : (val) => currentUnit?.conversionFactor == null
                        ? 'CAMPO OBLIGATORIO'
                        : null,
                screen: UnitsPage(selectedMode: true),
                onChanged: (xunit, _) {
                  currentUnit = xunit;

                  selectedProduct?.conversionFactor = xunit?.conversionFactor;
                  selectedProduct?.unitCode = xunit?.code;
                  selectedProduct?.unitName = xunit?.name;
                  selectedProduct?.unitSymbol = xunit?.symbol;
                  selectedProduct?.isBaseUnit = xunit?.isBaseUnit;

                  _calc();
                }),
          ),
          Container(
            width: 150,
            margin: EdgeInsets.only(right: kDefaultPadding),
            child: TextFormField(
              controller: price,
              readOnly: !isOrdenItem,
              validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
              onChanged: (_) {
                _calc();
              },
              decoration:
                  InputDecoration(labelText: 'PRECIO', hintText: '0.00'),
            ),
          ),
          Container(
            width: 150,
            margin: EdgeInsets.only(right: kDefaultPadding),
            child: TextFormField(
              controller: discount,
              readOnly: !isOrdenItem,
              onChanged: (_) {
                _calc();
              },
              decoration:
                  InputDecoration(labelText: 'DESCUENTO', hintText: '0.00'),
            ),
          ),
          Container(
            width: 150,
            child: TextFormField(
              controller: totalAmount,
              readOnly: true,
              decoration:
                  InputDecoration(labelText: 'MONTO TOTAL', hintText: '0.00'),
            ),
          )
        ],
      ),
    );
  }
}
