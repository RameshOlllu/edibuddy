import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home/homepage.dart';
import 'home/signin_page.dart';
import 'screens/profilesetup/profile_setup_manager.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  Future<bool> _isProfileComplete(User? user) async {
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data() ?? {};
      return data['profileComplete'] == true;
    } catch (e) {
      debugPrint('Error fetching profile status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = snapshot.data;

  if (user != null) {
  print("User logged in: ${user.uid}");
  return FutureBuilder<bool>(
    future: _isProfileComplete(user),
    builder: (context, profileSnapshot) {
      if (profileSnapshot.connectionState == ConnectionState.waiting) {
        print("Checking profile completion...");
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (profileSnapshot.hasData && profileSnapshot.data == true) {
        print("Profile complete. Navigating to HomePage.");
        return const HomePage();
      }

      print("Profile incomplete. Navigating to ProfileSetupManager.");
      return ProfileSetupManager(userId: user.uid);
    },
  );
}

print("No user logged in. Navigating to SignInPage.");
return const SignInPage();

      },
    );
  }
}
