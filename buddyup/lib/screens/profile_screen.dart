import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'edit_profile_screen.dart';

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
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {

  String bio = "";
  String interests = "";

  int? age;

  String? profilePictureUrl;

  List<String> galleryImages = [];

  final TextEditingController _reportController = TextEditingController();

  bool isLoading = true;

  Future<void> loadProfile() async {

    final url = Uri.parse(
      'http://10.0.2.2:8000/profiles/${widget.userId}/',
    );

    try {

      final response = await http.get(url);

      if (response.statusCode == 200) {

        final data =
        jsonDecode(response.body);

        final galleryResponse =
        await http.get(

          Uri.parse(
            'http://10.0.2.2:8000/profiles/gallery/${widget.userId}/',
          ),
        );

        final galleryData =
        jsonDecode(
          galleryResponse.body,
        );

        setState(() {

          bio = data['bio'] ?? "";

          interests =
              data['interests'] ?? "";

          age = data['age'];

          profilePictureUrl =
          data['profile_picture'];

          galleryImages =
          List<String>.from(

            galleryData.map(

                  (image) => image['image']
                  .replaceAll(
                '127.0.0.1',
                '10.0.2.2',
              ),
            ),
          );

          isLoading = false;
        });

      } else {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Failed to load profile",
            ),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> _blockUser() async {
    final url = Uri.parse('http://10.0.2.2:8000/reports/api/block_user/');

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
          content: Text('Eroare la blocare: ${response.statusCode}'),
        ),
      );
    }
  }

  Future<void> _reportUser(String reason) async {
    final url = Uri.parse('http://10.0.2.2:8000/reports/api/report_user/');

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
        const SnackBar(
          content: Text('Raport trimis cu succes!'),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la raportare: ${response.statusCode}'),
        ),
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFF0F172A),

      appBar: AppBar(

        title: const Text(
          "My Profile",
        ),

        backgroundColor:
        const Color(0xFF0F172A),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Text(
                  'Block User',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text(
                  'Report User',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'block') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Block User'),
                    content: const Text(
                      'Ești sigur că vrei să blochezi acest utilizator? Nu veți mai putea comunica.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Anulează'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Block',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _blockUser();
                }
              } else if (value == 'report') {
                _reportController.clear();

                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Report User'),
                    content: TextField(
                      controller: _reportController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Introduce motivul raportării',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Anulează'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _reportUser(_reportController.text.trim());
                        },
                        child: const Text(
                          'Report',
                          style: TextStyle(color: Colors.orange),
                        ),
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

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : Padding(

        padding:
        const EdgeInsets.all(24),

        child: Column(

          children: [

            const SizedBox(
              height: 40,
            ),

            CircleAvatar(

              radius: 60,

              backgroundColor:
              Colors.blueAccent,

              backgroundImage:

              profilePictureUrl != null

                  ? NetworkImage(

                profilePictureUrl!
                    .replaceAll(
                  '127.0.0.1',
                  '10.0.2.2',
                ),
              )

                  : null,

              child:

              profilePictureUrl == null

                  ? const Icon(

                Icons.person,

                size: 60,

                color:
                Colors.white,
              )

                  : null,
            ),

            const SizedBox(
              height: 30,
            ),

            Text(

              widget.username,

              style:
              const TextStyle(

                fontSize: 30,

                fontWeight:
                FontWeight.bold,

                color: Colors.white,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(

              bio.isEmpty
                  ? "No bio yet"
                  : bio,

              textAlign:
              TextAlign.center,

              style:
              const TextStyle(

                fontSize: 18,

                color:
                Colors.white70,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(

              interests.isEmpty

                  ? "No interests added"

                  : "Interests: $interests",

              textAlign:
              TextAlign.center,

              style:
              const TextStyle(

                fontSize: 18,

                color:
                Colors.white70,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(

              age == null

                  ? "Age not set"

                  : "Age: $age",

              style:
              const TextStyle(

                fontSize: 18,

                color:
                Colors.white70,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            SizedBox(

              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: () async {

                  final result =
                  await Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (context) =>
                          EditProfileScreen(

                            userId:
                            widget.userId,

                            currentBio: bio,

                            currentInterests:
                            interests,

                            currentAge: age,
                          ),
                    ),
                  );

                  if (result == true) {

                    loadProfile();
                  }
                },

                child: const Text(
                  "Edit Profile",
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(

              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  Colors.redAccent,
                ),

                onPressed: () {

                  Navigator.popUntil(

                    context,

                        (route) =>
                    route.isFirst,
                  );
                },

                child: const Text(

                  "Logout",

                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            const Align(

              alignment:
              Alignment.centerLeft,

              child: Text(

                "Gallery",

                style: TextStyle(

                  fontSize: 24,

                  fontWeight:
                  FontWeight.bold,

                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Expanded(

              child: GridView.builder(

                itemCount:
                galleryImages.length,

                gridDelegate:

                const SliverGridDelegateWithFixedCrossAxisCount(

                  crossAxisCount: 2,

                  crossAxisSpacing: 10,

                  mainAxisSpacing: 10,
                ),

                itemBuilder:
                    (context, index) {

                  return ClipRRect(

                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),

                    child: Image.network(

                      galleryImages[index],

                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}