import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/ledger_transaction.dart';

final transactionFilterProvider = StateProvider<TransactionFilter>(
  (_) => const TransactionFilter(),
);

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(apiClientProvider));
});

final transactionProvider = FutureProvider<List<LedgerTransaction>>((ref) {
  final filter = ref.watch(transactionFilterProvider);
  return ref.watch(transactionRepositoryProvider).getTransactions(filter);
});

class TransactionRepository {
  TransactionRepository(this._api);

  final ApiClient _api;

  Future<List<LedgerTransaction>> getTransactions(
    TransactionFilter filter,
  ) async {
    final response = await _api.get('/transactions', query: filter.toQuery());
    final data = response.data as List<dynamic>;
    return data
        .map((item) => LedgerTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
