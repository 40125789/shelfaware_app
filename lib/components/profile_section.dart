import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/screens/my_profile.dart';
import 'package:shelfaware_app/providers/auth_provider.dart';
import 'package:shelfaware_app/providers/profile_image_provider.dart';

final isUploadingProvider = StateProvider<bool>((ref) => false);

class ProfileSection extends ConsumerWidget {
  const ProfileSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final profileImageUrl = ref.watch(profileImageProvider(user?.uid ?? ''));
    final isUploading = ref.watch(isUploadingProvider.state).state;

    Future<void> _uploadProfileImage(String uid, WidgetRef ref) async {
  final user = ref.read(authProvider).user;
  if (user == null) return;

  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      debugPrint('No image selected.');
      return;
    }

    ref.read(isUploadingProvider.notifier).state = true;

    final storageRef =
        FirebaseStorage.instance.ref().child('user_profile_images/$uid.jpg');
    final uploadTask = storageRef.putFile(File(pickedFile.path));

    uploadTask.snapshotEvents.listen((taskSnapshot) {
      double progress =
          taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
      debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileImageUrl': downloadUrl,
    });

    ref.invalidate(profileImageProvider(user.uid));
    debugPrint('Profile image uploaded successfully!');
  } catch (e) {
    debugPrint('Error uploading profile image: $e');
  } finally {
    ref.read(isUploadingProvider.notifier).state = false; // Reset to false
  }
}
  


    return GestureDetector(
      onTap: () {
        if (user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(userId: user.uid),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF388E3C), Color(0xFF4CAF50)], // Green gradient
          ),
        ),
        padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 8), // Reduced bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: user != null
                      ? () => _uploadProfileImage(user.uid, ref)
                      : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 34, // Keep profile image size same
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: profileImageUrl.when(
                              data: (url) => url != null && url.isNotEmpty
                                  ? CachedNetworkImageProvider(url)
                                  : const AssetImage(
                                          'assets/default_avatar.png')
                                      as ImageProvider,
                              loading: () =>
                                  const AssetImage('assets/default_avatar.png'),
                              error: (_, __) =>
                                  const AssetImage('assets/default_avatar.png'),
                            ),
                            child: profileImageUrl.when(
                              data: (url) => url == null || url.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) =>
                                  const Icon(Icons.error, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      if (isUploading)
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                    return AnimatedOpacity(
                      opacity: 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: const Text(
                      "Loading...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                      ),
                    );
                    }
                    if (snapshot.hasError) {
                    return const Text(
                      "Error loading profile",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.white),
                    );
                    }

                    // Fetch user data
                    final userData =
                      snapshot.data?.data() as Map<String, dynamic>?;

                    final firstName =
                      userData?['firstName'] ?? 'No First Name';
                    final lastName = userData?['lastName'] ?? 'No Last Name';

                    return AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      "$firstName $lastName",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    ),
                    );
                  },
                  ),
                ),
                // The tappable icon (chevron or arrow)
                const Icon(
                  Icons
                      .arrow_forward_ios, // Chevron icon to indicate a tapable area
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 4), // Reduced space between name and email
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final email = userData?['email'] ?? 'No email';

                return Text(
                  email,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
