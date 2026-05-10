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
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {

  List<dynamic> profiles = [];

  bool isLoading = true;

  final CardSwiperController controller =
  CardSwiperController();

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

          profiles =
              jsonDecode(response.body);
        });
      } else {
        debugPrint("Eroare Server: ${response.statusCode}");
      }

    } catch (e) {

      debugPrint(
        "Eroare la incarcare: $e",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Eroare de conexiune la server!")),
        );
      }
    } finally {

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

    if (previousIndex >= profiles.length) {

      return false;
    }

    final swipedProfile =
    profiles[previousIndex];

    final String swipeType =

    (direction ==
        CardSwiperDirection.right)

        ? 'like'
        : 'dislike';

    final int swipedId =
    swipedProfile['id'];

    final url = Uri.parse(
      'http://10.0.2.2:8000/swipes/api/inregistreaza/$swipedId/$swipeType/?from_user=${widget.userId}',
    );

    try {

      final response =
      await http.post(url);

      if (response.statusCode == 200) {

        final data =
        jsonDecode(response.body);

        if (data['is_match'] == true) {

          ScaffoldMessenger.of(context)
              .showSnackBar(

            SnackBar(

              content: Text(

                "MATCH! Te-ai potrivit cu ${swipedProfile['username']}!",
              ),

              backgroundColor:
              Colors.pinkAccent,

              behavior:
              SnackBarBehavior.floating,
            ),
          );
        }
      }

      return true;

    } catch (e) {

      return false;
    }
  }
  // Funcția care deschide sertarul cu recomandările AI
  void _showAIPicks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return FutureBuilder(
          // Apelăm endpoint-ul nou creat în Django
          future: http.get(Uri.parse('http://10.0.2.2:8000/swipes/api/ai-picks/?user_id=${widget.userId}')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200, 
                child: Center(child: CircularProgressIndicator(color: Colors.amberAccent))
              );
            }
            if (!snapshot.hasData || snapshot.hasError) {
              return const SizedBox(
                height: 200, 
                child: Center(child: Text("Eroare la conectarea cu AI-ul.", style: TextStyle(color: Colors.white)))
              );
            }

            final List picks = jsonDecode((snapshot.data as http.Response).body);
            if (picks.isEmpty) {
              return const SizedBox(
                height: 200, 
                child: Center(child: Text("AI-ul nu a găsit nicio recomandare azi.", style: TextStyle(color: Colors.white)))
              );
            }

            final pick = picks[0]; // Luăm prima recomandare

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 28),
                      SizedBox(width: 10),
                      Text("Top Pick by AI", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.amberAccent, 
                      child: Icon(Icons.person, color: Color(0xFF0F172A))
                    ),
                    title: Text("${pick['username']}, ${pick['age']}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(pick['interests'] ?? "", style: const TextStyle(color: Colors.cyanAccent)),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), 
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      pick['ai_reason'], 
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 15, height: 1.4, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAIPicks,
        backgroundColor: Colors.amberAccent,
        icon: const Icon(Icons.auto_awesome, color: Color(0xFF0F172A)),
        label: const Text("AI Picks", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(

        title: const Text(
          "BuddyUp",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        centerTitle: true,

        leading: IconButton(

          icon: const Icon(

            Icons.message,
            color: Colors.cyanAccent,
          ),

          onPressed: () => Navigator.push(

            context,

            MaterialPageRoute(

              
              builder: (context) =>
                  MatchesScreen(
                    userId: widget.userId,
                  ),
            ),
          ),
        ),

        actions: [

          IconButton(

            icon: const Icon(

              Icons.person,
              color: Colors.cyanAccent,
            ),

            onPressed: () => Navigator.push(

              context,

              MaterialPageRoute(

                builder: (context) =>
                    ProfileScreen(

                      username:
                      widget.username,

                      description: "",

                      userId: widget.userId,
                    ),
              ),
            ),
          ),
        ],
      ),

      body: isLoading

          ? const Center(

        child:
        CircularProgressIndicator(

          color: Colors.cyanAccent,
        ),
      )

          : profiles.isEmpty

          ? _buildEmptyState()

          : Column(

        children: [

          Expanded(

            child: CardSwiper(

              controller:
              controller,

              cardsCount:
              profiles.length,

              onSwipe: _onSwipe,

              numberOfCardsDisplayed:

              profiles.length > 3

                  ? 3
                  : profiles.length,

              cardBuilder:

                  (
                  context,
                  index,
                  h,
                  v,
                  ) =>

                  _buildProfileCard(
                    profiles[index],
                  ),
            ),
          ),

          _buildActionButtons(),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      dynamic profile) {

    String? imageUrl =
    profile['profile_picture'];

    if (

    imageUrl != null &&
        imageUrl.contains('127.0.0.1')

    ) {

      imageUrl = imageUrl.replaceAll(
        '127.0.0.1',
        '10.0.2.2',
      );
    }

    return Container(

      decoration: BoxDecoration(

        color: const Color(0xFF1E293B),

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Stack(

        children: [

          Positioned.fill(

            child:

            imageUrl != null

                ? Image.network(

              imageUrl,

              fit: BoxFit.cover,
            )

                : const Icon(

              Icons.person,

              size: 100,

              color: Colors.white24,
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

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                Text(

                  profile['interests'] ?? "",

                  style: const TextStyle(

                    color: Colors.cyanAccent,

                    fontSize: 16,
                  ),
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

      mainAxisAlignment:
      MainAxisAlignment.spaceEvenly,

      children: [

        IconButton(

          icon: const Icon(

            Icons.close,

            color: Colors.redAccent,

            size: 40,
          ),

          onPressed: () =>

              controller.swipe(
                CardSwiperDirection.left,
              ),
        ),

        IconButton(

          icon: const Icon(

            Icons.favorite,

            color: Colors.greenAccent,

            size: 40,
          ),

          onPressed: () =>

              controller.swipe(
                CardSwiperDirection.right,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {

    return Center(

      child: Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          const Text(

            
            "Nu mai sunt utilizatori!",

           
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withOpacity(0.2)),
            

            onPressed:
            fetchPotentialMatches,

           
            child: const Text(
              "Reincarca",
              style: TextStyle(
                color: Colors.cyanAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}