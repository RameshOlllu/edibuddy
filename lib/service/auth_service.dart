import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Getter for the current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Check sign-in methods for the user's email
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    return await _firebaseAuth.fetchSignInMethodsForEmail(email.trim());
  }

  // Link Email/Password with Google Sign-In
  Future<void> linkEmailPasswordWithGoogle(
      User user, String email, String password) async {
    final credential =
        EmailAuthProvider.credential(email: email, password: password);

    await user.linkWithCredential(credential);
  }

  // Change Password
  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return userCredential.user;
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User canceled the sign-in process

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    // Ensure user data exists in Firestore
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'profileComplete': false,
          'photoURL': user.photoURL ?? "",
          'basicDetails': {
            'fullName': user.displayName ?? 'N/A',
            'email': user.email ?? 'N/A',
            'dob': null,
            'gender': null,
          },
        });
      }
    }

    return user;
  }

  // Check if user profile is complete
Future<bool> isProfileComplete(String userId) async {
  try {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      debugPrint('User document does not exist for userId: $userId');
      return false;
    }

    // Safely access the `profileComplete` field with a default value
    final isProfileComplete = docSnapshot.data()?['profileComplete'] ?? false;

    debugPrint('Profile completion status for userId $userId: $isProfileComplete');
    return isProfileComplete;
  } catch (e) {
    debugPrint('Error fetching profile completion status for userId $userId: $e');
    return false; // Default to false if an error occurs
  }
}


  // Logout
  Future<void> logout(BuildContext context) async {
    try {
      await _firebaseAuth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
    } catch (e) {
      debugPrint(e.toString());
      throw Exception('Logout failed.');
    }
  }


  Future<void> reauthenticateUser(BuildContext context, User user) async {
  final signInMethods = await fetchSignInMethodsForEmail(user.email!);

  if (signInMethods.contains('google.com')) {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception("Google reauthentication canceled.");
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
  } else if (signInMethods.contains('password')) {
    // Prompt for password reauthentication
    String? password = await _promptForPassword(context);
    if (password == null || password.isEmpty) {
      throw Exception("Password reauthentication canceled.");
    }

    final credential =
        EmailAuthProvider.credential(email: user.email!, password: password);

    await user.reauthenticateWithCredential(credential);
  }
}

Future<String?> _promptForPassword(BuildContext context) async {
  final TextEditingController passwordController = TextEditingController();
  String? password;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Reauthenticate"),
      content: TextField(
        controller: passwordController,
        decoration: const InputDecoration(labelText: "Enter Password"),
        obscureText: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            password = passwordController.text;
            Navigator.pop(context);
          },
          child: const Text("Confirm"),
        ),
      ],
    ),
  );

  return password?.trim();
}

}
