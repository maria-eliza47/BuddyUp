import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

const Color kBg     = Color(0xFFFF6B9D);   // coral pink — fundal principal
const Color kDeep   = Color(0xFFBD1E5E);   // roz închis — butoane primare
const Color kCard   = Color(0xFFFFFFFF);   // alb — carduri / suprafețe
const Color kBlush  = Color(0xFFFFF0F5);   // blush — inputuri
const Color kDark   = Color(0xFF2D0A1A);   // text închis pe alb

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB), Color(0xFFFFB3CF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: kDeep.withValues(alpha: 0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    size: 80,
                    color: kBg,
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'BuddyUp',
                  style: TextStyle(
                    color: kCard,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Color(0x55BD1E5E),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Find friends and build real connections.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFE0EE),
                    fontSize: 17,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                // Login button — alb cu text roz
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCard,
                      foregroundColor: kDeep,
                      elevation: 6,
                      shadowColor: kDeep.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Register button — outline alb
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kCard,
                      side: const BorderSide(color: kCard, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
