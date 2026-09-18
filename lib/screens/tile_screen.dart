import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart' show isFirebaseInitialized;

class TileScreen extends StatefulWidget {
  const TileScreen({super.key});

  @override
  State<TileScreen> createState() => _TileScreenState();
}

class _TileScreenState extends State<TileScreen> {
  late Box _favoritesBox;
  Set<String> _favoriteRideIds = {};
  StreamSubscription? _favoritesSubscription;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadFavorites();
    _listenToFavorites();
    _loadRides();
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
        debugPrint('📌 TileScreen: Loaded ${favorites.length} favorites');
      }
      if (mounted) {
        setState(() {
          _favoriteRideIds = favorites;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ TileScreen favorites load error: $e');
      }
    }
  }

  void _listenToFavorites() {
    _favoritesSubscription = _favoritesBox.watch().listen((event) {
      if (kDebugMode) {
        debugPrint('🔄 TileScreen: Favorites box changed - $event');
      }
      _loadFavorites();
    });
  }

  Future<void> _loadRides() async {
    if (!isFirebaseInitialized || _currentUserId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRide(String rideId) async {
    try {
      // Remove from Firestore
      await FirebaseFirestore.instance.collection('rides').doc(rideId).delete();

      // Remove from favorites if present
      if (_favoriteRideIds.contains(rideId)) {
        await Hive.box('favorites').delete(rideId);
        if (kDebugMode) {
          debugPrint('✅ Removed ride $rideId from favorites');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Deleted ride $rideId from Firestore');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ride deleted successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Delete ride error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ride: ${e.toString().substring(0, 50)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String rideId, String fromName, String toName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Ride'),
          content: Text('Are you sure you want to delete this ride?\n\n$fromName → $toName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteRide(rideId);
    }
  }

  void _navigateToEditRide(String rideId, Map<String, dynamic> data) {
    // Pass ride data to edit screen via route parameters
    context.push('/ride', extra: {
      'rideId': rideId,
      'data': data,
    });
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
        title: const Text('My Tiles'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildRideList(),
    );
  }

// ... existing imports and class declaration ...

  Widget _buildRideList() {
    if (_currentUserId == null) {
      return Center(
        child: Text(
          'Please log in to view your tiles',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('driverUid', isEqualTo: _currentUserId)
          .where('isActive', isEqualTo: true)
          .where('departureTime', isGreaterThan: Timestamp.now())
          .orderBy('departureTime', descending: false)
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tiles yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first tile by offering a ride',
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

        final rides = snapshot.data!.docs;
        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            final rideId = ride.id;
            final data = ride.data();
            final depTime = (data['departureTime'] as Timestamp).toDate();
            final formattedTime =
                '${depTime.day}/${depTime.month} at ${depTime.hour.toString().padLeft(2, '0')}:${depTime.minute.toString().padLeft(2, '0')}';
            final fromName = data['fromName'] as String;
            final toName = data['toName'] as String;
            final seats = data['seats'] as int;
            // ✅ EXTRACT language, name and status for proper rendering
            final riderLanguage = data['language'] ?? 'English';
            final riderName = data['name'] ?? '';
            final rideStatus = data['rideStatus'] ?? 'Available';

            return Dismissible(
              key: Key('tile_ride_$rideId'),
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
                if (direction == DismissDirection.endToStart) {
                  await _showDeleteConfirmation(rideId, fromName, toName);
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
                        _showRideDetailsBottomSheet(context, rideId, data);
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
                                    '$fromName →',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    toName,
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$formattedTime • $seats seat(s) free',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  // ✅ LINE 2: Language - Name (ALWAYS DISPLAYED - NO CONDITION)
                                  Text(
                                    '$riderLanguage • $riderName',
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
                                _navigateToEditRide(rideId, data);
                              },
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
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

  void _showRideDetailsBottomSheet(
      BuildContext context,
      String rideId,
      Map<String, dynamic> data,
      ) {
    // ✅ FIXED: Use depTime for formatting instead of unused variable
    final depTime = (data['departureTime'] as Timestamp).toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with edit button
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
                        const SizedBox(height: 4),
                        Text(
                          'Tap anywhere to close',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditRide(rideId, data);
                    },
                    color: Theme.of(context).colorScheme.primary,
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
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Route'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, 'From', data['fromName'] ?? 'Not specified'),
                    _buildInfoRow(Icons.flag, 'To', data['toName'] ?? 'Not specified'),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Schedule'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Date',
                      _formatDate(depTime), // ✅ Using depTime here
                    ),
                    _buildInfoRow(
                      Icons.access_time,
                      'Time',
                      _formatTime(depTime), // ✅ Using depTime here
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Driver Information'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.person, 'Gender', data['gender'] ?? 'Not specified'),
                    _buildInfoRow(Icons.language, 'Language', data['language'] ?? 'Not specified'),
                    _buildInfoRow(Icons.directions_car, 'Car Brand', data['carBrand'] ?? 'Not specified'),
                    // ✅ ADDED: Display rider name in bottom sheet
                    _buildInfoRow(Icons.person_outline, 'Name', data['name'] ?? 'Not specified'),
                    // ✅ ADDED: Display ride status in bottom sheet
                    _buildInfoRow(Icons.lock, 'Ride Status', data['rideStatus'] ?? 'Available'),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Ride Preferences'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.pets,
                      'Pet Friendly',
                      data['isPetFriendly'] == true ? 'Yes ✓' : 'No ✗',
                    ),
                    _buildInfoRow(
                      Icons.smoking_rooms,
                      'Smoking Allowed',
                      data['isSmoker'] == true ? 'Yes ✓' : 'No ✗',
                    ),
                    _buildInfoRow(Icons.luggage, 'Luggage Space', data['luggageSpace'] ?? 'Not specified'),
                    _buildInfoRow(Icons.chat, 'Conversation', data['conversationPreference'] ?? 'Not specified'),
                    _buildInfoRow(Icons.event_seat, 'Available Seats', '${data['seats'] ?? 0} seat(s)'),
                    if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle('Additional Notes'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
}