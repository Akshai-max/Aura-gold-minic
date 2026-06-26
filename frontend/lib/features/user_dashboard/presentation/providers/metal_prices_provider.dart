import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_prices.dart';
import 'package:ags_gold/services/service_providers.dart';

const _refreshInterval = Duration(seconds: 30);

final metalPricesProvider = StreamProvider.autoDispose<MetalPrices>((ref) async* {
  final apiClient = ref.watch(apiClientProvider);

  var isFirst = true;
  while (true) {
    try {
      final response = await apiClient.get('/dashboard/metal-prices');
      yield MetalPrices.fromJson(response.data as Map<String, dynamic>);
      isFirst = false;
    } catch (error) {
      if (isFirst) rethrow;
    }
    await Future<void>.delayed(_refreshInterval);
  }
});
