import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final int userId;
  final String otherUserName;
  final int threadId;
  final int otherUserId;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.otherUserName,
    required this.threadId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  List<dynamic> messages = [];
  bool isLoading = true;
  String? myName;

  @override
  void dispose() {
    _messageController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _blockUser() async {
    final url = Uri.parse('http://10.0.2.2:8000/reports/api/block/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'blocker_id': widget.userId,
        'blocked_id': widget.otherUserId,
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilizator blocat cu succes!'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la blocare: ${response.statusCode}'),
          ),
        );
      }
    }
  }

  Future<void> _reportUser(String reason) async {
    final url = Uri.parse('http://10.0.2.2:8000/reports/api/report/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reason': reason,
        'reporter_id': widget.userId,
        'reported_id': widget.otherUserId,
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Raport trimis cu succes!'),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la raportare: ${response.statusCode}'),
          ),
        );
      }
    }
  }

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
      // 1. Am scos threadId din link, ca sa se potriveasca exact cu urls.py din Django
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/chat/api/send/'),
        headers: {'Content-Type': 'application/json'},
        // 2. Am adaugat thread_id in interiorul pachetului trimis
        body: jsonEncode({
          'sender_id': widget.userId,
          'text': text,
          'thread_id': widget.threadId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Mesaj salvat cu succes in baza de date!");
      } else {
        debugPrint("❌ Eroare la salvare. Cod: ${response.statusCode}. Motiv: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Eroare de retea: $e");
    }
  }
  // Funcția care apelează Agentul 2 (AI Icebreaker)
  Future<void> generateIcebreaker() async {
    // Putem goli textul sau pune un mesaj temporar pana vine raspunsul
    _messageController.text = "Se gândește AI-ul..."; 

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
        setState(() {
          _messageController.text = data['suggestion'] ?? "";
        });
      } else {
        _messageController.clear();
        debugPrint("Eroare AI: ${response.statusCode}");
      }
    } catch (e) {
      _messageController.clear();
      debugPrint("Eroare retea AI: $e");
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.cyanAccent,
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
                // BUTONUL NOU PENTRU AI ✨
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                  onPressed: generateIcebreaker,
                ),
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