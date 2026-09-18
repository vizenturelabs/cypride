import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'main.dart' show isFirebaseInitialized;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _secureStorage = const FlutterSecureStorage();
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  final ScrollController _ridersScrollController = ScrollController();
  final ScrollController _guestsScrollController = ScrollController();
  late Box _favoritesBox;
  Set<String> _favoriteRideIds = {};
  bool _favoritesLoaded = false;
  StreamSubscription? _favoritesSubscription;

  late AnimationController _menuIconController;

  static const String _appVersion = '1.1.1';
  static const String _disclaimerKey = 'disclaimer_accepted_version';
  bool _disclaimerAccepted = false;

  @override
  void initState() {
    super.initState();
    _menuIconController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _menuIconController.value = 0.0;

    if (kDebugMode) {
      debugPrint('🔥 isFirebaseInitialized: $isFirebaseInitialized');
    }
    // ✅ REMOVED: _loadProfileImage(); — now handled by ProfileProvider

    _loadFavorites();
    _listenToFavorites();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkDisclaimerAcceptance();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _ridersScrollController.dispose();
    _guestsScrollController.dispose();
    _favoritesSubscription?.cancel();
    _menuIconController.dispose();
    super.dispose();
  }

  String _getDisplayName(User? user) {
    final name = user?.displayName?.trim();
    return (name != null && name.isNotEmpty) ? name : 'User';
  }

  String _getUserContactInfo(User? user) {
    if (user == null) return 'Not available';

    if (user.email != null && user.email!.isNotEmpty && user.email!.trim().isNotEmpty) {
      return user.email!;
    }

    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty && user.phoneNumber!.trim().isNotEmpty) {
      return user.phoneNumber!;
    }

    return 'Not available';
  }

  // ✅ REMOVED: _loadProfileImage() method — no longer needed

  Future<void> _loadFavorites() async {
    try {
      if (!Hive.isBoxOpen('favorites')) {
        await Hive.openBox('favorites');
      }
      _favoritesBox = Hive.box('favorites');
      final favorites = _favoritesBox.keys.cast<String>().toSet();
      if (kDebugMode) {
        debugPrint('📌 HomeScreen: Loaded ${favorites.length} favorites');
      }
      if (mounted) {
        setState(() {
          _favoriteRideIds = favorites;
          _favoritesLoaded = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ HomeScreen favorites load error: $e');
      }
      if (mounted) {
        setState(() => _favoritesLoaded = true);
      }
    }
  }

  void _listenToFavorites() {
    _favoritesSubscription = _favoritesBox.watch().listen((event) {
      if (kDebugMode) {
        debugPrint('🔄 HomeScreen: Favorites box changed - $event');
      }
      _loadFavorites();
    });
  }

  Future<void> _toggleFavorite(String rideId, bool isFavorite) async {
    try {
      if (isFavorite) {
        await Hive.box('favorites').put(rideId, true);
        if (kDebugMode) {
          debugPrint('✅ Added to favorites: $rideId');
        }
      } else {
        await Hive.box('favorites').delete(rideId);
        if (kDebugMode) {
          debugPrint('❌ Removed from favorites: $rideId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Toggle favorite error: $e');
      }
    }
  }

  bool _isFavorite(String rideId) => _favoriteRideIds.contains(rideId);

  ScrollController _getScrollController() {
    return _selectedTabIndex == 0
        ? _ridersScrollController
        : _guestsScrollController;
  }

  Future<void> _checkDisclaimerAcceptance() async {
    if (_disclaimerAccepted) return;

    try {
      final acceptedVersion = await _secureStorage.read(key: _disclaimerKey);

      if (acceptedVersion != _appVersion) {
        if (!mounted) return;
        await _showDisclaimerDialog();
      } else {
        _disclaimerAccepted = true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Disclaimer check error: $e');
      }
      if (mounted) await _showDisclaimerDialog();
    }
  }

  Future<void> _showDisclaimerDialog() async {
    if (_disclaimerAccepted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Important Notice',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'While we developed this open-source app with dedication and great care, use is entirely at your own responsibility. We assume no liability for actions or decisions made when arranging private rides between individuals.',
                  style: TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By accepting, you acknowledge that you understand and agree to these terms.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton.tonal(
              onPressed: () {
                _exitApp();
              },
              child: const Text('Decline & Exit'),
            ),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);

                try {
                  await _secureStorage.write(
                    key: _disclaimerKey,
                    value: _appVersion,
                  );

                  if (!mounted) return;

                  setState(() => _disclaimerAccepted = true);
                  navigator.pop();
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text('Failed to save acceptance. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
              child: const Text('I Accept', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _exitApp() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Get profile image path from ProfileProvider (reactive)
    final profileImagePath = context.watch<ProfileProvider>().profileImagePath;

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        onDrawerChanged: (bool? isOpen) {
          _searchFocusNode.unfocus();

          if (mounted && isOpen != null) {
            _menuIconController.value = isOpen ? 1.0 : 0.0;
          }
        },
        drawer: _buildNavigationDrawer(context, profileImagePath),
        appBar: AppBar(
          title: const Text('CypRide'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.menu_arrow,
                progress: _menuIconController,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              onPressed: () {
                _searchFocusNode.unfocus();

                final scaffold = _scaffoldKey.currentState;
                if (scaffold == null) return;
                scaffold.isDrawerOpen ? scaffold.closeDrawer() : scaffold.openDrawer();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search destinations or names..',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTab(
                      label: 'Riders',
                      icon: Icons.person,
                      isSelected: _selectedTabIndex == 0,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTab(
                      label: 'Guests',
                      icon: Icons.groups,
                      isSelected: _selectedTabIndex == 1,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isFirebaseInitialized
                  ? _buildRideList()
                  : _buildDesktopMock(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/ride', extra: {'rideType': _selectedTabIndex == 1 ? 'guest' : 'rider'}),
          icon: const Icon(Icons.add_road_outlined),
          label: Text(_selectedTabIndex == 0 ? 'Offer a Ride' : 'Ask a Ride'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Pass profileImagePath as parameter
  Widget _buildNavigationDrawer(BuildContext context, String? profileImagePath) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = _getDisplayName(user);
    final userEmail = _getUserContactInfo(user);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: const TextStyle(color: Colors.white),
            ),
            accountEmail: Text(
              userEmail,
              style: const TextStyle(color: Colors.white),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundImage: profileImagePath != null
                  ? FileImage(File(profileImagePath))
                  : const AssetImage('assets/profile_placeholder.jpg') as ImageProvider,
              backgroundColor: Colors.white,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Tile'),
            onTap: () {
              Navigator.pop(context);
              context.push('/tile');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.star,
              color: _favoriteRideIds.isNotEmpty
                  ? Colors.amber
                  : Theme.of(context).iconTheme.color,
            ),
            title: const Text('Favorite'),
            onTap: () {
              Navigator.pop(context);
              context.push('/favorite');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Safety'),
            onTap: () {
              Navigator.pop(context);
              context.push('/safety');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('FAQ'),
            onTap: () {
              Navigator.pop(context);
              context.push('/faq');
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_page),
            title: const Text('Contact'),
            onTap: () {
              Navigator.pop(context);
              context.push('/contact');
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CypRide v1.1.1',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMock() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.computer,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '🖥️ Desktop Mode\nFirebase disabled for UI testing',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideList() {
    if (!_favoritesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final rideTypeFilter = _selectedTabIndex == 0 ? 'rider' : 'guest';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('isActive', isEqualTo: true)
          .where('departureTime', isGreaterThan: Timestamp.now())
          .orderBy('departureTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (kDebugMode) debugPrint('🔄 Firestore still loading...');
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (kDebugMode) debugPrint('❌ Firestore error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          final emptyMessage = _selectedTabIndex == 0
              ? 'No rides available yet.\nBe the first to offer one!'
              : 'No rides available yet.\nBe the first to ask one!';

          return Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          );
        }

        var rides = snapshot.data!.docs;

        rides = rides.where((ride) {
          final data = ride.data();
          final rideType = data['rideType'] as String?;
          return rideType == rideTypeFilter;
        }).toList();

        if (_searchQuery.isNotEmpty) {
          rides = rides.where((ride) {
            final data = ride.data();
            final fromName = (data['fromName'] as String).toLowerCase();
            final toName = (data['toName'] as String).toLowerCase();
            final riderName = (data['name'] as String?)?.toLowerCase() ?? '';

            return fromName.contains(_searchQuery) ||
                toName.contains(_searchQuery) ||
                riderName.contains(_searchQuery);
          }).toList();
        }

        if (rides.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'No rides match your search'
                  : 'No ${_selectedTabIndex == 0 ? 'rider' : 'guest'} rides available',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          );
        }

        return Scrollbar(
          controller: _getScrollController(),
          thumbVisibility: true,
          child: ListView.builder(
            controller: _getScrollController(),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final rideId = ride.id;
              final data = ride.data();
              final depTime = (data['departureTime'] as Timestamp).toDate();
              final formattedTime =
                  '${depTime.day}/${depTime.month} at ${depTime.hour.toString().padLeft(2, '0')}:${depTime.minute.toString().padLeft(2, '0')}';
              final driverPhone = data['driverPhone'] as String?;
              final allowCall = data['allowCall'] ?? true;
              final driverUid = data['driverUid'] as String?;
              final isFavorited = _isFavorite(rideId);
              final riderLanguage = data['language'] ?? 'English';
              final riderName = data['name'] ?? '';
              final rideStatus = data['rideStatus'] ?? 'Available';

              // ✅ Get OTT platform and username
              final ottPlatform = data['ottPlatform'] as String?;
              final username = data['username'] as String?;

              return Dismissible(
                key: Key('ride_$rideId'),
                direction: DismissDirection.horizontal,
                dismissThresholds: const {
                  DismissDirection.startToEnd: 0.2,
                  DismissDirection.endToStart: 0.2,
                },
                background: Container(
                  color: Colors.amber,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.star, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.star, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (direction == DismissDirection.startToEnd) {
                    await _toggleFavorite(rideId, true);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Added to favorites'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.amber,
                        ),
                      );
                    }
                  } else if (direction == DismissDirection.endToStart) {
                    await _toggleFavorite(rideId, false);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Removed from favorites'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      InkWell(
                        onTap: () {
                          _showRideDetailsBottomSheet(
                            context,
                            data,
                            rideId,
                            driverPhone,
                            allowCall,
                            driverUid,
                            ottPlatform,
                            username,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data['fromName']} →',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      data['toName'] ?? '',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$formattedTime - ${data['seats']} seat(s) free',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '$riderLanguage - $riderName',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.tonal(
                                onPressed: () {
                                  if (allowCall && driverPhone != null) {
                                    final messenger = ScaffoldMessenger.of(context);
                                    _makeCall(driverPhone, messenger);
                                  } else {
                                    // ✅ Handle OTT messaging directly (no in-app chat)
                                    _handleOttContact(ottPlatform, username, driverPhone, context);
                                  }
                                },
                                child: Text(allowCall ? 'Call' : 'Chat', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isFavorited)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                      if (rideStatus == 'Booked')
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Booked',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.lock,
                                color: Colors.red,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showRideDetailsBottomSheet(
      BuildContext context,
      Map<String, dynamic> data,
      String rideId,
      String? driverPhone,
      bool allowCall,
      String? driverUid,
      String? ottPlatform,
      String? username,
      ) {
    final depTime = (data['departureTime'] as Timestamp).toDate();
    final formattedDate = '${depTime.day}/${depTime.month}/${depTime.year}';
    final formattedTime =
        '${depTime.hour.toString().padLeft(2, '0')}:${depTime.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        duration: const Duration(seconds: 1),
        vsync: Scaffold.of(context),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          '$formattedDate • $formattedTime',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Route'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, 'From',
                        data['fromName'] ?? 'Not specified'),
                    _buildInfoRow(Icons.flag, 'To',
                        data['toName'] ?? 'Not specified'),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Route Overview'),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: const LatLng(34.8706, 33.6093),
                          initialZoom: 10,
                          minZoom: 8,
                          maxZoom: 18,
                          interactionOptions: InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.vizenture.cypride',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: const LatLng(34.8706, 33.6093),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 40,
                                ),
                              ),
                              Marker(
                                point: const LatLng(34.6841, 33.0379),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: const [
                                  LatLng(34.8706, 33.6093),
                                  LatLng(34.6841, 33.0379),
                                ],
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Driver Information'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.account_circle, 'Name',
                        data['name'] ?? 'Not specified'),
                    _buildInfoRow(Icons.person, 'Gender',
                        data['gender'] ?? 'Not specified'),
                    _buildInfoRow(Icons.language, 'Language',
                        data['language'] ?? 'Not specified'),
                    _buildInfoRow(Icons.directions_car, 'Car Brand',
                        data['carBrand'] ?? 'Not specified'),
                    if (!allowCall) ...[
                      _buildInfoRow(
                        Icons.chat,
                        'Channel',
                        ottPlatform ?? 'WhatsApp',
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionTitle('Ride Preferences'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        Icons.pets,
                        'Pet Friendly',
                        data['isPetFriendly'] == true ? 'Yes ✓' : 'No ✗'),
                    _buildInfoRow(
                        Icons.smoking_rooms,
                        'Smoking Allowed',
                        data['isSmoker'] == true ? 'Yes ✓' : 'No ✗'),
                    _buildInfoRow(Icons.luggage, 'Luggage Space',
                        data['luggageSpace'] ?? 'Not specified'),
                    _buildInfoRow(Icons.chat, 'Conversation',
                        data['conversationPreference'] ?? 'Not specified'),
                    _buildInfoRow(Icons.event_seat, 'Available Seats',
                        '${data['seats'] ?? 0} seat(s)'),
                    if (data['notes'] != null &&
                        (data['notes'] as String).isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Additional Notes'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['notes'],
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (allowCall && driverPhone != null)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _makeCall(driverPhone,
                                    ScaffoldMessenger.of(context));
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Call Driver'),
                            ),
                          ),
                        if (!allowCall)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // ✅ Direct OTT contact (no in-app chat)
                                _handleOttContact(ottPlatform, username, driverPhone, context);
                              },
                              icon: const Icon(Icons.chat),
                              label: const Text('Chat'),
                            ),
                          ),
                        if (allowCall && driverPhone != null)
                          const SizedBox(width: 12),
                        if (allowCall && driverPhone != null)
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                Navigator.pop(context);
                                // ✅ Direct OTT contact (no in-app chat)
                                _handleOttContact(ottPlatform, username, driverPhone, context);
                              },
                              icon: const Icon(Icons.chat),
                              label: const Text('Chat'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall(
      String phone, ScaffoldMessengerState messenger) async {
    final Uri call = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(call)) {
      await launchUrl(call);
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  // ✅ Handle OTT contact logic (direct app opening)
  void _handleOttContact(String? ottPlatform, String? username, String? driverPhone, BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    // Case 1: Username provided
    if (username != null && username.trim().isNotEmpty) {
      final cleanUsername = username.startsWith('@') ? username.substring(1) : username;

      if (ottPlatform == 'Telegram') {
        _openTelegramChat(cleanUsername, messenger);
      } else if (ottPlatform == 'Viber') {
        _openViberChat(cleanUsername, messenger);
      } else {
        // Default to WhatsApp
        _openWhatsAppUsername(cleanUsername, messenger);
      }
    }
    // Case 2: No username but phone number available
    else if (driverPhone != null && driverPhone.trim().isNotEmpty) {
      if (ottPlatform == 'Viber') {
        _openViberWithPhone(driverPhone, messenger);
      } else {
        _openWhatsAppWithPhone(driverPhone, messenger);
      }
    }
    // Case 3: No contact method available
    else {
      messenger.showSnackBar(
        const SnackBar(content: Text('No contact method available for this ride')),
      );
    }
  }

  // ✅ Open WhatsApp with username
  void _openWhatsAppUsername(String username, ScaffoldMessengerState messenger) {
    final whatsappUrl = Uri.parse('https://wa.me/$username');
    _launchOttUrl(whatsappUrl, 'WhatsApp', messenger);
  }

  // ✅ Open WhatsApp with phone number
  void _openWhatsAppWithPhone(String phone, ScaffoldMessengerState messenger) {
    // Ensure phone number is in international format
    String formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+357$formattedPhone'; // Cyprus country code
    }

    final message = "Hi, I'm interested in your ride!";
    final whatsappUrl = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');
    _launchOttUrl(whatsappUrl, 'WhatsApp', messenger);
  }

  // ✅ FIXED: Open Telegram chat with native deep link
  void _openTelegramChat(String username, ScaffoldMessengerState messenger) {
    // Remove @ if present
    final cleanUsername = username.startsWith('@') ? username.substring(1) : username;

    // ✅ Use native Telegram deep link
    final telegramUrl = Uri.parse('tg://resolve?domain=$cleanUsername');

    _launchOttUrl(telegramUrl, 'Telegram', messenger);
  }

  // ✅ NEW: Open Viber chat with username (public account)
  void _openViberChat(String username, ScaffoldMessengerState messenger) {
    // Viber public account deep link
    final viberUrl = Uri.parse('viber://pa?chatURI=$username');
    _launchOttUrl(viberUrl, 'Viber', messenger);
  }

  // ✅ NEW: Open Viber chat with phone number
  void _openViberWithPhone(String phone, ScaffoldMessengerState messenger) {
    // Ensure phone number is in international format
    String formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+357$formattedPhone'; // Cyprus country code
    }

    // Viber contact deep link
    final viberUrl = Uri.parse('viber://contact?number=$formattedPhone');
    _launchOttUrl(viberUrl, 'Viber', messenger);
  }

  // ✅ Generic URL launcher with error handling
  Future<void> _launchOttUrl(Uri url, String platform, ScaffoldMessengerState messenger) async {
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('$platform not available. Please install $platform to chat.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error opening $platform: ${e.toString()}')),
      );
    }
  }
}