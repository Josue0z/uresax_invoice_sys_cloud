import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart' as pos;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'dart:ui' as ui;


Uint8List mergeUint8List(List<Uint8List> list) {
  // Calcula el tamaño total
  final totalLength = list.fold<int>(0, (sum, item) => sum + item.length);

  // Crea un buffer con el tamaño total
  final result = Uint8List(totalLength);

  // Copia cada bloque en el buffer final
  int offset = 0;
  for (final item in list) {
    result.setRange(offset, offset + item.length, item);
    offset += item.length;
  }

  return result;
}

Widget buildBarcode(String data) {
  final bc = Barcode.code128();
  final svg = bc.toSvg(data, width: 200, height: 80, drawText: true);

  return Container(
    margin: EdgeInsets.symmetric(vertical: kDefaultPadding),
    child: SvgPicture.string(svg),
  );
}

class BarcodeList extends StatelessWidget {
  final List<String> codes;

  const BarcodeList({required this.codes});

  Future<void> printBarcodes() async {
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
        await PrinterHandler.printBytes(devicePos ?? '', allBytes);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('BARCODES (${codes.length})'),
          actions: [
            CircleAvatar(
              child: IconButton(
                  onPressed: () => printBarcodes(), icon: Icon(Icons.print)),
            ),
            SizedBox(
              width: kDefaultPadding,
            )
          ],
        ),
        body: SingleChildScrollView(
            child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: codes.map((c) => buildBarcode(c)).toList(),
          ),
        )));
  }
}

Future<Uint8List> svgToImageBytes(String svg) async {
  final pictureInfo = await vg.loadPicture(SvgStringLoader(svg), null);
  final image = await pictureInfo.picture.toImage(200, 80);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
