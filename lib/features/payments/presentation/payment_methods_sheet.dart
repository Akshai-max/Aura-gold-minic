import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../orders/domain/order.dart';
import '../providers/payment_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

class PaymentMethodsSheet extends ConsumerStatefulWidget {
  const PaymentMethodsSheet({
    required this.order,
    super.key,
  });

  final OrderModel order;

  @override
  ConsumerState<PaymentMethodsSheet> createState() => _PaymentMethodsSheetState();
}

class _PaymentMethodsSheetState extends ConsumerState<PaymentMethodsSheet> {
  int _selectedTab = 0; // 0: UPI, 1: Card, 2: Netbanking
  bool _simulateSuccess = true;
  bool _isPaying = false;

  // UPI Form controllers
  final _upiController = TextEditingController();
  final _upiFormKey = GlobalKey<FormState>();

  // Card Form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _cardFormKey = GlobalKey<FormState>();

  // Netbanking Selection
  String? _selectedBank;
  final List<Map<String, dynamic>> _banks = [
    {'name': 'State Bank of India', 'icon': Icons.account_balance},
    {'name': 'HDFC Bank', 'icon': Icons.account_balance},
    {'name': 'ICICI Bank', 'icon': Icons.account_balance},
    {'name': 'Axis Bank', 'icon': Icons.account_balance},
  ];

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Format Card Number with Spaces
  void _onCardNumberChanged(String val) {
    String clean = val.replaceAll(' ', '');
    if (clean.length > 16) clean = clean.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      buffer.write(clean[i]);
      if ((i + 1) % 4 == 0 && i != clean.length - 1) {
        buffer.write(' ');
      }
    }
    final formatted = buffer.toString();
    _cardNumberController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // Format Expiry MM/YY
  void _onExpiryChanged(String val) {
    String clean = val.replaceAll('/', '');
    if (clean.length > 4) clean = clean.substring(0, 4);
    if (clean.length >= 2) {
      final formatted = '${clean.substring(0, 2)}/${clean.substring(2)}';
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      _expiryController.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
  }

  // Validate and submit
  Future<void> _handlePayment() async {
    if (_selectedTab == 0) {
      if (!_upiFormKey.currentState!.validate()) return;
    } else if (_selectedTab == 1) {
      if (!_cardFormKey.currentState!.validate()) return;
    } else {
      if (_selectedBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a bank for net banking.')),
        );
        return;
      }
    }

    setState(() => _isPaying = true);

    // Call payment notifier to verify order payment simulation
    final success = await ref.read(paymentNotifierProvider.notifier).verifySimulatedPayment(
      orderId: widget.order.id,
      simulateSuccess: _simulateSuccess,
    );

    if (mounted) {
      setState(() => _isPaying = false);
      Navigator.of(context).pop(); // Dismiss sheet
      
      // Navigate to payment status page
      context.push('/payment-status', extra: {
        'order': widget.order,
        'success': success,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Razorpay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Secure Checkout', style: textTheme.labelSmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Payable Amount: ${_currency.format(widget.order.amount)}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),

          // Custom Razorpay tabs
          Row(
            children: [
              _buildTabButton(0, Icons.bolt, 'UPI'),
              _buildTabButton(1, Icons.credit_card, 'Card'),
              _buildTabButton(2, Icons.account_balance, 'Net Banking'),
            ],
          ),
          const SizedBox(height: 16),

          // Tab views
          IndexedStack(
            index: _selectedTab,
            children: [
              // UPI Tab
              Form(
                key: _upiFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _upiController,
                      decoration: InputDecoration(
                        labelText: 'UPI ID / VPA',
                        hintText: 'username@bank',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.bolt, color: Colors.deepPurple),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'UPI ID is required';
                        final reg = RegExp(r'^[\w\.\-]+@[\w\-]+$');
                        if (!reg.hasMatch(value.trim())) return 'Invalid UPI ID format';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Quick Suggestions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['@okaxis', '@okhdfcbank', '@okicici', '@ybl'].map((suf) {
                        return ChoiceChip(
                          label: Text(suf),
                          selected: false,
                          onSelected: (_) {
                            final base = _upiController.text.split('@').first;
                            _upiController.text = '${base.isEmpty ? 'username' : base}$suf';
                            _upiFormKey.currentState!.validate();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Card Tab
              Form(
                key: _cardFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Card Number',
                        hintText: '4111 1111 1111 1111',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.credit_card),
                      ),
                      onChanged: _onCardNumberChanged,
                      validator: (value) {
                        if (value == null || value.replaceAll(' ', '').length < 16) return 'Invalid card number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Expiry',
                              hintText: 'MM/YY',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: _onExpiryChanged,
                            validator: (value) {
                              if (value == null || !value.contains('/') || value.length < 5) return 'Invalid Expiry';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              hintText: '•••',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 3) return 'Invalid CVV';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Cardholder Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 3) return 'Cardholder name is required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Netbanking Tab
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Select Bank', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _banks.map((bank) {
                      final isSelected = _selectedBank == bank['name'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBank = bank['name'] as String;
                          });
                        },
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15) : null,
                          ),
                          child: Row(
                            children: [
                              Icon(bank['icon'] as IconData, color: isSelected ? theme.colorScheme.primary : null),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bank['name'] as String,
                                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Simulation Switch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bug_report_outlined, color: Colors.amber),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Simulation Mode', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Simulate payment result', style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _simulateSuccess,
                  onChanged: (val) {
                    setState(() {
                      _simulateSuccess = val;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Pay Button
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isPaying ? null : _handlePayment,
            child: _isPaying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Pay ${_currency.format(widget.order.amount)} via Simulated Razorpay',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : null,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
