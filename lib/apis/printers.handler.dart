import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.abs.dart';
import 'package:uresax_invoice_sys_cloud/pages/pdf.view_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';

const int PRINTER_STATUS_PAUSED = 0x00000001;
const int PRINTER_STATUS_ERROR = 0x00000002;
const int PRINTER_STATUS_PENDING_DELETION = 0x00000004;
const int PRINTER_STATUS_PAPER_JAM = 0x00000008;
const int PRINTER_STATUS_PAPER_OUT = 0x00000010;
const int PRINTER_STATUS_MANUAL_FEED = 0x00000020;
const int PRINTER_STATUS_OFFLINE = 0x00000080;

class PrinterHandler {
  /// Detecta la plataforma actual
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;

  /// Lista las impresoras disponibles
  static Future<List<String>> listPrinters() async {
    if (isWindows) {
      final result = await Process.run('powershell',
          ['-Command', 'Get-Printer | ForEach-Object { \$_.Name }']);
      return LineSplitter.split(result.stdout.toString())
          .where((line) => line.trim().isNotEmpty)
          .toList();
    } else if (isMacOS) {
      final result = await Process.run('lpstat', ['-p']);

      final printers = LineSplitter.split(result.stdout.toString())
          .map((line) {
            return line.split(' ')[2];
          })
          .whereType<String>()
          .toList();
      return printers;
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }
  }

  static Future<List<Map<String, String>>> listSerialDevices() async {
    if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        '-Command',
        '''
      Get-WmiObject Win32_SerialPort | Where-Object { \$_.PNPDeviceID -like "USB*" } | ForEach-Object { "\$(\$_.Name)|\$(\$_.DeviceID)" }
      '''
      ]);

      print(result.stdout); // Para depurar

      return LineSplitter.split(result.stdout.toString())
          .where((line) => line.contains('|'))
          .map((line) {
        final parts = line.split('|');
        return {
          'name': parts[0].trim(),
          'deviceId': parts[1].trim(),
        };
      }).toList();
    } else {
      throw UnsupportedError('Solo compatible con Windows');
    }
  }

  /// Imprime un PDF desde bytes en Windows, macOS o Linux
  static Future<void> printPdfBytes(
      String printerName, List<int> pdfBytes) async {
    // Guarda los bytes en un archivo temporal
    final tempDir = Directory.systemTemp;
    final tempFile =
        File('${tempDir.path}${Platform.pathSeparator}temp_print.pdf');
    await tempFile.writeAsBytes(pdfBytes);

    if (Platform.isMacOS || Platform.isLinux) {
      // Usa el comando 'lp' para enviar el archivo al spool de impresión
      final result =
          await Process.run('lp', ['-d', printerName, tempFile.path]);
      if (result.exitCode != 0) {
        stderr.writeln('Error al imprimir en macOS/Linux: ${result.stderr}');
      }
    } else if (Platform.isWindows) {
      // Usa Adobe Reader si está disponible
      final adobePath =
          Platform.environment['URESAX_INVOICE_ADOBE_READER_PATH'] ??
              'C:\\xxx.txt';
      if (await File(adobePath).exists()) {
        final result = await Process.run(adobePath, ['/p', tempFile.path]);
        if (result.exitCode != 0) {
          stderr
              .writeln('Error al imprimir con Adobe Reader: ${result.stderr}');
        }
      } else {
        // Alternativa: usar el comando 'print' (solo para archivos de texto)
        final result = await Process.run(
            'cmd', ['/c', 'print /d:"$printerName" "${tempFile.path}"']);
        if (result.exitCode != 0) {
          stderr.writeln('Error al imprimir con cmd: ${result.stderr}');
        }
      }
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }

    // Limpieza opcional
    await tempFile.delete();
  }


  /// Imprime los bytes ESC/POS en la impresora seleccionada
  static Future<void> printBytes(
      String printerName, List<int> escPosBytes) async {
    if (isWindows) {
      final printerNamePtr = printerName.toNativeUtf16();
      final docInfo = calloc<DOC_INFO_1>();
      docInfo.ref.pDocName = 'Uresax Invoice Sys POS - $printerName'.toNativeUtf16();
      docInfo.ref.pOutputFile = nullptr;
      docInfo.ref.pDatatype = 'RAW'.toNativeUtf16();

      final hPrinter = calloc<HANDLE>();
      final success = OpenPrinter(printerNamePtr, hPrinter, nullptr);

      if (success == 0) {
        calloc.free(printerNamePtr);
        calloc.free(hPrinter);
        free(docInfo);
        throw 'No se pudo abrir la impresora';
      }

      // Consultar estado de la impresora
      final infoSizePtr = calloc<Uint32>();
      GetPrinter(hPrinter.value, 2, nullptr, 0, infoSizePtr);
      final bufferSize = infoSizePtr.value;
      final buffer = calloc<Uint8>(bufferSize);

      final okStatus =
          GetPrinter(hPrinter.value, 2, buffer, bufferSize, infoSizePtr);
      if (okStatus == 0) {
        final errorCode = GetLastError();
        ClosePrinter(hPrinter.value);
        calloc.free(printerNamePtr);
        calloc.free(hPrinter);
        free(docInfo);
        calloc.free(infoSizePtr);
        calloc.free(buffer);
        throw 'No se pudo obtener estado de la impresora. Código: $errorCode';
      }

      final printerInfo = buffer.cast<PRINTER_INFO_2>().ref;
      if ((printerInfo.Status & PRINTER_STATUS_OFFLINE) != 0) {
        ClosePrinter(hPrinter.value);
        calloc.free(printerNamePtr);
        calloc.free(hPrinter);
        free(docInfo);
        calloc.free(infoSizePtr);
        calloc.free(buffer);
        throw 'La impresora está desconectada o apagada';
      }
      if ((printerInfo.Status & PRINTER_STATUS_PAPER_OUT) != 0) {
        throw 'La impresora no tiene papel';
      }
      if ((printerInfo.Status & PRINTER_STATUS_ERROR) != 0) {
        throw 'La impresora está en error';
      }

      calloc.free(infoSizePtr);
      calloc.free(buffer);

      // Iniciar impresión
      StartDocPrinter(hPrinter.value, 1, docInfo);
      StartPagePrinter(hPrinter.value);

      final dataPtr = calloc<Uint8>(escPosBytes.length);
      final byteList = dataPtr.asTypedList(escPosBytes.length);
      byteList.setAll(0, escPosBytes);

      final bytesWrittenPtr = calloc<Uint32>();
      final ok = WritePrinter(
        hPrinter.value,
        dataPtr,
        escPosBytes.length,
        bytesWrittenPtr,
      );

      if (ok == 0 || bytesWrittenPtr.value != escPosBytes.length) {
        final errorCode = GetLastError();

        EndPagePrinter(hPrinter.value);
        EndDocPrinter(hPrinter.value);
        ClosePrinter(hPrinter.value);
        calloc.free(printerNamePtr);
        calloc.free(dataPtr);
        calloc.free(hPrinter);
        free(docInfo);
        calloc.free(bytesWrittenPtr);

        throw 'Error al imprimir. Código: $errorCode';
      }

      calloc.free(bytesWrittenPtr);

      // Cierre normal
      EndPagePrinter(hPrinter.value);
      EndDocPrinter(hPrinter.value);
      ClosePrinter(hPrinter.value);

      calloc.free(printerNamePtr);
      calloc.free(dataPtr);
      calloc.free(hPrinter);
      free(docInfo);
    } else if (isMacOS) {
      final process = await Process.start('lp', ['-d', printerName]);
      process.stdin.add(escPosBytes);
      await process.stdin.close();
      await process.exitCode;
    } else {
      throw 'Plataforma no soportada';
    }
  }

  static Future<void> showPdfView(
      {required BuildContext context,
      required List<int> bytes,
      required Document document,
      required Sale sale}) async {
    try {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => PDFScreen(
                    bytes: bytes,
                    document: document,
                    fileName: '${sale.ncf}_${company?.name}.PDF',
                  )));
    } catch (e) {
      throw UnsupportedError('No se puede mostrar el pdf');
    }
  }
}
