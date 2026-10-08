import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/categorie.dart';
import 'package:uresax_invoice_sys_cloud/models/discount.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/provider.dart';
import 'package:uresax_invoice_sys_cloud/models/unit.dart';
import 'package:uresax_invoice_sys_cloud/pages/categories_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/discounts_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/providers_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/units_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/image.selector.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/selector.item.widget.dart';

class ProductEditorModal extends StatefulWidget {
  bool editing;
  bool isParent;
  Products product;
  Products? parentProduct;

  ProductEditorModal({super.key, this.editing = false, this.isParent = false, required this.product,this.parentProduct});

  @override
  State<ProductEditorModal> createState() => _ProductEditorModalState();
}

class _ProductEditorModalState extends State<ProductEditorModal> {
  TextEditingController name = TextEditingController();
  TextEditingController cost = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController factor = TextEditingController();
  TextEditingController quantityResult = TextEditingController();
  TextEditingController chassis = TextEditingController();
  TextEditingController code = TextEditingController();
  TextEditingController licensePlate = TextEditingController();
  TextEditingController colorName = TextEditingController();
  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);

  AmountInputFormatter costInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? currentTaxId;
  int? currentWareHouseId;
  int? currentCategoryId;
  Providers? currentProvider;
  Category? currentCategory;
  int? currentProviderId;
  int? currentUnitId;
  Unit? currentUnit;
  double? xxquantity = 1;
  String? imageBase64;
  String? imageUrl;
  int? currentDiscountId;
  Discount? currentDiscount;
  double? conversionFactor = 1;
  TextEditingController maxDiscount = TextEditingController();

  bool editable = true;

  List<Map<String, dynamic>> optionsEdits = [
    {'value': true, 'name': 'EDITABLE'},
    {'value': false, 'name': 'NO EDITABLE'}
  ];

  bool isUnique = true;


    List<Map<String, dynamic>> optionsProductsModes = [
    {'value': true, 'name': 'ES UNICO'},
    {'value': false, 'name': 'NO ES UNICO'}
  ];

  _calcUnits() {
    double xquantity = widget.product.quantity ?? 0.0;
    double xfactor = widget.product.factor ?? 0.0;

    if (factor.text.isNotEmpty && xfactor >= 1) {
      xxquantity = (xquantity * xfactor);
      quantityResult.value =
          TextEditingValue(text: xxquantity?.toStringAsFixed(2) ?? '');
    } else {
      quantityResult.value = TextEditingValue.empty;
    }
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);
      try {
        widget.product.name = name.text.trim();
        widget.product.price = amountInputFormatter.doubleValue;
        widget.product.cost = costInputFormatter.doubleValue;
        widget.product.quantity =  double.tryParse(quantity.text);
        widget.product.chassis =
            chassis.text.isEmpty ? null : chassis.text.trim();
        widget.product.licensePlate =
            licensePlate.text.isEmpty ? null : licensePlate.text.trim();
        widget.product.colorName =
            colorName.text.isEmpty ? null : colorName.text.trim();
        widget.product.taxId = currentTaxId;
        widget.product.wareHouseId = currentWareHouseId;
        widget.product.providerId = currentProviderId;
        widget.product.code = code.text.isEmpty ? null : code.text.trim();
        widget.product.categoryId = currentCategoryId;
        widget.product.unitId = currentUnitId;
        widget.product.imageBase64 = imageBase64;
        widget.product.discountId = currentDiscountId;
        widget.product.editable = editable;
        widget.product.maxDiscount = double.tryParse(maxDiscount.text) ?? 90;
        widget.product.isUnique = isUnique;
        widget.product.parentId =  widget.parentProduct?.id;
        widget.product.factor = double.tryParse(factor.text) ?? 1.0;
        if (!widget.editing) {
          var product = await widget.product.create();
          await LogHandler.printEvent(
              'PRODUCTO: ${widget.product.name} CREADO');
          Navigator.pop(context);
          Navigator.pop(context, product);
        } else {
          var product = await widget.product.update();
          await LogHandler.printEvent(
              'PRODUCTO: ${widget.product.name} ACTUALIZADO');
          Navigator.pop(context);
          Navigator.pop(context, product);
          showTopSnackBar(context,
              message: widget.editing ? 'PRODUCTO EDITADO' : 'PRODUCTO CREADO',
              color: Colors.green);
        }
      } catch (e) {
        await LogHandler.printError(e.toString());
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  String get title {
    return widget.editing ? 'EDITANDO PRODUCTO' : 'AGREGANDO PRODUCTO';
  }

  String get btnTitle {
    return widget.editing ? 'EDITAR PRODUCTO' : 'AGREGAR PRODUCTO';
  }

  @override
  void initState() {
  
    name.value = TextEditingValue(text: widget.product.name ?? '');

    currentWareHouseId = widget.product.wareHouseId;

    currentProviderId = widget.product.providerId;
    currentProvider =
        Providers(id: currentProviderId, name: widget.product.providerName);

    currentCategoryId = widget.product.categoryId;
    currentCategory = Category(
        id: widget.product.categoryId, name: widget.product.categoryName);

    maxDiscount.text = '90.00';

  

    if (widget.editing) {
      imageUrl = widget.product.imageUrl;

      currentDiscountId = widget.product.discountId;
      currentDiscount = Discount(
          id: currentDiscountId,
          name: widget.product.discountName,
          rate: widget.product.discountRate,
          symbolId: widget.product.discountSymbolId);
      maxDiscount.text =
          widget.product.maxDiscount?.toStringAsFixed(2) ?? '0.00';
  
      currentUnit = Unit(
          id: widget.product.unitId,
          name: widget.product.unitName,
          symbol: widget.product.unitSymbol,
          conversionFactor: widget.product.conversionFactor);
      currentUnitId = currentUnit?.id;

      xxquantity = widget.product.quantity;
      amount.value = amountInputFormatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
              text: widget.product.price?.toStringAsFixed(2) ?? ''));

      cost.value = costInputFormatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
              text: widget.product.cost?.toStringAsFixed(2) ?? ''));
      isUnique = widget.product.isUnique ?? false;
      editable = widget.product.editable ?? false;
      conversionFactor = widget.product.conversionFactor ?? 1.0;
    }
    code.value = TextEditingValue(text: widget.product.code ?? '');

    if (enabledStore == true && widget.editing == false) {
      xxquantity = null;
    }

   
    factor.value =
        TextEditingValue(text:conversionFactor?.toStringAsFixed(2) ?? '');
    quantity.value =
        TextEditingValue(text: xxquantity?.toStringAsFixed(2) ?? '');

    chassis.value = TextEditingValue(text: widget.product.chassis ?? '');
    licensePlate.value =
        TextEditingValue(text: widget.product.licensePlate ?? '');

    colorName.value = TextEditingValue(text: widget.product.colorName ?? '');

    currentTaxId = widget.product.taxId;

    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
          key: _formKey,
          child: Container(
              width: 350,
              height: 550,
              padding: EdgeInsets.all(kDefaultPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                      color: Theme.of(context).primaryColor))),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close))
                    ],
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                    child: Column(
                      children: [
                        enabledImageChanges
                            ? Container(
                                margin: EdgeInsets.only(
                                    top: kDefaultPadding,
                                    bottom: kDefaultPadding),
                                child: ImageSelectorWidget(
                                    imageBase64: imageBase64,
                                    imageUrl: imageUrl,
                                    element: widget.product,
                                    onDelete: (type) {
                                      if (type == 'FROM-URL') {
                                        Navigator.pop(context, widget.product);
                                      }
                                    },
                                    onChanged: (img, url) {
                                      setState(() {
                                        imageBase64 = img;
                                        imageUrl = url;
                                      });
                                    }),
                              )
                            : SizedBox(),
                        Container(
                          margin:
                              EdgeInsets.symmetric(vertical: kDefaultPadding),
                          child: DropdownButtonFormField<int>(
                              initialValue: currentWareHouseId,
                              validator: (val) =>
                                  val == null ? 'CAMPO OBLIGATORIO' : null,
                              items: List.generate(wareHouses.length, (index) {
                                var wareHouse = wareHouses[index];
                                return DropdownMenuItem(
                                    value: wareHouse.id,
                                    child: Text(wareHouse.name ?? ''));
                              }),
                              onChanged: (id) {
                                currentWareHouseId = id;
                              }),
                        ),
                        Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: SelectorItemWidget<Providers>(
                              context: context,
                              initialValue: currentProvider,
                              validator: (val) =>
                                  val?.id == null ? 'CAMPO OBLIGATORIO' : null,
                              onChanged: (xprovider, _) {
                                currentProvider = xprovider;
                                currentProviderId = xprovider?.id;
                              },
                              screen: ProvidersPage(selectorMode: true),
                              title: 'SELECCIONA PROVEEDOR',
                            )),
                        Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: SelectorItemWidget<Category>(
                              context: context,
                              initialValue: currentCategory,
                              validator: (val) =>
                                  val?.id == null ? 'CAMPO OBLIGATORIO' : null,
                              onChanged: (xcategory, _) {
                                currentCategory = xcategory;
                                currentCategoryId = xcategory?.id;
                              },
                              screen: CategoriesPage(selectorMode: true),
                              title: 'SELECCIONA CATEGORIA',
                            )),
                        Container(
                          margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child: TextFormField(
                            controller: name,
                            validator: (val) =>
                                val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                            decoration: InputDecoration(
                                labelText: 'NOMBRE',
                                hintText: 'Escribir nombre...'),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child: TextFormField(
                            controller: cost,
                            validator: (val) =>
                                val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                            inputFormatters: [costInputFormatter],
                            decoration: InputDecoration(
                                labelText: 'COSTO', hintText: '0.00'),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child: TextFormField(
                            controller: amount,
                            validator: (val) =>
                                val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                            inputFormatters: [amountInputFormatter],
                            decoration: InputDecoration(
                                labelText: 'PRECIO', hintText: '0.00'),
                          ),
                        ),
                        Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: SelectorItemWidget<Discount>(
                              context: context,
                              initialValue: currentDiscount,
                              onChanged: (xdiscount, _) {
                                currentDiscount = xdiscount;
                                currentDiscountId = xdiscount?.id;
                              },
                              screen: DiscountsPage(selectorMode: true),
                              title: 'SELECCIONA DESCUENTO',
                            )),
                        Container(
                          margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child: TextFormField(
                            controller: maxDiscount,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}$'))
                            ],
                            decoration: InputDecoration(
                                labelText: 'MAXIMO DESCUENTO', hintText: '90%'),
                          ),
                        ),
                        eCommerceMode || enabledStore
                            ? Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: code,
                                  decoration: InputDecoration(
                                      labelText: 'CODIGO PRODUCTO',
                                      hintText: '0000000000',
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            if(name.text.trim().isNotEmpty){
                                              code.text = generarCodigoIniciales(name.text.trim());
                                            }
                                          },
                                          icon: Icon(Icons.refresh))),
                                ),
                              )
                            : Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: chassis,
                                  decoration: InputDecoration(
                                      labelText: 'CHASIS',
                                      hintText: 'Escribir...'),
                                ),
                              ),
                        eCommerceMode || enabledStore
                            ? SizedBox()
                            : Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: licensePlate,
                                  decoration: InputDecoration(
                                      labelText: 'PLACA',
                                      hintText: 'Escribir...'),
                                ),
                              ),
                        eCommerceMode || enabledStore
                            ? SizedBox()
                            : Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: colorName,
                                  decoration: InputDecoration(
                                      labelText: 'COLOR',
                                      hintText: 'Escribir...'),
                                ),
                              ),
                        Container(
                          margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child: DropdownButtonFormField<int>(
                              initialValue: currentTaxId,
                              decoration: InputDecoration(
                                  labelText: 'TIPO DE IMPUESTO'),
                              items: List.generate(taxes.length, (index) {
                                var tax = taxes[index];
                                return DropdownMenuItem(
                                    value: tax.id, child: Text(tax.name ?? ''));
                              }),
                              onChanged: (option) {
                                currentTaxId = option;
                              }),
                        ),
                        Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: SelectorItemWidget<Unit>(
                              context: context,
                              initialValue: currentUnit,
                              validator: (val) =>
                                  val?.id == null ? 'CAMPO OBLIGATORIO' : null,
                              onChanged: (xunit, _) {
                                currentUnit = xunit;
                                currentUnitId = xunit?.id;
                                factor.text = currentUnit?.conversionFactor.toString() ?? '1.00';
                              },
                              screen: UnitsPage(selectedMode: true),
                              title: 'SELECCIONA UNIDAD',
                            )),
                        Container(
                          margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child: DropdownButtonFormField<bool>(
                            initialValue: editable,
                            decoration: InputDecoration(labelText: 'PRODUCTO'),
                            items: List.generate(optionsEdits.length, (index) {
                              var option = optionsEdits[index];
                              return DropdownMenuItem(
                                  value: option['value'],
                                  child: Text(option['name']));
                            }),
                            onChanged: (val) {
                              editable = val ?? false;
                            },
                          ),
                        ),

                  
                       widget.isParent? SizedBox(): Container(
                             margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child: DropdownButtonFormField<bool>(
                            initialValue: isUnique,
                            decoration: InputDecoration(labelText: 'PRODUCTO'),
                            items: List.generate(optionsProductsModes.length, (index) {
                              var option = optionsProductsModes[index];
                              return DropdownMenuItem(
                                  value: option['value'],
                                  child: Text(option['name']));
                            }),
                            onChanged: widget.editing ? null : (val) {
                             setState(() {
                                isUnique = val!;

                                if(isUnique == false){
                                  xxquantity = 0;
                                  quantity.text = '0.00';
                                }else{
                                  xxquantity = 1;
                                  quantity.text = '1.00';
                                }
                             });
                            },
                          ),
                        ),

                            widget.editing || (isUnique == false && widget.isParent == false) ?SizedBox(): Container(
                              margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child:TextFormField(
                            controller: factor,
                              inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,6}'))],
                            decoration: InputDecoration(
                                labelText: 'FACTOR DE CONVERSION',
                                hintText: '1.00'),
                          )
                        ),

                        widget.editing || (isUnique == false && widget.isParent == false)
                            ? SizedBox(): Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: quantity,
                                  readOnly: eCommerceMode == false &&
                                      enabledStore == false,
                                 inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                  onChanged: (val) {
                                    widget.product.quantity =
                                        double.tryParse(quantity.text) ?? 0.0;
                                    _calcUnits();
                                  },
                                  validator: (val) =>
                                      val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                      labelText: 'CANTIDAD', hintText: '0'),
                                ),
                              )
                           
                      ],
                    ),
                  )),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _onSubmit, child: Text(btnTitle)),
                  )
                ],
              ))),
    );
  }
}
