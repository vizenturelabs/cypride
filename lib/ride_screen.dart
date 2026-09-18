import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main.dart' show isFirebaseInitialized;

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  // NEW: Name/nickname field
  final TextEditingController _nameController = TextEditingController();

  // Route information
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _seats = 2;

  // Rider/Guest selection
  String _rideType = 'rider'; // Default: rider

  // NEW: Ride Status field
  String _rideStatus = 'Available'; // Default: Available
  final List<String> _rideStatusOptions = ['Available', 'Booked'];

  // Driver profile
  String _gender = '';
  final List<String> _genders = ['Male', 'Female'];
  String _language = 'English';
  final List<String> _languages = [
    'English',
    'Greek',
    'Russian',
    'Ukrainian',
    'French',
    'German',
    'Arabic',
    'Other'
  ];
  String _otherLanguage = '';

  // Vehicle details
  String _carBrand = '';
  final List<String> _carBrands = [
    'Toyota',
    'Honda',
    'Ford',
    'BMW',
    'Mercedes',
    'Audi',
    'Volkswagen',
    'Nissan',
    'Hyundai',
    'Kia',
    'Other'
  ];
  String _otherCarBrand = '';
  final TextEditingController _otherCarBrandController = TextEditingController(); // ✅ STEP 1: Added persistent controller

  // Ride preferences
  bool _isPetFriendly = false;
  bool _isSmoker = false;
  bool _allowCall = false; // CHANGED: Default to false (chat active by default)
  final TextEditingController _phoneController = TextEditingController(); // Phone number controller

  // ✅ NEW: OTT Messaging fields - UPDATED TO INCLUDE VIBER
  String _ottPlatform = 'WhatsApp'; // Default OTT platform
  final List<String> _ottPlatforms = ['WhatsApp', 'Telegram', 'Viber']; // Added Viber
  final TextEditingController _usernameController = TextEditingController();
  String _username = '';

  bool _hasLuggage = false; // NEW: For guests
  String _fuelSharing = 'no'; // NEW: Default: no
  final List<String> _fuelSharingOptions = [
    'no',
    'flexible',
    '€10',
    '€20',
    'more'
  ];
  String _luggageSpace = 'Medium';
  final List<String> _luggageSpaces = [
    'Small',
    'Medium',
    'Large',
    'Extra Large'
  ];
  String _conversationPreference = 'Friendly';
  final List<String> _conversationPreferences = [
    'Friendly',
    'Quiet',
    'Depends'
  ];

  // ✅ ADDED: Edit mode tracking
  String? _editingRideId;
  bool _isLoading = false;

  // ✅ ADDED: Flag to prevent duplicate initialization
  bool _isEditModeChecked = false;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize with default values
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day + 1);
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);

    // ✅ FIXED: Schedule route parameter check AFTER widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isEditModeChecked) {
        _isEditModeChecked = true;
        _checkEditMode();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _noteController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _otherCarBrandController.dispose(); // ✅ STEP 2: Dispose new controller
    super.dispose();
  }

// ✅ NEW METHOD: Safe context access after widget is built
  void _checkEditMode() {
    try {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (extra != null) {
        // ✅ CRITICAL FIX: Handle rideType BEFORE edit mode check
        if (extra.containsKey('rideType')) {
          final newRideType = extra['rideType'] as String;
          // Only update if different from current value to avoid unnecessary rebuilds
          if (newRideType != _rideType) {
            // ✅ MUST use setState() to trigger UI rebuild with correct initial value
            setState(() {
              _rideType = newRideType;
              // Guests should default to "Available" status (never "Booked" by default)
              if (_rideType == 'guest') {
                _rideStatus = 'Available';
              }
            });
          }
        }

        // Check for edit mode AFTER setting rideType
        if (extra.containsKey('rideId')) {
          _editingRideId = extra['rideId'] as String;
          final data = extra['data'] as Map<String, dynamic>;
          _prefillForm(data);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Edit mode check error: $e');
      }
    }
  }

// ✅ FIXED: Added mounted check before setState
  void _prefillForm(Map<String, dynamic> data) {
    if (!mounted) return;

    setState(() {
      _nameController.text = data['name'] ?? '';
      _fromController.text = data['fromName'] ?? '';
      _toController.text = data['toName'] ?? '';
      _noteController.text = data['notes'] ?? '';

      // ✅ Prefill phone number if exists
      final user = FirebaseAuth.instance.currentUser;
      final authPhone = user?.phoneNumber ?? '';
      final ridePhone = data['driverPhone'] as String? ?? '';
      _phoneController.text = ridePhone.isNotEmpty ? ridePhone : authPhone;

      // ✅ Prefill OTT fields
      _allowCall = data['allowCall'] ?? false;
      _ottPlatform = data['ottPlatform'] ?? 'WhatsApp';
      _username = data['username'] ?? '';
      _usernameController.text = _username;

      final depTime = (data['departureTime'] as Timestamp).toDate();
      _selectedDate = DateTime(depTime.year, depTime.month, depTime.day);
      _selectedTime = TimeOfDay(hour: depTime.hour, minute: depTime.minute);

      _seats = data['seats'] ?? 2;
      _rideType = data['rideType'] ?? 'rider';
      _rideStatus = data['rideStatus'] ?? 'Available';
      _gender = data['gender'] ?? '';

      // ✅ CRITICAL FIX: Handle language dropdown safely
      final languageFromData = data['language'] ?? 'English';
      if (_languages.contains(languageFromData)) {
        _language = languageFromData;
        _otherLanguage = '';
      } else {
        _language = 'Other';
        _otherLanguage = languageFromData;
      }

      // ✅ CRITICAL FIX: Handle car brand dropdown safely
      final carBrandFromData = data['carBrand'] ?? '';
      if (carBrandFromData.isEmpty) {
        _carBrand = '';
        _otherCarBrand = '';
        _otherCarBrandController.text = ''; // ✅ STEP 4: Update controller on prefill
      } else if (_carBrands.contains(carBrandFromData)) {
        _carBrand = carBrandFromData;
        _otherCarBrand = '';
        _otherCarBrandController.text = ''; // ✅ STEP 4: Update controller on prefill
      } else {
        _carBrand = 'Other';
        _otherCarBrand = carBrandFromData;
        _otherCarBrandController.text = carBrandFromData; // ✅ STEP 4: Update controller on prefill
      }

      _isPetFriendly = data['isPetFriendly'] ?? false;
      _isSmoker = data['isSmoker'] ?? false;
      _luggageSpace = data['luggageSpace'] ?? 'Medium';
      _conversationPreference = data['conversationPreference'] ?? 'Friendly';
      _fuelSharing = data['fuelSharing'] ?? 'no';

      // Guest-specific fields
      if (_rideType == 'guest') {
        _hasLuggage = data['hasLuggage'] ?? false;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _selectLocation(String locationType) async {
    final result =
    await context.push('/map-selection', extra: {'type': locationType});
    if (result != null && mounted) {
      final Map<String, dynamic> locationData = result as Map<String, dynamic>;
      if (locationType == 'departure') {
        setState(() => _fromController.text = locationData['address']);
      } else {
        setState(() => _toController.text = locationData['address']);
      }
    }
  }

  // ✅ NEW: Disclaimer dialog method
  Future<bool> _showDisclaimerDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ride Confirmation'),
          content: const Text(
            'Remember to change the status to \'Booked\' when you\'ve made contact and confirmed the ride.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FilledButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _postRide() async {
    // ✅ CONDITIONAL DISCLAIMER: Only show when status is 'Available'
    if (_rideStatus == 'Available') {
      final confirmed = await _showDisclaimerDialog();
      if (!confirmed || !mounted) return;
    }

    // Loading state management (only after user confirms disclaimer OR if status is 'Booked')
    setState(() => _isLoading = true);

    // Firebase guard for desktop
    if (!isFirebaseInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🖥️ Desktop: Ride not saved')),
        );
        context.go('/home');
      }
      return;
    }

    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    if (from.isEmpty || to.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both departure and destination')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (_gender.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // ✅ CRITICAL FIX: Mandatory Name validation
    final riderName = _nameController.text.trim();
    if (riderName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // ✅ CRITICAL FIX: Mandatory Language validation (including "Other" case)
    if (_language == 'Other' && _otherLanguage.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify your language')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // ✅ VALIDATE PHONE NUMBER IF CALLS ARE ENABLED
    String driverPhone = '';
    final user = FirebaseAuth.instance.currentUser!;

    // Check if user has a verified phone number from Firebase auth
    final hasVerifiedPhone = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

    if (_allowCall) {
      if (hasVerifiedPhone) {
        // Use the verified phone number from Firebase auth
        driverPhone = user.phoneNumber!;
      } else {
        // User needs to provide phone number manually
        driverPhone = _phoneController.text.trim();
        if (driverPhone.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your phone number for calls')),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Basic phone number validation (digits only, length 7-15)
        final digitsOnly = RegExp(r'^\+?\d+$');
        if (!digitsOnly.hasMatch(driverPhone)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number must contain digits only (optional + prefix)')),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (driverPhone.length < 7 || driverPhone.length > 15) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number must be 7-15 digits')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
    } else {
      // Calls disabled → ensure username is provided if no phone
      if (_username.trim().isEmpty && !hasVerifiedPhone && _phoneController.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a username or phone number for chat contact')),
        );
        setState(() => _isLoading = false);
        return;
      }
      // Use authenticated user's phone if available, otherwise empty
      driverPhone = user.phoneNumber ?? '';
    }

    final departureDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ).toUtc();

    if (departureDateTime.isBefore(DateTime.now().toUtc())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departure time must be in the future')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Build the ride data map
      final rideData = <String, dynamic>{
        'driverUid': user.uid,
        'driverPhone': driverPhone,
        'fromName': from,
        'toName': to,
        'departureTime': Timestamp.fromDate(departureDateTime),
        'seats': _seats,
        'rideType': _rideType,
        'rideStatus': _rideStatus,
        'name': riderName,
        'gender': _gender,
        'language': _language == 'Other' ? _otherLanguage.trim() : _language,
        'carBrand': _carBrand == 'Other'
            ? _otherCarBrand
            : (_carBrand.isEmpty ? null : _carBrand),
        'isPetFriendly': _isPetFriendly,
        'isSmoker': _isSmoker,
        'luggageSpace': _luggageSpace,
        'conversationPreference': _conversationPreference,
        'notes': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'isActive': true,
        'allowCall': _allowCall,
        'fuelSharing': _fuelSharing,
      };

      // ✅ Save OTT info only if calls are disabled
      if (!_allowCall) {
        rideData['ottPlatform'] = _ottPlatform;
        rideData['username'] = _username.trim().isNotEmpty ? _username.trim() : null;
      }

      // Add guest-specific fields
      if (_rideType == 'guest') {
        rideData['hasLuggage'] = _hasLuggage;
      }

      // ✅ CRITICAL: Determine if we're creating or updating
      if (_editingRideId != null) {
        // UPDATE existing ride
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(_editingRideId)
            .update(rideData);
      } else {
        // CREATE new ride
        rideData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('rides').add(rideData);
      }

      if (!mounted) return;

      // ✅ Show appropriate success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _editingRideId != null
                  ? 'Ride updated successfully!'
                  : 'Ride posted successfully!'
          ),
        ),
      );

      // Clear form and navigate home
      if (mounted) {
        _nameController.clear();
        _fromController.clear();
        _toController.clear();
        _noteController.clear();
        _phoneController.clear();
        _usernameController.clear();
        _otherCarBrandController.clear(); // ✅ STEP 5: Clear controller on submit
        _rideType = 'rider';
        _rideStatus = 'Available';
        _gender = '';
        _language = 'English';
        _otherLanguage = '';
        _carBrand = '';
        _otherCarBrand = ''; // ✅ STEP 5: Reset variable too
        _isPetFriendly = false;
        _isSmoker = false;
        _hasLuggage = false;
        _luggageSpace = 'Medium';
        _conversationPreference = 'Friendly';
        _seats = 2;
        _allowCall = false;
        _ottPlatform = 'WhatsApp';
        _username = '';
        _editingRideId = null;
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Failed to ${_editingRideId != null ? 'update' : 'post'} ride: ${e.toString().substring(0, 50)}...')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final formattedTime = _selectedTime.format(context);
    final isGuest = _rideType == 'guest';
    // ✅ Dynamic title based on edit mode
    final screenTitle = _editingRideId != null
        ? 'Edit Ride'
        : (isGuest ? 'Ask a Ride' : 'Offer a Ride');

    // Get current user
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        title: Text(screenTitle), // ✅ Updated title
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ✅ NEW: Ride Status Section (BEFORE Route Information)
            Text(
              'Ride Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: _rideStatusOptions.map((status) => ButtonSegment(
                value: status,
                label: Text(status),
                icon: status == 'Booked'
                    ? const Icon(Icons.lock, size: 16)
                    : const Icon(Icons.check, size: 16),
              )).toList(),
              selected: {_rideStatus},
              onSelectionChanged: (Set<String> selection) {
                if (mounted && selection.isNotEmpty) {
                  setState(() => _rideStatus = selection.first);
                }
              },
            ),
            const SizedBox(height: 24),

            // Route Information Section
            Text(
              'Route Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),

            // Departure Field with Map Integration
            TextField(
              controller: _fromController,
              decoration: InputDecoration(
                labelText: 'Departure',
                hintText: 'Select departure location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: Icon(
                  Icons.map_outlined,
                  color: Theme.of(context)
                      .iconTheme
                      .color
                      ?.withAlpha((0.5 * 255).round()),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              readOnly: true,
              onTap: () => _selectLocation('departure'),
            ),
            const SizedBox(height: 16),

            // Destination Field with Map Integration
            TextField(
              controller: _toController,
              decoration: InputDecoration(
                labelText: 'Destination',
                hintText: 'Select destination location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: Icon(
                  Icons.map_outlined,
                  color: Theme.of(context)
                      .iconTheme
                      .color
                      ?.withAlpha((0.5 * 255).round()),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              readOnly: true,
              onTap: () => _selectLocation('destination'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Date'),
                    subtitle: Text(formattedDate),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('Time'),
                    subtitle: Text(formattedTime),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available seats:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _seats.toDouble(),
                  min: 1,
                  max: 4,
                  divisions: 3,
                  label: _seats.toString(),
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha((0.3 * 255).round()),
                  onChanged: (double value) {
                    if (mounted) setState(() => _seats = value.toInt());
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Driver Profile Section
            Text(
              'Your Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),

            // Rider/Guest Segmented Button
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'rider',
                  label: Text('Rider'),
                  icon: Icon(Icons.person),
                ),
                ButtonSegment(
                  value: 'guest',
                  label: Text('Guest'),
                  icon: Icon(Icons.groups),
                ),
              ],
              selected: {_rideType},
              onSelectionChanged: (Set<String> selection) {
                if (mounted && selection.isNotEmpty) {
                  setState(() => _rideType = selection.first);
                }
              },
            ),
            const SizedBox(height: 16),

            // ✅ CRITICAL FIX: Name field placed IMMEDIATELY BEFORE Gender
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g., John, Maria, Alex',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              maxLength: 20,
            ),
            const SizedBox(height: 16),

            // Gender Dropdown (NOW AFTER name field)
            DropdownButtonFormField<String>(
              initialValue: _gender.isEmpty ? null : _gender,
              decoration: InputDecoration(
                labelText: 'Gender',
                hintText: 'Please select your gender',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              items: _genders.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (mounted && newValue != null) {
                  setState(() => _gender = newValue);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Gender is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Language Dropdown
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              items: _languages.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (mounted && newValue != null) {
                  setState(() {
                    _language = newValue;
                    if (newValue != 'Other') _otherLanguage = '';
                  });
                }
              },
            ),
            if (_language == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _otherLanguage),
                decoration: InputDecoration(
                  labelText: 'Specify language',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                onChanged: (value) {
                  if (mounted) setState(() => _otherLanguage = value);
                },
              ),
            ],
            const SizedBox(height: 24),

            // Vehicle Details Section (HIDDEN for Guests)
            if (!isGuest) ...[
              Text(
                'Vehicle Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),

              // Car Brand Dropdown
              DropdownButtonFormField<String>(
                initialValue: _carBrand.isEmpty ? null : _carBrand,
                decoration: InputDecoration(
                  labelText: 'Brands',
                  hintText: 'Please select your brand',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                items: _carBrands.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (mounted && newValue != null) {
                    setState(() {
                      _carBrand = newValue;
                      if (newValue != 'Other') _otherCarBrand = '';
                    });
                  }
                },
              ),
              if (_carBrand == 'Other') ...[
                const SizedBox(height: 8),
                // ✅ STEP 3: Use persistent controller instead of creating new one
                TextField(
                  controller: _otherCarBrandController, // ✅ FIXED: Use persistent controller
                  decoration: InputDecoration(
                    labelText: 'Specify car brand',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                    Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  onChanged: (value) {
                    if (mounted) setState(() => _otherCarBrand = value);
                  },
                ),
              ],
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Pet friendly'),
                value: _isPetFriendly,
                onChanged: (bool value) {
                  if (mounted) {
                    setState(() => _isPetFriendly = value);
                  }
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('Smoking allowed'),
                value: _isSmoker,
                onChanged: (bool value) {
                  if (mounted) {
                    setState(() => _isSmoker = value);
                  }
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _luggageSpace,
                decoration: InputDecoration(
                  labelText: 'Luggage capacity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                items: _luggageSpaces.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (mounted && newValue != null) {
                    setState(() => _luggageSpace = newValue);
                  }
                },
              ),
            ] else ...[
              // GUEST-SPECIFIC FIELDS
              Text(
                'Guest Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('Smoker assumed'),
                value: _isSmoker,
                onChanged: (bool value) {
                  if (mounted) {
                    setState(() => _isSmoker = value);
                  }
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('Luggage with me'),
                value: _hasLuggage,
                onChanged: (bool value) {
                  if (mounted) {
                    setState(() => _hasLuggage = value);
                  }
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ],
            const SizedBox(height: 24),

            // Ride Preferences Section
            Text(
              'Ride Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),

            // Fuel Sharing Dropdown
            DropdownButtonFormField<String>(
              initialValue: _fuelSharing,
              decoration: InputDecoration(
                labelText: 'Fuel sharing',
                helperText:
                'CypRide will never charge fuel fees',
                helperStyle: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              items: _fuelSharingOptions.map((String value) {
                String displayValue = value;
                if (value == 'flexible') {
                  displayValue = 'Yes: Flexible';
                } else if (value == 'more') {
                  displayValue = 'More (Specify in notes)';
                }
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(displayValue),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (mounted && newValue != null) {
                  setState(() => _fuelSharing = newValue);
                }
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _conversationPreference,
              decoration: InputDecoration(
                labelText: 'Conversation style',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              items: _conversationPreferences.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (mounted && newValue != null) {
                  setState(() => _conversationPreference = newValue);
                }
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Additional notes',
                hintText: 'e.g., "I prefer not to pick up at the bus stop"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Call option toggle - CHANGED DEFAULT TO FALSE
            SwitchListTile(
              title: const Text('Allow direct calls'),
              subtitle: const Text('(Use Apps below if no calls)'),
              value: _allowCall,
              onChanged: (bool value) {
                if (mounted) {
                  setState(() => _allowCall = value);
                }
              },
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),

            // ✅ FIXED: OTT Platform Selection (only visible when calls disabled)
            if (!_allowCall) ...[
              DropdownButtonFormField<String>(
                initialValue: _ottPlatform,
                decoration: InputDecoration(
                  labelText: 'Messaging Platform',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                items: _ottPlatforms.map((String platform) {
                  return DropdownMenuItem<String>(
                    value: platform,
                    child: Text(platform),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (mounted && newValue != null) {
                    setState(() => _ottPlatform = newValue);
                  }
                },
              ),

              // ✅ FIXED: Added proper spacing with SizedBox
              const SizedBox(height: 16),

              // Username field with aligned icons
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username (@...)',
                  hintText: 'Enter your $_ottPlatform username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                onChanged: (value) {
                  if (mounted) setState(() => _username = value);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Phone number input - ONLY VISIBLE WHEN CALLS ARE ENABLED AND USER DOESN'T HAVE VERIFIED PHONE
            if (_allowCall && !(user?.phoneNumber?.isNotEmpty == true)) ...[
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number for direct calls',
                  helperText:
                  'Please include your country code first',
                  helperStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                keyboardType: TextInputType.phone,
                maxLength: 15,
              ),
              const SizedBox(height: 16),
            ],

            // Phone verification message - ONLY VISIBLE WHEN CALLS ARE ENABLED AND USER HAS VERIFIED PHONE
            if (_allowCall && user?.phoneNumber?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Phone already verified: ${user?.phoneNumber ?? 'Unknown'}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 24),

            // Action Button with Loading State - ✅ Dynamic text based on edit mode
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _postRide,
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  _editingRideId != null
                      ? 'Update Ride'
                      : (isGuest ? 'Ask Ride' : 'Post Ride'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}