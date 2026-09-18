import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  Set<String> _favoriteRideIds = {};
  bool _favoritesLoaded = false;
  late Box _favoritesBox;
  StreamSubscription? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _listenToFavorites();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      if (!Hive.isBoxOpen('favorites')) {
        await Hive.openBox('favorites');
      }

      _favoritesBox = Hive.box('favorites');
      final favorites = _favoritesBox.keys.cast<String>().toSet();

      if (kDebugMode) {
        debugPrint('📌 FavoriteScreen: Loaded ${favorites.length} favorites');
      }

      if (mounted) {
        setState(() {
          _favoriteRideIds = favorites;
          _favoritesLoaded = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ FavoriteScreen favorites load error: $e');
      }
      if (mounted) {
        setState(() => _favoritesLoaded = true);
      }
    }
  }

  void _listenToFavorites() {
    _favoritesSubscription = _favoritesBox.watch().listen((event) {
      if (kDebugMode) {
        debugPrint('🔄 FavoriteScreen: Favorites box changed - $event');
      }
      _loadFavorites();
    });
  }

  Future<void> _removeFromFavorites(String rideId) async {
    try {
      await Hive.box('favorites').delete(rideId);
      if (kDebugMode) {
        debugPrint('❌ Removed from favorites: $rideId');
      }
      if (mounted) {
        setState(() => _favoriteRideIds.remove(rideId));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Remove favorite error: $e');
      }
    }
  }

  // ✅ NEW METHOD: Show confirmation dialog before removal
  Future<bool> _showRemovalConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: const Text(
          'Removing this ride from favorites will permanently delete all associated records and channels. This action cannot be undone.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true), // Confirm
            child: const Text('Remove Anyway'),
          ),
        ],
      ),
    ) ?? false; // Default to false if dialog is dismissed without selection
  }

  void _showRideDetailsBottomSheet(
      BuildContext context,
      Map<String, dynamic> data,
      String rideId,
      String? driverPhone,
      bool allowCall,
      String? driverUid,
      ) {
    final depTime = (data['departureTime'] as Timestamp).toDate();
    final formattedDate = '${depTime.day}/${depTime.month}/${depTime.year}';
    final formattedTime =
        '${depTime.hour.toString().padLeft(2, '0')}:${depTime.minute.toString().padLeft(2, '0')}';

    // ✅ Extract OTT platform for channel display
    final ottPlatform = data['ottPlatform'] as String?;

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
                    // ✅ ADDED: Channel field (matches home_screen implementation)
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
                        if (!allowCall || driverPhone == null)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: driverUid != null
                                  ? () {
                                Navigator.pop(context);
                                context.push('/chat/$driverUid');
                              }
                                  : null,
                              icon: const Icon(Icons.chat),
                              label: const Text('Chat'),
                            ),
                          ),
                        if (allowCall &&
                            driverPhone != null &&
                            driverUid != null)
                          const SizedBox(width: 12),
                        if (allowCall &&
                            driverPhone != null &&
                            driverUid != null)
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/chat/$driverUid');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        title: const Text('My Favorites'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: _favoritesLoaded
          ? _buildFavoritesList()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildFavoritesList() {
    if (_favoriteRideIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Swipe left on rides in home screen\nto add them to favorites',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No rides available',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          );
        }

        var rides = snapshot.data!.docs
            .where((ride) => _favoriteRideIds.contains(ride.id))
            .toList();

        if (rides.isEmpty) {
          return Center(
            child: Text(
              'No favorites yet',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          );
        }

        return ListView.builder(
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
            final rideStatus = data['rideStatus'] ?? 'Available';
            final riderLanguage = data['language'] ?? 'English';
            final riderName = data['name'] ?? '';

            return Dismissible(
              key: Key('fav_ride_$rideId'),
              direction: DismissDirection.endToStart,
              dismissThresholds: const {
                DismissDirection.endToStart: 0.2,
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                // ✅ FIXED: Capture messenger and theme color BEFORE async operation
                final messenger = ScaffoldMessenger.of(context);
                final snackBarColor = Theme.of(context).colorScheme.primary;

                if (direction == DismissDirection.endToStart) {
                  final shouldRemove = await _showRemovalConfirmation(context);

                  if (shouldRemove == true && mounted) {
                    await _removeFromFavorites(rideId);

                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Removed from favorites'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: snackBarColor,
                      ),
                    );
                  }
                  // Return false to prevent default dismiss animation (we handle removal manually)
                  return false;
                }
                return false;
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Theme.of(context).cardTheme.color,
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
                                    '$formattedTime • ${data['seats']} seat(s) free',
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
                                } else if (driverUid != null) {
                                  context.push('/chat/$driverUid');
                                }
                              },
                              child: Text(
                                allowCall ? 'Call' : 'Chat',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
        );
      },
    );
  }

  Future<void> _makeCall(
      String phone, ScaffoldMessengerState messenger) async {
    final Uri call = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(call)) {
      await launchUrl(call);
    } else if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Could not launch phone app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}