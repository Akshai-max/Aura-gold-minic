import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, prod }

class EnvConfig {
  final AppEnvironment environment;
  final String baseUrl;
  final Duration connectionTimeout;
  final Duration receiveTimeout;

  EnvConfig({
    required this.environment,
    required this.baseUrl,
    this.connectionTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
  });

  static String get _devBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static final EnvConfig dev = EnvConfig(
    environment: AppEnvironment.dev,
    baseUrl: _devBaseUrl,
  );

  static final EnvConfig prod = EnvConfig(
    environment: AppEnvironment.prod,
    baseUrl: 'https://api.agsgold.com/api/v1',
  );

  static EnvConfig get active {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'prod':
        return prod;
      case 'dev':
      default:
        return dev;
    }
  }
}
