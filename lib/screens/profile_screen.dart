import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import 'dart:io';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();
  String? _profileImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final imagePath = await _secureStorage.read(key: 'profile_image_path');
    if (mounted) {
      setState(() {
        _profileImagePath = imagePath;
      });
    }
  }

  // ✅ ADDED: Refresh profile image function
  Future<void> _refreshProfileImage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _loadProfileImage();

      if (mounted) {
        setState(() => _isLoading = false);
        _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Profile photo refreshed!'))
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Refresh failed: ${e.toString()}'))
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // ✅ GET PROVIDER REFERENCE BEFORE ASYNC OPERATIONS
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      // STEP 1: Copy image to permanent location
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_$userId.jpg';
      final permanentPath = '${directory.path}/$fileName';

      final originalFile = File(image.path);
      await originalFile.copy(permanentPath);

      // ✅ Verify copy succeeded using the permanent path directly
      final copiedFile = File(permanentPath);
      if (!await copiedFile.exists()) {
        throw Exception('Failed to copy profile image to $permanentPath');
      }

      // STEP 2: Save permanent path to secure storage
      await _secureStorage.write(key: 'profile_image_path', value: permanentPath);

      // ✅ USE EXISTING PROVIDER REFERENCE (no context access across async gap)
      profileProvider.updateProfileImagePath(permanentPath);

      // STEP 3: Calculate image hash for Firebase
      final bytes = await File(permanentPath).readAsBytes();
      final sha256 = SHA256Digest();
      final digest = sha256.process(Uint8List.fromList(bytes));
      final hash = base64Encode(digest);

      // STEP 4: Store ONLY the hash in Firebase (not the image)
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'profileHash': hash,
        'updatedAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // Update UI
      if (mounted) {
        setState(() {
          _profileImagePath = permanentPath;
          _isLoading = false;
        });

        _scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Profile photo updated!'))
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ GET CURRENT USER FOR ID VERIFICATION
    final user = FirebaseAuth.instance.currentUser;
    String contactInfo = '';
    bool isContactVerified = false;

    if (user != null) {
      if (user.phoneNumber != null) {
        contactInfo = user.phoneNumber!;
        isContactVerified = true; // Phone numbers are verified during sign-in
      } else if (user.email != null) {
        contactInfo = user.email!;
        isContactVerified = user.emailVerified;
      }
    }

    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                _isLoading
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    key: ValueKey(_profileImagePath),
                    radius: 60,
                    backgroundImage: _profileImagePath != null
                        ? FileImage(File(_profileImagePath!))
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: _profileImagePath == null
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ✅ UPDATED: Row with text and refresh button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tap to refresh profile photo',
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: _refreshProfileImage,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2), // Minimal spacing
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // ✅ UPDATED: Profile Verification with dynamic badge but consistent text
            ListTile(
              leading: Icon(
                _profileImagePath != null ? Icons.verified : Icons.cancel,
                color: _profileImagePath != null ? Colors.green : Colors.red,
              ),
              title: const Text('Profile Photo Verification'),
              subtitle: const Text(
                'Your profile photo is verified during chats by matching secure hashes, ensuring you are chatting with the right person in the right channel.',
              ),
            ),
            // ✅ ADDED: Profile ID Verification section
            if (contactInfo.isNotEmpty)
              ListTile(
                leading: Icon(
                  isContactVerified ? Icons.verified : Icons.cancel,
                  color: isContactVerified ? Colors.green : Colors.red,
                ),
                title: const Text('Profile ID Verification'),
                subtitle: Text(
                  contactInfo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                if (_isLoading) return;
                setState(() => _isLoading = true);

                // ✅ GET PROVIDER REFERENCE BEFORE ASYNC OPERATIONS
                final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

                try {
                  // Clear local profile image
                  await _secureStorage.delete(key: 'profile_image_path');

                  // Delete local file
                  if (_profileImagePath != null) {
                    final file = File(_profileImagePath!);
                    if (await file.exists()) {
                      await file.delete();
                    }
                  }

                  // ✅ USE EXISTING PROVIDER REFERENCE (no context access across async gap)
                  profileProvider.updateProfileImagePath(null);

                  // Clear Firebase hash
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId != null) {
                    await FirebaseFirestore.instance.collection('users')
                        .doc(userId)
                        .update({'profileHash': FieldValue.delete()});
                  }

                  if (mounted) {
                    setState(() => _profileImagePath = null);
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('Profile photo removed'))
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(content: Text('Error removing photo: ${e.toString()}'))
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Remove profile photo', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}