
import 'package:edibuddy/home/email_verification_page.dart';
import 'package:edibuddy/home/homepage.dart';
import 'package:edibuddy/home/signin_page.dart';
import 'package:edibuddy/home/signup_page.dart';
import 'package:edibuddy/screens/profilesetup/splash_screen_with_tabs.dart';
import 'package:edibuddy/utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/flow_manager.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  @override
  Widget build(BuildContext context) {
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
            navigatorKey: navigatorKey, // Use the global navigator key
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
                  const HomeScreen(), // Dashboard widget
              '/signin': (context) => const SignInPage(),
              '/signup': (context) => const SignUpPage(),
              '/email-verification': (context) =>
                  const EmailVerificationPage(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}
