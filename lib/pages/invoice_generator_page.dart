// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:amount_input_formatter/amount_input_formatter.dart';
import 'package:ecf_dgii/ecf_dgii.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/modals/ncfs.selector.modal.dart';
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
import 'package:uresax_invoice_sys_cloud/models/sale.item.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.service.dart';
import 'package:uresax_invoice_sys_cloud/models/taxpayer.dart';
import 'package:uresax_invoice_sys_cloud/pages/printers_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/utils/invoices.functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/escape.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/invoice_item_generator_widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/rnc.query.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/toolbutton.widget.dart';
import 'package:uuid/uuid.dart';

class InvoiceGeneratorPage extends StatefulWidget {
  SaleMode mode;
  Sale sale;
  List<SaleItem> items;

  bool editing;
  bool generateNcfFromProforma;

  InvoiceGeneratorPage(
      {super.key,
      this.mode = SaleMode.service,
      required this.sale,
      this.items = const [],
      this.editing = false,
      this.generateNcfFromProforma = false});

  @override
  State<InvoiceGeneratorPage> createState() => _InvoiceGeneratorPageState();
}

class _InvoiceGeneratorPageState extends State<InvoiceGeneratorPage> {
  String? currentNcfTypeId;
  int? currentPaymentMethodId;
  int? currentBankId;
  int? currentCurrencyId = 1;
  String? currentTypeIncomeId = '01';
  int? currentOverrideCode;
  int? currentPaymentType;
  int? currentPaymentModeId;
  TaxPayer? taxPayer;
  Client? client;
  TextEditingController description = TextEditingController();
  TextEditingController issueDateController = TextEditingController();
  TextEditingController retentionDateController = TextEditingController();
  TextEditingController paymentDateController = TextEditingController();
  TextEditingController fechaVencimientoController = TextEditingController();
  DateTime createdAt = DateTime.now();
  DateTime? issueDate;
  DateTime? retentionDate;
  DateTime? paymentDate = DateTime.now();
  DateTime fechaVencimiento = DateTime.now().endOfYear();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AmountInputFormatter amountInputFormatter =
      AmountInputFormatter(fractionalDigits: 2);
  TextEditingController amount = TextEditingController();
  TextEditingController rncOrId = TextEditingController();
  TextEditingController clientName = TextEditingController();
  TextEditingController transfRef = TextEditingController();
  TextEditingController rate = TextEditingController();

  NcfsList? ncfList;

  bool isValid = false;

  bool loading = true;

  Future? future;

  List<NcfType> _ncfs = [];

  List<FormaDePago> formasDePagos = [];

  Sale? _currentSale;
  double creditNoteTotal = 0;

  final ScrollController _scrollControllerY = ScrollController();
  final ScrollController _scrollControllerX = ScrollController();


  int? get brancheId {
    return int.tryParse(localStorage.getItem('URESAX_INVOICE_BRANCHE_ID_${company?.id}') ?? 'x');
  }
  bool get esGubernamental {
    return currentNcfTypeId == '45' || currentNcfTypeId == '15';
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

  bool get esConsumo {
    return currentNcfTypeId == '02' || currentNcfTypeId == '32';
  }

  bool get esNotaCredito {
    if (electronicNcfEnabled) {
      return currentNcfTypeId == '34';
    }

    return currentNcfTypeId == '04';
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

  bool get onlyEcommerce {
    return (eCommerceMode && widget.sale is SaleProduct);
  }

  bool get isEnabledRetentionsSelector {
    return !enabledRetentions || eCommerceMode || widget.sale is SaleProduct;
  }

  bool esCodigoValido(String code) {
    // Acepta numéricos de 6 a 13 dígitos (UPC/EAN típicos)
    final regexNumerico = RegExp(r'^[0-9]{6,13}$');
    // Acepta alfanuméricos tipo SKU (ej. Amazon: X002CCANUH)
    final regexAlfanumerico = RegExp(r'^[A-Za-z0-9]+$');

    return regexNumerico.hasMatch(code) || regexAlfanumerico.hasMatch(code);
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

      setState(() {
        widget.items = [];
      });

      await Future.delayed(const Duration(milliseconds: 90));
      if (widget.sale is SaleProduct) {
        setState(() {
          widget.sale = SaleProduct(items: []);

          widget.items.add(SaleItemProduct());
        });
      }
      if (widget.sale is SaleService) {
        setState(() {
          widget.sale = SaleService(items: []);

          widget.items.add(SaleItemService());
        });
      }
      _scrollControllerY.jumpTo(0);
      _scrollControllerX.jumpTo(0);

      setState(() {});
    } catch (e) {
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      showLoader(context);
      try {
        if (eCommerceMode) {
          if (devicePos == null) {
            throw 'EL DISPOSITIVO DE PUNTO DE VENTA NO ESTA CONFIGURADO (CONTACTE CON EL ADMINISTRADOR DEL SISTEMA)';
          }
        }
        var now = DateTime.now();

        createdAt = now;

        widget.sale.ncfTypeId = currentNcfTypeId;
        widget.sale.items = widget.items;
        widget.sale.net = calcs[0];
        widget.sale.discount = calcs[1];
        widget.sale.tax = calcs[2];
        widget.sale.total = calcs[15];
        widget.sale.retentionIsr = calcs[4];
        widget.sale.retentionTax = calcs[5];
        widget.sale.paymentMethodId = currentPaymentMethodId;
        widget.sale.clientId = client?.id ?? taxPayer?.taxPayerId;
        widget.sale.clientIdentification = rncOrId.text.replaceAll('-', '');
        widget.sale.typeIncomeId = currentTypeIncomeId;
        widget.sale.description = description.text;
        widget.sale.clientName = clientName.text;
        widget.sale.retentionDate = retentionDate;
        widget.sale.paymentDate = paymentDate;
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
        widget.sale.exemptAmount = calcs[13];
        widget.sale.authorId = currentUser?.id;
        widget.sale.ncfAffectedCreatedAt = _currentSale?.createdAt;
        widget.sale.coinBack = 0;
        widget.sale.law10 = calcs[14];
        widget.sale.ncfListId = ncfList?.id;
        widget.sale.brancheId = brancheId;
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

        widget.items = widget.items.where((e) => e.enabled == true).toList();

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
          widget.sale.paid = amount * xrate;

          if (sale.debt == 0 ||
              sale.amountPaid! > sale.tax! ||
              esNotaCredito ||
              (automaticSendEcf && !widget.editing)) {
            sale.issueDate = issueDate ?? now;

            await enviarDgii(
                sale: sale,
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
                totalFacturado: montoTotal,
                fechaVencimiento: fechaVencimiento,
                currentPaymentMethodId: currentPaymentMethodId,
                currentPaymentType: currentPaymentType,
                currentTypeIncomeId: currentTypeIncomeId,
                currentOverrideCode: currentOverrideCode,
                canOverrideTaxes: canOverrideTaxes);
          }

          await LogHandler.printEvent(
              '${sale.ncfTypeName} ${sale.ncf} FUE ENVIADA A DGII, RNC/CEDULA: ${sale.clientId}, EL CLIENTE: ${sale.clientName}');
        }

        File? file;

        if (eCommerceMode) {
          if (devicePos != null) {
            var bytes = await createDefaultTicket(sale: sale!);

            await PrinterHandler.printBytes(devicePos ?? '', bytes);

            await LogHandler.printEvent('SE IMPRIMIO LA FACTURA ${sale.ncf}');
          }
        } else {
          var doc = await createInvoice(sale!);

          var fileName =
              '${sale.clientName?.trim()}_${sale.ncf}_${company?.name?.trim()}.PDF';

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

          await OpenFile.open(file.path);

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
        _reset();
        Navigator.pop(context);
        if (!eCommerceMode ||
            widget.editing ||
            widget.generateNcfFromProforma) {
          Navigator.pop(
              context,
              widget.editing || widget.generateNcfFromProforma
                  ? 'UPDATE'
                  : null);
        }
        showTopSnackBar(context,
            message: widget.editing ? 'FACTURA EDITADA' : 'FACTURA CREADA',
            color: Colors.green);
      } catch (e) {
        print(e);
        await LogHandler.printEvent(e.toString());
        Navigator.pop(context);
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

    if (esGubernamental) {
      retentionDate = null;
      retentionDateController.value = TextEditingValue.empty;
      setState(() {});
    }

    if (option == '50') {
      currentPrefix = 'P';
      maxSequence = 8;
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
              unitSuite: item.unitSuite,
              clientSuite: item.clientSuite,
              priceSuite: item.priceSuite,
              indicadorFacturacion: item.indicadorFacturacion,
              exemptAmount: item.netFinal,
              total: item.total
              );

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
              net16: 0,
              net18: 0,
              net3: 0,
              price: item.price,
              priceItem: item.priceItem,
              discount: item.discount,
              law10: item.law10,
              retentionTaxId: item.retentionTaxId,
              retentionTax: item.retentionTax,
              retentionIsrId: item.retentionIsrId,
              retentionIsr: item.retentionIsr,
              net: item.net,
              netFinal: item.netFinal,
              taxId: item.taxId,
              indicadorFacturacion: 4,
              exemptAmount: item.netFinal,
              unitSuite: item.unitSuite,
              clientSuite: item.clientSuite,
              priceSuite: item.priceSuite,
              total: item.total! - (item.tax ?? 0));

          widget.items[i] = newItem;
        } else {
          if (item.price != null) {
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

            double priceAmount = item.price! * (item.quantity ?? 1);
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
                net16: net16,
                net18: net18,
                law10: law10,
                netFinal: netFinal,
                discountId: item.discountId,
                discount: discount,
                taxId: type,
                price: item.price,
                priceItem: item.priceItem,
                retentionTaxId: item.retentionTaxId,
                retentionTax: item.retentionTax,
                retentionIsrId: item.retentionIsrId,
                retentionIsr: item.retentionIsr,
                indicadorFacturacion: indicadorFacturacion,
                exemptAmount: exemptAmount,
                unitSuite: item.unitSuite,
                clientSuite: item.clientSuite,
                priceSuite: item.priceSuite,
                total: total);

            widget.items[i] = newItem;
          }
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
          if (ncfList?.expirationDate != null) {
            fechaVencimiento = ncfList!.expirationDate!;

            fechaVencimientoController.value = TextEditingValue(
                text: fechaVencimiento.format(payload: 'DD/MM/YYYY'));
          }

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

  _addSaleItemService() async {
    widget.items.add(SaleItemService(id: Uuid().v4()));
    setState(() {});
  }

  _addSaleItemProduct() {
    widget.items.add(SaleItemProduct(id: Uuid().v4()));
    setState(() {});
  }

  _addSaleItem() {
    if (widget.mode == SaleMode.service) {
      _addSaleItemService();
    }

    if (widget.mode == SaleMode.product) {
      _addSaleItemProduct();
    }
  }

  bool get canOverrideTaxes {
    if (_currentSale == null) return false;
    var days = DateTime.now().difference(_currentSale!.issueDate!).inDays;
    return days > 30;
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

    for (int i = 0; i < widget.items.length; i++) {
      var item = widget.items[i];

      net += item.enabled == true ? widget.items[i].net ?? 0 : 0;
      discount += item.enabled == true ? widget.items[i].discount ?? 0 : 0;
      subtotal += item.enabled == true ? widget.items[i].netFinal ?? 0 : 0;

      if (!canOverrideTaxes) {
        tax += item.enabled == true ? widget.items[i].tax ?? 0 : 0;
      }
      total += item.enabled == true ? widget.items[i].total ?? 0 : 0;
      retentionIsr +=
          item.enabled == true ? widget.items[i].retentionIsr ?? 0 : 0;
      retentionTax +=
          item.enabled == true ? widget.items[i].retentionTax ?? 0 : 0;

      if (!canOverrideTaxes) {
        tax18 += item.enabled == true ? widget.items[i].tax18 ?? 0 : 0;

        tax16 += item.enabled == true ? widget.items[i].tax16 ?? 0 : 0;

        tax3 += item.enabled == true ? widget.items[i].tax3 ?? 0 : 0;
      }

      net18 += item.enabled == true ? widget.items[i].net18 ?? 0 : 0;

      net16 += item.enabled == true ? widget.items[i].net16 ?? 0 : 0;

      net3 += item.enabled == true ? widget.items[i].net3 ?? 0 : 0;

      law10 += item.enabled == true ? widget.items[i].law10 ?? 0 : 0;

      exemptAmount +=
          item.enabled == true ? widget.items[i].exemptAmount ?? 0 : 0;
    }

    return [
      net,
      discount,
      tax,
      total,
      retentionIsr,
      retentionTax,
      (total - (retentionIsr + retentionTax)),
      tax18,
      tax16,
      tax3,
      net18,
      net16,
      net3,
      exemptAmount,
      law10,
      total,
      subtotal
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
      calcs[15] * xrate,
      calcs[16] * xrate
    ];
  }

  String get net {
    if (currentCurrencyId == 2) {
      return calcs[0].toUS();
    }

    return calcs[0].toDop();
  }

  String get discount {
    if (currentCurrencyId == 2) {
      return calcs[1].toUS();
    }

    return calcs[1].toDop();
  }

  String get subtotal {
    if (currentCurrencyId == 2) {
      return calcs[16].toUS();
    }

    return calcs[16].toDop();
  }

  String get tax {
    if (currentCurrencyId == 2) {
      return calcs[2].toUS();
    }
    return calcs[2].toDop();
  }

  String get law10 {
    if (currentCurrencyId == 2) {
      return calcs[14].toUS();
    }
    return calcs[14].toDop();
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

  double get montoTotal {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[15];
    }
    return calcs[15];
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
      return calcsDollarsToDop[14];
    }
    return calcs[14];
  }

  double get totalGravado {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[16] - montoExento;
    }

    return calcs[16] - montoExento;
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

  double oldtTotalRetencionIsr = 0;
  double get totalRetencionIsr {
    if (currentCurrencyId == 2) {
      return calcsDollarsToDop[4];
    }
    return calcs[4];
  }

  double oldTotalRetencionItbis = 0;

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

  _showDatePicker() async {
    var result = await showDatePicker(
      context: context,
      initialDate: retentionDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      lastDate: DateTime.now(),
    );

    if (result == null) {
      // Usuario canceló → limpiar fecha y rebuild
      setState(() {
        retentionDate = null;
        paymentDate = DateTime.now();
        retentionDateController.value = const TextEditingValue(text: '');
        paymentDateController.value = const TextEditingValue(text: '');
      });
    } else {
      // Usuario seleccionó fecha → actualizar
      setState(() {
        retentionDate = result;
        paymentDate = result;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        retentionDateController.value = TextEditingValue(
          text: retentionDate?.format(payload: 'DD/MM/YYYY') ?? '',
        );
        paymentDateController.value = TextEditingValue(
          text: paymentDate?.format(payload: 'DD/MM/YYYY') ?? '',
        );
      });
    }

    _formKey.currentState!.validate();
  }

  _showDatePickerPayment() async {
    var result = await showDatePicker(
      context: context,
      initialDate: paymentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      lastDate: DateTime.now(),
    );

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

    _formKey.currentState!.validate();
  }

  _showDatePicker3() async {
    var result = await showDatePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 25)));

    if (result != null) {
      fechaVencimiento = result;
      fechaVencimientoController.value = TextEditingValue(
          text: fechaVencimiento.format(payload: 'DD/MM/YYYY'));
    }
  }

  bool get isSale {
    return widget.sale is SaleService || widget.sale is SaleProduct;
  }

  double get paidAmount {
    return double.parse(calcs[6].toStringAsFixed(2));
  }

  double get pendingAmount {
    double total = 0;
    double retentionIsr = 0;
    double retentionTax = 0;

    for (int i = 0; i < widget.items.length; i++) {
      var item = widget.items[i];
      total += item.enabled == false ? widget.items[i].total ?? 0 : 0;
      retentionIsr +=
          item.enabled == false ? widget.items[i].retentionIsr ?? 0 : 0;
      retentionTax +=
          item.enabled == false ? widget.items[i].retentionTax ?? 0 : 0;
    }

    return (total - (retentionTax + retentionIsr));
  }

  bool get hasRetencionesAplicadas {
    return (widget.sale.retentionTax ?? 0) > 0 ||
        (widget.sale.retentionIsr ?? 0) > 0;
  }

  double get debt {
    if (esNotaCredito && _currentSale != null) {
      return _currentSale!.amountPaid! - creditNoteTotal;
    }

    if (widget.sale.amountPaid != null && widget.editing) {
      final retenciones = calcs[5] + calcs[4];

      if (hasRetencionesAplicadas == true) {
        // Ya se aplicaron las retenciones en la deuda original
        return (widget.sale.debt! - amountInputFormatter.doubleValue);
      } else {
        // Retenciones se aplican ahora junto con el pago
        return ((widget.sale.debt! - retenciones) -
            amountInputFormatter.doubleValue);
      }
    }

    return (paidAmount - amountInputFormatter.doubleValue);
  }

  String get debtString {
    if (currentCurrencyId == 2) {
      return (debt).abs().toUS();
    }
    return debt.abs().toDop();
  }

  NcfType? currentNcfType;
  String currentPrefix = 'P';
  int maxSequence = 8;

  String ncfLabel = '';

  Future<void> _initAsync() async {
    try {
      if (widget.editing == false) {
        if (widget.generateNcfFromProforma == false) {
          if (isSale && enabledPosAutomaticSetup) {
            client = await Client.findClientContado();
            clientName.value = TextEditingValue(text: client?.name ?? '');
            rncOrId.value =
                TextEditingValue(text: client?.identification ?? '');
            isValid = true;
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
        }
      }

      setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    if (!mounted) return;

    _ncfs = [...ncfs];

    if (!widget.editing) {
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
        }
      }
    }

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
          e.id == '50' ||
          e.id == '43' ||
          e.id == '41' ||
          e.id == '60');
    }

    if (isSale) {
      _ncfs.removeWhere((e) => e.id == '34' || e.id == '04');
    } else {
      currentNcfTypeId = '34';
      currentPrefix = 'E';
      maxSequence = 10;
    }

    var now = DateTime.now();
    var dateLocal = now;

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
      currentCurrencyId = widget.sale.currencyId;
      currentTypeIncomeId = widget.sale.typeIncomeId;
      description.text = widget.sale.description ?? '';
    }

    issueDateController.value =
        TextEditingValue(text: createdAt.format(payload: 'DD/MM/YYYY'));

    fechaVencimientoController.value =
        TextEditingValue(text: fechaVencimiento.format(payload: 'DD/MM/YYYY'));

    paymentDateController.value = TextEditingValue(
        text: paymentDate?.format(payload: 'DD/MM/YYYY') ?? '');

    if (widget.editing) {
      paymentDate = null;
      oldTotalRetencionItbis = totalRetencionItbis;
      oldtTotalRetencionIsr = totalRetencionIsr;
      client = Client(
          id: widget.sale.clientId,
          identification: widget.sale.clientIdentification,
          name: widget.sale.clientName);

      clientName.value = TextEditingValue(text: widget.sale.clientName ?? '');
      rncOrId.value =
          TextEditingValue(text: widget.sale.clientIdentification ?? '');
      currentNcfTypeId = widget.sale.ncfTypeId;
      currentTypeIncomeId = widget.sale.typeIncomeId;
      retentionDate = widget.sale.retentionDate;
      retentionDateController.value = TextEditingValue(
          text: retentionDate?.format(payload: 'DD/MM/YYYY') ?? '');
      description.value = TextEditingValue(text: widget.sale.description ?? '');
      paymentDateController.value = TextEditingValue(
          text: paymentDate?.format(payload: 'DD/MM/YYYY') ?? '');
      currentCurrencyId = widget.sale.currencyId;

      if (widget.sale.rate! > 1) {
        rate.text = widget.sale.rate?.toStringAsFixed(2) ?? '';
      }
      if (widget.sale.debt! > 0) {
        currentPaymentModeId = 3;
      }
      isValid = true;
    }

    if (eCommerceMode && !widget.editing && !widget.generateNcfFromProforma) {
      currentTypeIncomeId = '01';
    }
    if (enabledPosAutomaticSetup) {
      if (isSale) {
        if (widget.editing == false) {
          if (widget.generateNcfFromProforma == false) {
            currentNcfTypeId = '32';
          }
        }
      }

      currentPaymentMethodId = 1;
      currentPaymentModeId = 3;
      currentPaymentType = 1;
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
      future = _initAsync();
    });

    super.initState();
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

      currentCurrencyId = _currentSale?.currencyId;

      currentPaymentType = 1;

      if (_currentSale?.rate != null) {
        rate.value = TextEditingValue(
            text: _currentSale?.rate?.toStringAsFixed(2) ?? '');
      }

      rncOrId.value = TextEditingValue(
          text: res.clientIdentification?.replaceAll('-', '') ?? '');

      var items = await res.getSaleData();


      items = items
          .map((e) => e is SaleItemService
              ? CreditNoteService(
                  id: e.id,
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
                  tax: e.tax,
                  total: e.total,
                  retentionIsr: e.retentionIsr,
                  retentionTax: e.retentionTax,
                  isrRate: e.isrRate,
                  taxRate: e.taxRate,
                  retentionTaxId: e.retentionTaxId,
                  retentionIsrId: e.retentionIsrId,
                  enabled: e.enabled,
                  chassis: e.chassis,
                  licensePlate: e.licensePlate,
                  creditNoteId: e.creditNoteId,
                  quantity: e.quantity,
                  returnQuantity: e.returnQuantity,
                  tax18: e.tax18,
                  tax16: e.tax16,
                  tax3: e.tax3,
                  net18: e.net18,
                  net16: e.net16,
                  net3: e.net3,
                  exemptAmount: e.exemptAmount,
                  indicadorFacturacion: e.indicadorFacturacion,
                  indicadorAgentePercepcion: e.indicadorAgentePercepcion,
                  law10: e.law10,
                  priceItem: e.priceItem,
                  unitSuite: e.unitSuite,
                  clientSuite: e.clientSuite,
                  priceSuite: e.priceSuite)
              : CreditNoteProduct(
                  id: e.id,
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
                  tax: e.tax,
                  total: e.total,
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
                  tax18: e.tax18,
                  tax16: e.tax16,
                  tax3: e.tax3,
                  net18: e.net18,
                  net16: e.net16,
                  net3: e.net3,
                  exemptAmount: e.exemptAmount,
                  indicadorFacturacion: e.indicadorFacturacion,
                  indicadorAgentePercepcion: e.indicadorAgentePercepcion,
                  conversionFactor: e.conversionFactor,
                  unitCode: e.unitCode,
                  unitName: e.unitName,
                  unitSymbol: e.unitSymbol,
                  units: e.units,
                  law10: e.law10,
                  priceItem: e.priceItem))
          .toList();

   
      for (int i = 0; i < items.length; i++) {
        var item = items[i];
        widget.items.add(item);
   
      }

      setState(() {});
      description.value = TextEditingValue(text: res.description ?? '');
    }
  }

  Widget get contentFilled {
    return EscNavigationDemo(
        child: Scaffold(
            appBar: AppBar(
              toolbarHeight: kDefaultNavbarHeight,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                    Icon(Icons.receipt_long_outlined),
                    SizedBox(
                      width: kDefaultPadding
                    ),
                  Text(title,style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600
              ))
                ],
              ),
              centerTitle: false,
              actions: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: [
                 
                  esNotaCredito ?  ToolButtonWidget(
                        icon: Icons.document_scanner, onTap: _scanInvoice):SizedBox(),
                  eCommerceMode ?   ToolButtonWidget(
                        icon: Icons.print,
                        onTap: () async {
                          devicePos = await Navigator.push<String?>(
                              context,
                              MaterialPageRoute(
                                  builder: (ctx) => PrintersPage()));
                        }):SizedBox(),
                    ToolButtonWidget(
                        icon: Icons.close_outlined,
                        onTap: () => Navigator.pop(context)),
                  ],
                )
              ],
            ),
            body: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  controller: _scrollControllerY,
                  padding: EdgeInsets.all(kDefaultPadding),
                  physics: Theme.of(context).platform == TargetPlatform.iOS ||
                          Theme.of(context).platform == TargetPlatform.macOS
                      ? const BouncingScrollPhysics()
                      : const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                            children: [
                              DropdownButtonFormField(
                                  initialValue: currentNcfTypeId,
                                  isExpanded: true,
                                  validator: (val) =>
                                      val == null ? 'CAMPO OBLIGATORIO' : null,
                                  decoration: InputDecoration(
                                    isDense: true,
                                      hintText:
                                          'SELECCIONA UN TIPO DE COMPROBANTE',
                                      labelText: 'TIPO DE COMPROBANTE'),
                                  items: _ncfs
                                      .map((e) => DropdownMenuItem(
                                          value: e.id,
                                          child: Text(e.name ?? '')))
                                      .toList(),
                                  onChanged:
                                      widget.editing ? null : _onSelectedNcf),
                              SizedBox(
                                height: kDefaultPadding,
                              ),
                              RncQueryWidget(
                                clientName: clientName,
                                editing: widget.editing || esNotaCredito,
                                editingController: rncOrId,
                                isDense: true,
                                onChanged: (xtaxPayer, xclient, xisValid) {
                                  taxPayer = xtaxPayer;
                                  client = xclient;

                                  isValid = xisValid;
                                  setState(() {});
                                },
                              )
                            ],
                          )),
                          SizedBox(width: kDefaultPadding),
                          Expanded(
                              child: Column(
                            children: [
                              Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: DropdownButtonFormField<String?>(
                                    initialValue: currentTypeIncomeId,
                                    isExpanded: true,
                                    validator: (val) => val == null
                                        ? 'CAMPO OBLIGATORIO'
                                        : null,
                                    decoration: InputDecoration(
                                      isDense: true,
                                        labelText: 'TIPO DE INGRESO'),
                                    items: typesIncomes
                                        .map((e) => DropdownMenuItem(
                                            value: e.id,
                                            child: Text(e.name ?? '')))
                                        .toList(),
                                    onChanged: widget.editing || esNotaCredito
                                        ? null
                                        : (option) {
                                            setState(() {
                                              currentTypeIncomeId = option;
                                            });
                                          }),
                              ),
                              !isSale
                                  ? Container(
                                      margin: EdgeInsets.only(
                                          bottom: kDefaultPadding),
                                      child: DropdownButtonFormField(
                                          initialValue: currentOverrideCode,
                                          isExpanded: true,
                                          validator: (val) => val == null
                                              ? 'CAMPO OBLIGATORIO'
                                              : null,
                                          decoration: InputDecoration(
                                            isDense: true,
                                              labelText: 'CODIGO MODIFICACION'),
                                          items: overrideCodes
                                              .map((e) => DropdownMenuItem(
                                                  value: e.id,
                                                  child: Text(e.name ?? '')))
                                              .toList(),
                                          onChanged: (option) {
                                            setState(() {
                                              currentOverrideCode = option;
                                            });
                                          }),
                                    )
                                  : SizedBox(),
                              Row(
                                children: [
                                  Expanded(
                                      child: Container(
                                    margin: EdgeInsets.only(
                                        bottom: kDefaultPadding),
                                    child: TextFormField(
                                      controller: issueDateController,
                                      readOnly: true,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      decoration: InputDecoration(
                                        isDense: true,
                                          labelText: 'FECHA DE CREACION',
                                          hintText: 'DD/MM/YYYY',
                                          suffixIcon: IconButton(
                                              onPressed: null,
                                              icon:
                                                  Icon(Icons.calendar_month))),
                                    ),
                                  )),
                                  SizedBox(
                                    width: kDefaultPadding / 2,
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          bottom: kDefaultPadding),
                                      child: TextFormField(
                                        controller: retentionDateController,
                                        readOnly: true,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        decoration: InputDecoration(
                                          isDense: true,
                                            labelText: 'FECHA DE RETENCION',
                                            hintText: 'DD/MM/YYYY',
                                            suffixIcon: IconButton(
                                                onPressed: widget.editing &&
                                                            retentionDate !=
                                                                null ||
                                                        esGubernamental ||
                                                        esEspecial ||
                                                        esMenor ||
                                                        isEnabledRetentionsSelector
                                                    ? null
                                                    : _showDatePicker,
                                                icon: Icon(
                                                    Icons.calendar_month))),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              TextFormField(
                                controller: fechaVencimientoController,
                                readOnly: true,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: InputDecoration(
                                  isDense: true,
                                    labelText: 'FECHA DE VENCIMIENTO',
                                    hintText: 'DD/MM/YYYY',
                                    suffixIcon: IconButton(
                                        onPressed: null,
                                        icon: Icon(Icons.calendar_month))),
                              )
                            ],
                          ))
                        ],
                      ),
                      SizedBox(
                        height: kDefaultPadding,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 100.00 * (widget.items.length),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _scrollControllerX,
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: [
                              ...List.generate(widget.items.length, (index) {
                                var item = widget.items[index];

                                return InvoiceItemGeneratorWidget(
                                  key: ValueKey(item.id),
                                  enabledEditing: widget.sale is SaleService &&
                                      enabledTextEditor,
                                  saleItem: item,
                                  index: index,
                                  sale: widget.sale,
                                  saleItems: widget.items,
                                  editing: widget.editing,
                                  isProForma: widget.generateNcfFromProforma,
                                  canOverrideTaxes: canOverrideTaxes,
                                  esGubernamental: esGubernamental,
                                  esEspecial: esEspecial,
                                  esMenor: esMenor,
                                  esCompra: esCompra,
                                  retentionDate: retentionDate,
                                  totalRetentionTax: totalRetencionItbis,
                                  totalRetentionIsr: totalRetencionIsr,
                                  enableds: widget.items
                                      .where((e) => e.enabled == true)
                                      .toList(),
                                  onDelete: (i) {
                                    if (widget.items.length > 1) {
                                      widget.items.removeAt(index);
                                    }

                                    setState(() {});
                                  },
                                  onChanged: (saleItem) {
                               
                                    setState(() {});
                                  },
                                );
                              })
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: kDefaultPadding),
                      Row(
                        children: [
                          !isSale || widget.editing
                              ? SizedBox()
                              : Container(
                                  width: 150,
                                  height: 50,
                                  margin:
                                      EdgeInsets.only(right: kDefaultPadding),
                                  child: ElevatedButton(
                                      onPressed: _addSaleItem,
                                      child: Text('AGREGAR')),
                                ),
                          widget.items.isNotEmpty && !widget.editing
                              ? SizedBox(
                                  width: 150,
                                  height: 50,
                                  child: ElevatedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                  const Color.fromARGB(
                                                      244, 220, 243, 247))),
                                      onPressed: _reset,
                                      child: Text(
                                        'REINICIAR',
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor),
                                      )),
                                )
                              : SizedBox(),
                        ],
                      ),
                      SizedBox(height: kDefaultPadding),
                      TextFormField(
                        key: ValueKey('editortext_description'),
                        controller: description,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                            labelText: 'DESCRIPCION',
                            hintText: 'Escribir algo...'),
                      ),
                      SizedBox(height: kDefaultPadding),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Subtotal',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(net,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Descuento',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(discount,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Subtotal',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(subtotal,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Itbis',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(tax,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Total',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(total,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Retencion Itbis',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(retentionTax,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Retencion Isr',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(retentionIsr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text('Monto Propina Legal',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(law10,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          isSale
                                              ? 'Total a pagar'
                                              : 'Total a Devolver',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .primaryColor))),
                                  Expanded(
                                      child: Text(amountPaid,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          textAlign: TextAlign.right))
                                ],
                              ),
                            ],
                          )),
                          SizedBox(width: kDefaultPadding),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: DropdownButtonFormField<int?>(
                                    initialValue: currentCurrencyId,
                                    validator: (val) => val == null
                                        ? 'CAMPO OBLIGATORIO'
                                        : null,
                                    decoration: InputDecoration(
                                        labelText: 'MONEDA', isDense: true),
                                    items: List.generate(currencies.length,
                                        (index) {
                                      var currency = currencies[index];
                                      return DropdownMenuItem(
                                          value: currency.id,
                                          child: Text(currency.name ?? ' '));
                                    }),
                                    onChanged: widget.editing || esNotaCredito
                                        ? null
                                        : (option) {
                                           rate.clear();
                                            currentCurrencyId = option;
                                            setState(() {});
                                          }),
                              ),
                         currentCurrencyId == 2 ?   Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(
                                              bottom: kDefaultPadding),
                                          child: TextFormField(
                                            key: ValueKey('editortext_rate'),
                                            controller: rate,
                                            readOnly:
                                                widget.editing || esNotaCredito,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d*\.?\d{0,2}$'),
                                              ),
                                            ],
                                            validator: (val) => val!.isEmpty
                                                ? 'CAMPO OBLIGATORIO'
                                                : null,
                                            onChanged: (_) {
                                              setState(() {});
                                            },
                                            decoration: InputDecoration(
                                                isDense: true,
                                                labelText: 'TASA DE CAMBIO',
                                                hintText: '0.00'),
                                          ),
                                        )
                                      ],
                                    ):SizedBox(),
                              Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: kDefaultPadding / 2),
                                child: DropdownButtonFormField(
                                    initialValue: currentPaymentMethodId,
                                    validator: (val) => val == null
                                        ? 'CAMPO OBLIGATORIO'
                                        : null,
                                    decoration: InputDecoration(
                                        isDense: true,
                                        labelText: isSale
                                            ? 'METODO DE PAGO'
                                            : 'FORMA DE PAGO'),
                                    items: paymentsMethods
                                        .map((e) => DropdownMenuItem(
                                            value: e.id,
                                            child: Text(e.name ?? '')))
                                        .toList(),
                                    onChanged: (option) {
                                      currentPaymentMethodId = option;

                                      if (currentPaymentMethodId == 4) {
                                        currentPaymentType = 2;
                                        currentPaymentModeId = 2;
                                      }else{
                                        currentPaymentType = 1;
                                        currentPaymentModeId = 3;
                                      }

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
                                        isDense: true,
                                        labelText: 'TIPO DE PAGO'),
                                    items: paymentsTypes
                                        .map((e) => DropdownMenuItem(
                                            value: e.id,
                                            child: Text(e.name ?? '')))
                                        .toList(),
                                    onChanged: (option) {
                                      currentPaymentType = option;
                                    }),
                              ),
                              esNotaCredito
                                  ? SizedBox()
                                  : Container(
                                      margin: EdgeInsets.symmetric(
                                          vertical: kDefaultPadding),
                                      child: DropdownButtonFormField<int?>(
                                          initialValue: currentPaymentModeId,
                                          isExpanded: true,
                                          validator: (val) => val == null
                                              ? 'CAMPO OBLIGATORIO'
                                              : null,
                                          decoration: InputDecoration(
                                              isDense: true,
                                              labelText: 'MODO DE PAGO'),
                                          items: paymentsModes
                                              .map((e) => DropdownMenuItem(
                                                  value: e.id,
                                                  child: Text(e.name ?? '')))
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
                              Container(
                                margin:
                                    EdgeInsets.only(bottom: kDefaultPadding),
                                child: TextFormField(
                                  controller: paymentDateController,
                                  readOnly: true,
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                                          onPressed: _showDatePickerPayment,
                                          icon: Icon(Icons.calendar_month))),
                                ),
                              ),
                              currentPaymentMethodId == 3
                                  ? Column(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(
                                              bottom: kDefaultPadding),
                                          child: DropdownButtonFormField(
                                              decoration: InputDecoration(
                                                   isDense: true,
                                                  labelText: 'BANCO'),
                                              validator: (val) => val == null
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : null,
                                              items: List.generate(banks.length,
                                                  (index) {
                                                var bank = banks[index];
                                                return DropdownMenuItem(
                                                    value: bank.id,
                                                    child:
                                                        Text(bank.name ?? ''));
                                              }),
                                              onChanged: (option) {
                                                currentBankId = option;
                                              }),
                                        ),
                                        Container(
                                            margin: EdgeInsets.only(
                                                bottom: kDefaultPadding),
                                            child: TextFormField(
                                              key: ValueKey(
                                                  'editortext_bank_ref'),
                                              controller: transfRef,
                                              validator: (val) => val!.isEmpty
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : null,
                                              decoration: InputDecoration(
                                                  hintText: 'Escribir algo...',
                                                  isDense: true,
                                                  labelText:
                                                      'NUMERO DE CHEQUE O REFERENCIA'),
                                            ))
                                      ],
                                    )
                                  : SizedBox(),
                              widget.sale.debt == 0
                                  ? SizedBox()
                                  : Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                                isSale
                                                    ? debt < 0
                                                        ? 'Devuelta'
                                                        : 'Deuda'
                                                    : 'Pendiente a Devolver',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .displayMedium
                                                    ?.copyWith(
                                                        color: Theme.of(context)
                                                            .primaryColor))),
                                        Text(debtString,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                      ],
                                    ),
                              widget.sale.debt == 0
                                  ? SizedBox()
                                  : SizedBox(
                                      height: kDefaultPadding,
                                    ),
                              Row(
                                children: [
                                  currentPaymentModeId == 2 ||
                                          currentPaymentModeId == 1
                                      ? SizedBox()
                                      : Expanded(
                                          flex: 2,
                                          child: Container(
                                            margin: EdgeInsets.only(
                                                right: kDefaultPadding / 2),
                                            child: TextFormField(
                                              key:
                                                  ValueKey('editortext_amount'),
                                              controller: amount,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              onChanged: (_) {
                                                setState(() {});
                                              },
                                              validator: (val) => val!.isEmpty
                                                  ? 'CAMPO OBLIGATORIO'
                                                  : (esNotaCredito &&
                                                          amountInputFormatter
                                                                  .doubleValue >
                                                              debt)
                                                      ? 'EL MONTO ES MAYOR'
                                                      : null,
                                              inputFormatters: [
                                                amountInputFormatter
                                              ],
                                              decoration: InputDecoration(
                                                  isDense: true,
                                                  labelText: 'MONTO',
                                                  hintText: '0.00'),
                                            ))
                                          ),
                                  Expanded(
                                      child: SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                        onPressed: isValid ? _onSubmit : null,
                                        child: Text(widget.editing
                                            ? 'EDITAR FACTURA'
                                            : 'CREAR FACTURA')),
                                  ))
                                ],
                              ),
                              SizedBox(
                                height: kDefaultPadding,
                              ),
                            ],
                          ))
                        ],
                      ),
                    ],
                  ),
                ))));
  }

  Widget get contentLoading {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget get contentEmpty {
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: future,
        builder: (ctx, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return contentLoading;
          }

          if (s.hasError) {
            return ContentErrorWidget(
              error: s.error.toString(),
              onRetry: () {
                setState(() {
                  future = _initAsync();
                });
              },
            );
          }
          if (taxes.isNotEmpty &&
              retentionsTaxes.isNotEmpty &&
              retentionsIsrs.isNotEmpty) {
            return contentFilled;
          }
          return contentEmpty;
        });
  }
}
