import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:ecf_dgii/ecf_dgii.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/element.selector.widget.dart';
import 'package:uresax_invoice_sys_cloud/modals/ncfs.selector.modal.dart';
import 'package:uresax_invoice_sys_cloud/modals/payment.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/modals/pre.confirm.invoice.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/client.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.product.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.service.dart';
import 'package:uresax_invoice_sys_cloud/models/ncf.secuencia.dart';
import 'package:uresax_invoice_sys_cloud/models/ncfList.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.element.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/models/service.dart';
import 'package:uresax_invoice_sys_cloud/models/taxpayer.dart';
import 'package:uresax_invoice_sys_cloud/pages/cotizations_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/rnc.query.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/toolbutton.widget.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class TableInvoiceGenerator extends StatefulWidget {
  List<SaleItem> items;
  Sale sale;
  bool editing;
  bool generateNcfFromProforma;
  SaleMode mode;
  TableInvoiceGenerator(
      {super.key,
      required this.items,
      required this.sale,
      this.mode = SaleMode.product,
      this.editing = false,
      this.generateNcfFromProforma = false});

  @override
  State<TableInvoiceGenerator> createState() => _TableInvoiceGeneratorState();
}

class _TableInvoiceGeneratorState extends State<TableInvoiceGenerator> {
  List<List<TextEditingController>> controllers = [];
  List<List<FocusNode>> focusNodes = [];
  final ScrollController _verticalScrollController = ScrollController();
  FocusNode keyboardFocus = FocusNode();
  final FocusNode _ncfSelectorFocus = FocusNode(skipTraversal: true);
  final FocusNode _rncEditorFocus = FocusNode(skipTraversal: false);
  //final FocusNode _amountFocus = FocusNode(skipTraversal: true);
  List<String> columns = [
    'CODIGO',
    'DESCRIPCION',
    'CANTIDAD',
    'PRECIO',
    'DESCUENTO',
    'ITBIS',
    'TOTAL'
  ];

  TextEditingController clientName = TextEditingController();
  TextEditingController rncOrId = TextEditingController();
  TaxPayer? taxPayer;
  Client? client;
  String? currentTypeIncomeId = '01';
  int? currentPaymentMethodId;
  int? currentPaymentType;
  int? currentPaymentModeId;
  int? currentOverrideCode = 1;
  String? currentNcfTypeId;
  String? currentPrefix;
  int currentLawMode = 1;
  int? maxSequence;
  List<NcfType> _ncfs = [];

  bool showNumericKeyboard = false;

  NcfsList? ncfList;
  double oldTotalRetencionItbis = 0;
  double oldtTotalRetencionIsr = 0;

  TextEditingController description = TextEditingController();
  TextEditingController issueDateController = TextEditingController();
  TextEditingController retentionDateController = TextEditingController();
  TextEditingController fechaVencimientoController = TextEditingController();
  TextEditingController transfRef = TextEditingController();
  TextEditingController paymentDateController = TextEditingController();
  DateTime createdAt = DateTime.now();
  DateTime issueDate = DateTime.now();
  DateTime? retentionDate;
  DateTime? paymentDate = DateTime.now();
  DateTime fechaVencimiento = DateTime.now().endOfYear();

  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  TextEditingController amount = TextEditingController();
  Sale? _currentSale;
  double creditNoteTotal = 0;

  final FocusNode _focusKeyboard = FocusNode();
  final FocusNode _focusCommands = FocusNode();
  TextEditingController rate = TextEditingController();
  int? currentCurrencyId = 1;
  int? currentBankId;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<FormaDePago> formasDePagos = [];

  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollController2 = ScrollController();

  List<Map<String, dynamic>> law10Modes = [
    {'id': 1, 'value': null, 'name': 'MONTO PROPINA LEGAL'},
    {'id': 2, 'value': 10, 'name': 'APLICAR PROPINA LEGAL'}
  ];

  List<int> offsets = [0, 0];

  int x = 0, y = 0;

  double get xrate {
    double xrate = 1;

    double? calcRate = double.tryParse(rate.text);
    if (calcRate != null) {
      xrate = calcRate;
    }
    return xrate;
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
    return currentNcfTypeId == '44' ||
        currentNcfTypeId == '14' ||
        _currentSale?.ncfTypeId == '44' ||
        _currentSale?.ncfTypeId == '14';
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
        currentNcfTypeId == '04' ||
        currentNcfTypeId == '11' ||
        currentNcfTypeId == '13' ||
        currentNcfTypeId == '15' ||
        currentNcfTypeId == '04' ||
        currentNcfTypeId == '14' ||
        currentNcfTypeId == '50' ||
        currentNcfTypeId == '60';
  }

  List<List<TextEditingController>> get xcontrollers {
    for (int i = 0; i < widget.items.length; i++) {
      var row = widget.items[i];
      var keys = columns.toList();
      var list = List.generate(keys.length, (j) => TextEditingController());
      controllers.add(list);
    }
    return controllers;
  }

  List<List<FocusNode>> get xfocusNodes {
    for (int i = 0; i < widget.items.length; i++) {
      var row = widget.items[i];
      var keys = columns.toList();
      var list = List.generate(keys.length, (j) => FocusNode());
      focusNodes.add(list);
    }
    return focusNodes;
  }

  int get maxOffsetX {
    return widget.items.length - 1;
  }

  bool get isSale {
    return widget.sale is SaleService || widget.sale is SaleProduct;
  }

  _showDatePickerPayment() async {
    var result = await showDatePicker(
        context: context,
        initialDate: paymentDate ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
        lastDate: DateTime.now());

    if (result == null) {
      // Usuario canceló → limpiar fecha y rebuild
      setState(() {
        paymentDate = null;
        paymentDateController.value = const TextEditingValue(text: '');
      });
    } else {
      // Usuario seleccionó fecha → actualizar
      setState(() {
        paymentDate = result;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        paymentDateController.value = TextEditingValue(
          text: paymentDate?.format(payload: 'DD/MM/YYYY') ?? '',
        );
      });
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
      widget.sale.exemptAmount = 0;
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

      if (isSale) {
        currentTypeIncomeId = '01';
        if (enabledPosAutomaticSetup) {
          client = await Client.findClientContado();
          clientName.value = TextEditingValue(text: client?.name ?? '');
          rncOrId.value = TextEditingValue(text: client?.identification ?? '');
          isValid = true;

          if (enabledOnlySeller == false) {
            currentNcfTypeId = '32';
            currentCurrencyId = 1;
            currentPaymentMethodId = 1;
            currentPaymentModeId = 3;
            currentPaymentType = 1;
          }
        } else if (enabledOnlySeller) {
          currentNcfTypeId = '60';
          currentPrefix = 'C';
          currentPaymentMethodId = 4;
          currentPaymentType = 2;
          currentPaymentModeId = 2;
        } else {
          clientName.text = '';
          rncOrId.text = '';
          currentTypeIncomeId = '01';
          currentNcfTypeId = null;
          currentCurrencyId = 1;
          currentOverrideCode = 1;
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
        currentOverrideCode = 1;
        currentPaymentMethodId = null;
        currentPaymentType = null;
        currentPaymentModeId = null;
      }

      if (!isSale) {
        currentNcfTypeId = '34';
        currentOverrideCode = 1;
        currentPaymentMethodId = 1;
        currentPaymentType = 1;
        currentPaymentModeId = 3;
      }

      setState(() {
        if (isSale) {
          if (widget.mode == SaleMode.product) {
            widget.items = [SaleItemProduct()];
          }

          if (widget.mode == SaleMode.service) {
            widget.items = [SaleItemService()];
          }

          controllers = [
            List.generate(columns.length, (_) => TextEditingController())
          ];

          focusNodes = [List.generate(columns.length, (_) => FocusNode())];

          // mover foco a la nueva fila, primera columna
          x = widget.items.length - 1;
          y = 0;
          offsets[0] = x;
          offsets[1] = y;
          focusNodes[x][y].requestFocus();
          _focusKeyboard.requestFocus();
        } else {
          widget.items = [];
          controllers = [];
          focusNodes = [];
        }
      });

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
        _scrollController2.jumpTo(0);
      }
      if (_verticalScrollController.hasClients) {
        _verticalScrollController.jumpTo(0);
      }

      setState(() {});
    } catch (e) {
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _onSelectedNcf(String? option) async {
    ncfList = null;
    currentNcfTypeId = option;
    currentPrefix = 'E';
    maxSequence = 10;
    currentPaymentMethodId = 1;
    currentPaymentModeId = 3;
    currentPaymentType = 1;
    /* if (option == '60') {
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
    }*/

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
      for (int i = 0; i < widget.items.length; i++) {
        var item = widget.items[i];
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
              retentionIsrId: null,
              retentionIsr: 0,
              retentionTaxId: null,
              retentionTax: 0,
              indicadorFacturacion: item.indicadorFacturacion,
              exemptAmount: item.netFinal,
              total: item.total);
          widget.items[i] = newItem;
        }

        if (esEspecial || esMenor) {
          newItem = item.copyWith(
              serviceId: item.serviceId,
              productId: item.productId,
              tax: 0,
              tax16: 0,
              tax18: 0,
              tax3: 0,
              net: item.net,
              netFinal: item.netFinal,
              net16: 0,
              net18: 0,
              net3: 0,
              law10: item.law10,
              taxId: item.taxId,
              price: item.price,
              priceItem: item.priceItem,
              discount: item.discount,
              retentionIsrId: item.retentionIsrId,
              retentionIsr: item.retentionIsr,
              retentionTaxId: item.retentionTaxId,
              retentionTax: item.retentionTax,
              indicadorFacturacion: 4,
              exemptAmount: item.netFinal,
              total: item.total! - (item.tax ?? 0));
          widget.items[i] = newItem;
        } else {
          var type = item.taxId;
          double tax = 0;
          double tax16 = 0;
          double tax18 = 0;
          double net = 0;
          double net16 = 0;
          double net18 = 0;
          double discount = item.discount ?? 0;
          double netFinal = 0;
          double law10 = 0;
          double total = 0;
          double exemptAmount = 0;

          double priceAmount = item.priceItem! * (item.quantity ?? 1);

          double priceAmountx = priceAmount;
          int indicadorFacturacion = 1;

          if (type == 1) {
            indicadorFacturacion = 2;
            net = priceAmountx / 1.16;
            netFinal = net - discount;
            net16 = netFinal;
            tax16 = net16 * 0.16;
          }
          if (type == 2) {
            indicadorFacturacion = 1;
            net = priceAmountx / 1.18;
            netFinal = net - discount;
            net18 = netFinal;
            tax18 = net18 * 0.18;
          }

          if (type == null) {
            net = priceAmountx;
            netFinal = net - discount;
            tax16 = 0;
            net16 = 0;
            net18 = 0;
            tax18 = 0;
            indicadorFacturacion = 4;
            exemptAmount = netFinal;
          }
          tax = tax16 + tax18;
          law10 = item.law10 ?? 0;

          if (item.discountSymbol == '%') {
            discount = (item.discountRate! / 100) * priceAmountx;
          }

          if (item.discountSymbol == '\$') {
            discount = item.discountRate ?? 0;
          }

          if (item.law10 != null && item.law10! > 0) {
            law10 = netFinal * 0.10;
          }

          total = netFinal + tax + law10;

          newItem = item.copyWith(
              serviceId: item.serviceId,
              productId: item.productId,
              tax: tax,
              tax16: tax16,
              tax18: tax18,
              net: net,
              net16: net16,
              net18: net18,
              netFinal: netFinal,
              law10: law10,
              taxId: type,
              discount: item.discount,
              retentionTaxId: item.retentionTaxId,
              retentionTax: item.retentionTax,
              retentionIsrId: item.retentionIsrId,
              retentionIsr: item.retentionIsr,
              price: item.price,
              priceItem: item.priceItem,
              indicadorFacturacion: indicadorFacturacion,
              exemptAmount: exemptAmount,
              total: total);

          widget.items[i] = newItem;
        }
      }

      setState(() {
        widget.items = List.from(widget.items);
      });
    }
    try {
      if (currentNcfTypeId != null) {
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
              showTopSnackBar(context,
                  message: msg['error'], color: Colors.red);
            }
          }
        } else {
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

  void addRow() {
    setState(() {
      if (widget.sale is SaleProduct) {
        widget.items.add(SaleItemProduct(id: Uuid().v4(), quantity: 1.0));
      }
      if (widget.sale is SaleService) {
        widget.items.add(SaleItemService(id: Uuid().v4(), quantity: 1.0));
      }

      controllers
          .add(List.generate(columns.length, (_) => TextEditingController()));
      focusNodes.add(
          List.generate(columns.length, (_) => FocusNode(skipTraversal: true)));

      // mover foco a la nueva fila, primera columna
      x = widget.items.length - 1;
      y = 0;
      offsets[0] = x;
      offsets[1] = y;
      focusNodes[x][y].requestFocus();
    });
  }

void deleteRow(int rowIndex) {
  if (rowIndex > 0 && rowIndex < widget.items.length) {
    setState(() {
      widget.items.removeAt(rowIndex);

      if (rowIndex < controllers.length) {
        controllers[rowIndex].forEach((c) => c.dispose());
        controllers.removeAt(rowIndex);
      }

      if (rowIndex < focusNodes.length) {
        focusNodes[rowIndex].forEach((f) => f.dispose());
        focusNodes.removeAt(rowIndex);
      }

      x = (widget.items.isEmpty) ? -1 : min(rowIndex, widget.items.length - 1);

      offsets[0] = x;
      offsets[1] = y;

      if (x >= 0 && x < focusNodes.length &&
          y >= 0 && y < focusNodes[x].length) {
        focusNodes[x][y].requestFocus();
      }
    });
  }
}

  void cleanUnassignedRows() {
    if (widget.items.length == 1) return;
    setState(() {
      // Recorremos de atrás hacia adelante para evitar problemas de índice
      for (int i = widget.items.length - 1; i >= 0; i--) {
        var item = widget.items[i];

        // Validación: si no tiene serviceId ni productId
        if ((item.serviceId == null || item.serviceId == 0) &&
            (item.productId == null || item.productId == 0)) {
          widget.items.removeAt(i);
          controllers.removeAt(i);
          focusNodes.removeAt(i);
        }
      }

      // Ajustar índice actual (x) si quedó fuera de rango
      if (x >= widget.items.length) {
        x = widget.items.isEmpty ? 0 : widget.items.length - 1;
      }

      // Mantener columna actual
      offsets[0] = x;
      offsets[1] = y;

      // Reenfocar si aún hay elementos
      if (x >= 0 &&
          x < focusNodes.length &&
          y >= 0 &&
          y < focusNodes[x].length) {
        focusNodes[x][y].requestFocus();
      }
    });
  }

  Future<SaleElement?> _showElementSelector({required int rowIndex}) async {
    return await showDialog<SaleElement?>(
        context: context,
        builder: (ctx) => SaleElementSelectorWidget(mode: widget.mode));
  }

  Future<void> _onHandlerKeyboard(KeyEvent event) async {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        x = offsets[0];
        y = offsets[1];
        y = (y <= 0) ? columns.length - 1 : y - 1;
        offsets[1] = y;
        focusNodes[x][y].requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        x = offsets[0];
        y = offsets[1];
        y = (y >= columns.length - 1) ? 0 : y + 1;
        offsets[1] = y;
        focusNodes[x][y].requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        x = offsets[0];
        y = offsets[1];
        x = (x >= maxOffsetX) ? 0 : x + 1;
        offsets[0] = x;
        focusNodes[x][y].requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        x = offsets[0];
        y = offsets[1];
        x = (x <= 0) ? maxOffsetX : x - 1;
        offsets[0] = x;
        focusNodes[x][y].requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft) {
        addRow();
      } else if (event.logicalKey == LogicalKeyboardKey.delete) {
        deleteRow(offsets[0]); // usa x como fila actual
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        x = offsets[0];
        y = offsets[1];
        var c = controllers[x][0];
        if (y == 0) {
          y = (y + 3 >= columns.length) ? 0 : y + 3;

          if (c.text.isEmpty) {
            cleanUnassignedRows();
            _focusCommands.requestFocus();
            FocusScope.of(context).nextFocus();
          } else {
            focusNodes[x][y].requestFocus();
          }

          offsets[1] = y;
        } else if (y == 3 || y == 2 || y == 4) {
          addRow();
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.tab) {
        x = offsets[0];
        y = offsets[1];
        var c = controllers[x][0];
        if (y == 0) {
          if (c.text.isEmpty) {
            cleanUnassignedRows();
          }
        }
        _focusCommands.requestFocus();
      }

      if (event.logicalKey == LogicalKeyboardKey.f1 ||
          event.logicalKey == LogicalKeyboardKey.numpadSubtract ||
          (HardwareKeyboard.instance.logicalKeysPressed
                  .contains(LogicalKeyboardKey.controlLeft) &&
              event.logicalKey == LogicalKeyboardKey.minus)) {
        _reset();
      }

      if (event.logicalKey == LogicalKeyboardKey.f3 ||
          event.logicalKey == LogicalKeyboardKey.numpadAdd ||
          (HardwareKeyboard.instance.logicalKeysPressed
                  .contains(LogicalKeyboardKey.controlLeft) &&
              event.logicalKey == LogicalKeyboardKey.equal)) {
        x = offsets[0];
        y = offsets[1];

        var c1 = controllers[x][0];
        if (y == 0) {
          var el = await _showElementSelector(rowIndex: x);

          if (el != null) {
            c1.text = el.code ?? '';

            _calcRows(rowIndex: x, element: el);
          }
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.f8) {
        await Navigator.push(
            context, MaterialPageRoute(builder: (ctx) => CotizationsPage()));
      }

      if (event.logicalKey == LogicalKeyboardKey.f11) {
        currentNcfTypeId = '32';
        _onSelectedNcf(currentNcfTypeId);
      }

      if (event.logicalKey == LogicalKeyboardKey.f12) {
        currentNcfTypeId = '60';
        _onSelectedNcf(currentNcfTypeId);
      }
    }
  }

  Future<void> _initAsync() async {
    if (widget.editing == false) {
      if (widget.generateNcfFromProforma == false) {
        if (isSale) {
          if (enabledPosAutomaticSetup || enabledOnlySeller) {
            client = await Client.findClientContado();
            clientName.value = TextEditingValue(text: client?.name ?? '');
            rncOrId.value =
                TextEditingValue(text: client?.identification ?? '');
            isValid = true;
          }
        }
      }
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

  @override
  void initState() {
    if (!mounted) return;
    var now = DateTime.now();
    var dateLocal = now;

    createdAt = now;

    paymentDateController.text =
        paymentDate?.format(payload: 'DD/MM/YYYY') ?? '';
    _ncfs = [...ncfs];

    if (isSale) {
      _ncfs.removeWhere((e) => e.id == '34' || e.id == '04');
    } else {
      _ncfs.removeWhere((e) =>
          e.id == '01' ||
          e.id == '02' ||
          e.id == '15' ||
          e.id == '31' ||
          e.id == '32' ||
          e.id == '45' ||
          e.id == '44' ||
          e.id == '50' ||
          e.id == '43' ||
          e.id == '41' ||
          e.id == '60');
      currentNcfTypeId = '34';
      currentPrefix = 'E';
      maxSequence = 10;
    }

    if (esNotaCredito == false &&
        widget.editing == false &&
        widget.generateNcfFromProforma == false) {
      controllers
          .add(List.generate(columns.length, (_) => TextEditingController()));
      focusNodes.add(
          List.generate(columns.length, (_) => FocusNode(skipTraversal: true)));

      // mover foco a la nueva fila, primera columna
      x = widget.items.length - 1;
      y = 0;
      offsets[0] = x;
      offsets[1] = y;
      focusNodes[x][y].requestFocus();
    }

    if (widget.generateNcfFromProforma == true) {
      _ncfs.removeWhere((e) => e.id == '60' || e.id == '50');
    }

    if (widget.editing || widget.generateNcfFromProforma) {
      currentCurrencyId = widget.sale.currencyId;
      rate.text = widget.sale.rate?.toStringAsFixed(2) ?? '';
      client = Client(
          id: widget.sale.clientId,
          identification: widget.sale.clientIdentification,
          name: widget.sale.clientName);

      rncOrId.text = widget.sale.clientIdentification ?? '';
      clientName.text = widget.sale.clientName ?? '';
      currentNcfTypeId = widget.sale.ncfTypeId;
      controllers = [];
      focusNodes = [];
      List.generate(widget.items.length, (index) {
        var e = widget.items[index];

        controllers
            .add(List.generate(columns.length, (i) => TextEditingController()));
        focusNodes.add(List.generate(
            columns.length, (i) => FocusNode(skipTraversal: true)));
        var c0 = controllers[index][0];
        var c1 = controllers[index][1];
        var c2 = controllers[index][2];
        var c3 = controllers[index][3];
        var c4 = controllers[index][4];
        var c5 = controllers[index][5];
        var c6 = controllers[index][6];

        c0.text = e.productCode ?? e.serviceCode ?? '';
        c1.text = e.productName ?? e.serviceName ?? '';
        c2.text = e.quantity?.toStringAsFixed(2) ?? '';
        c3.text = e.priceItem?.toStringAsFixed(2) ?? '';
        c4.text = e.discount?.toStringAsFixed(2) ?? '';
        c5.text = e.tax?.toStringAsFixed(2) ?? '';
        c6.text = e.total?.toStringAsFixed(2) ?? '';
      });
    }

    if (!widget.generateNcfFromProforma) {
      createdAt = widget.sale.createdAt ?? dateLocal;
    } else {
      createdAt = dateLocal;

      isValid = true;

      if (widget.editing == false) {
        if (enabledPosAutomaticSetup) {
          currentNcfTypeId = '32';
        }
      }
      currentCurrencyId = widget.sale.currencyId ?? 1;
      currentTypeIncomeId = widget.sale.typeIncomeId;
      description.text = widget.sale.description ?? '';
    }

    issueDate = widget.sale.createdAt ?? createdAt;

    issueDateController.value =
        TextEditingValue(text: issueDate.format(payload: 'DD/MM/YYYY'));

    fechaVencimientoController.value =
        TextEditingValue(text: fechaVencimiento.format(payload: 'DD/MM/YYYY'));

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

    if (widget.editing == false && isSale) {
      if (widget.generateNcfFromProforma == false) {
        if (enabledOnlySeller) {
          _ncfs.removeWhere((e) =>
              e.id == '01' ||
              e.id == '02' ||
              e.id == '04' ||
              e.id == '15' ||
              e.id == '31' ||
              e.id == '32' ||
              e.id == '34' ||
              e.id == '45' ||
              e.id == '44' ||
              e.id == '50' ||
              e.id == '43' ||
              e.id == '41');

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

  double get montoAPagarReferencia {
    return (_calc['paidAmount'] ?? 0);
  }

  double get totalFacturado {
    return (_calc['total'] ?? 0) * xrate;
  }

  double get itbisGravado {
    return (_calc['itbisGravado'] ?? 0) * xrate;
  }

  double get itbisGravado18 {
    return (_calc['tax18'] ?? 0) * xrate;
  }

  double get itbisGravado16 {
    return (_calc['tax16'] ?? 0) * xrate;
  }

  double get itbisGravado3 {
    return (_calc['tax3'] ?? 0) * xrate;
  }

  double get law10Calc {
    return (_calc['law10'] ?? 0) * xrate;
  }

  double get totalGravado {
    return (_calc['totalGravado'] ?? 0) * xrate;
  }

  double get totalGravado18 {
    return (_calc['net18'] ?? 0) * xrate;
  }

  double get totalGravado16 {
    return (_calc['net16'] ?? 0) * xrate;
  }

  double get totalGravado3 {
    return (_calc['net3'] ?? 0) * xrate;
  }

  double get totalRetencionIsr {
    return (_calc['retentionIsr'] ?? 0) * xrate;
  }

  double get totalRetencionItbis {
    return (_calc['retentionTax'] ?? 0) * xrate;
  }

  double get montoExento {
    return (_calc['exemptAmount'] ?? 0) * xrate;
  }

  String get labelTag {
    if (widget.editing) {
      if (widget.sale.ncf != null) {
        return '${widget.sale.ncf} - EDITANDO';
      } else {
        return 'EDITANDO';
      }
    }

    return 'FACTURANDO';
  }

  String get title {
    if (widget.sale is SaleService) {
      return '$labelTag SERVICIO...';
    }
    if (widget.sale is SaleProduct) {
      return '$labelTag PRODUCTO...';
    }

    if (widget.sale is CreditNoteAsService) {
      return '${_currentSale?.ncf ?? ''} $labelTag NOTA DE CREDITO - SERVICIO';
    }
    if (widget.sale is CreditNoteAsProduct) {
      return '${_currentSale?.ncf ?? ''} $labelTag NOTA DE CREDITO - PRODUCTO';
    }
    return '';
  }

  _handlerCommands(KeyEvent event) async {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.controlLeft)) {
        if (_formKey.currentState!.validate()) {
          _onSubmit();
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.f1) {
        _reset();
      }

      if (event.logicalKey == LogicalKeyboardKey.f8) {
        await Navigator.push(
            context, MaterialPageRoute(builder: (ctx) => CotizationsPage()));
      }

      if (event.logicalKey == LogicalKeyboardKey.f11) {
        currentNcfTypeId = '32';
        _onSelectedNcf(currentNcfTypeId);
      }

      if (event.logicalKey == LogicalKeyboardKey.f12) {
        currentNcfTypeId = '60';
        _onSelectedNcf(currentNcfTypeId);
      }
    }
  }

  String get amountString {
    if (currentCurrencyId == 1) {
      return amountInputFormatter.doubleValue.toDop();
    }
    return amountInputFormatter.doubleValue.toUS();
  }

  _preConfirm() async {
    if (_formKey.currentState!.validate()) {
      var completed = amountInputFormatter.doubleValue == 0 &&
          (currentNcfTypeId != '60' && currentNcfTypeId != '50');

      if (completed) {
        amount.value = amountInputFormatter.formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: montoAPagarReferencia.toStringAsFixed(2)));
      }
      var res = await showPreConfirmInvoice(
          context: context,
          amountPaid: totalString,
          paid: amountString,
          debt: debt,
          debtString: debtString);

      if (res == true) {
        _onSubmit(completed: completed);
      }
    }
  }

  _onSubmit({bool completed = false}) async {
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

        if (widget.items.isEmpty) throw 'DEBES AGREGAR AL MENOS UN ARTICULO';

        var now = DateTime.now();

        createdAt = now;

        widget.sale.ncfTypeId = currentNcfTypeId;
        widget.sale.items = widget.items;
        widget.sale.net = _calc['net'];
        widget.sale.discount = _calc['discount'];
        widget.sale.tax = _calc['tax'];
        widget.sale.total = _calc['total'];
        widget.sale.retentionIsr = _calc['retentionIsr'];
        widget.sale.retentionTax = _calc['retentionTax'];
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
        widget.sale.rate = xrate;
        widget.sale.net18 = _calc['net18'];
        widget.sale.net16 = _calc['net16'];
        widget.sale.net3 = _calc['net3'];
        widget.sale.tax18 = _calc['tax18'];
        widget.sale.tax16 = _calc['tax16'];
        widget.sale.tax3 = _calc['tax3'];
        widget.sale.law10 = _calc['law10'];
        widget.sale.exemptAmount = _calc['exemptAmount'];
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

        if (currentPaymentModeId == 1 || completed) {
          amountx = montoAPagarReferencia;
          amount = montoAPagarReferencia;
        }

        if (currentPaymentModeId == 2) {
          amountx = 0;
          amount = 0;
        }

        if(currentNcfTypeId == '60' ||  currentNcfTypeId == '50'){
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

        widget.items = widget.items.where((e) => e.enabled == true).toList();
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

        if (widget.generateNcfFromProforma || widget.editing) {
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
        await LogHandler.printEvent(e.toString());
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  Map<String, double> get _calc {
    double net = 0;
    double net16 = 0;
    double net18 = 0;
    double net3 = 0;
    double totalGravado = 0;
    double discount = 0;
    double subtotal = 0;
    double tax = 0;
    double tax16 = 0;
    double tax18 = 0;
    double tax3 = 0;
    double itbisGravado = 0;
    double total = 0;
    double law10 = 0;
    double exemptAmount = 0;
    double retentionIsr = 0;
    double retentionTax = 0;
    for (int i = 0; i < widget.items.length; i++) {
      var row = widget.items[i];
      net += row.net ?? 0;
      net16 += row.net16 ?? 0;
      net18 += row.net18 ?? 0;
      net3 += row.net3 ?? 0;
      discount += row.discount ?? 0;
      subtotal += row.netFinal ?? 0;
      tax += row.tax ?? 0;
      tax16 += row.tax16 ?? 0;
      tax18 += row.tax18 ?? 0;
      tax3 += row.tax3 ?? 0;
      total += row.total ?? 0;
      exemptAmount += row.exemptAmount ?? 0;
      law10 += row.law10 ?? 0;
      retentionIsr += row.retentionIsr ?? 0;
      retentionTax += row.retentionTax ?? 0;
    }
    double retentions = retentionTax + retentionIsr;

    totalGravado = net16 + net18 + net3;
    itbisGravado = tax16 + tax18 + tax3;
    double totalPaid = total - (retentions);

    return {
      'net': net,
      'net16': net16,
      'net18': net18,
      'net3': net3,
      'discount': discount,
      'subtotal': subtotal,
      'tax': tax,
      'tax16': tax16,
      'tax18': tax18,
      'tax3': tax3,
      'exemptAmount': exemptAmount,
      'law10': law10,
      'total': total,
      'retentionIsr': retentionIsr,
      'retentionTax': retentionTax,
      'paidAmount': totalPaid,
      'totalGravado': totalGravado,
      'itbisGravado': itbisGravado
    };
  }

  String get totalString {
    if (currentCurrencyId == 1) {
      return _calc['total']?.toDop();
    }
    return _calc['total']?.toUS();
  }

  String get totalPaidString {
    if (currentCurrencyId == 1) {
      return _calc['paidAmount']?.toDop();
    }
    return _calc['paidAmount']?.toUS();
  }

  String get law10String {
    if (currentCurrencyId == 1) {
      return _calc['law10']?.toDop();
    }
    return _calc['law10']?.toUS();
  }

  String get taxString {
    if (currentCurrencyId == 1) {
      return _calc['tax']?.toDop();
    }
    return _calc['tax']?.toUS();
  }

  String get subtotalString {
    if (currentCurrencyId == 1) {
      return _calc['subtotal']?.toDop();
    }
    return _calc['subtotal']?.toUS();
  }

  String get discountString {
    if (currentCurrencyId == 1) {
      return _calc['discount']?.toDop();
    }
    return _calc['discount']?.toUS();
  }

  String get netString {
    if (currentCurrencyId == 1) {
      return _calc['net']?.toDop();
    }
    return _calc['net']?.toUS();
  }

  double get debt {
    if (esNotaCredito && _currentSale != null) {
      return _currentSale!.amountPaid! - creditNoteTotal;
    }
    if (widget.sale.amountPaid != null && widget.editing) {
      return (widget.sale.debt! - (amountInputFormatter.doubleValue));
    }

    return (paidAmount - (amountInputFormatter.doubleValue));
  }

  String get debtString {
    if (currentCurrencyId == 2) {
      return (debt).abs().toUS();
    }
    return debt.abs().toDop();
  }

  double get paidAmount {
    return double.parse(_calc['paidAmount']?.toStringAsFixed(2) ?? '0.00');
  }

  _calcRows(
      {int rowIndex = 0,
      SaleElement? element,
      double quantity = 1.0,
      bool enabledRender = true}) {
    var code = controllers[rowIndex][0];
    var description = controllers[rowIndex][1];
    var count = controllers[rowIndex][2];
    var priceController = controllers[rowIndex][3];
    var discountController = controllers[rowIndex][4];
    var taxController = controllers[rowIndex][5];
    var totalController = controllers[rowIndex][6];

    var item = widget.items[rowIndex];
    SaleElement? xelement = element;
    int? taxId = xelement?.taxId;

    var y1 = offsets[1];

    if (code.text.isEmpty) {
      discountController.clear();
    }

    if (y1 > 0) {
      if (element == null) {
        if (widget.mode == SaleMode.service) {
          xelement = Services(
              id: item.serviceId, price: item.price, taxId: item.taxId);
        }

        if (widget.mode == SaleMode.product) {
          xelement = Products(
              id: item.productId, price: item.price, taxId: item.taxId);
        }
      }
    }

    double xquantity = double.tryParse(count.text) ?? quantity;

    double price =
        xelement?.price ?? double.tryParse(priceController.text) ?? 0;

    double priceAmountx = price * xquantity;
    double net = price;
    double netFinal = 0;
    double net16 = 0;
    double net18 = 0;
    double net3 = 0;
    double tax = 0;
    double tax16 = 0;
    double tax18 = 0;
    double tax3 = 0;
    double total = 0;
    double exemptAmount = 0;

    double discount = double.tryParse(discountController.text) ?? 0;
    double law10 = 0;
    int indicadorFacturacion = 1;
    double? rate;
    String? discountSymbol;
    String? discountName;

    int? discountId = xelement?.discountId ?? item.discountId;

    if (discount > 0) {
      rate = null;
      discountId = null;
      discountSymbol = '\$';
      discountName = 'DESCUENTO ${discount.toStringAsFixed(2)} PESOS';
    }

    if (esNotaCredito) {
      if (currentOverrideCode == 3) {
        discount = 0;
        discountSymbol = null;
        discountName = null;
      } else if (currentOverrideCode == 1) {
        rate = null;
        discountSymbol = '\$';
        discountName = 'DESCUENTO ${discount.toStringAsFixed(2)} PESOS';
      }
    }

    if (taxId == null) {
      net = priceAmountx;
      if (discountId != null) {
        var d = 0.0;
        if (xelement?.discountSymbol == '%') {
          d = (xelement?.discountRate ?? 0) / 100;
          discount = d * net;
        } else {
          d = xelement?.discountRate ?? 0;
          discount = d;
        }
      }
      netFinal = net - discount;
      tax = 0;
      tax16 = 0;
      tax18 = 0;
      tax3 = 0;
      net16 = 0;
      net18 = 0;
      net3 = 0;
      exemptAmount = netFinal;
      indicadorFacturacion = 4;
    }
    if (taxId == 1) {
      net = priceAmountx / 1.16;
      if (discountId != null) {
        var d = 0.0;
        if (xelement?.discountSymbol == '%') {
          d = (xelement?.discountRate ?? 0) / 100;
          discount = d * net;
        } else {
          d = xelement?.discountRate ?? 0;
          discount = d;
        }
      }
      netFinal = net - discount;
      tax = netFinal * 0.16;
      tax16 = tax;
      tax18 = 0;
      tax3 = 0;
      net16 = netFinal;
      indicadorFacturacion = 2;
    }

    if (taxId == 2) {
      net = priceAmountx / 1.18;
      if (discountId != null) {
        var d = 0.0;
        if (xelement?.discountSymbol == '%') {
          d = (xelement?.discountRate ?? 0) / 100;
          discount = d * net;
        } else {
          d = xelement?.discountRate ?? 0;
          discount = d;
        }
      }
      netFinal = net - discount;
      tax = netFinal * 0.18;
      tax16 = 0;
      tax18 = tax;
      tax3 = 0;
      net18 = netFinal;
      indicadorFacturacion = 1;
    }

    if (esEspecial || esMenor) {
      tax = 0;
      tax16 = 0;
      tax18 = 0;
      tax3 = 0;
      net16 = 0;
      net18 = 0;
      net3 = 0;
      indicadorFacturacion = 4;
      exemptAmount = netFinal;
    }

    if (canOverrideTaxes) {
      indicadorFacturacion = 3;
      net18 = 0;
      net16 = 0;
      net3 = netFinal;
      tax = 0;
      tax16 = 0;
      tax18 = 0;
      tax3 = tax;
      exemptAmount = 0;
    }

    if (currentLawMode == 2) {
      law10 = netFinal * 0.10;
    }

    total = netFinal + tax + law10;

    if (enabledRender) {
      description.text = element?.name ?? '';
      count.text = xquantity.toStringAsFixed(2);
    }

    var y = offsets[1];

    if (y == 2) {
      discountController.text = discount.toStringAsFixed(2);
    }

    var newItem = item.copyWith(
        quantity: xquantity,
        indicadorFacturacion: indicadorFacturacion,
        productId: xelement?.id,
        serviceId: xelement?.id,
        productName: description.text,
        serviceName: description.text,
        price: price,
        priceItem: price,
        net: net,
        net16: net16,
        net18: net18,
        net3: net3,
        discountId: discountId,
        discount: discount,
        discountRate: rate,
        discountName: discountName,
        discountSymbol: discountSymbol,
        netFinal: netFinal,
        tax: tax,
        tax16: tax16,
        tax18: tax18,
        tax3: tax3,
        taxId: xelement?.taxId,
        exemptAmount: exemptAmount,
        law10: law10,
        unitCode: xelement?.unitCode,
        unitName: xelement?.unitName,
        unitSymbol: xelement?.unitSymbol,
        conversionFactor: xelement?.conversionFactor,
        chassis: xelement?.chassis,
        licensePlate: xelement?.licensePlate,
        colorName: xelement?.colorName,
        editable: xelement?.editable,
        total: total);

    widget.items[rowIndex] = newItem;

    if (enabledRender) {
      priceController.text = xelement?.price?.toStringAsFixed(2) ?? '';
    }

    taxController.text = tax.toStringAsFixed(2);

    if (discountId != null && y != 4) {
      discountController.text = discount.toStringAsFixed(2);
    }

    totalController.text = total.toStringAsFixed(2);

    setState(() {});
  }

  _onHandlerCode(String code, int rowIndex) async {


    var count = controllers[rowIndex][2];
    var price = controllers[rowIndex][3];
    SaleElement? element;
    try {
   

      count.text = '1.00';

      if (code.length >= 3) {
        if (widget.mode == SaleMode.product) {
          element = await Products.findByCode(code: code.trim());
        }
        if (widget.mode == SaleMode.service) {
          element = await Services.findByCode(code: code.trim());
        }
      } else {
        element = null;
        price.text = '';
      }
    } catch (e) {
      element = null;
      price.text = '';
    } finally {
      _calcRows(rowIndex: rowIndex, element: element);
    }
  }

  _scanInvoice() async {
    setState(() {
      rncOrId.value = TextEditingValue.empty;
      widget.items = [];
    });
    var res = await showDialog(
        context: context,
        builder: (ctx) => NcfsSelectorModal(saleMode: widget.mode));

    if (res is Sale) {
      _currentSale = res;

      retentionDate = res.retentionDate;

      retentionDateController.value = TextEditingValue(
        text: retentionDate?.format(payload: 'DD/MM/YYYY') ?? '',
      );

      creditNoteTotal = await getCreditNoteAmountByNcf(
          saleId: _currentSale!.id!,
          ncfAffected: _currentSale?.ncf ?? '',
          ncfAffectedCreatedAt: _currentSale!.createdAt!);

      widget.sale.saleId = res.id;
      widget.sale.typeIncomeId = res.typeIncomeId;
      widget.sale.clientType = res.clientType;
      widget.sale.invoiceTypeId = res.invoiceTypeId;
      currentTypeIncomeId = res.typeIncomeId;
      widget.sale.clientId = res.clientId;
      widget.sale.clientIdentification = res.clientIdentification;
      widget.sale.effective = res.effective;
      widget.sale.creditCard = res.creditCard;
      widget.sale.checkOrTransf = res.checkOrTransf;
      widget.sale.saleToCredit = res.saleToCredit;
      widget.sale.description = res.description;
      widget.sale.amountPaid = res.amountPaid;
      widget.sale.ncf = res.ncf;
      widget.sale.createdAt = res.createdAt;
      widget.sale.expirationDate = res.expirationDate;

      client = Client(id: widget.sale.clientId, name: widget.sale.clientName);

      currentCurrencyId = _currentSale?.currencyId ?? 1;

      currentPaymentType = 1;

      if (_currentSale?.rate != null) {
        rate.value = TextEditingValue(
            text: _currentSale?.rate?.toStringAsFixed(2) ?? '');
      }

      rncOrId.value = TextEditingValue(
          text: res.clientIdentification?.replaceAll('-', '') ?? '');

      var items = await res.getSaleData();
      items = List.generate(items.length, (index) {
        var e = items[index];
        e.enabled = true;

        controllers
            .add(List.generate(columns.length, (i) => TextEditingController()));
        focusNodes.add(List.generate(
            columns.length, (i) => FocusNode(skipTraversal: true)));
        var c0 = controllers[index][0];
        var c1 = controllers[index][1];
        var c2 = controllers[index][2];
        var c3 = controllers[index][3];
        var c4 = controllers[index][4];
        var c5 = controllers[index][5];
        var c6 = controllers[index][6];

        c0.text = e.productCode ?? e.serviceCode ?? '';
        c1.text = e.productName ?? e.serviceName ?? '';
        c2.text = e.quantity?.toStringAsFixed(2) ?? '';
        c3.text = e.priceItem?.toStringAsFixed(2) ?? '';
        c4.text = e.discount?.toStringAsFixed(2) ?? '';
        c5.text = e.tax?.toStringAsFixed(2) ?? '';
        c6.text = e.total?.toStringAsFixed(2) ?? '';

        return e is SaleItemService
            ? CreditNoteService(
                id: e.id,
                serviceCode: e.serviceCode,
                serviceId: e.serviceId,
                serviceName: e.serviceName,
                saleId: e.saleId,
                productId: e.productId,
                productName: e.productName,
                discount: e.discount,
                discountId: e.discountId,
                discountName: e.discountName,
                discountSymbol: e.discountSymbol,
                discountRate: e.discountRate,
                price: e.price,
                net: e.net,
                taxId: e.taxId,
                tax: canOverrideTaxes ? 0 : e.tax,
                total: canOverrideTaxes ? e.netFinal : e.total,
                retentionIsr: e.retentionIsr,
                retentionTax: e.retentionTax,
                retentionTaxId: e.retentionTaxId,
                retentionIsrId: e.retentionIsrId,
                enabled: e.enabled,
                chassis: e.chassis,
                licensePlate: e.licensePlate,
                creditNoteId: e.creditNoteId,
                quantity: e.quantity,
                returnQuantity: e.returnQuantity,
                tax18: canOverrideTaxes ? 0 : e.tax18,
                tax16: canOverrideTaxes ? 0 : e.tax16,
                tax3: canOverrideTaxes ? 0 : e.tax3,
                net18: canOverrideTaxes ? 0 : e.net18,
                net16: canOverrideTaxes ? 0 : e.net16,
                net3: canOverrideTaxes ? e.netFinal : e.net3,
                netFinal: e.netFinal,
                exemptAmount: canOverrideTaxes ? 0 : e.exemptAmount,
                indicadorFacturacion:
                    canOverrideTaxes ? 3 : e.indicadorFacturacion,
                indicadorAgentePercepcion: e.indicadorAgentePercepcion,
                law10: e.law10,
                priceItem: e.priceItem,
                unitSuite: e.unitSuite,
                clientSuite: e.clientSuite,
                priceSuite: e.priceSuite,
                maxDiscount: e.maxDiscount)
            : CreditNoteProduct(
                id: e.id,
                productCode: e.productCode,
                serviceId: e.serviceId,
                saleId: e.saleId,
                productId: e.productId,
                productName: e.productName,
                discount: e.discount,
                discountId: e.discountId,
                discountName: e.discountName,
                discountSymbol: e.discountSymbol,
                discountRate: e.discountRate,
                price: e.price,
                net: e.net,
                taxId: e.taxId,
                tax: canOverrideTaxes ? 0 : e.tax,
                total: canOverrideTaxes ? e.netFinal : e.total,
                retentionIsr: e.retentionIsr,
                retentionTax: e.retentionTax,
                retentionTaxId: e.retentionTaxId,
                retentionIsrId: e.retentionIsrId,
                enabled: e.enabled,
                chassis: e.chassis,
                licensePlate: e.licensePlate,
                colorName: e.colorName,
                creditNoteId: e.creditNoteId,
                quantity: e.quantity,
                returnQuantity: e.returnQuantity,
                tax18: canOverrideTaxes ? 0 : e.tax18,
                tax16: canOverrideTaxes ? 0 : e.tax16,
                tax3: canOverrideTaxes ? 0 : e.tax3,
                net18: canOverrideTaxes ? 0 : e.net18,
                net16: canOverrideTaxes ? 0 : e.net16,
                net3: canOverrideTaxes ? e.netFinal : e.net3,
                netFinal: e.netFinal,
                exemptAmount: canOverrideTaxes ? 0 : e.exemptAmount,
                indicadorFacturacion:
                    canOverrideTaxes ? 3 : e.indicadorFacturacion,
                indicadorAgentePercepcion: e.indicadorAgentePercepcion,
                conversionFactor: e.conversionFactor,
                unitCode: e.unitCode,
                unitName: e.unitName,
                unitSymbol: e.unitSymbol,
                units: e.units,
                law10: e.law10,
                priceItem: e.priceItem,
                maxDiscount: e.maxDiscount);
      });

      widget.items = items;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var w = size.width;
    var h = size.height;
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          toolbarHeight: kToolbarHeight + kDefaultPadding,
          actions: [

          Container(
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(
              right: kDefaultPadding
            ),
            child:Text(currentUser?.name ?? '',style: TextStyle(
              color: Colors.white
            ),)
          ),
            esNotaCredito
                ? ToolButtonWidget(
                    icon: Icons.document_scanner_outlined, onTap: _scanInvoice)
                : SizedBox(),
            ToolButtonWidget(icon: Icons.restore, onTap: _reset),
            ToolButtonWidget(
                icon: Icons.close,
                onTap: () {
                  Navigator.pop(context);
                }),
          ],
        ),
        body: SizedBox(
            width: w,
            height: h,
            child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 2,
                        child: KeyboardListener(
                            focusNode: _focusKeyboard,
                            onKeyEvent:
                                widget.editing || widget.generateNcfFromProforma
                                    ? null
                                    : _onHandlerKeyboard,
                            child: Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height,
                              alignment: Alignment.topCenter,
                              color: const Color.fromARGB(255, 243, 241, 241),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: Colors.black38))),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ...List.generate(columns.length,
                                            (index) {
                                          var col = columns[index];
                                          return Expanded(
                                              flex: index == 1 ? 2 : 1,
                                              child: Container(
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.all(
                                                    kDefaultPadding / 2),
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF6F5F5),
                                                    border: Border(
                                                        right: BorderSide(
                                                            color: Colors
                                                                .black38))),
                                                child: Text(
                                                  col,
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                ),
                                              ));
                                        }),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                      child: SingleChildScrollView(
                                    clipBehavior: Clip.hardEdge,
                                    child: Column(
                                      children: [
                                        ...List.generate(widget.items.length,
                                            (index) {
                                          var row = widget.items[index];
                                          var c1 = controllers[index][0];
                                          var c2 = controllers[index][1];
                                          var c3 = controllers[index][2];
                                          var c4 = controllers[index][3];
                                          var c5 = controllers[index][4];
                                          var c6 = controllers[index][5];
                                          var c7 = controllers[index][6];
                                          var f1 = focusNodes[index][0];
                                          var f2 = focusNodes[index][1];
                                          var f3 = focusNodes[index][2];
                                          var f4 = focusNodes[index][3];
                                          var f5 = focusNodes[index][4];
                                          var f6 = focusNodes[index][5];
                                          var f7 = focusNodes[index][6];

                                          return Container(
                                            key: ValueKey(row.id),
                                            width: double.infinity,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                border: Border(
                                                    bottom: BorderSide(
                                                        color:
                                                            Colors.black38))),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(
                                                    child: TextFormField(
                                                  controller: c1,
                                                  focusNode: f1,
                                                  readOnly: esNotaCredito ||
                                                      widget
                                                          .generateNcfFromProforma ||
                                                      widget.editing,
                                                  onTap: () {
                                                    x = index;
                                                    y = 0;
                                                    offsets[0] = x;
                                                    offsets[1] = y;
                                                  },
                                                  onChanged: (code) =>
                                                      _onHandlerCode(
                                                          code, index),
                                                  textInputAction:
                                                      TextInputAction.none,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(
                                                      RegExp(r'[a-zA-Z0-9]'),
                                                    )
                                                  ],
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      hintText: '0000000000',
                                                      error: row.serviceId ==
                                                                  null &&
                                                              row.productId ==
                                                                  null
                                                          ? SizedBox()
                                                          : null,
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                219, 217, 217),
                                                            width: 0.5),
                                                      ),
                                                      border: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: const Color
                                                                  .fromARGB(
                                                                  255,
                                                                  219,
                                                                  217,
                                                                  217),
                                                              width: 0.5),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .zero)),
                                                )),
                                                Expanded(
                                                    flex: 2,
                                                    child: TextFormField(
                                                      controller: c2,
                                                      focusNode: f2,
                                                      onChanged: (val){
                                                        row.serviceName = val.isEmpty ? null : val;
                                                        row.productName = val.isEmpty ? null : val;
                                                      },
                                                      readOnly: esNotaCredito ||
                                                          widget
                                                              .generateNcfFromProforma ||
                                                          widget.editing,
                                                      onTap: () {
                                                        x = index;
                                                        y = 1;
                                                        offsets[0] = x;
                                                        offsets[1] = y;
                                                      },
                                                      textInputAction:
                                                          TextInputAction.none,
                                                      keyboardType:
                                                          TextInputType.text,
                                                      decoration:
                                                          InputDecoration(
                                                              filled: true,
                                                              fillColor:
                                                                  Colors.white,
                                                              hintText:
                                                                  'Escribir algo...',
                                                              enabledBorder:
                                                                  OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        219,
                                                                        217,
                                                                        217),
                                                                    width: 0.5),
                                                              ),
                                                              border: OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          width:
                                                                              0.5),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .zero)),
                                                    )),
                                                Expanded(
                                                    child: TextFormField(
                                                  controller: c3,
                                                  focusNode: f3,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'^\d*\.?\d{0,2}$'))
                                                  ],
                                                  readOnly: (esNotaCredito &&
                                                          currentOverrideCode ==
                                                              1) ||
                                                      widget
                                                          .generateNcfFromProforma ||
                                                      widget.editing,
                                                  onTap: () {
                                                    x = index;
                                                    y = 2;
                                                    offsets[0] = x;
                                                    offsets[1] = y;
                                                  },
                                                  onChanged: (count) {
                                                    var price =
                                                        double.parse(c4.text);
                                                    double quantity =
                                                        double.parse(
                                                            count.isEmpty
                                                                ? '0.00'
                                                                : count);

                                                    SaleElement? element;
                                                    if (widget.mode ==
                                                        SaleMode.product) {
                                                      element = Products(
                                                          id: row.productId,
                                                          price: price,
                                                          taxId: row.taxId,
                                                          name: row.productName,
                                                          editable:
                                                              row.editable);
                                                    }
                                                    if (widget.mode ==
                                                        SaleMode.service) {
                                                      element = Services(
                                                          id: row.serviceId,
                                                          price: price,
                                                          taxId: row.taxId,
                                                          name: row.serviceName,
                                                          editable:
                                                              row.editable);
                                                    }

                                                    _calcRows(
                                                      rowIndex: index,
                                                      element: element,
                                                      quantity: quantity,
                                                      enabledRender: false,
                                                    );
                                                  },
                                                  textInputAction:
                                                      TextInputAction.none,
                                                  decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      hintText: '0.00',
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                219, 217, 217),
                                                            width: 0.5),
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                      width:
                                                                          0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero)),
                                                )),
                                                Expanded(
                                                    child: TextFormField(
                                                  controller: c4,
                                                  focusNode: f4,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'^\d*\.?\d{0,2}$'))
                                                  ],
                                                  readOnly: esNotaCredito ||
                                                      widget
                                                          .generateNcfFromProforma ||
                                                      widget.editing ||
                                                      row.editable == false,
                                                  onTap: () {
                                                    x = index;
                                                    y = 3;
                                                    offsets[0] = x;
                                                    offsets[1] = y;
                                                  },
                                                  onChanged: (val) {
                                                    var price = double.parse(
                                                        val.isEmpty
                                                            ? '0.00'
                                                            : val);

                                                    double quantity =
                                                        row.quantity ?? 0;

                                                    SaleElement? element;
                                                    if (widget.mode ==
                                                        SaleMode.product) {
                                                      element = Products(
                                                          id: row.productId,
                                                          price: price,
                                                          taxId: row.taxId,
                                                          name: row.productName,
                                                          editable:
                                                              row.editable);
                                                    }
                                                    if (widget.mode ==
                                                        SaleMode.service) {
                                                      element = Services(
                                                          id: row.serviceId,
                                                          price: price,
                                                          taxId: row.taxId,
                                                          name: row.serviceName,
                                                          editable:
                                                              row.editable);
                                                    }

                                                    _calcRows(
                                                      rowIndex: index,
                                                      element: element,
                                                      quantity: quantity,
                                                      enabledRender: false,
                                                    );
                                                  },
                                                  textInputAction:
                                                      TextInputAction.none,
                                                  keyboardType:
                                                      TextInputType.text,
                                                  decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      hintText: '0.00',
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                219, 217, 217),
                                                            width: 0.5),
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                      width:
                                                                          0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero)),
                                                )),
                                                Expanded(
                                                    child: TextFormField(
                                                  controller: c5,
                                                  focusNode: f5,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'^\d*\.?\d{0,2}$'))
                                                  ],
                                                  readOnly: esNotaCredito ||
                                                      widget
                                                          .generateNcfFromProforma ||
                                                      widget.editing,
                                                  onTap: () {
                                                    x = index;
                                                    y = 4;
                                                    offsets[0] = x;
                                                    offsets[1] = y;
                                                  },
                                                  onChanged: (val) {
                                                    double quantity =
                                                        row.quantity ?? 0;

                                                    SaleElement? element;
                                                    if (widget.mode ==
                                                        SaleMode.product) {
                                                      element = Products(
                                                          id: row.productId,
                                                          price: row.price,
                                                          taxId: row.taxId,
                                                          name: row.productName,
                                                          editable:
                                                              row.editable);
                                                    }
                                                    if (widget.mode ==
                                                        SaleMode.service) {
                                                      element = Services(
                                                          id: row.serviceId,
                                                          price: row.price,
                                                          taxId: row.taxId,
                                                          name: row.serviceName,
                                                          editable:
                                                              row.editable);
                                                    }

                                                    _calcRows(
                                                      rowIndex: index,
                                                      element: element,
                                                      quantity: quantity,
                                                      enabledRender: false,
                                                    );
                                                  },
                                                  textInputAction:
                                                      TextInputAction.none,
                                                  keyboardType:
                                                      TextInputType.text,
                                                  decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      hintText: '0.00',
                                                      error: (row.discount ??
                                                                  0) >
                                                              (row.net ?? 0) *
                                                                  ((row.maxDiscount ??
                                                                          0) /
                                                                      100)
                                                          ? SizedBox()
                                                          : null,
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                219, 217, 217),
                                                            width: 0.5),
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                      width:
                                                                          0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero)),
                                                )),
                                                Expanded(
                                                    child: TextFormField(
                                                  controller: c6,
                                                  focusNode: f6,
                                                  readOnly: true,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'^\d*\.?\d{0,2}$'))
                                                  ],
                                                  onTap: () {
                                                    x = index;
                                                    y = 5;
                                                    offsets[0] = x;
                                                    offsets[1] = y;
                                                  },
                                                  textInputAction:
                                                      TextInputAction.none,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      hintText: '0.00',
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                219, 217, 217),
                                                            width: 0.5),
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                      width:
                                                                          0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero)),
                                                )),
                                                Expanded(
                                                    child: TextFormField(
                                                  controller: c7,
                                                  focusNode: f7,
                                                  readOnly: true,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'^\d*\.?\d{0,2}$'))
                                                  ],
                                                  onTap: () {
                                                    x = index;
                                                    y = 6;
                                                    offsets[0] = x;
                                                    offsets[1] = y;
                                                  },
                                                  textInputAction:
                                                      TextInputAction.none,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      hintText: '0.00',
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                219, 217, 217),
                                                            width: 0.5),
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                      width:
                                                                          0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero)),
                                                ))
                                              ],
                                            ),
                                          );
                                        })
                                      ],
                                    ),
                                  ))
                                ],
                              ),
                            ))),
                    Expanded(
                        child: GestureDetector(
                      onTap: () => _focusCommands.requestFocus(),
                      child: KeyboardListener(
                          focusNode: _focusCommands,
                          onKeyEvent:
                              widget.editing || widget.generateNcfFromProforma
                                  ? null
                                  : _handlerCommands,
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    left: BorderSide(
                                        width: 0.8,
                                        color: const Color.fromRGBO(
                                            220, 219, 219, 1)))),
                            child: SingleChildScrollView(
                              controller: _verticalScrollController,
                              padding: EdgeInsets.all(kDefaultPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  !isSale
                                      ? Container(
                                          margin: EdgeInsets.only(
                                              bottom: kDefaultPadding),
                                          child: DropdownButtonFormField<int?>(
                                              initialValue: currentOverrideCode,
                                              isExpanded: true,
                                              validator: (val) => val == null
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : null,
                                              decoration: InputDecoration(
                                                  labelText:
                                                      'CODIGO MODIFICACION'),
                                              items: overrideCodes
                                                  .map((e) => DropdownMenuItem(
                                                      value: e.id,
                                                      child:
                                                          Text(e.name ?? '')))
                                                  .toList(),
                                              onChanged: (option) {
                                                setState(() {
                                                  currentOverrideCode = option;
                                                });
                                              }),
                                        )
                                      : SizedBox(),
                                  Container(
                                      margin: EdgeInsets.symmetric(
                                          vertical: kDefaultPadding),
                                      child: Focus(
                                          focusNode: _ncfSelectorFocus,
                                          onKeyEvent: (focusNode, event) {
                                            if (event is KeyDownEvent) {
                                              if (event.logicalKey ==
                                                  LogicalKeyboardKey.enter) {
                                                FocusScope.of(context)
                                                    .nextFocus();
                                                FocusScope.of(context)
                                                    .nextFocus();
                                                return KeyEventResult.handled;
                                              }
                                            }

                                            return KeyEventResult.ignored;
                                          },
                                          child: DropdownButtonFormField(
                                              initialValue: currentNcfTypeId,
                                              isExpanded: true,
                                              isDense: true,
                                              validator: (val) => val == null
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : null,
                                              decoration: InputDecoration(
                                                  isDense: true,
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
                                              onChanged: widget.editing
                                                  ? null
                                                  : _onSelectedNcf))),
                                  RncQueryWidget(
                                    clientName: clientName,
                                    editingController: rncOrId,
                                    isDense: true,
                                    rncEditorFocus: _rncEditorFocus,
                                    editing: widget.editing,
                                    onChanged: (xtaxPayer, xclient, xisValid) {
                                      taxPayer = xtaxPayer;
                                      client = xclient;
                                      isValid = xisValid;
                                    },
                                    onEnter: () {
                                      FocusScope.of(context).nextFocus();
                                      FocusScope.of(context).nextFocus();
                                    },
                                  ),
                                  SizedBox(height: kDefaultPadding),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              'TOTAL NETO',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            )),
                                        Expanded(
                                            child: Text(netString,
                                                style: TextStyle(fontSize: 15),
                                                textAlign: TextAlign.right))
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              'DECUENTO',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            )),
                                        Expanded(
                                            child: Text(discountString,
                                                style: TextStyle(fontSize: 15),
                                                textAlign: TextAlign.right))
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              'SUBTOTAL',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            )),
                                        Expanded(
                                            child: Text(subtotalString,
                                                style: TextStyle(fontSize: 15),
                                                textAlign: TextAlign.right))
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              'TOTAL ITBIS',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            )),
                                        Expanded(
                                            child: Text(taxString,
                                                style: TextStyle(fontSize: 15),
                                                textAlign: TextAlign.right))
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              'PROPINA LEGAL',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            )),
                                        Expanded(
                                            child: Text(law10String,
                                                style: TextStyle(fontSize: 15),
                                                textAlign: TextAlign.right))
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              'TOTAL FACTURADO',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            )),
                                        Expanded(
                                            child: Text(totalString,
                                                style: TextStyle(fontSize: 15),
                                                textAlign: TextAlign.right))
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: kDefaultPadding / 3,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              'TOTAL PAGADO',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            )),
                                        Expanded(
                                            child: Text(
                                          totalPaidString,
                                          style: TextStyle(fontSize: 15),
                                          textAlign: TextAlign.right,
                                        ))
                                      ],
                                    ),
                                  ),
                                  const Divider(),
                                  Row(children: [
                                    Expanded(
                                        child: Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: kDefaultPadding / 3),
                                            child: DropdownButtonFormField<
                                                    int?>(
                                                focusNode: FocusNode(
                                                    skipTraversal: true),
                                                initialValue: currentCurrencyId,
                                                validator: (val) => val == null
                                                    ? 'CAMPO OBLIGATORIO'
                                                    : null,
                                                isExpanded: true,
                                                decoration: InputDecoration(
                                                    isDense: true,
                                                    labelText: 'MONEDA'),
                                                items: List.generate(
                                                    currencies.length, (index) {
                                                  var currency =
                                                      currencies[index];
                                                  return DropdownMenuItem(
                                                      value: currency.id,
                                                      child: Text(
                                                          currency.name ??
                                                              ' '));
                                                }),
                                                onChanged: widget.editing ||
                                                        esNotaCredito
                                                    ? null
                                                    : (option) {
                                                        currentCurrencyId =
                                                            option;
                                                        setState(() {});
                                                      }))),
                                    currentCurrencyId == 2 &&
                                            currentNcfTypeId != '50'
                                        ? Expanded(
                                            child: Container(
                                                margin: EdgeInsets.only(
                                                    left: kDefaultPadding / 2),
                                                child: TextFormField(
                                                  focusNode: FocusNode(
                                                      skipTraversal: true),
                                                  key: ValueKey(
                                                      'editortext_rate'),
                                                  controller: rate,
                                                  readOnly: widget.editing ||
                                                      esNotaCredito,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(
                                                          decimal: true),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(
                                                      RegExp(
                                                          r'^\d*\.?\d{0,2}$'),
                                                    ),
                                                  ],
                                                  validator: (val) =>
                                                      val!.isEmpty
                                                          ? 'CAMPO OBLIGATORIO'
                                                          : null,
                                                  onChanged: (_) {
                                                    setState(() {});
                                                  },
                                                  decoration: InputDecoration(
                                                      isDense: true,
                                                      labelText:
                                                          'TASA DE CAMBIO',
                                                      hintText: '0.00'),
                                                )))
                                        : SizedBox(),
                                  ]),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Container(
                                              margin: EdgeInsets.symmetric(
                                                  vertical: kDefaultPadding /
                                                      3),
                                              child: DropdownButtonFormField(
                                                  focusNode: FocusNode(
                                                      skipTraversal: true),
                                                  initialValue:
                                                      currentPaymentMethodId,
                                                  isExpanded: true,
                                                  validator: (val) =>
                                                      val == null
                                                          ? 'CAMPO OBLIGATORIO'
                                                          : null,
                                                  decoration: InputDecoration(
                                                      isDense: true,
                                                      labelText:
                                                          'METODO DE PAGO'),
                                                  items: paymentsMethods
                                                      .map((e) =>
                                                          DropdownMenuItem(
                                                              value: e.id,
                                                              child: Text(
                                                                  e.name ??
                                                                      '')))
                                                      .toList(),
                                                  onChanged: (option) {
                                                    currentPaymentMethodId =
                                                        option;

                                                    if (currentPaymentMethodId ==
                                                        4) {
                                                      currentPaymentType = 2;
                                                      currentPaymentModeId = 2;
                                                    } else {
                                                      currentPaymentType = 1;
                                                      currentPaymentModeId = 3;
                                                    }

                                                    setState(() {});
                                                  }))),
                                      const SizedBox(width: kDefaultPadding),
                                      Expanded(
                                        child: Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: kDefaultPadding / 3),
                                            child: DropdownButtonFormField(
                                                focusNode: FocusNode(
                                                    skipTraversal: true),
                                                initialValue:
                                                    currentPaymentType,
                                                isExpanded: true,
                                                isDense: true,
                                                validator: (val) => val == null
                                                    ? 'CAMPO OBLIGATORIO'
                                                    : null,
                                                decoration: InputDecoration(
                                                    isDense: true,
                                                    labelText: 'TIPO DE PAGO'),
                                                items: paymentsTypes
                                                    .map((e) =>
                                                        DropdownMenuItem(
                                                            value: e.id,
                                                            child: Text(
                                                                e.name ?? '')))
                                                    .toList(),
                                                onChanged: (option) {
                                                  currentPaymentType = option;
                                                  if (currentPaymentMethodId !=
                                                      1) {
                                                    amount.clear();
                                                    amountInputFormatter
                                                        .clear();
                                                  }
                                                  setState(() {});
                                                })),
                                      )
                                    ],
                                  ),
                                  esNotaCredito
                                      ? SizedBox()
                                      : Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: kDefaultPadding),
                                          child: TextFormField(
                                            focusNode:
                                                FocusNode(skipTraversal: true),
                                            controller: paymentDateController,
                                            readOnly: true,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            validator: (val) {
                                              return paymentDate == null
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : null;
                                            },
                                            decoration: InputDecoration(
                                                labelText: 'FECHA DE PAGO',
                                                hintText: 'DD/MM/YYYY',
                                                isDense: true,
                                                suffixIcon: IconButton(
                                                    focusNode: FocusNode(
                                                        skipTraversal: true),
                                                    onPressed:
                                                        _showDatePickerPayment,
                                                    icon: Icon(
                                                        Icons.calendar_month))),
                                          )),
                                  currentPaymentMethodId == 3
                                      ? Column(
                                          children: [
                                            Container(
                                                margin: EdgeInsets.only(
                                                    bottom: kDefaultPadding),
                                                child: DropdownButtonFormField(
                                                    focusNode: FocusNode(
                                                        skipTraversal: true),
                                                    isExpanded: true,
                                                    decoration: InputDecoration(
                                                        isDense: true,
                                                        labelText: 'BANCO'),
                                                    validator: (val) => val ==
                                                            null
                                                        ? 'CAMPO OBLIGATORIO'
                                                        : null,
                                                    items: List.generate(
                                                        banks.length, (index) {
                                                      var bank = banks[index];
                                                      return DropdownMenuItem(
                                                          value: bank.id,
                                                          child: Text(
                                                              bank.name ?? ''));
                                                    }),
                                                    onChanged: (option) {
                                                      currentBankId = option;
                                                    })),
                                            Container(
                                                margin: EdgeInsets.only(
                                                    bottom: kDefaultPadding),
                                                child: TextFormField(
                                                  focusNode: FocusNode(
                                                      skipTraversal: true),
                                                  key: ValueKey(
                                                      'editortext_bank_ref'),
                                                  controller: transfRef,
                                                  validator: (val) =>
                                                      val!.isEmpty
                                                          ? 'CAMPO OBLIGATORIO'
                                                          : null,
                                                  decoration: InputDecoration(
                                                      isDense: true,
                                                      hintText:
                                                          'Escribir algo...',
                                                      labelText:
                                                          'NUMERO DE CHEQUE O REFERENCIA'),
                                                ))
                                          ],
                                        )
                                      : SizedBox(),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Container(
                                              margin: EdgeInsets.symmetric(
                                                  vertical: kDefaultPadding /
                                                      3),
                                              child: DropdownButtonFormField<
                                                      int?>(
                                                  focusNode: FocusNode(
                                                      skipTraversal: true),
                                                  initialValue:
                                                      currentPaymentModeId,
                                                  isExpanded: true,
                                                  isDense: true,
                                                  validator: (val) =>
                                                      val == null
                                                          ? 'CAMPO OBLIGATORIO'
                                                          : null,
                                                  decoration: InputDecoration(
                                                      isDense: true,
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
                                                  onChanged: widget.editing ||
                                                          esNotaCredito
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
                                                        }))),
                                      currentPaymentModeId == 2 ||
                                              currentPaymentModeId == 1
                                          ? SizedBox()
                                          : Expanded(
                                              child: Container(
                                                margin: EdgeInsets.only(
                                                    left: kDefaultPadding / 2),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Focus(
                                                        onKeyEvent:
                                                            (focus, event) {
                                                          if (event
                                                              is KeyDownEvent) {
                                                            if (event
                                                                    .logicalKey ==
                                                                LogicalKeyboardKey
                                                                    .enter) {
                                                              _preConfirm();
                                                              return KeyEventResult
                                                                  .handled;
                                                            }
                                                          }

                                                          return KeyEventResult
                                                              .ignored;
                                                        },
                                                        child: TextFormField(
                                                          controller: amount,
                                                          autofocus: widget
                                                              .generateNcfFromProforma,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                          onChanged: (_) {
                                                            setState(() {});
                                                          },
                                                          inputFormatters: [
                                                            amountInputFormatter
                                                          ],
                                                          validator: (val) {
                                                            if (esNotaCredito &&
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
                                                          decoration:
                                                              InputDecoration(
                                                            isDense: true,
                                                            labelText:
                                                                'MONTO PAGADO',
                                                            hintText: '0.00',
                                                          ),
                                                        ))
                                                  ],
                                                ),
                                              ),
                                            )
                                    ],
                                  ),
                                  !enabledRestaurantMode
                                      ? SizedBox()
                                      : Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: kDefaultPadding / 3),
                                          child: DropdownButtonFormField<int?>(
                                              initialValue: currentLawMode,
                                              isExpanded: true,
                                              isDense: true,
                                              decoration: InputDecoration(
                                                  isDense: true,
                                                  labelText:
                                                      'MONTO PROPINA LEGAL'),
                                              items: law10Modes
                                                  .map((e) => DropdownMenuItem(
                                                      value: e['id'] as int,
                                                      child: Text(
                                                          e['name'] ?? '')))
                                                  .toList(),
                                              onChanged: widget.editing
                                                  ? null
                                                  : (option) {
                                                      currentLawMode = option!;
                                                      if (option == 2) {
                                                        for (int i = 0;
                                                            i <
                                                                widget.items
                                                                    .length;
                                                            i++) {
                                                          var item =
                                                              widget.items[i];
                                                          var law10 =
                                                              item.netFinal! *
                                                                  0.10;
                                                          item.law10 = law10;
                                                          item.total =
                                                              item.netFinal! +
                                                                  item.tax! +
                                                                  law10;

                                                          var newItem = item.copyWith(
                                                              serviceId: item
                                                                  .serviceId,
                                                              productId: item
                                                                  .productId,
                                                              tax: item.tax,
                                                              tax16: item.tax16,
                                                              tax18: item.tax18,
                                                              net: item.net,
                                                              net16: item.net16,
                                                              net18: item.net18,
                                                              netFinal:
                                                                  item.netFinal,
                                                              law10: law10,
                                                              taxId: item.taxId,
                                                              discount:
                                                                  item.discount,
                                                              retentionTaxId: item
                                                                  .retentionTaxId,
                                                              retentionTax: item
                                                                  .retentionTax,
                                                              retentionIsrId: item
                                                                  .retentionIsrId,
                                                              retentionIsr: item
                                                                  .retentionIsr,
                                                              price: item.price,
                                                              priceItem: item
                                                                  .priceItem,
                                                              indicadorFacturacion:
                                                                  item
                                                                      .indicadorFacturacion,
                                                              exemptAmount: item
                                                                  .exemptAmount,
                                                              total:
                                                                  item.total);
                                                          widget.items[i] =
                                                              newItem;
                                                        }
                                                      } else {
                                                        for (int i = 0;
                                                            i <
                                                                widget.items
                                                                    .length;
                                                            i++) {
                                                          var item =
                                                              widget.items[i];
                                                          var law10 = 0.0;
                                                          item.law10 = law10;
                                                          item.total =
                                                              item.netFinal! +
                                                                  item.tax!;
                                                          var newItem = item.copyWith(
                                                              serviceId: item
                                                                  .serviceId,
                                                              productId: item
                                                                  .productId,
                                                              tax: item.tax,
                                                              tax16: item.tax16,
                                                              tax18: item.tax18,
                                                              net: item.net,
                                                              net16: item.net16,
                                                              net18: item.net18,
                                                              netFinal:
                                                                  item.netFinal,
                                                              law10: law10,
                                                              taxId: item.taxId,
                                                              discount:
                                                                  item.discount,
                                                              retentionTaxId: item
                                                                  .retentionTaxId,
                                                              retentionTax: item
                                                                  .retentionTax,
                                                              retentionIsrId: item
                                                                  .retentionIsrId,
                                                              retentionIsr: item
                                                                  .retentionIsr,
                                                              price: item.price,
                                                              priceItem: item
                                                                  .priceItem,
                                                              indicadorFacturacion:
                                                                  item
                                                                      .indicadorFacturacion,
                                                              exemptAmount: item
                                                                  .exemptAmount,
                                                              total:
                                                                  item.total);
                                                          widget.items[i] =
                                                              newItem;
                                                        }
                                                      }

                                                      setState(() {});
                                                    }),
                                        ),
                                  currentPaymentMethodId == 2 &&
                                          currentPaymentType == 1
                                      ? SizedBox()
                                      : Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: kDefaultPadding / 3),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                  child: Text(
                                                      isSale
                                                          ? debt < 0
                                                              ? 'DEVUELTA'
                                                              : 'DEUDA'
                                                          : 'PENDIENTE A DEVOLVER',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .displayMedium
                                                          ?.copyWith(
                                                              fontSize: 15,
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
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w500))
                                            ],
                                          ),
                                        ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: kDefaultPadding / 3),
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton(
                                        onPressed: () async {
                                          _preConfirm();
                                        },
                                        child: Text(widget.editing
                                            ? 'EDITAR FACTURA'
                                            : 'CREAR FACTURA')),
                                  )
                                ],
                              ),
                            ),
                          )),
                    ))
                  ],
                ))));
  }
}
