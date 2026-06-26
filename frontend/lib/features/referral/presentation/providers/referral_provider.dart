import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/referral/domain/referral_summary.dart';
import 'package:ags_gold/services/service_providers.dart';

final referralSummaryProvider = FutureProvider<ReferralSummary>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/referrals/me');
  return ReferralSummary.fromJson(response.data as Map<String, dynamic>);
});
