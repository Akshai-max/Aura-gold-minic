import 'package:flutter/foundation.dart';

/// When [API_LOGS_ONLY]=true, only `[API]` and `[APP_EVENT]` debug lines are printed.
void installApiOnlyDebugLogging() {
  const apiLogsOnly = bool.fromEnvironment('API_LOGS_ONLY');
  if (!kDebugMode || !apiLogsOnly) return;

  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null &&
        (message.contains('[API]') || message.contains('[APP_EVENT]'))) {
      original(message, wrapWidth: wrapWidth);
    }
  };
}

void apiLog(String message) {
  debugPrint(message.startsWith('[API]') ? message : '[API] $message');
}
