import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_profile_screen.dart';
import 'chat_screen.dart';

const Color kBg    = Color(0xFFFF6B9D);
const Color kDeep  = Color(0xFFBD1E5E);
const Color kCard  = Color(0xFFFFFFFF);
const Color kBlush = Color(0xFFFFF0F5);
const Color kDark  = Color(0xFF2D0A1A);

class MatchesScreen extends StatefulWidget {
  final int userId;

  const MatchesScreen({super.key, required this.userId});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<dynamic> matches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  Future<void> fetchMatches() async {
    final url = Uri.parse(
        'http://10.0.2.2:8000/matches/api/lista/?user_id=${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => matches = jsonDecode(response.body));
      } else {
        debugPrint('Eroare Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Eroare Retea: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'Match-urile tale',
          style: TextStyle(
              color: kCard, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kCard),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: kCard),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  userId: widget.userId,
                  currentBio: '',
                  currentInterests: '',
                  currentAge: null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kCard))
          : matches.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 72, color: kCard.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            const Text(
              'Inca nicio potrivire gasita.',
              style: TextStyle(
                  color: kCard,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final m = matches[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kDeep.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: kBg.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: kDeep),
              ),
              title: Text(
                m['username'] ?? 'Utilizator',
                style: const TextStyle(
                    color: kDark, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Data: ${m['data_match']}',
                style: TextStyle(
                    color: kDark.withValues(alpha: 0.5)),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kDeep.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat, color: kDeep, size: 20),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      userId: widget.userId,
                      otherUserName: m['username'] ?? "Utilizator",
                      threadId: m['thread_id'] ?? 1,
                      otherUserId: m['user_id'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
