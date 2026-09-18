import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  static const String _cyprusEmergencyNumber = '112';

  Future<void> _showEmergencyDialog() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: _buildEmergencyDialog(context),
      ),
    );

    if (confirmed == true && mounted) {
      _callEmergencyNumber();
    }
  }

  Widget _buildEmergencyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
          const SizedBox(width: 12),
          Text(
            'EMERGENCY CALL',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will connect you to Cyprus Emergency Services (Police, Ambulance, Fire).',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Text(
              '⚠️ ONLY USE IN GENUINE LIFE-THREATENING EMERGENCIES\n\nFalse emergency calls are a criminal offense in Cyprus (Penal Code Article 146).',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: textTheme.labelLarge?.color),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: const Text('CALL 112 NOW', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _callEmergencyNumber() async {
    if (!mounted) return;

    final Uri call = Uri(scheme: 'tel', path: _cyprusEmergencyNumber);

    try {
      final canLaunch = await canLaunchUrl(call);

      if (!mounted) return;

      if (canLaunch) {
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => PopScope(
            canPop: false,
            child: _buildPreCallDialog(dialogContext),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Emergency call failed. Please dial 112 manually.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, 50)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildPreCallDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.phone_in_talk, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Text(
            'CONNECTING..',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Your location and device details will be shared with Cyprus Emergency Services.',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Stay on the line. An operator will answer shortly.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () {
            if (!mounted) return;
            Navigator.pop(context);
            if (mounted) {
              launchUrl(Uri(scheme: 'tel', path: _cyprusEmergencyNumber));
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
          child: const Text('CONFIRM CALL', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSafetyTip(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Safety',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: textTheme.titleLarge?.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: textTheme.titleLarge?.color,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR SAFETY MATTERS',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Follow these critical guidelines for every ride. In emergencies, use the PANIC BUTTON below.',
                        style: textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSafetyTip(
            context,
            Icons.person,
            'Match with Same Gender',
            'Prefer matching with drivers of the same gender for enhanced comfort and security.',
          ),
          _buildSafetyTip(
            context,
            Icons.group,
            'Travel with a Companion',
            'Opt for two seats and bring a companion whenever possible. There is safety in numbers.',
          ),
          _buildSafetyTip(
            context,
            Icons.remove_red_eye,
            'Stay Alert & Trust Instincts',
            'Use your best judgment with irrational or pushy behavior. If something feels wrong, cancel the ride immediately.',
          ),
          _buildSafetyTip(
            context,
            Icons.badge,
            'Verify Driver Credentials',
            'Feel free to request a photo of the driver\'s license to verify their eligibility to drive.',
          ),
          _buildSafetyTip(
            context,
            Icons.map,
            'Pre-Agree on Route',
            'Confirm the exact route beforehand to avoid unexpected detours. Ensure you\'re both aligned on the journey path.',
          ),
          _buildSafetyTip(
            context,
            Icons.person_search,
            'Know Your Travel Partner',
            'Evaluate carefully before committing. Get to know your travel partner through call or chat before meeting.',
          ),
          _buildSafetyTip(
            context,
            Icons.share_location,
            'Share Trip Details',
            'ALWAYS share your trip details (route, driver info, ETA) with a trusted friend or family member before departure.',
          ),

          const SizedBox(height: 8),
          Divider(color: colorScheme.outline, height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_police, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Cyprus Emergency Contacts',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildContactRow(context, 'Police (Non-Emergency)', '1444'),
                _buildContactRow(context, 'Ambulance', '199'),
                _buildContactRow(context, 'Fire Department', '199'),
                _buildContactRow(context, 'Road Assistance', '1474'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'For ALL life-threatening emergencies, use the PANIC BUTTON below to call 112 (connects to Police, Ambulance & Fire)',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEmergencyDialog,
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.call, size: 28),
        label: const Text(
          'PANIC BUTTON - CALL 112',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        tooltip: 'Emergency call to Cyprus authorities',
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, String label, String number) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            number,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}