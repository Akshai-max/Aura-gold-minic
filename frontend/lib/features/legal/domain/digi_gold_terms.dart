class DigiGoldTermsSection {
  final String title;
  final List<String> bullets;

  const DigiGoldTermsSection({
    required this.title,
    required this.bullets,
  });
}

class DigiGoldTermsContent {
  static const intro =
      'By enrolling in the Aurum Gold Works Digi Gold Program, you agree to the '
      'following Terms & Conditions.';

  static const sections = <DigiGoldTermsSection>[
    DigiGoldTermsSection(
      title: '1. Purpose of the Program',
      bullets: [
        'The Digi Gold Program enables customers to save and accumulate gold digitally through small investments.',
        'The amount invested will be converted into gold grams based on the prevailing gold rate at the time of purchase.',
      ],
    ),
    DigiGoldTermsSection(
      title: '2. Account Registration',
      bullets: [
        'Customers must provide accurate personal information, including name, mobile number, and other required details.',
        'Aurum Gold Works shall not be responsible for any issues arising from incorrect or incomplete information provided by the customer.',
      ],
    ),
    DigiGoldTermsSection(
      title: '3. Payments',
      bullets: [
        'Payments may be made through UPI, Net Banking, Debit Card, Credit Card, or other approved payment methods.',
        "Gold will be credited to the customer's account only after successful payment confirmation.",
      ],
    ),
    DigiGoldTermsSection(
      title: '4. Gold Pricing',
      bullets: [
        'Each purchase of Digi Gold will be calculated based on the live gold rate prevailing at the time of the transaction.',
        'Gold prices are subject to market fluctuations.',
      ],
    ),
    DigiGoldTermsSection(
      title: '5. Redemption',
      bullets: [
        'Customers may redeem their accumulated Digi Gold for jewellery, gold coins, or other eligible products as per company policy.',
        'Redemption value will be based on the prevailing gold rate at the time of redemption.',
      ],
    ),
    DigiGoldTermsSection(
      title: '6. Cancellation & Refunds',
      bullets: [
        'Purchases of Digi Gold are generally non-refundable.',
        'Refund requests, if any, will be reviewed at the sole discretion of Aurum Gold Works and subject to applicable policies.',
      ],
    ),
    DigiGoldTermsSection(
      title: '7. Taxes & Charges',
      bullets: [
        'Applicable taxes, including GST and other statutory charges, will be levied as per government regulations.',
        'Any applicable fees or charges will be communicated to customers in advance.',
      ],
    ),
    DigiGoldTermsSection(
      title: '8. Security',
      bullets: [
        'Customers are responsible for maintaining the confidentiality of their account credentials, OTPs, and login information.',
        'Aurum Gold Works shall not be liable for any loss arising from unauthorized access due to customer negligence.',
      ],
    ),
    DigiGoldTermsSection(
      title: '9. Amendments',
      bullets: [
        'Aurum Gold Works reserves the right to modify, update, or amend these Terms & Conditions at any time without prior notice.',
        'Changes will become effective upon publication on the App or Website.',
      ],
    ),
    DigiGoldTermsSection(
      title: '10. Governing Law',
      bullets: [
        'These Terms & Conditions shall be governed by and construed in accordance with the laws of India.',
        'Any disputes arising from the Digi Gold Program shall be subject to the exclusive jurisdiction of the courts in Tamil Nadu, India.',
      ],
    ),
  ];
}
