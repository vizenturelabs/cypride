import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Added for Email Link

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController(); // ✅ Added for Email Link
  bool _isLoading = false;
  DateTime? _lastLinkSentTime;

  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();

    // ✅ BULLETPROOF COLD START FIX:
    // Listen for background auth changes (like Magic Link completing on cold start)
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        // Delay slightly to ensure the router is fully ready and to avoid build-phase navigation errors
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/home');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // ✅ Cancel the subscription to prevent memory leaks
    _authSubscription.cancel();
    _emailController.dispose();
    super.dispose();
  }

  // Check if running on desktop/web for mock mode
  bool get _isDesktop {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows;
  }

  // ✅ Added for Email Link
  bool _validateEmail(String email) {
    if (email.isEmpty) {
      _showError('Email cannot be empty');
      return false;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Added for Email Link
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      context.go('/home');
    }
  }

  // Google Sign-In (v7.2.0 compatible)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _navigateToHome();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Google Sign-In failed. Please try again.');
    }
  }

  // ✅ Email Link (Passwordless) Sign-In
  Future<void> _sendMagicLink() async {
    final now = DateTime.now();
    if (_lastLinkSentTime != null && now.difference(_lastLinkSentTime!).inSeconds < 30) {
      _showError('Please wait 30 seconds before requesting another link.');
      return;
    }

    final email = _emailController.text.trim();
    if (!_validateEmail(email)) return;

    setState(() => _isLoading = true);

    try {
      // ✅ CRITICAL: Save email so main.dart listener can retrieve it on deep link click
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email_for_signin', email);

      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://project-bbc-alpha.web.app/auth-action',
          handleCodeInApp: true,
          iOSBundleId: 'com.vizenture.cypride',
          androidPackageName: 'com.vizenture.cypride',
          androidInstallApp: true,
          androidMinimumVersion: '21',
        ),
      );

      _lastLinkSentTime = DateTime.now();
      setState(() => _isLoading = false);
      _showSuccess('Magic link sent! Check your email inbox.');

      if (mounted) {
        _showEmailInstructions(email);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = 'Failed to send magic link.';
      if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please wait and try again.';
      }
      _showError(message);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('An error occurred. Please try again.');
    }
  }

  // ✅ Added for Email Link
  void _showEmailInstructions(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Check Your Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Magic link sent to:\n\n$email\n\n'),
            const Text(
              '1. Open your email app\n'
                  '2. Look for an email from Firebase\n'
                  '3. Click the "Sign in" button',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tip: Check spam/promotions folders!',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(ctx).pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CypRide Login'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isDesktop && !kIsWeb) ...[
                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // OR Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Email Input
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'your@email.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Send Magic Link Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _sendMagicLink,
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Send Magic Link'),
                  ),
                ),
              ] else ...[
                // Desktop/Web Mock Mode
                const Icon(Icons.computer, size: 64),
                const SizedBox(height: 24),
                const Text(
                  '🖥️ Desktop Development Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Authentication is mocked in desktop mode.\nClick below to skip to home screen.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Skip to Home (Mock Mode)'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}