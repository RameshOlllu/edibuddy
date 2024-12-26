import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edibuddy/home/email_verification_page.dart';
import 'package:edibuddy/home/homepage.dart';
import 'package:edibuddy/home/signin_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'home/signup_page.dart';
import 'screens/profilesetup/splash_screen_with_tabs.dart';
import 'utils/constants.dart';
import 'providers/flow_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set initial System UI Overlay Style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Transparent to use app bar color
    statusBarIconBrightness: Brightness.dark, // Default to light theme
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

// Future<void> fetchAndPrintFirstUserDocument() async {
//   try {
//     final QuerySnapshot<Map<String, dynamic>> querySnapshot =
//         await FirebaseFirestore.instance.collection('users').limit(1).get();

//     if (querySnapshot.docs.isNotEmpty) {
//       final Map<String, dynamic> firstDocData = querySnapshot.docs.first.data();
//       final jsonData = _convertFirestoreDataToJson(firstDocData);
//       debugPrint(jsonData, wrapWidth: 1024); // Prevent truncation
//     } else {
//       print("No documents found in the `users` collection.");
//     }
//   } catch (e) {
//     print("Error fetching first user document: $e");
//   }
// }

// dynamic _convertFirestoreDataToJson(Map<String, dynamic> data) {
//   return jsonEncode(data.map((key, value) {
//     if (value is Timestamp) {
//       return MapEntry(key, value.toDate().toIso8601String());
//     } else if (value is Map) {
//       return MapEntry(
//         key,
//         _convertFirestoreDataToJson(
//           value.map((nestedKey, nestedValue) => MapEntry(nestedKey.toString(), nestedValue)),
//         ),
//       );
//     } else if (value is List) {
//       return MapEntry(
//         key,
//         value.map((item) {
//           if (item is Map) {
//             return _convertFirestoreDataToJson(
//               item.map((nestedKey, nestedValue) => MapEntry(nestedKey.toString(), nestedValue)),
//             );
//           } else if (item is Timestamp) {
//             return item.toDate().toIso8601String();
//           } else {
//             return item;
//           }
//         }).toList(),
//       );
//     } else {
//       return MapEntry(key, value);
//     }
//   }));
// }

  @override
  Widget build(BuildContext context) {
    // fetchAndPrintFirstUserDocument();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FlowManager()),
      ],
      child: Builder(
        builder: (context) {
          // Adjust System UI Overlay Style dynamically based on theme
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // Keep it transparent
            statusBarIconBrightness:
                isDarkMode ? Brightness.light : Brightness.dark, // Icons adjust
            statusBarBrightness:
                isDarkMode ? Brightness.dark : Brightness.light, // iOS support
          ));

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EdiBuddy',
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: ColorSeed.baseColor.color,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: ColorSeed.baseColor.color,
              brightness: Brightness.dark,
            ),
            themeMode: ThemeMode.system,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
            ],
            // Define the routes table
            routes: {
              '/': (context) => SplashScreenWithTabs(), // Default route
              '/home': (context) =>
                  const HomeScreen(), // Update this to your actual dashboard widget
              '/signin': (context) => const SignInPage(),
              '/signup': (context) => const SignUpPage(),
              '/email-verification': (context) => const EmailVerificationPage(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}
