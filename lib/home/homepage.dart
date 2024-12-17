// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key); 

  // Sign out method
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    // No need to navigate manually; AuthWrapper handles it
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Signout', // Optional: Add tooltip
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${user?.email}',
          style: textTheme.headlineMedium,
        ),
      ),
    );
  }
}
