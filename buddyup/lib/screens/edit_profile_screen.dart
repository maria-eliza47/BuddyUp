import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

const Color kBg    = Color(0xFFFF6B9D);
const Color kDeep  = Color(0xFFBD1E5E);
const Color kCard  = Color(0xFFFFFFFF);
const Color kBlush = Color(0xFFFFF0F5);
const Color kDark  = Color(0xFF2D0A1A);

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
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController bioController;
  late TextEditingController interestsController;
  late TextEditingController ageController;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    bioController = TextEditingController(text: widget.currentBio);
    interestsController =
        TextEditingController(text: widget.currentInterests);
    ageController =
        TextEditingController(text: widget.currentAge?.toString() ?? '');
  }

  Future<void> updateProfile() async {
    final url = Uri.parse(
        'http://10.0.2.2:8000/profiles/update/${widget.userId}/');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'])));
        if (selectedImage != null) {
          var request = http.MultipartRequest(
            'PUT',
            Uri.parse(
                'http://10.0.2.2:8000/profiles/upload-picture/${widget.userId}/'),
          );
          request.files.add(await http.MultipartFile.fromPath(
              'profile_picture', selectedImage!.path));
          await request.send();
        }
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  @override
  void dispose() {
    bioController.dispose();
    interestsController.dispose();
    ageController.dispose();
    super.dispose();
  }

  InputDecoration _field(String hint, IconData icon,
      {bool multiline = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kDeep.withValues(alpha: 0.5)),
        prefixIcon: multiline
            ? Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Icon(icon, color: kDeep))
            : Icon(icon, color: kDeep),
        filled: true,
        fillColor: kBlush,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: kDeep, width: 1.8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kCard),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              color: kCard, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: kCard,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : null,
                      child: selectedImage == null
                          ? const Icon(Icons.camera_alt,
                          size: 40, color: kBg)
                          : null,
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kDeep,
                        shape: BoxShape.circle,
                        border: Border.all(color: kCard, width: 2),
                      ),
                      child: const Icon(Icons.edit,
                          color: kCard, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to change photo',
                style: TextStyle(
                    color: Color(0xFFFFE0EE), fontSize: 13),
              ),
              const SizedBox(height: 24),
              // Form card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kDeep.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      style: const TextStyle(color: kDark),
                      decoration:
                      _field('Bio', Icons.notes_rounded, multiline: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: interestsController,
                      style: const TextStyle(color: kDark),
                      decoration: _field(
                          'Interests (ex: muzica, sport)',
                          Icons.interests_rounded),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: kDark),
                      decoration: _field('Age', Icons.cake_rounded),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDeep,
                          foregroundColor: kCard,
                          elevation: 4,
                          shadowColor:
                          kDeep.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
