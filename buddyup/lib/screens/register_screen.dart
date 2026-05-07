import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  Future<void> registerUser() async {

    String username = usernameController.text;
    String email = emailController.text;
    String password = passwordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );

      return;
    }

    final url = Uri.parse(
      'http://127.0.0.1:8000/users/register/',
    );

    try {

      final response = await http.post(

        url,

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          'username': username,
          'email': email,
          'password': password,

        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
          ),
        );

        Navigator.pop(context);

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ?? 'Registration failed',
            ),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: const Color(0xFF0F172A),
      ),

      body: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          children: [

            const SizedBox(height: 40),

            TextField(

              controller: usernameController,

              decoration: InputDecoration(
                hintText: "Username",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(

              controller: emailController,

              decoration: InputDecoration(
                hintText: "Email",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(

              controller: passwordController,
              obscureText: true,

              decoration: InputDecoration(
                hintText: "Password",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: registerUser,

                child: const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}