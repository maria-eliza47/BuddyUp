import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'profile_screen.dart';
import 'matches_screen.dart';

const Color kBg    = Color(0xFFFF6B9D);   // coral pink — fundal
const Color kDeep  = Color(0xFFBD1E5E);   // roz închis — butoane
const Color kCard  = Color(0xFFFFFFFF);   // alb
const Color kBlush = Color(0xFFFFF0F5);   // blush
const Color kDark  = Color(0xFF2D0A1A);   // text închis

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
  final Map<int, int> currentImageIndex = {};
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
      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
            'Location services disabled — skipping permission request');
        return;
      }
      LocationPermission permission =
      await Geolocator.checkPermission();
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
      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      final LocationPermission permission =
      await Geolocator.checkPermission();
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
        Uri.parse(
            'http://10.0.2.2:8000/swipes/api/update-location/'),
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
          for (int i = 0; i < profiles.length; i++) {
            currentImageIndex[i] = 0;
          }
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
                  const Icon(Icons.favorite, color: kCard),
                  const SizedBox(width: 10),
                  Text('MATCH cu ${swipedProfile['username']}!',
                      style: const TextStyle(color: kCard)),
                ],
              ),
              backgroundColor: kDeep,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
      return true;
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
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        style: TextStyle(color: kDark))),
              );
            }
            final response = snapshot.data as http.Response;
            final decodedData = jsonDecode(response.body);
            if (decodedData is Map) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Eroare Server: ${decodedData['error']}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            }
            final List picks = decodedData;
            if (picks.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                    child: Text(
                        'AI-ul nu a găsit nicio recomandare azi.',
                        style: TextStyle(color: kDark))),
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
                              color: kDark,
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
                      child: Icon(Icons.person,
                          color: Color(0xFF2D0A1A)),
                    ),
                    title: Text(
                      '${pick['username']}, ${pick['age']}',
                      style: const TextStyle(
                          color: kDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(pick['interests'] ?? '',
                        style: const TextStyle(color: kDeep)),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: kBlush,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.amberAccent
                              .withValues(alpha: 0.5)),
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
      backgroundColor: kBg,
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerTop,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAIPicks,
        backgroundColor: Colors.amberAccent,
        icon: const Icon(Icons.auto_awesome,
            color: Color(0xFF2D0A1A)),
        label: const Text('AI Picks',
            style: TextStyle(
                color: Color(0xFF2D0A1A),
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
            color: kCard,
            shadows: [
              Shadow(
                  color: Color(0x44BD1E5E),
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.message_rounded, color: kCard),
          tooltip: 'Matches',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MatchesScreen(userId: widget.userId),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded, color: kCard),
            tooltip: 'Profilul meu',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  username: widget.username,
                  description: '',
                  userId: widget.userId,
                  otherUserId: widget.userId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: kCard))
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
                  if (mounted)
                    setState(() => profiles = []);
                },
                numberOfCardsDisplayed:
                profiles.length > 3
                    ? 3
                    : profiles.length,
                backCardOffset: const Offset(0, 20),
                padding: EdgeInsets.zero,
                cardBuilder: (context, index, h, v) =>
                    _buildProfileCard(
                        profiles[index], index),
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
  // CARD PROFIL (COMBINAT DESIGN + GALERIE)
  // ──────────────────────────────────────────

  Widget _buildProfileCard(dynamic profile, int cardIndex) {
    String? imageUrl = profile['profile_picture'];
    if (imageUrl != null && imageUrl.contains('127.0.0.1')) {
      imageUrl = imageUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }

    List<String> allImages = [];
    if (imageUrl != null) allImages.add(imageUrl);
    if (profile['gallery_images'] != null) {
      for (var img in profile['gallery_images']) {
        allImages
            .add(img.toString().replaceAll('127.0.0.1', '10.0.2.2'));
      }
    }
    if (allImages.isEmpty) allImages.add('');

    final selectedImage = currentImageIndex[cardIndex] ?? 0;

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
                child: GestureDetector(
                  onTapDown: (details) {

                    final width =
                        MediaQuery.of(context).size.width;

                    if (details.localPosition.dx >
                        width / 2) {

                      if (selectedImage <
                          allImages.length - 1) {

                        setState(() {

                          currentImageIndex[cardIndex] =
                              selectedImage + 1;
                        });
                      }

                    } else {

                      if (selectedImage > 0) {

                        setState(() {

                          currentImageIndex[cardIndex] =
                              selectedImage - 1;
                        });
                      }
                    }
                  },

                  child: allImages[selectedImage].isNotEmpty

                      ? Image.network(
                    allImages[selectedImage],
                    fit: BoxFit.cover,
                  )

                      : _buildPlaceholder(),
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    "${profile['username']}, ${profile['age']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    profile['interests'] ?? "",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: List.generate(
                      allImages.length,
                          (index) => Container(
                        margin:
                        const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),

                        width: 8,
                        height: 8,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          color: index == selectedImage
                              ? Colors.cyanAccent
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFB3CF), Color(0xFFFF6B9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded,
            size: 100, color: Colors.white54),
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
            bgColor: kCard,
            iconColor: Colors.redAccent,
            onTap: () =>
                controller.swipe(CardSwiperDirection.left),
          ),
          _swipeButton(
            icon: Icons.favorite_rounded,
            bgColor: kCard,
            iconColor: kDeep,
            onTap: () =>
                controller.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _swipeButton({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 32),
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
          Icon(Icons.people_outline,
              size: 72, color: kCard.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          const Text(
            'Nu mai sunt utilizatori!',
            style: TextStyle(
                color: kCard,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kCard,
              foregroundColor: kDeep,
              elevation: 4,
              shadowColor: kDeep.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reîncarcă',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: fetchPotentialMatches,
          ),
        ],
      ),
    );
  }
}
