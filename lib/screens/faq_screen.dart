import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // For Clipboard

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  // ✅ TEMPLATE: Add new FAQs here following this structure
  static final List<FaqItem> _faqItems = [
    // ====== Getting Started ======
    FaqItem(
      id: 'q1',
      question: 'How does CypRide work?',
      answer: '''
CypRide connects drivers (Riders) offering empty seats with passengers (Guests) traveling the same route in Cyprus.

• Riders: Offer rides by specifying departure/destination, time, available seats, and preferences
• Guests: Search and join rides that match their travel needs
• No payments processed in-app – arrange cost-sharing directly with fellow travelers
• All communication happens through OTT chats or optional phone calls (driver's choice)
''',
    ),
    FaqItem(
      id: 'q2',
      question: 'Is my personal information safe?',
      answer: '''
Your privacy is our priority:

✓ Phone numbers are NEVER visible to other users unless you explicitly enable "Allow Calls" when offering a ride
✓ Email addresses are hidden – only shown in your private profile
✓ Location data is only shared for active rides you've created or joined
✓ We use Firebase Authentication with industry-standard security
✓ No third-party tracking or data selling – your data belongs to you

We never store payment information since CypRide doesn't process payments.
''',
    ),

    // ====== For Riders (Drivers) ======
    FaqItem(
      id: 'q3',
      question: 'What are the requirements to offer rides?',
      answer: '''
To offer rides as a Rider:

• Valid Cyprus driving license
• Registered vehicle with valid insurance
• Minimum age: 21 years old
• Vehicle must pass basic safety MOT checks (functional lights, seatbelts, etc.)

⚠️ Important: CypRide is for cost-sharing only – not a taxi service. Drivers cannot profit beyond sharing fuel/parking costs.
''',
    ),
    FaqItem(
      id: 'q4',
      question: 'Can I control who contacts me?',
      answer: '''
Yes! When creating a ride, you can:

• Toggle "Allow Calls" ON/OFF to control phone access
• Default setting: OFF (only OTT messaging with @username available)
• Even with calls disabled, Riders/Guests can still message you, but your phone remain secret.
• You can cancel any ride anytime before departure - no Terms & Conditions.
''',
    ),

    // ====== For Guests (Passengers) ======
    FaqItem(
      id: 'q5',
      question: 'How do I find and join a ride?',
      answer: '''
1. Tap "Guests" tab on the home screen
2. Search by destination or browse available rides
3. Tap any ride to see full details (route map, driver preferences, available seats)
4. Contact the driver via:
   • "Call" button (if driver enabled phone access)
   • "Chat" button (always available for secure messaging)
5. Coordinate pickup details and cost-sharing directly with the driver

💡 Tip: Use the star icon (swipe left on ride) to save favorite routes for quick access later!
''',
    ),
    FaqItem(
      id: 'q6',
      question: 'Do I need to pay through the app?',
      answer: '''
No. CypRide does NOT process payments. 

• Cost-sharing (fuel/parking) is arranged directly between Riders and Guests
• Typical practice: Passengers contribute fairly to fuel costs (e.g., €5-15 depending on distance)
• Payment happens in cash or via personal bank transfer (Revolut..) – never through the app
• This keeps the service simple, private, and compliant with Cyprus transportation regulations
''',
    ),

    // ====== Safety & Etiquette ======
    FaqItem(
      id: 'q7',
      question: 'What safety features does CypRide offer?',
      answer: '''
We prioritize safe travel experiences:

🛡️ Verified accounts: All users must authenticate with phone/email via Firebase
🛡️ OTT messaging: Keep conversations within OTT apps (phone number or @username)
🛡️ Ride transparency: Full route details, departure times, and driver preferences visible before joining
🛡️ Reporting: Flag inappropriate behavior via Contact > Get in Touch > Telegram (CypRideOfficial) > CyprRideSupport

⚠️ Always meet in public places for pickup with cameras around. Trust your instincts – if something feels wrong, cancel the ride.
''',
    ),

    // ====== Support the Project ======
    FaqItem(
      id: 'q8',
      question: 'How can I support the CypRide project?',
      answer: '''
CypRide is an independent open-source project built for the Cyprus community. You can support us in two ways:

☕ Buy Me A Coffee
Show appreciation with a small donation:
→ Visit: https://buymeacoffee.com/cypride
→ Takes 30 seconds – no account required
→ Helps cover future server costs and development time

₿ Cryptocurrency Support
Prefer crypto? Send a tip with a quick copy
• Bitcoin (BTC)
• Monero (XMR)

💡 All support is voluntary and helps keep CypRide free, ad-free, and privacy-focused for everyone.
''',
      // Special metadata for interactive elements
      cryptoAddresses: {
        'BTC': 'bc1q2cw8rls2cg476esrm5ygqkppl3lft3l4d4n98m',
        'XMR': '43wZVXSPhd6FC1H1gA37SEPqBLDFiCgnMdMP44XCn8Pu779UtnjdEeNdoB96kZe3FgZGz2pz5T2SE2F4Xic7wmuTHpi8VQv',
      },
    ),
    FaqItem(
      id: 'q9',
      question: 'Why does CypRide need support?',
      answer: '''
While the app itself is free and open-source, we could have real costs coming soon:

• Firebase services (authentication, database, cloud functions)
• Map tile hosting fees (OpenStreetMap infrastructure)
• Domain and maintenance costs
• Development time (built by volunteers passionate about sustainable transport)

Your support ensures:
✓ No ads or data selling
✓ Continued privacy protection
✓ Regular updates and new features
✓ Server stability during peak travel seasons (summer, holidays)

Even small contributions make a big difference – thank you for keeping CypRide community-focused!
''',
    ),

    // ====== Template for Future FAQs ======
    // ✅ ADD NEW FAQs BELOW THIS LINE
    // FaqItem(
    //   id: 'q10',
    //   question: 'Your new question here?',
    //   answer: '''
    // Detailed answer with:
    // • Bullet points for readability
    // • Emojis for visual scanning 😊
    // • Clear actionable steps
    // ''',
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        title: const Text('Frequently Asked Questions'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqItems.length,
        itemBuilder: (context, index) {
          final faq = _faqItems[index];
          return _buildFaqItem(context, faq, index);
        },
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, FaqItem faq, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showAnswerBottomSheet(context, faq),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 28,
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  faq.question,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnswerBottomSheet(BuildContext context, FaqItem faq) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: Navigator.of(context),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle to dismiss
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with question
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable answer content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnswerContent(context, faq),
                    const SizedBox(height: 24),
                    // Special interactive elements for support question
                    if (faq.id == 'q8') ...[
                      // Official Buy Me A Coffee button
                      _buildOfficialBmcButton(context),
                      const SizedBox(height: 24),
                      // Crypto address copy buttons
                      _buildCryptoCopySection(context, faq.cryptoAddresses!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerContent(BuildContext context, FaqItem faq) {
    return SelectableText(
      faq.answer.trim(),
      style: TextStyle(
        height: 1.5,
        fontSize: 15,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      textAlign: TextAlign.left,
    );
  }

  // ✅ OFFICIAL Buy Me A Coffee button (from your provided HTML)
  Widget _buildOfficialBmcButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(context, 'https://www.buymeacoffee.com/cypride'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF000000), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=cypride&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff',
            height: 50,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 50,
              color: const Color(0xFFFFDD00),
              child: const Center(
                child: Text(
                  'Buy me a coffee',
                  style: TextStyle(
                    fontFamily: 'Cookie',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Crypto address copy section with inline copy icons
  Widget _buildCryptoCopySection(BuildContext context, Map<String, String> addresses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Quick Copy:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _buildAddressRow(
          context,
          'Bitcoin (BTC)',
          addresses['BTC']!,
          Icons.currency_bitcoin,
          Colors.yellow.shade700,
        ),
        const SizedBox(height: 12),
        _buildAddressRow(
          context,
          'Monero (XMR)',
          addresses['XMR']!,
          Icons.account_balance_wallet,
          Colors.orange.shade700,
        ),
      ],
    );
  }

  Widget _buildAddressRow(
      BuildContext context,
      String label,
      String address,
      IconData icon,
      Color iconColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            decoration: BoxDecoration(
              // ✅ FIXED: Use withAlpha() instead of deprecated red/green/blue getters
              color: iconColor.withAlpha(26), // 0.1 opacity = 26/255
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                address,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyToClipboard(context, address, label),
            tooltip: 'Copy address',
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: No async context gaps - capture all UI dependencies BEFORE async operation
  Future<void> _copyToClipboard(
      BuildContext context,
      String text,
      String label,
      ) async {
    // ✅ Capture messenger and theme colors BEFORE async gap
    final messenger = ScaffoldMessenger.of(context);
    final snackbarBgColor = Theme.of(context).colorScheme.primary;

    await Clipboard.setData(ClipboardData(text: text));

    // ✅ SAFE: Using pre-captured values after async operation
    messenger.showSnackBar(
      SnackBar(
        content: Text('$label address copied!'),
        duration: const Duration(seconds: 2),
        backgroundColor: snackbarBgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ FIXED: No async context gaps - capture messenger BEFORE async operation
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);

    // ✅ Capture messenger BEFORE async gap
    final messenger = ScaffoldMessenger.of(context);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      // ✅ messenger already captured - no context usage after async gap
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open $urlString')),
      );
    }
  }
}

// ✅ FAQ DATA MODEL - Enhanced with optional crypto metadata
class FaqItem {
  final String id;
  final String question;
  final String answer;
  final Map<String, String>? cryptoAddresses; // Optional for support questions

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.cryptoAddresses,
  });
}