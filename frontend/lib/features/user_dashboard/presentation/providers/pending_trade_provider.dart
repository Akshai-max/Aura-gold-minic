import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_prices.dart';

class PendingTrade {
  final bool isBuy;
  final MetalType metal;

  const PendingTrade({required this.isBuy, required this.metal});

  String get routePath {
    final metalParam = metal == MetalType.silver ? 'silver' : 'gold';
    return isBuy ? '/buy-gold?metal=$metalParam' : '/sell-gold?metal=$metalParam';
  }
}

class PendingTradeNotifier extends Notifier<PendingTrade?> {
  @override
  PendingTrade? build() => null;

  void set(PendingTrade? trade) => state = trade;

  void clear() => state = null;
}

final pendingTradeProvider =
    NotifierProvider<PendingTradeNotifier, PendingTrade?>(
      PendingTradeNotifier.new,
    );
