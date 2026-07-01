import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/app_update/data/app_update_repository.dart';
import 'package:ags_gold/services/service_providers.dart';

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return AppUpdateRepository(ref.watch(apiClientProvider));
});
