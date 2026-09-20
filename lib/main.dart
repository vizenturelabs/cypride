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
import 'package:app_links/app_links.dart';
import 'providers/profile_provider.dart';

bool isFirebaseInitialized = false;
late Box favoritesBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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

  await SharedPreferences.getInstance();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await Firebase.initializeApp();
      isFirebaseInitialized = true;

      if (kDebugMode) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttest,
        );
      }

      await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _initializeUserDocument(user.uid);
      }
      if (kDebugMode) print('🔥 Firebase initialized, user: ${user?.uid ?? "none"}');

      _handleIncomingLinks();

    } catch (e) {
      if (kDebugMode) print('⚠️ Firebase init failed: $e');
    }
  } else {
    if (kDebugMode) print('🖥️ Desktop/Web mode: Firebase skipped');
  }

  final profileProvider = ProfileProvider();
  await profileProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: profileProvider),
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

void _handleIncomingLinks() {
  final appLinks = AppLinks();

  Future<void> processLink(Uri? uri) async {
    if (uri == null) return;

    String? linkToVerify;

    if (uri.scheme == 'cypride' && uri.host == 'auth') {
      final encodedLink = uri.queryParameters['link'];
      if (encodedLink != null) {
        linkToVerify = Uri.decodeComponent(encodedLink);
        if (!linkToVerify.startsWith('https://project-bbc-alpha.web.app/')) {
          if (kDebugMode) print('⚠️ Rejected deep link: Untrusted domain');
          return;
        }
        if (kDebugMode) print('🔗 Caught custom scheme, decoded and validated Firebase link');
      }
    } else {
      linkToVerify = uri.toString();
    }

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
          appRouter.go('/home');
        } catch (e) {
          if (kDebugMode) print('⚠️ Error signing in with email link: $e');
        }
      } else {
        if (kDebugMode) print('⚠️ No email found in SharedPreferences for email link sign-in');
      }
    }
  }

  appLinks.getInitialLink().then(processLink);

  appLinks.uriLinkStream.listen(processLink);
}