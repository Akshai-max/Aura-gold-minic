import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/user_dashboard/domain/sell_gold_inquiry.dart';
import 'package:ags_gold/services/service_providers.dart';

final sellInquiriesListProvider =
    FutureProvider.autoDispose<List<AdminSellGoldInquiry>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/sell-inquiries');
  final data = response.data as Map<String, dynamic>;
  final items = data['items'] as List<dynamic>? ?? [];
  return items
      .map((e) => AdminSellGoldInquiry.fromJson(e as Map<String, dynamic>))
      .toList();
});

final respondSellInquiryProvider = Provider((ref) {
  return ({
    required String inquiryId,
    required String adminResponse,
    String status = 'responded',
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.patch(
      '/sell-inquiries/$inquiryId/respond',
      data: {
        'admin_response': adminResponse,
        'status': status,
      },
    );
    return AdminSellGoldInquiry.fromJson(response.data as Map<String, dynamic>);
  };
});
