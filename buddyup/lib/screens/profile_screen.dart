import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'edit_profile_screen.dart';

const Color kBg    = Color(0xFFFF6B9D);
const Color kDeep  = Color(0xFFBD1E5E);
const Color kCard  = Color(0xFFFFFFFF);
const Color kBlush = Color(0xFFFFF0F5);
const Color kDark  = Color(0xFF2D0A1A);

class ProfileScreen extends StatefulWidget {
  final String username;
  final String description;
  final int userId;
  final int otherUserId;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.description,
    required this.userId,
    required this.otherUserId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String bio = '';
  String interests = '';
  int? age;
  String? profilePictureUrl;
  List<dynamic> galleryImages = [];
  final TextEditingController _reportController = TextEditingController();
  bool isLoading = true;

  Future<void> loadProfile() async {
    final url =
    Uri.parse('http://10.0.2.2:8000/profiles/${widget.userId}/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final galleryResponse = await http.get(
          Uri.parse(
              'http://10.0.2.2:8000/profiles/gallery/${widget.userId}/'),
        );
        final galleryData = jsonDecode(galleryResponse.body);
        setState(() {
          bio = data['bio'] ?? '';
          interests = data['interests'] ?? '';
          age = data['age'];
          profilePictureUrl = data['profile_picture'];
          galleryImages = galleryData;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> pickAndUploadGalleryImage() async {
    if (galleryImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 images allowed')),
      );
      return;
    }
    final picker = ImagePicker();
    final XFile? image =
    await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'http://10.0.2.2:8000/profiles/upload-gallery/${widget.userId}/'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('image', image.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
    }
  }

  Future<void> deleteGalleryImage(int imageId) async {
    final response = await http.delete(
      Uri.parse(
          'http://10.0.2.2:8000/profiles/delete-gallery/$imageId/'),
    );
    if (response.statusCode == 200) {
      loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete image')),
      );
    }
  }

  Future<void> _blockUser() async {
    final url =
    Uri.parse('http://10.0.2.2:8000/reports/api/block_user/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'other_user_id': widget.otherUserId,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilizator blocat cu succes!'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Eroare la blocare: ${response.statusCode}')),
      );
    }
  }

  Future<void> _reportUser(String reason) async {
    final url =
    Uri.parse('http://10.0.2.2:8000/reports/api/report_user/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reason': reason,
        'user_id': widget.userId,
        'other_user_id': widget.otherUserId,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Raport trimis cu succes!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Eroare la raportare: ${response.statusCode}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  AlertDialog _styledDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) =>
      AlertDialog(
        backgroundColor: kCard,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                color: kDark, fontWeight: FontWeight.bold)),
        content: content,
        actions: actions,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
              color: kCard, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kCard),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kCard),
            color: kCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Text('Block User',
                    style: TextStyle(color: Colors.redAccent)),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report User',
                    style: TextStyle(color: Colors.orange)),
              ),
            ],
            onSelected: (value) async {
              if (value == 'block') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => _styledDialog(
                    title: 'Block User',
                    content: const Text(
                      'Ești sigur că vrei să blochezi acest utilizator? Nu veți mai putea comunica.',
                      style: TextStyle(color: kDark),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Anulează',
                            style: TextStyle(color: kDeep)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Block',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await _blockUser();
              } else if (value == 'report') {
                _reportController.clear();
                await showDialog<void>(
                  context: context,
                  builder: (context) => _styledDialog(
                    title: 'Report User',
                    content: TextField(
                      controller: _reportController,
                      maxLines: 3,
                      style: const TextStyle(color: kDark),
                      decoration: InputDecoration(
                        hintText: 'Introduce motivul raportării',
                        hintStyle: TextStyle(
                            color: kDark.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: kBlush,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: kDeep, width: 1.5),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Anulează',
                            style: TextStyle(color: kDeep)),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _reportUser(
                              _reportController.text.trim());
                        },
                        child: const Text('Report',
                            style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kCard))
          : SingleChildScrollView(
        child: Column(
          children: [
            // ── Pink header section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: kCard,
                    backgroundImage: profilePictureUrl != null
                        ? NetworkImage(profilePictureUrl!
                        .replaceAll('127.0.0.1', '10.0.2.2'))
                        : null,
                    child: profilePictureUrl == null
                        ? const Icon(Icons.person,
                        size: 64, color: kBg)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kCard,
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$age ani',
                      style: const TextStyle(
                          color: Color(0xFFFFE0EE),
                          fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
            // ── White body ──
            Container(
              decoration: const BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio
                  if (bio.isNotEmpty)
                    _infoCard(
                        Icons.notes_rounded, 'Bio', bio)
                  else
                    _emptyInfo('No bio yet'),
                  // Interests
                  if (interests.isNotEmpty)
                    _infoCard(Icons.interests_rounded, 'Interests',
                        interests)
                  else
                    _emptyInfo('No interests added'),
                  const SizedBox(height: 24),
                  // Edit Profile
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(
                                  userId: widget.userId,
                                  currentBio: bio,
                                  currentInterests: interests,
                                  currentAge: age,
                                ),
                          ),
                        );
                        if (result == true) loadProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDeep,
                        foregroundColor: kCard,
                        elevation: 4,
                        shadowColor:
                        kDeep.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Gallery header
                  Row(
                    children: [
                      const Icon(Icons.photo_library_rounded,
                          color: kDeep, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Gallery',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: galleryImages.length < 6
                        ? galleryImages.length + 1
                        : galleryImages.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0 &&
                          galleryImages.length < 6) {
                        return GestureDetector(
                          onTap: pickAndUploadGalleryImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: kBlush,
                              borderRadius:
                              BorderRadius.circular(15),
                              border: Border.all(
                                  color: kDeep.withValues(
                                      alpha: 0.3),
                                  width: 1.5),
                            ),
                            child: Center(
                              child: Icon(
                                Icons
                                    .add_photo_alternate_rounded,
                                size: 48,
                                color: kDeep.withValues(
                                    alpha: 0.6),
                              ),
                            ),
                          ),
                        );
                      }
                      final imageIndex =
                      galleryImages.length < 6
                          ? index - 1
                          : index;
                      return GestureDetector(
                        onLongPress: () async {
                          final confirmed =
                          await showDialog<bool>(
                            context: context,
                            builder: (context) =>
                                _styledDialog(
                                  title: 'Delete image',
                                  content: const Text(
                                      'Are you sure?',
                                      style: TextStyle(
                                          color: kDark)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              context, false),
                                      child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                              color: kDeep)),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              context, true),
                                      child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                              color: Colors
                                                  .redAccent)),
                                    ),
                                  ],
                                ),
                          );
                          if (confirmed == true) {
                            await deleteGalleryImage(
                                galleryImages[imageIndex]
                                ['id']);
                          }
                        },
                        child: ClipRRect(
                          borderRadius:
                          BorderRadius.circular(15),
                          child: Image.network(
                            galleryImages[imageIndex]
                            ['image']
                                .replaceAll(
                                '127.0.0.1', '10.0.2.2'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: kCard,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        final prefs =
                        await SharedPreferences
                            .getInstance();
                        await prefs.remove('isLoggedIn');
                        await prefs.remove('username');
                        await prefs.remove('userId');
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const WelcomeScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                            color: kCard,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBlush,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDeep.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: kDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: kDark, fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: TextStyle(
              color: kDark.withValues(alpha: 0.35), fontSize: 15)),
    );
  }
}
