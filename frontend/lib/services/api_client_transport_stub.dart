import 'package:dio/dio.dart';

void configureHttpAdapters(
  Dio dio,
  Dio refreshDio,
  Duration connectionTimeout,
) {}

bool isTransportLevelError(Object? error) => false;
