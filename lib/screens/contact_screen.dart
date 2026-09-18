import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _openTelegram(BuildContext context) async {
    const telegramUsername = 'CypRideOfficial';

    final telegramAppUri = Uri(scheme: 'tg', path: 'resolve', queryParameters: {'domain': telegramUsername});
    final webUri = Uri.https('t.me', '/$telegramUsername');

    bool launched = false;

    try {
      if (await canLaunchUrl(telegramAppUri)) {
        launched = await launchUrl(telegramAppUri);
      }
      if (!launched && await canLaunchUrl(webUri)) {
        launched = await launchUrl(webUri);
      }
    } catch (e) {
      // Try web fallback only if initial attempt failed
      try {
        if (!launched && await canLaunchUrl(webUri)) {
          launched = await launchUrl(webUri);
        }
      } catch (_) {
        // Ignore nested error; handle below
      }
    }

    if (!launched) {
      // Show error only if context is still valid
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open Telegram'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openGitHub(BuildContext context) async {
    final uri = Uri.https('github.com', '/vizenturelabs/cypride');
    bool launched = false;

    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
    } catch (e) {
      // Ignore
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to open GitHub'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: textTheme.titleLarge?.color,
        ),
        title: const Text('Contact'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Get in Touch',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reach out to us through our social channels',
              style: textTheme.bodyMedium?.copyWith(
                color: textTheme.bodyMedium?.color?.withAlpha((255 * 0.7).toInt()),
              ),
            ),
            const SizedBox(height: 40),

            // Telegram Link
            InkWell(
              onTap: () => _openTelegram(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2CA5E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.telegram,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Telegram',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Join our Telegram channel',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // GitHub Link
            InkWell(
              onTap: () => _openGitHub(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.code,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GitHub',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View our open-source projects',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}