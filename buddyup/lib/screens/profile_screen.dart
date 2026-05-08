import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {

  final String username;
  final String description;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF0F172A),
      ),

      body: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          children: [

            const SizedBox(height: 40),

            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blueAccent,

              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            Text(

              username,

              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            Text(

                    description,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),

            const SizedBox(height: 50),

            SizedBox(

              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: () {},

                child: const Text(
                  "Edit Profile",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}