import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureHttpAdapters(
  Dio dio,
  Dio refreshDio,
  Duration connectionTimeout,
) {
  final adapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.connectionTimeout = connectionTimeout;
      return client;
    },
  );
  dio.httpClientAdapter = adapter;
  refreshDio.httpClientAdapter = adapter;
}

bool isTransportLevelError(Object? error) =>
    error is SocketException || error is HttpException;
