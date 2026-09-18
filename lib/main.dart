import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cypride/app.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart'; // ✅ Added for Email Link deep linking
import 'providers/profile_provider.dart';

// ✅ Shared global state (imported by app.dart and all screens)
bool isFirebaseInitialized = false;
late Box favoritesBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ✅ Initialize Hive FIRST
  await Hive.initFlutter();
  try {
    if (!Hive.isBoxOpen('favorites')) {
      favoritesBox = await Hive.openBox('favorites');
      if (kDebugMode) {
        debugPrint('✅ Hive favorites box opened successfully');
        debugPrint('📌 Existing favorites: ${favoritesBox.keys.length}');
      }
    } else {
      favoritesBox = Hive.box('favorites');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Hive box open error: $e');
    }
  }

  // ✅ Initialize SharedPreferences
  await SharedPreferences.getInstance();

  // ✅ Initialize Firebase
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await Firebase.initializeApp();
      isFirebaseInitialized = true;

      // ✅ Initialize App Check for security
      if (kDebugMode) {
        // Use debug providers during development
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      } else {
        // Use production providers for release builds
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttest,
        );
      }

      // ✅ Wait for auth state to restore (critical fix!)
      await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => null, // Continue even if timeout
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _initializeUserDocument(user.uid);
      }
      if (kDebugMode) print('🔥 Firebase initialized, user: ${user?.uid ?? "none"}');

      // ✅ NEW: Listen for Email Link deep links
      _handleIncomingLinks();

    } catch (e) {
      if (kDebugMode) print('⚠️ Firebase init failed: $e');
    }
  } else {
    if (kDebugMode) print('🖥️ Desktop/Web mode: Firebase skipped');
  }

  // ✅ NEW: Initialize ProfileProvider with persisted data
  final profileProvider = ProfileProvider();
  await profileProvider.init(); // Load profile image path from secure storage

  // ✅ Run CyprideApp wrapped with pre-initialized ProfileProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profileProvider), // ✅ Pass initialized instance
      ],
      child: const CyprideApp(),
    ),
  );
}

Future<void> _initializeUserDocument(String userId) async {
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
  if (!userDoc.exists) {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'createdAt': FieldValue.serverTimestamp(),
      'userId': userId,
      'profileHash': '',
    });
  }
}

// ✅ UPDATED: Handle Email Link (Passwordless) Deep Links + Custom Scheme
void _handleIncomingLinks() {
  final appLinks = AppLinks();

  Future<void> processLink(Uri? uri) async {
    if (uri == null) return;

    String? linkToVerify;

    // 1. Check if it's our custom scheme (cypride://auth?link=...) from the web landing page
    if (uri.scheme == 'cypride' && uri.host == 'auth') {
      final encodedLink = uri.queryParameters['link'];
      if (encodedLink != null) {
        linkToVerify = Uri.decodeComponent(encodedLink);
        if (kDebugMode) print('🔗 Caught custom scheme, decoded Firebase link');
      }
    } else {
      // 2. Fallback: Check if it's a direct App Link (https://...)
      linkToVerify = uri.toString();
    }

    // 3. Verify the extracted link with Firebase
    if (linkToVerify != null && FirebaseAuth.instance.isSignInWithEmailLink(linkToVerify)) {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email_for_signin') ?? '';

      if (email.isNotEmpty) {
        try {
          await FirebaseAuth.instance.signInWithEmailLink(
            email: email,
            emailLink: linkToVerify,
          );
          await prefs.remove('email_for_signin');
          if (kDebugMode) print('✅ Successfully signed in with email link');
          // GoRouter will automatically detect the auth state change and redirect to /home
          appRouter.go('/home');
        } catch (e) {
          if (kDebugMode) print('⚠️ Error signing in with email link: $e');
        }
      } else {
        if (kDebugMode) print('⚠️ No email found in SharedPreferences for email link sign-in');
      }
    }
  }

  // 1. Handle cold start (app opened directly from the link while completely closed)
  appLinks.getInitialLink().then(processLink);

  // 2. Handle warm start (app was in background, link clicked)
  appLinks.uriLinkStream.listen(processLink);
}