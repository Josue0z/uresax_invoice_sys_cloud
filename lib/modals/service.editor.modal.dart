import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/categorie.dart';
import 'package:uresax_invoice_sys_cloud/models/service.dart';
import 'package:uresax_invoice_sys_cloud/pages/categories_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/image.selector.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/selector.item.widget.dart';

class ServiceEditorModal extends StatefulWidget {
  bool editing;
  Services service;

  ServiceEditorModal({super.key, this.editing = false, required this.service});

  @override
  State<ServiceEditorModal> createState() => _ServiceEditorModalState();
}

class _ServiceEditorModalState extends State<ServiceEditorModal> {
  TextEditingController name = TextEditingController();
  TextEditingController code = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController maxDiscount = TextEditingController();
  TextEditingController priceSuite = TextEditingController();
  AmountInputFormatter priceSuiteFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  TextEditingController rateSuite = TextEditingController();

  AmountInputFormatter rateSuiteFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);

  bool isWithTax = false;

  int? currentTaxId;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Category? currentCategory;
  int? currentCategoryId;
  String? imageBase64;
  String? imageUrl;

  bool editable = true;

  List<Map<String, dynamic>> optionsEdits = [
    {'value': true, 'name': 'EDITABLE'},
    {'value': false, 'name': 'NO EDITABLE'}
  ];

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        widget.service.name = name.text.trim();
        widget.service.price = amountInputFormatter.doubleValue;
        widget.service.taxId = currentTaxId;
        widget.service.categoryId = currentCategoryId;
        widget.service.imageBase64 = imageBase64;
        widget.service.code = code.text.isEmpty ? null : code.text;
        widget.service.maxDiscount = double.tryParse(maxDiscount.text) ?? 90.00;
        widget.service.editable = editable;
        widget.service.priceSuite = priceSuiteFormatter.doubleValue;
        widget.service.rateSuite =
            double.tryParse(rateSuite.text.replaceAll(',', '')) ?? 0.00;
        if (!widget.editing) {
          await widget.service.create();
          await LogHandler.printEvent(
              'SERVICIO: ${widget.service.name} CREADO');
          Navigator.pop(context, 'CREATE');
        } else {
          await widget.service.update();
          await LogHandler.printEvent(
              'SERVICIO: ${widget.service.name} ACTUALIZADO');
          Navigator.pop(context, 'UPDATE');
          showTopSnackBar(context,
              message: widget.editing ? 'SERVICIO EDITADO' : 'SERVICIO CREADO',
              color: Colors.green);
        }
      } catch (e) {
        await LogHandler.printError(e.toString());
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  String get title {
    return widget.editing ? 'EDITANDO SERVICIO' : 'AGREGANDO SERVICIO';
  }

  String get btnTitle {
    return widget.editing ? 'EDITAR SERVICIO' : 'AGREGAR SERVICIO';
  }

  @override
  void initState() {
    name.value = TextEditingValue(text: widget.service.name ?? '');
    maxDiscount.text = '90.00';
    if (widget.service.price != null) {
      currentCategory = Category(
          id: widget.service.categoryId, name: widget.service.categoryName);
      currentCategoryId = currentCategory?.id;
      imageUrl = widget.service.imageUrl;
      amount.value = amountInputFormatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
              text: widget.service.price?.toStringAsFixed(2) ?? ''));
      code.text = widget.service.code ?? '';
      editable = widget.service.editable ?? false;
      maxDiscount.text =
          widget.service.maxDiscount?.toStringAsFixed(2) ?? '0.00';

      if ((widget.service.priceSuite ?? 0) > 0) {
        priceSuite.value = priceSuiteFormatter.formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(
                text: widget.service.priceSuite?.toStringAsFixed(2) ?? '0.00'));
      }

      if ((widget.service.rateSuite ?? 0) > 0) {
        rateSuite.text = widget.service.rateSuite?.toStringAsFixed(2) ?? '';
      }
    }
    currentTaxId = widget.service.taxId;

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
              height: 700,
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
                                    element: widget.service,
                                    onDelete: (type) {
                                      if (type == 'FROM-URL') {
                                        Navigator.pop(context, 'UPDATE');
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
                          margin: EdgeInsets.only(
                              top: kDefaultPadding, bottom: kDefaultPadding),
                          child: TextFormField(
                            controller: name,
                            validator: (val) =>
                                val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                            decoration: InputDecoration(
                                labelText: 'NOMBRE',
                                hintText: 'Escribir nombre...'),
                          ),
                        ),
                        enabledRealEstateAgency == false
                            ? SizedBox()
                            : Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: priceSuite,
                                  inputFormatters: [priceSuiteFormatter],
                                  decoration: InputDecoration(
                                      labelText: 'PRECIO APART.',
                                      hintText: '0.00'),
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
                        enabledRealEstateAgency == false
                            ? SizedBox()
                            : Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: rateSuite,
                                  inputFormatters: [
                                    rateSuiteFormatter,
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}$'))
                                  ],
                                  decoration: InputDecoration(
                                      labelText: 'TASA COMISION.',
                                      hintText: '%10',
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            var rate = double.tryParse(rateSuite
                                                    .text
                                                    .replaceAll(',', '')) ??
                                                0.00;
                                            var ratePercent = rate / 100;
                                            var pb = priceSuiteFormatter
                                                    .doubleValue *
                                                ratePercent;
                                            double pn = pb;

                                          
                                          isWithTax = !isWithTax;
                                         

                                            if (currentTaxId == 1) {
                                              if (isWithTax) {
                                                pn = pb / 1.16;
                                              } else {
                                                pn = (pb / 1.16) / 1.16;
                                              }
                                            }
                                            if (currentTaxId == 2) {
                                              if (isWithTax) {
                                                pn = pb / 1.18;
                                              } else {
                                                pn = (pb / 1.18) / 1.18;
                                              }
                                            }

                                            amount.value = amountInputFormatter
                                                .formatEditUpdate(
                                                    TextEditingValue.empty,
                                                    TextEditingValue(
                                                        text:
                                                            pn.toStringAsFixed(
                                                                2)));
                                          },
                                          icon:
                                              Icon(Icons.calculate_outlined))),
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
                        enabledItemSimpleConfig
                            ? SizedBox()
                            : Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: maxDiscount,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}$'))
                                  ],
                                  decoration: InputDecoration(
                                      labelText: 'MAXIMO DESCUENTO',
                                      hintText: '90%'),
                                ),
                              ),
                        enabledItemSimpleConfig
                            ? SizedBox()
                            : Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: code,
                                  decoration: InputDecoration(
                                      labelText: 'CODIGO',
                                      hintText: '000000000'),
                                ),
                              ),
                        Container(
                          margin: EdgeInsets.only(bottom: kDefaultPadding),
                          child: DropdownButtonFormField<bool>(
                            initialValue: editable,
                            decoration: InputDecoration(labelText: 'SERVICIO'),
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
