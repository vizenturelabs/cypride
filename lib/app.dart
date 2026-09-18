import 'dart:async'; // ✅ Added for StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'auth_page.dart';
import 'screens/welcome_screen.dart';
import 'home_screen.dart';
import 'ride_screen.dart';
import 'screens/map_selection_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tile_screen.dart';
import 'screens/favorite_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/contact_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ FIX 2: Helper class to make GoRouter listen to Auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;

  GoRouterRefreshStream(Stream stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class CyprideApp extends StatelessWidget {
  const CyprideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'CypRide',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter, // _router
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// ✅ Desktop detection
bool get _isDesktop {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);
}

// ✅ Complete GoRouter Configuration
final GoRouter appRouter = GoRouter( // _router
  initialLocation: '/',
  // ✅ FIX 2: Force GoRouter to re-evaluate redirects when Firebase auth state changes
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (context, state) async {
    // Desktop mode: bypass all auth checks
    if (_isDesktop) return null;

    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isGoingToAuth = state.matchedLocation == '/auth';
    final isGoingToWelcome = state.matchedLocation == '/welcome';

    // Handle root path '/'
    if (state.matchedLocation == '/') {
      if (isLoggedIn) return '/home';
      final prefs = await SharedPreferences.getInstance();
      final showedWelcome = prefs.getBool('_show_welcome') ?? true;
      return showedWelcome ? '/welcome' : '/auth';
    }

    // ✅ FIX: Logged in users shouldn't see auth/welcome (This catches the magic link background login!)
    if (isLoggedIn && (isGoingToAuth || isGoingToWelcome)) {
      return '/home';
    }

    // Auth guard for protected routes
    if (!isLoggedIn && !isGoingToAuth && !isGoingToWelcome) {
      return '/auth';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: AuthPage())
          : const AuthPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: HomeScreen())
          : const HomeScreen(),
    ),
    GoRoute(
      path: '/ride',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: RideScreen())
          : const RideScreen(),
    ),
    GoRoute(
      path: '/map-selection',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final locationType = args?['type'] ?? 'departure';
        return _isDesktop
            ? const MockAuthWrapper(
          child: MapSelectionScreen(locationType: 'departure'),
        )
            : MapSelectionScreen(locationType: locationType);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: ProfileScreen())
          : const ProfileScreen(),
    ),
    GoRoute(
      path: '/tile',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: TileScreen())
          : const TileScreen(),
    ),
    GoRoute(
      path: '/favorite',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: FavoriteScreen())
          : const FavoriteScreen(),
    ),
    GoRoute(
      path: '/safety',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: SafetyScreen())
          : const SafetyScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: SettingsScreen())
          : const SettingsScreen(),
    ),
    GoRoute(
      path: '/faq',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: FaqScreen())
          : const FaqScreen(),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => _isDesktop
          ? const MockAuthWrapper(child: ContactScreen())
          : const ContactScreen(),
    ),
  ],
);

class MockAuthWrapper extends StatelessWidget {
  final Widget child;
  const MockAuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CypRide'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              '🖥️ Desktop Mode: Firebase disabled. Test on Android for real auth.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}