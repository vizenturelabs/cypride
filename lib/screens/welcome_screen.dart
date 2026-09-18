import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<Map<String, dynamic>> _slides = [
    {
      'title': 'Welcome to CypRide',
      'subtitle': 'Your trusted ride-sharing app across Cyprus',
      'image': 'assets/splash/welcome.png',
      'icon': Icons.directions_car,
    },
    {
      'title': 'How It Works',
      'subtitle': 'Book a ride in 3 taps — fast, simple, and local',
      'image': 'assets/splash/how_it_works.png',
      'icon': Icons.touch_app,
    },
    {
      'title': 'Privacy First',
      'subtitle': 'Get in touch the way you want, phone number or @username',
      'image': 'assets/splash/privacy_first.png',
      'icon': Icons.lock,
    },
    {
      'title': 'Ready to Ride?',
      'subtitle': 'Join a growing community of Cypriots using CypRide today',
      'image': 'assets/splash/community_app.png',
      'icon': Icons.check_circle,
    },
  ];

  Future<void> _markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('_show_welcome', false);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onSkip() async {
    await _markAsSeen();
    if (mounted) {
      context.go('/auth'); // ✅ GoRouter navigation
    }
  }

  void _onNextOrGetStarted() async {
    if (_currentPage == _slides.length - 1) {
      // Last slide: Navigate to Auth
      await _markAsSeen();
      if (mounted) {
        context.go('/auth'); // ✅ GoRouter navigation
      }
    } else {
      // Previous slides: Advance to next page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dotColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _slides.map((slide) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Image.asset(
                          slide['image']!,
                          fit: BoxFit.contain,
                          width: 280,
                          height: 280,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            slide['title']!,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            slide['subtitle']!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Positioned(
            top: 48,
            right: 24,
            child: TextButton(
              onPressed: _onSkip,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: isDarkMode
                    ? const Color.fromRGBO(255, 255, 255, 0.8)
                    : const Color.fromRGBO(0, 0, 0, 0.6),
              ),
              child: const Text('Skip', style: TextStyle(fontSize: 16)),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _slides.asMap().entries.map((entry) {
                final index = entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 12,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? dotColor
                        : const Color(0x802A6AAE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: ElevatedButton(
              onPressed: _onNextOrGetStarted, // ✅ Fixed: Checks page index first
              style: ElevatedButton.styleFrom(
                backgroundColor: dotColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                _currentPage == _slides.length - 1
                    ? 'Get Started'
                    : 'Next',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}