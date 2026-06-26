import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the full-screen add bank account flow.
Future<void> showAddBankAccountSheet(BuildContext context) {
  return context.push('/bank-accounts/add');
}
