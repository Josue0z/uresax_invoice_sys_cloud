import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:ecf_dgii/ecf_dgii.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/models/bank.dart';
import 'package:uresax_invoice_sys_cloud/models/company.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/credit.note.product.dart';
import 'package:uresax_invoice_sys_cloud/models/currency.dart';
import 'package:uresax_invoice_sys_cloud/models/dgiiStates.dart';
import 'package:uresax_invoice_sys_cloud/models/ncftype.dart';
import 'package:uresax_invoice_sys_cloud/models/override.codes.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.method.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.mode.dart';
import 'package:uresax_invoice_sys_cloud/models/payment.type.dart';
import 'package:uresax_invoice_sys_cloud/models/permission.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/retention.isr.dart';
import 'package:uresax_invoice_sys_cloud/models/retention.tax.dart';
import 'package:uresax_invoice_sys_cloud/models/role.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.item.service.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.product.dart';
import 'package:uresax_invoice_sys_cloud/models/symbol.dart';
import 'package:uresax_invoice_sys_cloud/models/taxes.dart';
import 'package:uresax_invoice_sys_cloud/models/type.income.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart' as pos;

import 'package:pdf_plus/signing.dart'
    as pdfpluss; // signing and validation       // PKI helpers

final List<OverlayEntry> activeSnackbars = [];

final List<AnimationController> activeAnimationControllers = [];
Future<void> closeAllSnackbars() async {
  await Future.wait([
    for (int i = 0; i < activeAnimationControllers.length; i++)
      (() async {
        final controller = activeAnimationControllers[i];
        final entry = activeSnackbars[i];

        if (controller.status == AnimationStatus.completed ||
            controller.status == AnimationStatus.forward) {
          await controller.reverse();
        }

        if (entry.mounted) {
          entry.remove();
        }

        controller.dispose();
      })()
  ]);

  activeSnackbars.clear();
  activeAnimationControllers.clear();
}

void showTopSnackBar(BuildContext context,
    {required String message,
    Color color = Colors.black,
    Color fontColor = Colors.white,
    Alignment alignment = Alignment.bottomCenter,
    Duration timeout = const Duration(seconds: 5),
    List<Widget> actions = const []}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  final controller = AnimationController(
    vsync: Navigator.of(context),
    duration: const Duration(milliseconds: 200),
  );

  final animation = Tween<Offset>(
    begin: alignment == Alignment.bottomCenter
        ? const Offset(0, 1)
        : const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 20,
      right: 20,
      top: alignment == Alignment.topCenter
          ? kToolbarHeight + kDefaultPadding
          : null,
      bottom: alignment == Alignment.bottomCenter
          ? kToolbarHeight + kDefaultPadding
          : null,
      child: SlideTransition(
        position: animation,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(10),
          color: color,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: fontColor, fontSize: 16),
                  ),
                ),
                ...actions,
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    controller.reverse().then((_) {
                      entry.remove();
                      activeSnackbars.remove(entry);
                      activeAnimationControllers.remove(controller);
                      controller.dispose();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  activeAnimationControllers.add(controller);
  activeSnackbars.add(entry);
  controller.forward();

  Future.delayed(timeout, () {
    if (controller.isForwardOrCompleted) {
      controller.reverse().then((_) {
        entry.remove();
        activeSnackbars.remove(entry);
        activeAnimationControllers.remove(controller);
        controller.dispose();
      });
    }
  });
}

Future<Directory> getUresaxInvoiceDir() async {
  var dir = Directory(path.join(
      localStorage.getItem('URESAX_INVOICE_STATIC_LOCAL_SERVER_PATH') ??
          Platform.environment['URESAX_INVOICE_STATIC_LOCAL_SERVER_PATH'] ??
          'x',
      'URESAX-INVOICE',
      company?.name?.trim()));

  return await dir.create(recursive: true);
}

Future<Directory?> pickerFolder() async {
  if (Platform.isWindows) {
    final result = await Process.run(
      'powershell',
      [
        '-command',
        r'Add-Type -AssemblyName System.Windows.Forms; '
        r'$f = New-Object System.Windows.Forms.FolderBrowserDialog; '
        r'if($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){ $f.SelectedPath }'
      ],
      runInShell: true,
    );

    final folderPath = (result.stdout as String).trim();
    if (folderPath.isNotEmpty) {
      return Directory(folderPath);
    }
  }
  return null;
}

Future<void> launchFile(String path) async {
  ProcessResult? result;

  if (Platform.isMacOS) {
    result = await Process.run('open', [path]);
  }

  if (Platform.isWindows) {
    result = await Process.run('cmd', ['/c', 'start', '', path]);
  }
  if (result?.exitCode == 0) {
  } else {}
}

Future<bool> isValidCertFilePath({Company? company}) async {
  try {
    var filePath = certFile?.path ??
        localStorage.getItem('certFilePath_${company?.id}')?.trim();

    certFile = File(filePath ?? '');

    var password = certPassword.text.isNotEmpty
        ? certPassword.text
        : localStorage.getItem('certPassword_${company?.id}') ?? '';

    // var data = await extraerInfoPfx(path: filePath ?? '', password: password);
    var request = http.MultipartRequest(
        'POST', Uri.parse('https://api.uresax.com/ecf/verificarcertificado'))
      ..headers['accept'] = 'application/json'
      ..headers['x-tempdirname'] = company?.name?.toUpperCase() ?? ''

      // archivo del certificado
      ..files.add(await http.MultipartFile.fromPath(
        'cert',
        certFile?.path ?? '',
        contentType:
            MediaType('application', 'x-pkcs12'), // o según el tipo real
        filename: path.basename(certFile?.path ?? ''),
      ))
      ..fields['password'] = password;

    final response = await request.send();
    await response.stream.bytesToString();

    if (response.statusCode == 200 && password.isNotEmpty == true) {
      isValid = true;
      currentElectronicNcfOption = 1;
      electronicNcfEnabled = true;

      return true;
    } else {
      return false;
    }
  } catch (e) {
    await LogHandler.printError(e.toString());
    isValid = false;
    currentElectronicNcfOption = 2;
    electronicNcfEnabled = false;
    return false;
  }
}

Future<bool?> hasInternet() async {
  try {
    final result = await http
        .get(Uri.parse('https://api.uresax.com'))
        .timeout(const Duration(seconds: 5));

    if (result.statusCode == 200) {
      return true; // OK
    } else {
      throw 'Servidor respondió con código: ${result.statusCode}';
    }
  } on SocketException {
    throw 'Error de red: no hay conexión o DNS NXDOMAIN';
  } on TimeoutException {
    throw 'Timeout al intentar conectar con el servidor';
  } catch (e) {
    throw 'Error inesperado: $e';
  }
}

showLoader(BuildContext context) async {
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return SizedBox(
          width: double.infinity,
          child: AlertDialog(
            constraints: BoxConstraints(minWidth: 120, maxHeight: 120),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(30)),
            content: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      });
}

String getCertPassword() {
  return localStorage.getItem('certPassword_${company?.id}') ?? '';
}

File getCertFile() {
  return File(localStorage.getItem('certFilePath_${company?.id}') ?? '');
}

String calcularCodigoModificacion(
    DateTime fechaNcfModificado, DateTime fechaEmisionActual) {
  final diferencia = fechaEmisionActual.difference(fechaNcfModificado).inDays;
  return diferencia > 30 ? '1' : '0';
}

String getItbisCode({
  required bool esNotaCredito,
  required bool canOverrideTaxes,
  required double gravado18,
  required double gravado16,
  required double gravado3,
  required double originalGravado18,
  required double originalGravado16,
}) {
  if (esNotaCredito) {
    if (!canOverrideTaxes) {
      if (originalGravado18 > 0) return '18';
      if (originalGravado16 > 0) return '16';
      return '';
    } else {
      if (originalGravado18 > 0 || originalGravado16 > 0) return '0';
      return '';
    }
  }
  if (gravado18 > 0) return '18';
  if (gravado16 > 0) return '16';
  if (gravado3 > 0) return '0';
  return '';
}

Future<void> enviarDgii(
    {required Sale sale,
    required Sale instanceSale,
    required Sale? currentSale,
    required String? currentNcfTypeId,
    required TextEditingController clientName,
    required TextEditingController rncOrId,
    required double xrate,
    required List<FormaDePago> formasDePagos,
    required double totalGravado,
    required double totalGravado18,
    required double totalGravado16,
    required double totalGravado3,
    required double montoExento,
    required double itbisGravado,
    required double itbisGravado18,
    required double itbisGravado16,
    required double itbisGravado0,
    required double totalRetencionItbis,
    required double totalRetencionIsr,
    required double totalFacturado,
    required DateTime fechaVencimiento,
    required int? currentPaymentMethodId,
    required int? currentPaymentType,
    required String? currentTypeIncomeId,
    required int? currentOverrideCode,
    required bool canOverrideTaxes}) async {
  dynamic estado;
  dynamic estadoEcf;
  int? code;
  try {
    String endPointApi = '';

    if (enabledEcfProduction) {
      GeneratorEndPoint.envEcfType = EnvEcfType.ecf;
      if (enabledRemoteSigned) {
        endPointApi =
            'https://api.uresax.com/produccion/fe/facturaselectronicasnofirmadas/api/ecf';
      } else {
        endPointApi =
            'https://api.uresax.com/produccion/fe/facturaselectronicas/api/ecf';
      }
    } else {
      GeneratorEndPoint.envEcfType = EnvEcfType.testEcf;
      if (enabledRemoteSigned) {
        endPointApi =
            'https://api.uresax.com/prueba/fe/facturaselectronicasnofirmadas/api/ecf';
      } else {
        endPointApi =
            'https://api.uresax.com/prueba/fe/facturaselectronicas/api/ecf';
      }
    }
    final cert = certFile;

    String password = localStorage.getItem('certPassword_${company?.id}') ?? '';

    EcfType ecfType = EcfType.e31;

    if (currentNcfTypeId == '31') {
      ecfType = EcfType.e31;
    }
    if (currentNcfTypeId == '32') {
      ecfType = EcfType.e32;
    }

    if (currentNcfTypeId == '33') {
      ecfType = EcfType.e33;
    }

    if (currentNcfTypeId == '34') {
      ecfType = EcfType.e34;
    }

    if (currentNcfTypeId == '41') {
      ecfType = EcfType.e41;
    }

    if (currentNcfTypeId == '43') {
      ecfType = EcfType.e43;
    }

    if (currentNcfTypeId == '44') {
      ecfType = EcfType.e44;
    }

    if (currentNcfTypeId == '45') {
      ecfType = EcfType.e45;
    }

    if (currentNcfTypeId == '46') {
      ecfType = EcfType.e46;
    }

    if (currentNcfTypeId == '47') {
      ecfType = EcfType.e47;
    }

    bool esNotaCredito = ecfType == EcfType.e34;

    bool esConsumo = ecfType == EcfType.e32;

    bool esEcf45 = ecfType == EcfType.e45;

    bool esEcf44 = ecfType == EcfType.e44;

    bool esEcf43 = ecfType == EcfType.e43;

    bool esEcf41 = ecfType == EcfType.e41;

    bool esEspecial = esConsumo || esEcf45 || esEcf44;

    bool esConsumox = esConsumo && sale.total! < 250000;

    bool esConsumoxx = false;

    if (currentSale != null) {
      esConsumoxx = esConsumo && currentSale.total! < 250000;
    }

    if (cert == null) {
      throw 'NO SE HA CONFIGURADO EL CERTIFICADO DIGITAL, NO PUEDE CONTINUAR';
    }
    AuthCertModel? authModel;

    if (!enabledRemoteSigned) {
      authModel = await getAuthP12(cert: cert, password: password);
      await LogHandler.printEvent(
          'EL CODIGO BASE 64 ${authModel.certBase64} FUE CREADO');
    }

    final dateFormat = DateFormat('dd-MM-yyyy');

    final fechaEmision = dateFormat.format(sale.issueDate!);

    String rncEmisor = company?.rncOrId?.trim().replaceAll('-', '') ?? '';

    String rncComprador = rncOrId.text.replaceAll('-', '');
    List<EcfDetailsModel> items = [];

    items = sale.items.map((item) {
      List<ImpuestoAdicional> impuestos = [];
      List<SubDescuento> descuentos = [];

      if (item.law10! > 0) {
        impuestos.add(ImpuestoAdicional(tipoImpuesto: '001'));
      }

      if (item.discount! > 0) {
        descuentos.add(SubDescuento(
            tipoSubDescuento: item.discountSymbol.toString(),
            subDescuentoPorcentaje: item.discountSymbol == '%'
                ? item.discountRate?.toStringAsFixed(2) ?? ''
                : '',
            montoSubDescuento: item.discount?.toStringAsFixed(2) ?? ''));
      }

      return EcfDetailsModel(
          cantidad: item is SaleItemProduct || item is CreditNoteProduct
              ? item.units?.toStringAsFixed(2) ?? ''
              : item.quantity?.toStringAsFixed(2) ?? '',
          unidadMedida: '',
          indicadorFacturacion: item.indicadorFacturacion.toString(),
          indicadorBienOServ:
              item is SaleItemService || item is CreditNoteService ? '2' : '1',
          nombreItem: item.serviceName != null
              ? item.serviceName?.split(' ')[0] ?? ''
              : item.productName?.split(' ')[0] ?? '',
          descripcionItem: item.serviceName != null
              ? item.serviceName ?? ''
              : item.productName ?? '',
          precioUnitario: item is SaleItemProduct || item is CreditNoteProduct
              ? (item.priceUnit! * xrate).toStringAsFixed(2)
              : (item.price! * xrate).toStringAsFixed(2),
          descuentoMonto: item.discount?.toStringAsFixed(2) ?? '',
          subDescuentos: descuentos,
          impuestosAdicionales: impuestos,
          retencion: esEspecial || esEcf43
              ? null
              : item.retentionTax != 0 || item.retentionIsr != 0
                  ? Retencion(
                      indicadorAgenteRetencionoPercepcion:
                          item.indicadorAgentePercepcion.toString(),
                      montoITBISRetenido: item.retentionTax != null
                          ? (item.retentionTax! * xrate).toStringAsFixed(2)
                          : '',
                      montoISRRetenido: item.retentionIsr != null
                          ? (item.retentionIsr! * xrate).toStringAsFixed(2)
                          : '')
                  : null,
          otraMonedaDetalles: [],
          montoItem: item.netFinal != null
              ? (item.netFinal! * xrate).toStringAsFixed(2)
              : '');
    }).toList();

    await LogHandler.printEvent(
        'SE INICIO LA CREACION DEL COMPROBANTE ${sale.ncf}');

    if (sale.effective! > 0) {
      formasDePagos.add(
          FormaDePago('1', ((sale.effective ?? 0) * xrate).toStringAsFixed(2)));
    }

    if (sale.creditCard! > 0) {
      formasDePagos.add(FormaDePago(
          '2', ((sale.creditCard ?? 0) * xrate).toStringAsFixed(2)));
    }
    if (sale.checkOrTransf! > 0) {
      formasDePagos.add(FormaDePago(
          '3', ((sale.checkOrTransf ?? 0) * xrate).toStringAsFixed(2)));
    }

    if (sale.saleToCredit! > 0) {
      formasDePagos.add(FormaDePago(
          '4', ((sale.saleToCredit ?? 0) * xrate).toStringAsFixed(2)));
    }

    List<ImpuestoAdicional> impuestos = [];

    double otherTaxes = 0;

    if (sale.law10! > 0) {
      otherTaxes += sale.law10! * xrate;
      impuestos.add(ImpuestoAdicional(
          tipoImpuesto: '001',
          tasaImpuestoAdicional: '10',
          otrosImpuestosAdicionales: (sale.law10! * xrate).toStringAsFixed(2)));
    }

    EcfModel ecf = EcfModel(
        tipoEcf: ecfType,
        tempDirName: company?.name?.toUpperCase() ?? 'temp_7',
        indicadorMontoGravado: esEcf44
            ? ''
            : totalGravado > 0
                ? '0'
                : '',
        indicadorNotaCredito: esNotaCredito
            ? esConsumoxx
                ? '1'
                : calcularCodigoModificacion(
                    currentSale!.issueDate!, instanceSale.issueDate!)
            : '',
        numeroComprobante: sale.ncf ?? '',
        numeroComprobanteModificado: currentSale?.ncf ?? '',
        rncOtroContribuyente: '',
        codigoModificacion: esNotaCredito ? currentOverrideCode.toString() : '',
        fechaEmision: fechaEmision,
        fechaVencimiento: esNotaCredito || esConsumo
            ? ''
            : fechaVencimiento.format(payload: 'DD-MM-YYYY'),
        fechaEmisionNcfModificado: esNotaCredito
            ? currentSale?.issueDate?.format(payload: 'DD-MM-YYYY') ?? ''
            : '',
        fechaLimitePago: esEcf43
            ? ''
            : esEcf41
                ? ''
                : currentPaymentType == 1
                    ? ''
                    : fechaVencimiento.format(payload: 'DD-MM-YYYY'),
        razonModificacion: '',
        tipoIngreso: esEcf43 || esEcf41 ? '' : currentTypeIncomeId.toString(),
        tipoPago: esEcf41
            ? '1'
            : esEcf43
                ? '1'
                : currentPaymentType.toString(),
        formasDePagos: esNotaCredito || esEcf43 ? [] : formasDePagos,
        sucursal: '',
        direccionEmisor: company?.address ?? '',
        municipio: '',
        provincia: '',
        telefonoEmisor1: '',
        telefonoEmisor2: '',
        telefonoEmisor3: '',
        totalPaginas: '',
        rncEmisor: rncEmisor,
        razonSocialEmisor: company?.name ?? '',
        nombreComercial: '',
        correoEmisor: company?.email ?? '',
        website: '',
        actividadEconomica: '',
        codigoVendedor: '',
        informacionAdicionalEmisor: '',
        rncComprador: esConsumox || esEcf43 ? '' : rncComprador,
        identificadorExtranjero: '',
        razonSocialComprador:
            esConsumox || esEcf43 ? '' : clientName.text.trim(),
        nombreComprador: '',
        contactoComprador: '',
        correoComprador: '',
        telefonoAdicional: '',
        direccionComprador: '',
        municipioComprador: '',
        provinciaComprador: '',
        codigoInternoComprador: '',
        fechaEntrega: '',
        fechaOrdenCompra: '',
        numeroOrdenCompra: '',
        numeroFacturaInterna: '',
        numeroPedidoInterno: '',
        zonaVenta: '',
        rutaVenta: '',
        paisDestino: '',
        conductor: '',
        documentoTransporte: '',
        ficha: '',
        placa: '',
        rutaTransporte: '',
        zonaTransporte: '',
        numeroAlbaran: '',
        totalGravado: esEcf44
            ? ''
            : totalGravado > 0
                ? totalGravado.toStringAsFixed(2)
                : '',
        totalGravado18: esEcf44
            ? ''
            : totalGravado18 > 0
                ? totalGravado18.toStringAsFixed(2)
                : '',
        totalGravado16: esEcf44
            ? ''
            : totalGravado16 > 0
                ? totalGravado16.toStringAsFixed(2)
                : '',
        totalGravadoTasa0: esEcf44
            ? ''
            : totalGravado3 > 0
                ? totalGravado3.toStringAsFixed(2)
                : '',
        montoExento: montoExento > 0 ? montoExento.toStringAsFixed(2) : '',
        totalItbis: canOverrideTaxes
            ? '0.00'
            : itbisGravado > 0
                ? itbisGravado.toStringAsFixed(2)
                : '',
        totalItbis18:
            itbisGravado18 > 0 ? itbisGravado18.toStringAsFixed(2) : '',
        totalItbis16:
            itbisGravado16 > 0 ? itbisGravado16.toStringAsFixed(2) : '',
        totalItbisTasa0: canOverrideTaxes
            ? '0.00'
            : itbisGravado0 > 0
                ? itbisGravado0.toStringAsFixed(2)
                : '',
        itbis1: esEcf44
            ? ''
            : getItbisCode(
                esNotaCredito: esNotaCredito,
                canOverrideTaxes: canOverrideTaxes,
                gravado18: itbisGravado18,
                gravado16: 0,
                gravado3: 0,
                originalGravado18: currentSale?.tax18 ?? 0,
                originalGravado16: 0,
              ),
        itbis2: esEcf44
            ? ''
            : getItbisCode(
                esNotaCredito: esNotaCredito,
                canOverrideTaxes: canOverrideTaxes,
                gravado18: 0,
                gravado16: itbisGravado16,
                gravado3: 0,
                originalGravado18: 0,
                originalGravado16: currentSale?.tax16 ?? 0,
              ),
        itbis3: (esNotaCredito && canOverrideTaxes) || esEcf44
            ? getItbisCode(
                esNotaCredito: esNotaCredito,
                canOverrideTaxes: canOverrideTaxes,
                gravado18: 0,
                gravado16: 0,
                gravado3: totalGravado3,
                originalGravado18: currentSale?.tax18 ?? 0,
                originalGravado16: currentSale?.tax16 ?? 0,
              )
            : '',
        montoTotal: totalFacturado > 0 ? totalFacturado.toStringAsFixed(2) : '',
        montoNoFacturable: '',
        montoPeriodo: '',
        montoAvancePago: '',
        valorPagar: esEcf45 ? totalFacturado.toStringAsFixed(2) : '',
        tipoMoneda: '',
        tipoCambio: '',
        montoGravadoTotalOtraMoneda: '',
        montoGravadoTotalOtraMoneda1: '',
        montoGravadoTotalOtraMoneda2: '',
        montoGravadoTotalOtraMoneda3: '',
        totalItbisOtraMoneda: '',
        totalItbis1OtraMoneda: '',
        totalItbis2OtraMoneda: '',
        totalItbis3OtraMoneda: '',
        montoExentoOtraMoneda: '',
        montoTotalOtraMoneda: '',
        totalItbisRetencion: esEspecial || esEcf43
            ? ''
            : totalRetencionItbis > 0
                ? totalRetencionItbis.toStringAsFixed(2)
                : '0.00',
        totalIsrRetencion: esEspecial || esEcf43
            ? ''
            : totalRetencionIsr > 0
                ? totalRetencionIsr.toStringAsFixed(2)
                : '0.00',
        montoImpuestoAdicional:
            otherTaxes > 0 ? otherTaxes.toStringAsFixed(2) : '',
        impuestosAdicionales: impuestos,
        terminoPago: '',
        bancoPago: '',
        paginas: [],
        items: items,
        privateKey: authModel?.privateKey ?? '',
        certBase64: authModel?.certBase64 ?? '');

    var xmlFile = File(path.join(Directory.systemTemp.path,
        company?.name?.toUpperCase(), '$rncEmisor${sale.ncf}.xml'));
    late http.MultipartRequest request;

    if (enabledRemoteSigned) {
      await xmlFile.create(recursive: true);
      if (esConsumox) {
        await xmlFile.writeAsString(ecf.xmle32);
      } else {
        await xmlFile.writeAsString(ecf.xmlDefault);
      }

      request = http.MultipartRequest('POST', Uri.parse(endPointApi))
        ..headers['accept'] = 'application/json'
        ..headers['x-tempdirname'] = company?.name?.toUpperCase() ?? ''
        ..files.add(await http.MultipartFile.fromPath(
          'xml',
          xmlFile.path,
          contentType: MediaType('text', 'xml'),
          filename: path.basename(xmlFile.path),
        ))
        // archivo del certificado
        ..files.add(await http.MultipartFile.fromPath(
          'cert',
          certFile?.path ?? '',
          contentType:
              MediaType('application', 'x-pkcs12'), // o según el tipo real
          filename: path.basename(certFile?.path ?? ''),
        ))
        ..fields['password'] = password;
    } else {
      await LogHandler.printEvent(
          'SE INICIO EL PROCESO DE ENVIO A DGII DEL COMPROBANTE ${sale.ncf}');

      await ecf.descargarSemilla();
      await LogHandler.printEvent(
          'SE DESCARGO LA SEMILLA SIN FIRMAR DEL COMPROBANTE ${sale.ncf}');
      await ecf.validarSemilla();

      await LogHandler.printEvent(
          'SE VALIDO LA SEMILLA DEL COMPROBANTE ${sale.ncf}');
      await ecf.firmar();

      await LogHandler.printEvent(
          'SE FIRMO EL XML DEL COMPROBANTE ${sale.ncf}');

      request = http.MultipartRequest('POST', Uri.parse(endPointApi))
        ..headers['accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer ${ecf.token}'
        ..files.add(await http.MultipartFile.fromPath(
          'xml',
          ecf.ecfFile!.path,
          contentType: MediaType('text', 'xml'),
          filename: path.basename(ecf.ecfFile!.path),
        ));
    }

    final response = await request.send().timeout(const Duration(seconds: 70));

    code = response.statusCode;

    final body = await response.stream.bytesToString();

    await LogHandler.printEvent(body);

    if (code != 200) {
      throw 'NO FUE POSIBLE ENVIAR LA FACTURA ${sale.ncf} A DGII, CONTACTE CON EL ADMINISTRADOR DEL SISTEMA, ESTADO DE CODIGO [${response.statusCode}]\n$body';
    }

    print(body);

    estado = jsonDecode(body);

    if (enabledRemoteSigned) {
      estadoEcf = estado;
    }

    dynamic fechaFirma;
    dynamic url;
    dynamic xmlFirmado;
    dynamic codigoSeguridad;

    ecf.trackId = estado['trackId'] ?? '';

    await LogHandler.printEvent(estado.toString());

    if (!enabledRemoteSigned) {
      if (ecf.trackId != '') {
        await Future.delayed(const Duration(milliseconds: 600));
        estado = await ecf.obtenerEcfEstadoDatos();
        print(estado);

        await LogHandler.printEvent(estado.toString());
      }
    }

    DateFormat xdateFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
    if (enabledRemoteSigned) {
      if (estado['codigo'] != 2) {
        var ff = estadoEcf['fechaHoraFirma'];

        if (ff == '' || ff == null) {
          ff = ecf.fechaHoraFirma;
        }

        fechaFirma = xdateFormat.parse(ff);
        url = estadoEcf['ecfUrl'];
        xmlFirmado = estadoEcf['xmlFirmado'];
        codigoSeguridad = estadoEcf['codigoSeguridad'];
      }
    } else {
      fechaFirma = xdateFormat.parse(ecf.fechaHoraFirma);
      url = ecf.uriEcf.toString();
      xmlFirmado = ecf.ecfSignXml;
      codigoSeguridad = ecf.codigoSeguridad;
    }
    sale.dgiiURL = url;
    sale.signatureDate = fechaFirma;
    sale.securityCode = codigoSeguridad;
    sale.ecfXmlFirmado = xmlFirmado;

    await LogHandler.printEvent(
        'SE ACTUALIZO LA INFORMACION DEL COMPROBANTE ELECTRONICO ${sale.ncf}');

    if (estado != null) {
      var codigo = estado['codigo'] is int
          ? estado['codigo']
          : int.parse(estado['codigo']);

      if ((sale is SaleProduct) && codigo != 2) {
        await Products.updateMinusStock(
            items: sale.items, ncfTypeId: sale.ncfTypeId!);
        await LogHandler.printEvent('EL STOCK FUE ACTUALIZADO - ${sale.ncf}');
      }

      if (sale is CreditNoteAsProduct && codigo != 2) {
        await Products.updateAddStock(
            items: sale.items, ncfTypeId: sale.ncfTypeId!);
        await LogHandler.printEvent('EL STOCK FUE ACTUALIZADO - ${sale.ncf}');
      }

      sale.estadoDgii = codigo;

      await sale.updateEcfInfo();

      await LogHandler.printEvent(
          'SE ACTUALIZO EL ESTADO DEL COMPROBANTE ELECTRONICO ${sale.ncf} A DGII, ESTADO: ${sale.estadoDgiiNombre}');
      await xmlFile.delete();
    }
  } catch (e) {
    if (code != 200) {
      await sale.delete();
      await LogHandler.printEvent('SE ELIMINO EL COMPROBANTE ${sale.ncf}');
    }

    if (estado != null) {
      if (estado['secuenciaUtilizada'] == false) {
        await sale.delete();
        await LogHandler.printEvent('SE ELIMINO EL COMPROBANTE ${sale.ncf}');
      }
    }
    rethrow;
  }
}

Future<bool?> showConfirm(BuildContext context,
    {String title = 'Confirmacion...'}) async {
  var formKey = GlobalKey<FormState>();
  TextEditingController code = TextEditingController();

  var number = math.Random().nextInt(999999);

  void ok() {
    if (formKey.currentState!.validate()) {
      Navigator.pop(context, true);
    }
  }

  var result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            content: SizedBox(
                width: 400,
                child: Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(title.toUpperCase(),
                                    style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500)
                                        .copyWith(
                                            color: Theme.of(context)
                                                .primaryColor))),
                          ]),
                          const SizedBox(height: 15),
                          Text('Escribe el siguiente codigo $number',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: code,
                            autofocus: true,
                            onFieldSubmitted: (_) {
                              ok();
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (val) => int.tryParse(val!) != number
                                ? 'El numero digitado no es correcto'
                                : null,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                                hintText: number
                                    .toString()
                                    .characters
                                    .map((e) => '#')
                                    .toList()
                                    .join()),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              const Spacer(),
                              ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Theme.of(context).colorScheme.error)),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text('CERRAR'))),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                  onPressed: ok,
                                  child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text('CONFIRMAR')))
                            ],
                          )
                        ],
                      ),
                    ))),
          ));

  return result == true;
}

Future<bool?> showUserValidator(BuildContext context,
    {String title = 'Introduce tus credenciales...'}) async {
  var formKey = GlobalKey<FormState>();
  TextEditingController password = TextEditingController();

  void ok() async {
    if (formKey.currentState!.validate()) {
      try {
        currentUser?.password = password.text;
        showLoader(context);
        var isCorrect = await currentUser?.verifyUser();

        if (isCorrect == true) {
          Navigator.pop(context);
          Navigator.pop(context, isCorrect);
        }
      } catch (e) {
        Navigator.pop(context);
        showTopSnackBar(context, message: e.toString(), color: Colors.red);
      }
    }
  }

  var result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            content: SizedBox(
                width: 400,
                child: Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(title.toUpperCase(),
                                    style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500)
                                        .copyWith(
                                            color: Theme.of(context)
                                                .primaryColor))),
                          ]),
                          const SizedBox(height: 15),
                          Text('Escribe las credenciales...',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: password,
                            autofocus: true,
                            obscureText: true,
                            onFieldSubmitted: (_) {
                              ok();
                            },
                            validator: (val) =>
                                val!.isEmpty ? 'CAMPO OBLIGATORIO' : null,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(hintText: '********'),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              const Spacer(),
                              ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Theme.of(context).colorScheme.error)),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text('CERRAR'))),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                  onPressed: ok,
                                  child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text('CONFIRMAR')))
                            ],
                          )
                        ],
                      ),
                    ))),
          ));

  return result == true;
}

bool isRemoteVersionGreater(String local, String remote) {
  List<int> localParts =
      local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  List<int> remoteParts =
      remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();

  for (int i = 0; i < localParts.length; i++) {
    if (remoteParts[i] > localParts[i]) return true;
    if (remoteParts[i] < localParts[i]) return false;
  }

  return false;
}

Future<void> printBarcodes({required List<String> codes}) async {
  try {
    final profile = await pos.CapabilityProfile.load();
    final generator = pos.Generator(pos.PaperSize.mm80, profile);

    for (var code in codes) {
      var allBytes = <int>[];
      allBytes += generator.barcode(
        pos.Barcode.code39(code
            .split('')
            .map((e) => int.parse(e))
            .toList()), // tipo de barcode
        width: 2, // grosor de barras
        height: 80, // altura
        textPos: pos.BarcodeText.below, // texto debajo del código
      );

      // salto de línea entre códigos
      allBytes += generator.cut();
      await PrinterHandler.printBytes(devicePosBarcodes ?? '', allBytes);
    }
  } catch (e) {
    print(e);
  }
}

bool esCodigoValido(String code) {
  // Acepta numéricos de 6 a 13 dígitos (UPC/EAN típicos)
  final regexNumerico = RegExp(r'^[0-9]{6,13}$');
  // Acepta alfanuméricos tipo SKU (ej. Amazon: X002CCANUH)
  final regexAlfanumerico = RegExp(r'^[A-Za-z0-9]+$');

  return regexNumerico.hasMatch(code) || regexAlfanumerico.hasMatch(code);
}

Future<void> loadMetaData() async {
  ncfs = [NcfType(name: 'TIPO DE COMPROBANTE'), ...await NcfType.get()];
  paymentsMethods = [
    PaymentMethod(name: 'METODO DE PAGO'),
    ...await PaymentMethod.get()
  ];
  typesIncomes = [
    TypeIncome(name: 'TIPO DE INGRESO'),
    ...await TypeIncome.get()
  ];

  banks = [Bank(name: 'BANCO'), ...await Bank.get()];

  roles = [Role(name: 'ROL'), ...await Role.get()];

  permissions = await Permission.get();

  taxes = [Taxes(name: 'EXENTO'), ...await Taxes.get()];
  currencies = [Currency(name: 'MONEDA'), ...await Currency.get()];
  paymentsTypes = [
    PaymentType(name: 'TIPO DE PAGO'),
    ...await PaymentType.get()
  ];
  paymentsModes = [
    PaymentMode(name: 'MODO DE PAGO'),
    ...await PaymentMode.get()
  ];

  overrideCodes = [
    OverrideCode(name: 'CODIGO DE MODIFICACION'),
    ...await OverrideCode.get()
  ];

  symbols = [SymbolModel(name: 'SIMBOLO'), ...await SymbolModel.get()];

  dgiiStates = [DgiiState(name: 'ESTADO DGII'), ...await DgiiState.get()];

  retentionsTaxes = [
    RetentionTax(name: 'RETENCION ITBIS'),
    ...await RetentionTax.get()
  ];
  retentionsIsrs = [
    RetentionIsr(name: 'RETENCION ISR'),
    ...await RetentionIsr.get()
  ];
}

Future<Uint8List> signaturePdf(File inputFile) async {
  final inputBytes = await File(inputFile.path).readAsBytes();

  final p12Bytes = await getCertFile().readAsBytes();

  var password = getCertPassword();

  final signer = await pdfpluss.PdfSignatureSigner.fromPkcs12Bytes(
      pkcs12Bytes: p12Bytes, password: password);

  final xdoc = pdfpluss.PdfLoadedDocument.fromBytes(inputBytes);

  await xdoc.addSignature(
    pdfpluss.PdfSignatureRequest(
      pageNumber: 1,
      fieldName: 'Signature1',
      signer: signer,
      bounds: pdfpluss.PdfSignatureBounds.topLeft(
        left: 40,
        top: 80,
        width: 220,
        height: 70,
      ),
      reason: 'Approval',
      location: 'Dominican Republic',
    ),
  );

  final signedBytes = await xdoc.save();
  return signedBytes;
}

Future<String?> getMotherboardUUID() async {
  try {
    // Ejecuta PowerShell para obtener el UUID
    var result = await Process.run(
      'powershell',
      [
        '-Command',
        'Get-CimInstance Win32_ComputerSystemProduct | Select-Object -ExpandProperty UUID'
      ],
      runInShell: true,
    );

    if (result.exitCode == 0) {
      var uuid = result.stdout.toString().trim();
      return uuid.isNotEmpty ? uuid : null;
    } else {
      print('Error ejecutando PowerShell: ${result.stderr}');
    }
  } catch (e) {
    print('Error obteniendo UUID: $e');
  }
  return null;
}

String generarCodigoIniciales(String nombre) {
  // Tomamos las iniciales de cada palabra
  List<String> partes = nombre.split(" ");
  String iniciales = partes.map((p) => p[0].toUpperCase()).join();

  // Agregamos un número aleatorio de 4 dígitos
  int randomNum = Random().nextInt(9000) + 1000;

  return "$iniciales-$randomNum";
}
