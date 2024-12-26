import 'package:edibuddy/screens/home/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../home/email_verification_page.dart';
import '../../home/homepage.dart';
import '../../home/signin_page.dart';
import '../home/quick_actions.dart';
import 'profile_setup_manager.dart';
import 'splash_screen_content.dart';

class SplashScreenWithTabs extends StatefulWidget {
  @override
  _SplashScreenWithTabsState createState() => _SplashScreenWithTabsState();
}

class _SplashScreenWithTabsState extends State<SplashScreenWithTabs> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isProfileComplete = false;
  bool _hasNavigated = false; // To prevent multiple navigations
  String? userId;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus(); // Ensures the navigation happens after the first frame
    });
  }

Future<void> _checkAuthStatus() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      debugPrint('User is logged in.');

      if (!user.emailVerified) {
        debugPrint('User email not verified. Navigating to Email Verification Page.');
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
            (route) => false,
          );
        }
        return;
      }

      final isProfileComplete = await _checkProfileCompletion(user);

      if (!isProfileComplete) {
        debugPrint('User profile incomplete. Navigating to Profile Setup Page.');
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => ProfileSetupManager(
                userId: user.uid,
                onProfileComplete: _navigateToHome,
              ),
            ),
            (route) => false,
          );
        }
        return;
      }

      // If the user is logged in, verified, and profile is complete
      setState(() {
        _isLoggedIn = true;
        _isProfileComplete = isProfileComplete;
        userId = user.uid;
        _initializePages();
      });
    } else {
      debugPrint('No user logged in. Navigating to Sign In Page.');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInPage()),
          (route) => false,
        );
      }
    }
  } catch (e) {
    debugPrint('Error checking auth status: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


void _navigateToHome() {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) =>  SplashScreenWithTabs()),
  );
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
      debugPrint('Error fetching profile completion status: $e');
      return false;
    }
  }

 void _initializePages() {
  debugPrint(
      "SplashScreen _initializePages: _isLoggedIn $_isLoggedIn _isProfileComplete $_isProfileComplete");
  _pages = [
    // Jobs Tab
    if (_isLoggedIn)
      (_isProfileComplete
          ? const HomeScreen() // Home Screen for logged-in users
          : ProfileSetupManager(
              userId: FirebaseAuth.instance.currentUser!.uid,
              onProfileComplete: _onProfileComplete,
            )),
    if (!_isLoggedIn)
      SplashContent(
        image: 'assets/images/rec.png',
        title: 'MADE WITH HEART',
        subtitle: 'Simplifying recruitment smartly',
        tagline: 'TO MAKE YOU A STAR',
        buttonLabel: 'Get Started',
        onButtonTap: _handleGetStarted,
      ),
    // Saved Jobs Tab
    const Center(
      child: Text(
        'Saved Jobs',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    // Quick Actions Tab
    const QuickActionsTab(),
    // Profile Tab
    if (userId != null) ProfileScreen(userId: userId!),
  ];
}

  void _handleGetStarted() {
    if (!_isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
    } else if (!_isProfileComplete) {
      setState(() {
        _currentIndex = 0;
        _pages[0] = ProfileSetupManager(
          userId: FirebaseAuth.instance.currentUser!.uid,
          onProfileComplete: _onProfileComplete,
        );
      });
    } else {
      setState(() {
        _currentIndex = 0;
        _pages[0] = const HomeScreen();
      });
    }
  }

  void _onProfileComplete() {
    setState(() {
      _isProfileComplete = true;
      _initializePages();
      _currentIndex = 0;
    });
  }

  void _onTabTapped(int index) {
    if (!_isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Ensure pages are initialized before rendering
    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Quick Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
