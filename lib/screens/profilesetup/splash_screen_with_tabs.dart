import 'package:edibuddy/screens/home/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../home/email_verification_page.dart';
import '../../home/employer/employer_home_screen.dart';
import '../../home/homepage.dart';
import '../../home/signin_page.dart';
import '../home/employer_profile_screen.dart';
import '../home/quick_actions.dart';
import 'profile_setup_manager.dart';
import 'splash_screen_content.dart';

class SplashScreenWithTabs extends StatefulWidget {
  final int initialTabIndex;

  const SplashScreenWithTabs({Key? key, this.initialTabIndex = 0})
      : super(key: key);

  @override
  _SplashScreenWithTabsState createState() => _SplashScreenWithTabsState();
}

class _SplashScreenWithTabsState extends State<SplashScreenWithTabs> {
  late int _currentIndex;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isProfileComplete = false;
  String? userId;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialTabIndex; // Initialize to the provided tab index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

 Future<void> _checkAuthStatus() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      debugPrint('User is logged in.');

      if (!user.emailVerified) {
        debugPrint(
            'User email not verified. Navigating to Email Verification Page.');
        setState(() {
          _isLoggedIn = true;
          _isProfileComplete = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data() ?? {};
      final userType = data['userType'] ?? 'employee';

      final isProfileComplete = data['profileComplete'] == true;

      setState(() {
        _isLoggedIn = true;
        _isProfileComplete = isProfileComplete;
        userId = user.uid;
        _initializePages(userType); // Pass userType to initializePages
      });
    } else {
      debugPrint('No user logged in. Showing default Splash Content.');
      setState(() {
        _isLoggedIn = false;
        _isProfileComplete = false;
        _initializePages(null); // No user type
      });
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
void _initializePages(String? userType) {
  Widget homePage;

  if (userType == 'employer') {
    homePage = const EmployerHomeScreen(); // Navigate to Employer Home Screen
  } else {
    homePage = const HomeScreen(); // Default to Employee Home Screen
  }

  _pages = [
    (_isLoggedIn && _isProfileComplete)
        ? homePage
        : SplashContent(
            image: 'assets/images/rec.png',
            title: 'MADE WITH HEART',
            subtitle: 'Simplifying recruitment smartly',
            tagline: 'TO MAKE YOU A STAR',
            buttonLabel: 'Get Started',
            onButtonTap: _handleGetStarted,
          ),
    if (_isLoggedIn)
      (_isProfileComplete
          ? homePage
          : ProfileSetupManager(
              userId: FirebaseAuth.instance.currentUser!.uid,
              onProfileComplete: _onProfileComplete,
            )),
    if (_isLoggedIn)
      QuickActionsTab()
    else
      const Center(
        child: Text(
          'Please log in to access your profile.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    if (_isLoggedIn)
     (userType == 'employee')? ProfileScreen(userId: userId ?? ''):EmployerProfileScreen()
    
    else
      const Center(
        child: Text(
          'Please log in to access your profile.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
  ];
}

void _handleGetStarted() {
  if (!_isLoggedIn) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  } else if (!_isProfileComplete) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProfileSetupManager(
          userId: FirebaseAuth.instance.currentUser!.uid,
          onProfileComplete: _onProfileComplete,
        ),
      ),
    );
  } else {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _pages[0], // Use the initialized home page
      ),
    );
  }
}


void _onProfileComplete() {
  setState(() {
    _isProfileComplete = true;
    // Reinitialize pages with the stored userType from _checkAuthStatus
    _initializePages(userId != null ? _pages[0] is EmployerHomeScreen ? 'employer' : 'employee' : null);
    _currentIndex = 0; // Reset to the first tab
  });
}


  void _onTabTapped(int index) {
    if (!_isLoggedIn) {
      // Navigate to SignInPage if user is not logged in and tries to access Profile tab
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
      return;
    }

    // Ensure index is within bounds of _pages
    if (index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
    } else {
      debugPrint('Invalid tab index: $index');
    }
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
