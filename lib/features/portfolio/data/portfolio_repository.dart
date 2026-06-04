import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/portfolio.dart';

final selectedPortfolioRangeProvider = StateProvider<PortfolioRange>(
  (_) => PortfolioRange.oneMonth,
);

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository(ref.watch(apiClientProvider));
});

final portfolioProvider = FutureProvider<PortfolioSummary>((ref) {
  final range = ref.watch(selectedPortfolioRangeProvider);
  return ref.watch(portfolioRepositoryProvider).getPortfolio(range);
});

final platformPortfolioProvider = FutureProvider<PlatformPortfolioOverview>((
  ref,
) {
  return ref.watch(portfolioRepositoryProvider).getPlatformOverview();
});

class PortfolioRepository {
  PortfolioRepository(this._api);

  final ApiClient _api;

  Future<PortfolioSummary> getPortfolio(PortfolioRange range) async {
    final response = await _api.get(
      '/portfolio',
      query: {'range': range.name},
    );
    return PortfolioSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlatformPortfolioOverview> getPlatformOverview() async {
    final response = await _api.get('/portfolio/platform-overview');
    return PlatformPortfolioOverview.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
