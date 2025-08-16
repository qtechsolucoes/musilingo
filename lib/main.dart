// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importe o pacote
import 'package:google_fonts/google_fonts.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart';
import 'package:musilingo/app/services/sfx_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variáveis de ambiente do ficheiro .env
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    // Usa as variáveis carregadas de forma segura
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Carrega os efeitos sonoros na inicialização
  await SfxService.instance.loadSounds();

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
