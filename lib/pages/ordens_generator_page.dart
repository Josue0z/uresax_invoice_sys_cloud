import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:uresax_invoice_sys_cloud/models/drivers.dart';
import 'package:uresax_invoice_sys_cloud/models/entry.warehouse.model.dart';
import 'package:uresax_invoice_sys_cloud/models/orden.item.model.dart';
import 'package:uresax_invoice_sys_cloud/models/orden.model.dart';
import 'package:uresax_invoice_sys_cloud/models/provider.dart';
import 'package:uresax_invoice_sys_cloud/models/warehouse.obj.dart';
import 'package:uresax_invoice_sys_cloud/pages/drivers_page.dart';
import 'package:uresax_invoice_sys_cloud/pages/providers_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/orden_item_generator_widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/selector.item.widget.dart';
import 'package:uuid/uuid.dart';

class OrdensGeneratorPage extends StatefulWidget {
  final WareHouseElement ordenModel;
  const OrdensGeneratorPage({super.key, required this.ordenModel});

  @override
  State<OrdensGeneratorPage> createState() => _OrdensGeneratorPageState();
}

class _OrdensGeneratorPageState extends State<OrdensGeneratorPage> {
  Drivers? driver;
  Providers? currentProvider;
  DateTime? ncfDate;
  TextEditingController ncfDateController = TextEditingController();
  TextEditingController ncfController = TextEditingController();

  int? currentCurrencyId = 1;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool get isOrden {
    return widget.ordenModel is OrdenModel;
  }

  String get title {
    return isOrden
        ? 'GENERANDO ORDEN DE COMPRA...'
        : 'GENERANDO ENTRADA DE ALMACEN';
  }

  String get btnText {
    return isOrden ? 'CREAR ORDEN DE COMPRA' : 'CREAR ENTRADA DE ALMACEN';
  }

  double get totalAmount {
    return data['totalAmount'] ?? 0.0;
  }

  double get taxAmount {
    return data['taxAmount'] ?? 0.0;
  }

  double get net {
    return data['net'] ?? 0.0;
  }

  double get netFinal {
    return data['netFinal'] ?? 0.0;
  }

  double get discount {
    return data['discount'] ?? 0.0;
  }

  _showDatePicker() async {
    var result = await showDatePicker(
      context: context,
      initialDate: ncfDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      lastDate: DateTime.now(),
    );

    if (result == null) {
      // Usuario canceló → limpiar fecha y rebuild
      setState(() {
        ncfDate = null;
        ncfDateController.value = const TextEditingValue(text: '');
      });
    } else {
      // Usuario seleccionó fecha → actualizar
      setState(() {
        ncfDate = result;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ncfDateController.value = TextEditingValue(
          text: ncfDate?.format(payload: 'DD/MM/YYYY') ?? '',
        );
      });
    }

    _formKey.currentState!.validate();
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);
      try {
        widget.ordenModel.net = net;
        widget.ordenModel.netFinal = netFinal;
        widget.ordenModel.discount = discount;
        widget.ordenModel.tax = taxAmount;
        widget.ordenModel.total = totalAmount;
        widget.ordenModel.amountPaid = 0;
        widget.ordenModel.authorId = currentUser?.id;
        widget.ordenModel.driverId = driver?.id;
        widget.ordenModel.providerId = currentProvider?.id;
        widget.ordenModel.ncf =
            ncfController.text.isEmpty == true ? null : ncfController.text;
        widget.ordenModel.ncfDate = ncfDate;
        widget.ordenModel.currencyId = currentCurrencyId;
        var now = DateTime.now().toUtc();
        widget.ordenModel.createdAt = now;

        await widget.ordenModel.create();
        Navigator.pop(context);
        Navigator.pop(context, 'CREATE');
      } catch (e) {
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  Map<String, double> get data {
    double net = 0;
    double discount = 0;
    double netFinal = 0;
    double totalAmount = 0;
    double taxAmount = 0;
    for (int i = 0; i < widget.ordenModel.items!.length; i++) {
      var item = widget.ordenModel.items![i];

      net += item.net ?? 0;
      discount += item.discount ?? 0;
      netFinal += item.netFinal ?? 0;
      taxAmount += item.tax ?? 0;
      totalAmount += item.total ?? 0;
    }
    return {
      'totalAmount': totalAmount,
      'net': net,
      'discount': discount,
      'netFinal': netFinal,
      'taxAmount': taxAmount
    };
  }

  @override
  void initState() {
    driver = Drivers(
        id: widget.ordenModel.driverId,
        name: widget.ordenModel.driverName,
        phone: widget.ordenModel.driverPhone,
        email: widget.ordenModel.driverEmail);

    currentProvider = Providers(
        id: widget.ordenModel.providerId,
        name: widget.ordenModel.providerName,
        rncOrId: widget.ordenModel.providerIdentification);

    currentCurrencyId = widget.ordenModel.currencyId ?? 1;

    ncfDate = widget.ordenModel.ncfDate ?? DateTime.now();
    ncfDateController.text = ncfDate?.format(payload: 'DD/MM/YYYY') ?? '';

    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Form(
            key: _formKey,
            child: Padding(
                padding: EdgeInsets.all(kDefaultPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: MediaQuery.of(context).size.width * 0.60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    children: [
                                      ...List.generate(
                                          widget.ordenModel.items?.length ?? 0,
                                          (index) {
                                        var item =
                                            widget.ordenModel.items![index];

                                        return OrdenItemGeneratorWidget(
                                          key: ValueKey(item.id),
                                          ordenItemModel: item,
                                          items: widget.ordenModel.items
                                                  ?.cast<OrdenItemModel>() ??
                                              [],
                                          index: index,
                                          onDelete: (_) {
                                            widget.ordenModel.items
                                                ?.removeAt(index);
                                            setState(() {});
                                          },
                                          onChanged: (ordenItem) {
                                            setState(() {});
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            )),
                        isOrden
                            ? SizedBox(
                                width: 250,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    widget.ordenModel.items?.add(OrdenItemModel(
                                        id: Uuid().v4(), quantity: 1));
                                    setState(() {});
                                  },
                                  child: Text('AGREGAR PRODUCTO'),
                                ),
                              )
                            : SizedBox(),
                      ],
                    )),
                    const Divider(),
                    Expanded(
                        child: Container(
                            child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            margin:
                                EdgeInsets.symmetric(vertical: kDefaultPadding),
                            child: SelectorItemWidget<Providers>(
                                context: context,
                                initialValue: currentProvider,
                                title: 'SELECCIONAR PROVEEDOR',
                                validator: (val) => val?.id == null
                                    ? 'CAMPO OBLIGATORIO'
                                    : null,
                                screen: ProvidersPage(selectorMode: true),
                                onChanged: (xprovider, _) {
                                  currentProvider = xprovider;
                                }),
                          ),
                          Container(
                            width: double.infinity,
                            margin:
                                EdgeInsets.symmetric(vertical: kDefaultPadding),
                            child: SelectorItemWidget<Drivers>(
                                context: context,
                                initialValue: driver,
                                title: 'SELECCIONAR CONDUCTOR',
                                validator: (val) => val?.id == null
                                    ? 'CAMPO OBLIGATORIO'
                                    : null,
                                screen: DriversPage(selectedMode: true),
                                onChanged: (xdriver, _) {
                                  driver = xdriver;
                                }),
                          ),
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: DropdownButtonFormField<int?>(
                                initialValue: currentCurrencyId,
                                validator: (val) =>
                                    val == null ? 'CAMPO OBLIGATORIO' : null,
                                decoration:
                                    InputDecoration(labelText: 'MONEDA'),
                                items:
                                    List.generate(currencies.length, (index) {
                                  var currency = currencies[index];
                                  return DropdownMenuItem(
                                      value: currency.id,
                                      child: Text(currency.name ?? ' '));
                                }),
                                onChanged:
                                    widget.ordenModel is EntryWareHouseModel
                                        ? null
                                        : (option) {
                                            currentCurrencyId = option;
                                            setState(() {});
                                          }),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: TextFormField(
                              controller: ncfDateController,
                              readOnly: true,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: InputDecoration(
                                  labelText: 'FECHA DE EMISIÓN DE NCF',
                                  hintText: 'DD/MM/YYYY',
                                  suffixIcon: IconButton(
                                      onPressed: _showDatePicker,
                                      icon: Icon(Icons.calendar_month))),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: kDefaultPadding),
                            child: TextFormField(
                              controller: ncfController,
                              validator: (val) => val?.isEmpty == true
                                  ? 'CAMPO OBLIGATORIO'
                                  : null,
                              decoration: InputDecoration(
                                  labelText: 'NCF', hintText: 'E310000000001'),
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.only(bottom: kDefaultPadding),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('SUBTOTAL',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(
                                          currentCurrencyId == 1
                                              ? net.toDop()
                                              : net.toUS(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          textAlign: TextAlign.right))
                                ],
                              )),
                          Container(
                              margin: EdgeInsets.only(bottom: kDefaultPadding),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('DESCUENTO',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(
                                          currentCurrencyId == 1
                                              ? discount.toDop()
                                              : discount.toUS(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          textAlign: TextAlign.right))
                                ],
                              )),
                          Container(
                              margin: EdgeInsets.only(bottom: kDefaultPadding),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('SUBTOTAL',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(
                                          currentCurrencyId == 1
                                              ? netFinal.toDop()
                                              : netFinal.toUS(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          textAlign: TextAlign.right))
                                ],
                              )),
                          Container(
                              margin: EdgeInsets.only(bottom: kDefaultPadding),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('TOTAL ITBIS',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(
                                          currentCurrencyId == 1
                                              ? taxAmount.toDop()
                                              : taxAmount.toUS(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          textAlign: TextAlign.right))
                                ],
                              )),
                          Container(
                              margin: EdgeInsets.only(bottom: kDefaultPadding),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('MONTO TOTAL',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(
                                          currentCurrencyId == 1
                                              ? totalAmount.toDop()
                                              : totalAmount.toUS(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          textAlign: TextAlign.right))
                                ],
                              )),
                          const Divider(),
                          Container(
                            width: double.infinity,
                            height: 50,
                            margin:
                                EdgeInsets.symmetric(vertical: kDefaultPadding),
                            child: ElevatedButton(
                                onPressed: _onSubmit, child: Text(btnText)),
                          )
                        ],
                      ),
                    )))
                  ],
                ))));
  }
}
