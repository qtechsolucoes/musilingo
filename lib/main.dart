// lib/main.dart

import 'package:flutter/material.dart'; // CORREÇÃO: 'package:flutter/material.dart'
import 'package:google_fonts/google_fonts.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://onsscmecztzhybfdjewo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9uc3NjbWVjenR6aHliZmRqZXdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5OTExNDgsImV4cCI6MjA3MDU2NzE0OH0.hlcHLlgPGHSHevdllh6AVOkEe-GOphLEDhY-FY5H9Q8',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserSession(),
      child: const MusilingoApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MusilingoApp extends StatelessWidget {
  const MusilingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musilingo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: AppColors.text,
                displayColor: AppColors.text,
              ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
