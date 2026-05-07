import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:midnight_pulse/auth/login_page.dart';
import 'package:midnight_pulse/screens/main_screen.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _onGetStarted(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background: Full-screen GIF
          SizedBox.expand(
            child: Image.asset(
              'assets/disco_ball.gif',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.background,
                  child: Center(
                    child: Icon(
                      Icons.nightlife_rounded,
                      size: 120,
                      color: AppColors.accent,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Dark overlay for better text visibility
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          
          // Foreground content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top spacer (empty space)
                const SizedBox(height: 20),
                
                // Center: App title
                Expanded(
                  child: Center(
                    child: Text(
                      'MIDNIGHT PULSE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                
                // Bottom: Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _onGetStarted(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4), // Cyan/Teal
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF00BCD4).withOpacity(0.5),
                      ),
                      child: const Text(
                        'GET STARTED',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
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
}
