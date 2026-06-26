/// Aurum Gold Works privacy policy (aurumgold.co.in).
class PrivacyPolicySection {
  final String title;
  final List<String> paragraphs;
  final List<String>? bullets;

  const PrivacyPolicySection({
    required this.title,
    this.paragraphs = const [],
    this.bullets,
  });
}

class PrivacyPolicyContent {
  static const intro =
      'Welcome to Aurum Gold Works. We value your privacy and are committed '
      'to protecting your personal information. This Privacy Policy explains '
      'how we collect, use, store, and protect the information you provide '
      'when using our website, mobile application, and services.';

  static const closing =
      'By using our website or mobile application, you agree to the terms '
      'of this Privacy Policy.';

  static const contactPhone = '+91 99437 95005';
  static const contactWebsite = 'https://aurumgold.co.in';
  static const contactEmail = 'info@aurumgold.co.in';

  static const sections = <PrivacyPolicySection>[
    PrivacyPolicySection(
      title: '1. Information We Collect',
      paragraphs: ['We may collect the following information:'],
      bullets: [
        'Name',
        'Mobile Number',
        'Email Address',
        'Postal Address',
        'Order and Transaction Details',
        'Any information submitted through Contact Forms or Enquiry Forms',
      ],
    ),
    PrivacyPolicySection(
      title: '2. How We Use Your Information',
      paragraphs: ['We use the information collected to:'],
      bullets: [
        'Process enquiries and orders',
        'Provide customer support',
        'Improve our products and services',
        'Send updates, offers, and promotional information (with your consent where required)',
        'Comply with legal and regulatory requirements',
      ],
    ),
    PrivacyPolicySection(
      title: '3. Information Security',
      paragraphs: [
        'We implement reasonable security measures to protect your personal '
            'information against unauthorized access, disclosure, alteration, '
            'or destruction.',
      ],
    ),
    PrivacyPolicySection(
      title: '4. Sharing of Information',
      paragraphs: [
        'We do not sell, rent, or trade your personal information to third parties.',
        'Information may be shared only:',
      ],
      bullets: [
        'When required by law',
        'To comply with legal obligations',
        'To protect our rights and business interests',
        'With trusted service providers assisting in website and app operations, subject to confidentiality obligations',
      ],
    ),
    PrivacyPolicySection(
      title: '5. Cookies',
      paragraphs: [
        'Our website may use cookies and similar technologies to enhance user '
            'experience, analyze website traffic, and improve website functionality.',
        'You may choose to disable cookies through your browser settings.',
      ],
    ),
    PrivacyPolicySection(
      title: '6. Third-Party Links',
      paragraphs: [
        'Our website may contain links to third-party websites. We are not '
            'responsible for the privacy practices or content of such websites.',
      ],
    ),
    PrivacyPolicySection(
      title: '7. Data Retention',
      paragraphs: [
        'We retain personal information only for as long as necessary to fulfill '
            'the purposes described in this Privacy Policy or as required by law.',
      ],
    ),
    PrivacyPolicySection(
      title: '8. Your Rights',
      paragraphs: ['You may request to:'],
      bullets: [
        'Access your personal information',
        'Correct inaccurate information',
        'Delete your personal information (subject to legal requirements)',
        'Withdraw consent for marketing communications',
      ],
    ),
    PrivacyPolicySection(
      title: '9. Changes to This Policy',
      paragraphs: [
        'We reserve the right to update this Privacy Policy at any time. Any '
            'changes will be posted on this page with the updated revision date.',
      ],
    ),
    PrivacyPolicySection(
      title: '10. Contact Us',
      paragraphs: ['Aurum Gold Works'],
    ),
  ];
}
