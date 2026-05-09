import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {

  final int userId;

  final String currentBio;
  final String currentInterests;

  final int? currentAge;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.currentBio,
    required this.currentInterests,
    required this.currentAge,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  late TextEditingController bioController;
  late TextEditingController interestsController;
  late TextEditingController ageController;
  File? selectedImage;

  @override
  void initState() {

    super.initState();

    bioController = TextEditingController(
      text: widget.currentBio,
    );

    interestsController = TextEditingController(
      text: widget.currentInterests,
    );

    ageController = TextEditingController(
      text: widget.currentAge?.toString() ?? "",
    );
  }

  Future<void> updateProfile() async {

    final url = Uri.parse(
      'http://10.0.2.2:8000/profiles/update/${widget.userId}/',
    );

    try {

      final response = await http.put(

        url,

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          'bio': bioController.text,
          'interests': interestsController.text,

          'age': ageController.text.isEmpty
              ? null
              : int.parse(ageController.text),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
          ),
        );

        if (selectedImage != null) {

          var request = http.MultipartRequest(

            'PUT',

            Uri.parse(
              'http://10.0.2.2:8000/profiles/upload-picture/${widget.userId}/',
            ),
          );

          request.files.add(

            await http.MultipartFile.fromPath(

              'profile_picture',

              selectedImage!.path,
            ),
          );

          await request.send();
        }

        Navigator.pop(context, true);

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update profile"),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> pickImage() async {

    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {

      setState(() {

        selectedImage = File(pickedFile.path);

      });
    }
  }

  @override
  void dispose() {

    bioController.dispose();
    interestsController.dispose();
    ageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF0F172A),
      ),

      body: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          children: [

            GestureDetector(

              onTap: pickImage,

              child: CircleAvatar(

                radius: 60,
                backgroundColor: Colors.blueAccent,

                backgroundImage:

                selectedImage != null
                    ? FileImage(selectedImage!)
                    : null,

                child:

                selectedImage == null

                    ? const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.white,
                )

                    : null,
              ),
            ),

            const SizedBox(height: 30),

            TextField(

              controller: bioController,

              decoration: InputDecoration(
                hintText: "Bio",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              maxLines: 3,
            ),

            const SizedBox(height: 20),

            TextField(

              controller: interestsController,

              decoration: InputDecoration(
                hintText: "Interests",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(

              controller: ageController,

              keyboardType: TextInputType.number,

              decoration: InputDecoration(
                hintText: "Age",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(

              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: updateProfile,

                child: const Text(
                  "Save Changes",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}