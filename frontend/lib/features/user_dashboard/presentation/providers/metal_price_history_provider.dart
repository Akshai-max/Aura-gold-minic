import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_history.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_prices.dart';
import 'package:ags_gold/services/service_providers.dart';

typedef MetalHistoryQuery = ({MetalType metal, MetalHistoryRange range});

final metalHistoryProvider = FutureProvider.autoDispose
    .family<MetalHistory, MetalHistoryQuery>((ref, query) async {
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);

      final apiClient = ref.watch(apiClientProvider);
      final response = await apiClient.get(
        '/dashboard/metal-prices/history',
        queryParameters: {
          'metal': query.metal == MetalType.silver ? 'silver' : 'gold',
          'range': query.range.apiValue,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
        ),
        cancelToken: cancelToken,
      );
      return MetalHistory.fromJson(
        response.data as Map<String, dynamic>,
        query.metal,
        query.range,
      );
    });
