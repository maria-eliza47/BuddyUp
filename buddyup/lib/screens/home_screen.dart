import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'profile_screen.dart';
import 'matches_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final int userId;

  const HomeScreen({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> profiles = [];
  bool isLoading = true;
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    fetchPotentialMatches();
  }

  // FUNCTIA CARE INCARCA DATELE
  Future<void> fetchPotentialMatches() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final url = Uri.parse(
      'http://10.0.2.2:8000/swipes/api/utilizatori/?user_id=${widget.userId}',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          profiles = jsonDecode(response.body);
        });
      } else {
        debugPrint("Eroare Server: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Eroare la incarcare: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Eroare de conexiune la server!")),
        );
      }
    } finally {
      // ACEASTA SECTIUNE OPRESTE CERCUL DE INCARCARE INDIFERENT DE REZULTAT
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> _onSwipe(
      int previousIndex,
      int? currentIndex,
      CardSwiperDirection direction,
      ) async {
    if (previousIndex >= profiles.length) return false;

    final swipedProfile = profiles[previousIndex];
    final String swipeType = (direction == CardSwiperDirection.right) ? 'like' : 'dislike';
    final int swipedId = swipedProfile['id'];

    final url = Uri.parse(
      'http://10.0.2.2:8000/swipes/api/inregistreaza/$swipedId/$swipeType/?from_user=${widget.userId}',
    );

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_match'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("MATCH! Te-ai potrivit cu ${swipedProfile['username']}!"),
              backgroundColor: Colors.pinkAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "BuddyUp",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.message, color: Colors.cyanAccent),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchesScreen(userId: widget.userId),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.cyanAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  username: widget.username,
                  description: "",
                  userId: widget.userId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : profiles.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: controller,
              cardsCount: profiles.length,
              onSwipe: _onSwipe,
              numberOfCardsDisplayed: profiles.length > 3 ? 3 : profiles.length,
              cardBuilder: (context, index, h, v) => _buildProfileCard(profiles[index]),
            ),
          ),
          _buildActionButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileCard(dynamic profile) {
    String? imageUrl = profile['profile_picture'];

    if (imageUrl != null) {
      if (!imageUrl.startsWith('http')) {
        imageUrl = 'http://10.0.2.2:8000$imageUrl';
      }
      imageUrl = imageUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black26,
                    child: const Icon(Icons.person, size: 100, color: Colors.white10),
                  );
                },
              )
                  : const Icon(Icons.person, size: 100, color: Colors.white10),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${profile['username']}, ${profile['age'] ?? '?'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  profile['interests'] ?? "Fara interese",
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  profile['bio'] ?? "Hai sa fim buddies!",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.redAccent, size: 45),
          onPressed: () => controller.swipe(CardSwiperDirection.left),
        ),
        IconButton(
          icon: const Icon(Icons.favorite, color: Colors.greenAccent, size: 45),
          onPressed: () => controller.swipe(CardSwiperDirection.right),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Nu mai sunt utilizatori!",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withOpacity(0.2)),
            onPressed: fetchPotentialMatches,
            child: const Text("Reincarca", style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}