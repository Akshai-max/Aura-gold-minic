import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/preferences_service.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> init() async {
    AppBootstrapCache.preferences = await SharedPreferences.getInstance();
  }
}
