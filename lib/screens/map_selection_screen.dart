import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapSelectionScreen extends StatefulWidget {
  final String locationType; // 'departure' or 'destination'
  const MapSelectionScreen({super.key, required this.locationType});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

// Coordinates centered on Republic of Cyprus territory (34.83, 33.28)
// Avoids northern area and UN Buffer Zone per Republic of Cyprus jurisdiction
// Source: Geographic centroid of RoC controlled territory
class _MapSelectionScreenState extends State<MapSelectionScreen> {
  late MapController _mapController;
  LatLng _initialPosition = const LatLng(34.83, 33.28);
  LatLng? _selectedPosition;
  String _address = '';
  bool _isLoading = false;
  bool _isLocationPermissionGranted = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
  GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getLocationAndInitialize();
  }

  Future<void> _getLocationAndInitialize() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      LatLng positionToUse;
      if (permission == LocationPermission.denied) {
        positionToUse = const LatLng(34.8706, 33.6093);
        _isLocationPermissionGranted = false;
      } else {
        // Get current position
        Position position = await Geolocator.getCurrentPosition();
        positionToUse = LatLng(position.latitude, position.longitude);
        _isLocationPermissionGranted = true;
      }

      // Update the position and initialize map
      if (mounted) {
        setState(() {
          _initialPosition = positionToUse;
        });
        _mapController.move(positionToUse, 12);
        await _getAddressFromLatLng(positionToUse);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialPosition = const LatLng(34.83, 33.28);
          _mapController.move(_initialPosition, 8);
          _address = 'Republic of Cyprus';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        String formattedAddress = _formatAddress(placemark, position);
        if (mounted) {
          setState(() {
            _address = formattedAddress;
            _selectedPosition = position;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _address =
            'Location ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
            _selectedPosition = position;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address =
          'Location ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _selectedPosition = position;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatAddress(Placemark placemark, LatLng position) {
    String address = '';
    // Correct way for geocoding 2.1.1
    if (placemark.street != null) {
      if (placemark.subThoroughfare != null) {
        address += '${placemark.subThoroughfare!} ${placemark.street!}, ';
      } else {
        address += '${placemark.street!}, ';
      }
    } else if (placemark.thoroughfare != null) {
      address += '${placemark.thoroughfare!}, ';
    }

    if (placemark.locality != null) {
      address += placemark.locality!;
    }

    // If we couldn't form a proper address, return coordinates
    if (address.isNotEmpty) {
      return address;
    } else {
      return 'Location ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.locationType == 'departure'
            ? 'Select Departure'
            : 'Select Destination'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Stack(
        children: [
          // FIX: Wrap FlutterMap in Positioned.fill to ensure it takes full screen
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 8,
                minZoom: 8,
                maxZoom: 18,
                onTap: (_, point) => _getAddressFromLatLng(point),
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  maxZoom: 19,
                  // CORRECT PARAMETER FOR USER-AGENT
                  userAgentPackageName: 'com.vizenture.cypride',
                ),
                // Correct attribution for OpenStreetMap
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black.withAlpha(128),
                    child: Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                if (_selectedPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPosition!,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.error,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_address.isNotEmpty && !_isLoading)
            Positioned(
              bottom: 36,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .shadowColor
                          .withAlpha((0.1 * 255).round()),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _address,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        if (_selectedPosition != null) {
                          Navigator.pop(context, {
                            'address': _address,
                            'latitude': _selectedPosition!.latitude,
                            'longitude': _selectedPosition!.longitude,
                          });
                        }
                      },
                      child: Text(widget.locationType == 'departure'
                          ? 'Use as Departure'
                          : 'Use as Destination'),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search location...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (query) async {
                if (!mounted) return;
                setState(() => _isLoading = true);
                try {
                  List<Location> locations = await locationFromAddress(query);
                  if (locations.isNotEmpty && mounted) {
                    LatLng position =
                    LatLng(locations[0].latitude, locations[0].longitude);
                    _mapController.move(position, 14);
                    await _getAddressFromLatLng(position);
                  }
                } catch (e) {
                  _scaffoldKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Location not found')),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
            ),
          ),
          if (_isLocationPermissionGranted)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'currentLocation',
                onPressed: () async {
                  if (!mounted) return;
                  setState(() => _isLoading = true);
                  try {
                    Position position = await Geolocator.getCurrentPosition();
                    LatLng currentPosition =
                    LatLng(position.latitude, position.longitude);
                    _mapController.move(currentPosition, 14);
                    await _getAddressFromLatLng(currentPosition);
                  } catch (e) {
                    _scaffoldKey.currentState?.showSnackBar(
                      const SnackBar(
                          content: Text('Could not get current location')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }
}