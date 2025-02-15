import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'splash_screen_with_tabs.dart';

class CongratulationsPage extends StatelessWidget {
  final int stars;
  final int hearts;

  const CongratulationsPage({
    Key? key,
    required this.stars,
    required this.hearts,
  }) : super(key: key);

  Widget _buildRatingSection(
      String title, int count, IconData icon, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (index) => Icon(
              icon,
              size: 36,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "$count Achieved",
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/congratulations.json',
                  repeat: true,
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.4,
                ),

                Text(
                  "Congratulations!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildRatingSection("Stars", stars, Icons.star, Colors.yellow),
                const SizedBox(height: 32),
                _buildRatingSection(
                    "Hearts", hearts, Icons.favorite, Colors.red),
                const SizedBox(height: 32),
                ElevatedButton(
                   onPressed: () => _navigateToHome(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Let's Explore",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
 void _navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreenWithTabs(initialTabIndex: 0), // Navigate to the first tab
      ),
      (route) => false,
      );
 }
}
