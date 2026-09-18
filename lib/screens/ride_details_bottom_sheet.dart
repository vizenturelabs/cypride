import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class RideDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> rideData;
  final String rideId;

  const RideDetailsBottomSheet({
    super.key,
    required this.rideData,
    required this.rideId,
  });

  @override
  State<RideDetailsBottomSheet> createState() => _RideDetailsBottomSheetState();
}

class _RideDetailsBottomSheetState extends State<RideDetailsBottomSheet> {
  late MapController _mapController;
  LatLng? _fromPosition;
  LatLng? _toPosition;
  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _geocodeLocations();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Geocode location names to coordinates (simplified for demo)
  Future<void> _geocodeLocations() async {
    // In production, use geocoding package to convert addresses to coordinates
    // For demo, we'll use Cyprus center as default with slight variations
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate geocoding

    if (mounted) {
      setState(() {
        // Use slightly different positions for demo
        _fromPosition = const LatLng(34.8706, 33.6093); // Cyprus center
        _toPosition = const LatLng(34.6841, 33.0379); // Example destination

        // ✅ FIXED: Calculate center and zoom manually instead of fitBounds
        final center = LatLng(
          (_fromPosition!.latitude + _toPosition!.latitude) / 2,
          (_fromPosition!.longitude + _toPosition!.longitude) / 2,
        );

        // Calculate distance-based zoom level
        final latDiff = (_fromPosition!.latitude - _toPosition!.latitude).abs();
        final lngDiff = (_fromPosition!.longitude - _toPosition!.longitude).abs();
        final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

        // Zoom level based on distance (smaller distance = higher zoom)
        double zoom = 10;
        if (maxDiff < 0.1) {
          zoom = 14;
        } else if (maxDiff < 0.3) {
          zoom = 12;
        } else if (maxDiff < 0.5) {
          zoom = 11;
        }

        _mapController.move(center, zoom);
        _mapLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.rideData;
    final depTime = (data['departureTime'] as Timestamp).toDate();
    final formattedDate = '${depTime.day}/${depTime.month}/${depTime.year}';
    final formattedTime = '${depTime.hour.toString().padLeft(2, '0')}:${depTime.minute.toString().padLeft(2, '0')}';
    final allowCall = data['allowCall'] ?? true;
    final driverPhone = data['driverPhone'] as String?;
    final driverUid = data['driverUid'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar for dragging
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Section
                  _buildSectionTitle('Route'),
                  const SizedBox(height: 8),
                  _buildRouteItem(
                    Icons.location_on,
                    data['fromName'] ?? 'Departure',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildRouteItem(
                    Icons.flag,
                    data['toName'] ?? 'Destination',
                    Colors.red,
                  ),

                  const SizedBox(height: 24),

                  // Map Section
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
                    child: _mapLoaded
                        ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _fromPosition ?? const LatLng(34.8706, 33.6093),
                        initialZoom: 10,
                        minZoom: 8,
                        maxZoom: 18,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.vizenture.cypride',
                        ),
                        if (_fromPosition != null && _toPosition != null) ...[
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _fromPosition!,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 40,
                                ),
                              ),
                              Marker(
                                point: _toPosition!,
                                width: 40,
                                height: 40,
                                child: Icon(
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
                                points: [_fromPosition!, _toPosition!],
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        ],
                      ],
                    )
                        : const Center(child: CircularProgressIndicator()),
                  ),

                  const SizedBox(height: 24),

                  // Driver Info Section
                  _buildSectionTitle('Driver Information'),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.account_circle,
                    'Name',
                    data['name'] ?? 'Not specified',
                  ),
                  _buildInfoRow(
                    Icons.person,
                    'Gender',
                    data['gender'] ?? 'Not specified',
                  ),
                  _buildInfoRow(
                    Icons.language,
                    'Language',
                    data['language'] ?? 'Not specified',
                  ),
                  _buildInfoRow(
                    Icons.directions_car,
                    'Car Brand',
                    data['carBrand'] ?? 'Not specified',
                  ),

                  const SizedBox(height: 24),

                  // Ride Preferences Section
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
                  _buildInfoRow(
                    Icons.luggage,
                    'Luggage Space',
                    data['luggageSpace'] ?? 'Not specified',
                  ),
                  _buildInfoRow(
                    Icons.chat,
                    'Conversation',
                    data['conversationPreference'] ?? 'Not specified',
                  ),
                  _buildInfoRow(
                    Icons.event_seat,
                    'Available Seats',
                    '${data['seats'] ?? 0} seat(s)',
                  ),

                  if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
                    const SizedBox(height: 24),
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

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      if (allowCall && driverPhone != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _makeCall(driverPhone),
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
                      if (allowCall && driverPhone != null && driverUid != null)
                        const SizedBox(width: 12),
                      if (allowCall && driverPhone != null && driverUid != null)
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

  Widget _buildRouteItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
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

  Future<void> _makeCall(String phone) async {
    final Uri call = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(call)) {
      await launchUrl(call);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }
}