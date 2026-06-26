import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/services/service_providers.dart';

final paymentSettlementsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/payments/settlements');
  final data = response.data as Map<String, dynamic>;
  final items = data['items'] as List<dynamic>? ?? [];
  return items.map((e) => e as Map<String, dynamic>).toList();
});
