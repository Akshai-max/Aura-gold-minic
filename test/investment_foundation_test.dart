import 'package:aura_gold/features/gold_price/domain/gold_price.dart';
import 'package:aura_gold/features/gold_wallet/domain/gold_wallet.dart';
import 'package:aura_gold/features/portfolio/domain/portfolio.dart';
import 'package:aura_gold/features/transactions/domain/ledger_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gold price model parses API response', () {
    final price = GoldPrice.fromJson({
      'current_price': '7325.40',
      'price_24k': 7325.40,
      'price_22k': 6714.95,
      'price_change': 84.20,
      'percentage_change': 1.16,
      'todays_high': 7364.90,
      'todays_low': 7241.20,
      'opening_price': 7241.20,
      'source': 'Admin Price Feed',
      'last_updated': '2026-06-04T10:00:00Z',
      'history': [
        {'label': 'Daily', 'price': '7241.20'},
      ],
    });

    expect(price.currentPrice, 7325.40);
    expect(price.history.single.label, 'Daily');
  });

  test('wallet model exposes balances and calculated values', () {
    final wallet = GoldWallet.fromJson({
      'wallet_id': 1,
      'user_id': 9,
      'gold_balance': '0',
      'available_gold': '0',
      'locked_gold': '0',
      'pending_gold': '0',
      'total_invested': '0',
      'current_value': '0',
      'profit_loss': '0',
      'created_at': '2026-06-04T10:00:00Z',
      'updated_at': '2026-06-04T10:00:00Z',
    });

    expect(wallet.walletId, '1');
    expect(wallet.availableGold, 0);
    expect(wallet.profitLoss, 0);
  });

  test('portfolio range labels match required time ranges', () {
    expect(
      PortfolioRange.values.map((range) => range.label),
      ['1 Day', '1 Week', '1 Month', '3 Months', '1 Year'],
    );
  });

  test('ledger transaction supports future transaction types', () {
    final transaction = LedgerTransaction.fromJson({
      'transaction_id': 1,
      'user_id': 2,
      'transaction_type': 'STAKE',
      'gold_amount': '1.2',
      'gold_price': '7300',
      'amount': '8760',
      'status': 'PENDING',
      'created_at': '2026-06-04T10:00:00Z',
    });

    expect(transaction.transactionType, TransactionType.stake);
    expect(TransactionType.redeem.apiValue, 'REDEEM');
  });
}
