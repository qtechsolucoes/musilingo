// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart'; // Importa a SplashScreen
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yjjzeruqvlkyegwbwdfi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqanplcnVxdmxreWVnd2J3ZGZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2NTY2NzYsImV4cCI6MjA3MDIzMjY3Nn0.S3VImD-B8CBJ18OSiQ6EKzQkoy_pWzeOs3rBUoFITiQ',
  );

  runApp(const MusilingoApp());
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
      // A tela inicial agora é sempre a SplashScreen
      home: const SplashScreen(),
    );
  }
}
