

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

String apiDomainDebug = 'http://localhost:443';
String apiDomainRelease = 'https://api.uresax.com';
String apiDomain = kDebugMode ? apiDomainDebug : apiDomainRelease;



var apiUresax = Dio(
   BaseOptions(
    baseUrl: apiDomainRelease,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    contentType: 'application/json'
));

Future<Dio> createDio(BaseOptions options) async {
  final dio = Dio(
      options
  );
 // Cargar el certificado desde assets como bytes
  final data = await rootBundle.load('assets/certs/isrgrootx1.pem');

  // Guardarlo en un archivo temporal
  final tempDir = await getTemporaryDirectory();
  final certFile = File('${tempDir.path}/isrgrootx1.pem');
  await certFile.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true
  );
  // Crear un SecurityContext y cargar el root/intermedio
  final context = SecurityContext(withTrustedRoots: true);
  // Asegúrate de tener el archivo isrgrootx1.pem en assets/
  context.setTrustedCertificates(certFile.path);

  // Usar IOHttpClientAdapter en lugar de DefaultHttpClientAdapter
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      return HttpClient(context: context);
    },
  );

  return dio;
}