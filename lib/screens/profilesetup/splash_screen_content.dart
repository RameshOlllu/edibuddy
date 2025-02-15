import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../home/homepage.dart';

import '../../home/signin_page.dart';
import 'profile_setup_manager.dart';

class SplashContent extends StatelessWidget {
  final String image;
  final String title;
  final String tagline;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onButtonTap; // Callback for navigation

  const SplashContent({
    Key? key,
    required this.image,
    required this.title,
    required this.tagline,
    required this.subtitle,
    required this.buttonLabel,
    required this.onButtonTap,
  }) : super(key: key);

  Future<void> _handleNavigation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Navigate to SignInPage if not logged in
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: const SignInPage(),
        ),
      );
    } else {
      final isProfileComplete = await _checkProfileCompletion(user);

      if (isProfileComplete) {
        // Navigate to HomeScreen if profile is complete
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: const HomeScreen(),
          ),
        );
      } else {
        // Navigate to ProfileSetupManager if profile is not complete
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: ProfileSetupManager(
              userId: user.uid,
              onProfileComplete: () {
                Navigator.pushReplacement(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: const HomeScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<bool> _checkProfileCompletion(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data() ?? {};
      return data['profileComplete'] == true;
    } catch (e) {
      debugPrint("Error checking profile completion: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF58D8D), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensures vertical centering
            children: [
                 Padding(
              padding: const EdgeInsets.only(top: 1.0, bottom: 10.0),
              child: Image.asset(
                'assets/icons/edibuddylogo.png',  // Ensure this is correctly added to assets
                width: 300,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 50,),
              // Logo Section
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Image.asset(
                  image,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),

              // Title Section
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'MADE WITH',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 1.5,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 3,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: ' HEART',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                        letterSpacing: 1.5,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 3,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Tagline
              Text(
                tagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Get Started Button
              ElevatedButton(
                onPressed: () => _handleNavigation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
