import 'package:edibuddy/home/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'splash_screen.dart';
import 'screens/profilesetup/resume_upload_screen.dart';
import 'utils/constants.dart';
import 'providers/flow_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      child: MaterialApp(
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
          '/': (context) => const SplashScreen(), // Default route
          '/resume-upload': (context) => const ResumeUploadScreen(userId: 'sampleUserId'),
          '/home': (context) => const HomePage(), // Update this to your actual dashboard widget
        },
        initialRoute: '/',
      ),
    );
  }
}
