import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:geolocator/geolocator.dart';
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
    _updateLocationThenFetch();
  }

  // ──────────────────────────────────────────
  // GPS — timeout de 5s ca sa nu blocheze loading-ul
  // ──────────────────────────────────────────

  Future<void> _updateLocationThenFetch() async {
    await _requestPermission();
    await _fetchAndSendLocation().timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
    fetchPotentialMatches();
  }

  Future<void> _requestPermission() async {
    try {
      // Verifica daca serviciile de locatie sunt activate la nivel de sistem
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled — skipping permission request');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Initial location permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('After request, permission: $permission');
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  Future<void> _fetchAndSendLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      debugPrint('Got position: ${pos.latitude}, ${pos.longitude}');

      await http.post(
        Uri.parse('http://10.0.2.2:8000/swipes/api/update-location/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        }),
      );
    } catch (e) {
      debugPrint('Location fetch/send failed: $e');
    }
  }

  // ──────────────────────────────────────────
  // INCARCARE PROFILURI
  // ──────────────────────────────────────────

  Future<void> fetchPotentialMatches() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final url = Uri.parse(
      'http://10.0.2.2:8000/swipes/api/utilizatori/?user_id=${widget.userId}',
    );

    try {
      final response =
      await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          profiles = jsonDecode(response.body);
        });
      } else {
        debugPrint('Eroare Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Eroare la incarcare: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eroare de conexiune la server!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ──────────────────────────────────────────
  // SWIPE
  // ──────────────────────────────────────────

  Future<bool> _onSwipe(
      int previousIndex,
      int? currentIndex,
      CardSwiperDirection direction,
      ) async {
    if (previousIndex >= profiles.length) return true;

    final swipedProfile = profiles[previousIndex];
    final String swipeType =
    (direction == CardSwiperDirection.right) ? 'like' : 'dislike';
    final int swipedId = swipedProfile['id'];

    final url = Uri.parse(
      'http://10.0.2.2:8000/swipes/api/inregistreaza/$swipedId/$swipeType/?from_user=${widget.userId}',
    );

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_match'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('MATCH cu ${swipedProfile['username']}!'),
                ],
              ),
              backgroundColor: Colors.pinkAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Swipe API error: $e');
    }
    return true;
  }

  // ──────────────────────────────────────────
  // AI PICKS
  // ──────────────────────────────────────────

  void _showAIPicks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return FutureBuilder(
          future: http.get(Uri.parse(
              'http://10.0.2.2:8000/swipes/api/ai-picks/?user_id=${widget.userId}')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                    child: CircularProgressIndicator(
                        color: Colors.amberAccent)),
              );
            }
            if (!snapshot.hasData || snapshot.hasError) {
              return const SizedBox(
                height: 200,
                child: Center(
                    child: Text('Eroare la conectarea cu AI-ul.',
                        style: TextStyle(color: Colors.white))),
              );
            }
            final List picks =
            jsonDecode((snapshot.data as http.Response).body);
            if (picks.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                    child: Text('AI-ul nu a găsit nicio recomandare azi.',
                        style: TextStyle(color: Colors.white))),
              );
            }
            final pick = picks[0];
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Colors.amberAccent, size: 28),
                      SizedBox(width: 10),
                      Text('Top Pick by AI',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.amberAccent,
                      child:
                      Icon(Icons.person, color: Color(0xFF0F172A)),
                    ),
                    title: Text(
                      '${pick['username']}, ${pick['age']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(pick['interests'] ?? '',
                        style:
                        const TextStyle(color: Colors.cyanAccent)),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color:
                          Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      pick['ai_reason'],
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 15,
                          height: 1.5,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // BUILD PRINCIPAL
  // ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAIPicks,
        backgroundColor: Colors.amberAccent,
        icon: const Icon(Icons.auto_awesome, color: Color(0xFF0F172A)),
        label: const Text('AI Picks',
            style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'BuddyUp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.cyanAccent,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.message_rounded, color: Colors.cyanAccent),
          tooltip: 'Matches',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchesScreen(userId: widget.userId),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded, color: Colors.cyanAccent),
            tooltip: 'Profilul meu',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  username: widget.username,
                  description: '',
                  userId: widget.userId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent))
          : profiles.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: CardSwiper(
                controller: controller,
                cardsCount: profiles.length,
                onSwipe: _onSwipe,
                onEnd: () {
                  if (mounted) setState(() => profiles = []);
                },
                numberOfCardsDisplayed:
                profiles.length > 3 ? 3 : profiles.length,
                backCardOffset: const Offset(0, 20),
                padding: EdgeInsets.zero,
                cardBuilder: (context, index, h, v) =>
                    _buildProfileCard(profiles[index]),
              ),
            ),
          ),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // CARD PROFIL
  // ──────────────────────────────────────────

  Widget _buildProfileCard(dynamic profile) {
    String? imageUrl = profile['profile_picture'];
    if (imageUrl != null && imageUrl.contains('127.0.0.1')) {
      imageUrl = imageUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }

    final double? distanceKm = profile['distance_km'] != null
        ? (profile['distance_km'] as num).toDouble()
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Poza de fundal
          imageUrl != null
              ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          )
              : _buildPlaceholder(),

          // Gradient la baza cardului
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  stops: const [0.40, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Badge distanta — dreapta sus
          if (distanceKm != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.cyanAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$distanceKm km',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Info utilizator — jos
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile['username']}, ${profile['age']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                  ),
                ),
                if ((profile['interests'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.interests,
                          color: Colors.cyanAccent, size: 15),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          profile['interests'],
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if ((profile['bio'] ?? '').toString().isNotEmpty &&
                    profile['bio'] != "Hey! Let's be buddies.") ...[
                  const SizedBox(height: 4),
                  Text(
                    profile['bio'],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 100, color: Colors.white24),
      ),
    );
  }

  // ──────────────────────────────────────────
  // BUTOANE SWIPE
  // ──────────────────────────────────────────

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _swipeButton(
            icon: Icons.close_rounded,
            color: Colors.redAccent,
            onTap: () => controller.swipe(CardSwiperDirection.left),
          ),
          _swipeButton(
            icon: Icons.favorite_rounded,
            color: Colors.greenAccent,
            onTap: () => controller.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _swipeButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }

  // ──────────────────────────────────────────
  // STARE GOALA
  // ──────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline,
              size: 72, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Nu mai sunt utilizatori!',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent, width: 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reîncarcă'),
            onPressed: fetchPotentialMatches,
          ),
        ],
      ),
    );
  }
}
