import 'package:flutter/material.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {

  final String username;

  const HomeScreen({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text("BuddyUp"),
        backgroundColor: const Color(0xFF0F172A),

        actions: [

          IconButton(

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => ProfileScreen(
                    username: username,
                    description: "This is my BuddyUp profile!",
                  ),
                ),
              );
            },

            icon: const Icon(
              Icons.person,
              size: 32,
              color: Colors.pinkAccent,
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(

        backgroundColor: Colors.pinkAccent,

        onPressed: () {

          Navigator.pop(context);

        },

        child: const Icon(
          Icons.logout,
          color: Colors.white,
        ),
      ),

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Text(

              "Welcome back,",

              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),

            const SizedBox(height: 20),

            Text(

              username,

              style: const TextStyle(
                fontSize: 22,
                color: Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}