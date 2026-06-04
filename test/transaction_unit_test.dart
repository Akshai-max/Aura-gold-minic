import 'package:flutter_test/flutter_test.dart';
import 'package:aura_gold/features/transactions/domain/ledger_transaction.dart';

void main() {
  group('Transaction Unit Tests', () {
    test('LedgerTransaction parses valid JSON correctly', () {
      final json = {
        'id': 't_100',
        'user_id': 9,
        'transaction_type': 'SIP',
        'gold_amount': '0.750',
        'gold_price': '7310.0',
        'amount': '5482.5',
        'status': 'PENDING',
        'created_at': '2026-06-04T12:00:00Z',
      };

      final transaction = LedgerTransaction.fromJson(json);

      expect(transaction.transactionId, equals('t_100'));
      expect(transaction.userId, equals('9'));
      expect(transaction.transactionType, equals(TransactionType.sip));
      expect(transaction.goldAmount, equals(0.750));
      expect(transaction.goldPrice, equals(7310.0));
      expect(transaction.amount, equals(5482.5));
      expect(transaction.status, equals('PENDING'));
    });

    test('TransactionFilter converts to query parameters mapping', () {
      // Empty filter
      const emptyFilter = TransactionFilter();
      expect(emptyFilter.toQuery(), isEmpty);

      // Full filter
      final date = DateTime(2026, 6, 4, 10, 0, 0);
      final fullFilter = TransactionFilter(
        date: date,
        type: TransactionType.buy,
        status: 'COMPLETED',
      );

      final query = fullFilter.toQuery();

      expect(query['date'], equals(date.toIso8601String()));
      expect(query['type'], equals('BUY'));
      expect(query['status'], equals('COMPLETED'));
    });

    test('TransactionType enum values map correctly', () {
      expect(TransactionType.buy.apiValue, equals('BUY'));
      expect(TransactionType.sell.apiValue, equals('SELL'));
      expect(TransactionType.sip.apiValue, equals('SIP'));
      expect(TransactionType.stake.apiValue, equals('STAKE'));
      expect(TransactionType.unstake.apiValue, equals('UNSTAKE'));
      expect(TransactionType.reward.apiValue, equals('REWARD'));
      expect(TransactionType.redeem.apiValue, equals('REDEEM'));
    });
  });
}
