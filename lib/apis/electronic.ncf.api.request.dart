import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

Future<Dio> createDioWithClientCert() async {
  if (certFile != null) {
    final context = SecurityContext();

    // Carga los certificados desde assets
    final certBytes = await certFile?.readAsBytes();

    context.useCertificateChainBytes(certBytes!, password: certPassword.text);

    final httpClient = HttpClient(context: context);
    final adapter = IOHttpClientAdapter();
    adapter.createHttpClient = () => httpClient;

    final dio = Dio();
    dio.httpClientAdapter = adapter;

    return dio;
  }
  return Dio();
}



Future<String> extraerInfoPfx({
  required String path,
  required String password,
}) async {
  final process = await Process.start(
    'openssl',
    [
      'pkcs12',
      '-in',
      path,
      '-clcerts',
      '-nokeys',
      '-passin',
      'pass:$password',
      '-legacy'
    ],
  );

  final outputBytes = <int>[];
  final errorBytes = <int>[];

  // Captura stdout y stderr como bytes crudos
  process.stdout.listen(outputBytes.addAll);
  process.stderr.listen(errorBytes.addAll);

  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    final err = utf8.decode(errorBytes, allowMalformed: true);
    throw Exception('OpenSSL error: $err');
  }

  final result = utf8.decode(outputBytes, allowMalformed: true);
  return result;
}
