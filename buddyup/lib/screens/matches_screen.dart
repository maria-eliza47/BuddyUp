import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_profile_screen.dart';

class MatchesScreen extends StatefulWidget {
  final int userId;
  const MatchesScreen({super.key, required this.userId});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List matches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  Future<void> fetchMatches() async {
    // URL-ul trebuie sa fie cel din matches/urls.py (asigura-te ca e 'lista/')
    final url = Uri.parse('http://10.0.2.2:8000/matches/api/lista/?user_id=${widget.userId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          // Acum primim direct o lista [], deci o putem salva direct
          matches = jsonDecode(response.body);
        });
      } else {
        debugPrint("Eroare Server: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Eroare Retea: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Match-urile tale", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.cyanAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  userId: widget.userId,
                  currentBio: "",
                  currentInterests: "",
                  currentAge: null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : matches.isEmpty
          ? const Center(
        child: Text(
          "Inca nicio potrivire gasita.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final m = matches[index];
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.cyanAccent,
                child: Icon(Icons.person, color: Color(0xFF0F172A)),
              ),
              title: Text(
                m['username'] ?? "Utilizator",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Data: ${m['data_match']}",
                style: const TextStyle(color: Colors.white60),
              ),
              trailing: const Icon(Icons.chat, color: Colors.cyanAccent),
            ),
          );
        },
      ),
    );
  }
}