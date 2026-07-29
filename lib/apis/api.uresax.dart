

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String apiDomainDebug = 'http://localhost:443';
String apiDomainRelease = 'https://api.uresax.com';
String apiDomain = kDebugMode ? apiDomainDebug : apiDomainRelease;

var apiUresax = Dio(
  BaseOptions(
    baseUrl: apiDomainRelease,
    headers: {
      'x-token':Platform.environment['URESAX_INVOICE_API_TOKEN']
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    contentType: 'application/json'
  ),
);

