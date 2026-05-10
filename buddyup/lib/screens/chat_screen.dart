import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final int userId;
  final String otherUserName;
  final int threadId;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.otherUserName,
    required this.threadId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> messages = [];
  bool isLoading = true;
  String? myName;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await fetchMyName();
    await fetchMessages();
  }

  Future<void> fetchMyName() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/profiles/${widget.userId}/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => myName = data['username'] ?? "Me");
      }
    } catch (e) {
      debugPrint("Eroare profil: $e");
    }
  }

  Future<void> fetchMessages() async {
    final url = Uri.parse('http://10.0.2.2:8000/chat/api/${widget.threadId}/messages/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = data['messages'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String text = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      messages.add({'sender': myName, 'text': text});
    });

    try {
      await http.post(
        Uri.parse('http://10.0.2.2:8000/chat/api/${widget.threadId}/send/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sender_id': widget.userId, 'text': text}),
      );
    } catch (e) {
      debugPrint("Eroare trimitere: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.otherUserName, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      bool isMe = msg['sender'] == myName;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.cyanAccent.withValues(alpha: 0.8) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            msg['text'] ?? "",
                            style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Scrie un mesaj...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyanAccent),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}