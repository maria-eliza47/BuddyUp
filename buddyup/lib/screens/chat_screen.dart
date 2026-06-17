import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const Color kBg    = Color(0xFFFF6B9D);
const Color kDeep  = Color(0xFFBD1E5E);
const Color kCard  = Color(0xFFFFFFFF);
const Color kBlush = Color(0xFFFFF0F5);
const Color kDark  = Color(0xFF2D0A1A);

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
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/profiles/${widget.userId}/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => myName = data['username'] ?? 'Me');
      }
    } catch (e) {
      debugPrint('Eroare profil: $e');
    }
  }

  Future<void> fetchMessages() async {
    final url = Uri.parse(
        'http://10.0.2.2:8000/chat/api/${widget.threadId}/messages/');
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
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/chat/api/send/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': widget.userId,
          'text': text,
          'thread_id': widget.threadId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Mesaj salvat cu succes in baza de date!');
      } else {
        debugPrint(
            '❌ Eroare la salvare. Cod: ${response.statusCode}. Motiv: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Eroare de retea: $e');
    }
  }

  Future<void> generateIcebreaker() async {
    _messageController.text = 'Se gândește AI-ul...';
    try {
      final url = Uri.parse('http://10.0.2.2:8000/chat/api/icebreaker/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'target_user': widget.otherUserName,
          'thread_id': widget.threadId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _messageController.text = data['suggestion'] ?? '');
      } else {
        _messageController.clear();
        debugPrint('Eroare AI: ${response.statusCode}');
      }
    } catch (e) {
      _messageController.clear();
      debugPrint('Eroare retea AI: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlush,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: kCard),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: kCard.withValues(alpha: 0.25),
              child: const Icon(Icons.person_rounded, color: kCard, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                  color: kCard,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
            tooltip: 'AI Icebreaker',
            onPressed: generateIcebreaker,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                child: CircularProgressIndicator(color: kDeep))
                : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                bool isMe = msg['sender'] == myName;
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                    const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? kDeep : kCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                        Radius.circular(isMe ? 16 : 4),
                        bottomRight:
                        Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kDeep.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isMe ? kCard : kDark,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            color: kCard,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.auto_awesome,
                      color: Colors.amberAccent),
                  onPressed: generateIcebreaker,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: kDark),
                    decoration: InputDecoration(
                      hintText: 'Scrie un mesaj...',
                      hintStyle: TextStyle(
                          color: kDark.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: kBlush,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: kDeep, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kDeep,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kDeep.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: kCard, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
