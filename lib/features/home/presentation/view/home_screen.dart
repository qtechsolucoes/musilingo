// lib/features/home/presentation/view/home_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/data/models/module_model.dart'; // Import do ModuleModel
import 'package:musilingo/app/presentation/view/splash_screen.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/home/presentation/widgets/world_widget.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart';

// A classe 'World' foi removida, pois não é mais necessária.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<Map<String, dynamic>> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
  }

  // --- LÓGICA DE BUSCA DE DADOS SIMPLIFICADA E CORRIGIDA ---
  Future<Map<String, dynamic>> _fetchHomeData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'Utilizador não autenticado.';

      // A busca já nos traz os módulos com suas respectivas lições aninhadas.
      final modules = await _databaseService.getModulesAndLessons();
      final completedLessonIds =
          await _databaseService.getCompletedLessonIds(userId);

      // Criamos uma lista plana de todas as lições para a lógica de desbloqueio.
      final allLessons = modules.expand((module) => module.lessons).toList();

      return {
        'modules': modules, // Passamos a lista de módulos diretamente
        'completedLessonIds': completedLessonIds,
        'allLessons': allLessons, // Passamos a lista completa para referência
      };
    } catch (error, stackTrace) {
      debugPrint("Erro detalhado ao buscar dados: $error");
      debugPrint("Stack Trace: $stackTrace");
      rethrow;
    }
  }

  void _refreshData() {
    setState(() {
      _homeDataFuture = _fetchHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSession = context.watch<UserSession>();
    final user = userSession.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Trilha de Aprendizagem',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Row(children: [
            const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
            const SizedBox(width: 4),
            Text(user?.currentStreak.toString() ?? '0',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
          ]),
          Row(children: [
            const Icon(Icons.favorite, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(user?.lives.toString() ?? '0',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
          ]),
          Row(children: [
            const Icon(Icons.music_note, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(user?.points.toString() ?? '0',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
          ]),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await supabase.auth.signOut();
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
                color: AppColors.background,
                child: const Center(
                    child: CircularProgressIndicator(color: AppColors.accent)));
          }

          if (snapshot.hasError) {
            return Container(
                color: AppColors.background,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Não foi possível carregar o conteúdo.\n\nErro: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Container(
                color: AppColors.background,
                child:
                    const Center(child: Text('Nenhum conteúdo encontrado.')));
          }

          final data = snapshot.data!;
          final modules = data['modules'] as List<Module>;
          final completedLessonIds = data['completedLessonIds'] as Set<int>;
          final allLessons = data['allLessons'] as List<Lesson>;

          // Lógica para encontrar o módulo inicial a ser exibido
          int initialModuleIndex = 0;
          if (modules.isNotEmpty) {
            int lastCompletedLessonIndex = allLessons.lastIndexWhere(
                (lesson) => completedLessonIds.contains(lesson.id));

            if (lastCompletedLessonIndex != -1) {
              final lastCompletedLessonId =
                  allLessons[lastCompletedLessonIndex].id;
              // Encontra o próximo módulo a ser exibido
              for (int i = 0; i < modules.length; i++) {
                if (modules[i]
                    .lessons
                    .any((l) => l.id == lastCompletedLessonId)) {
                  // Se a lição completada for a última do módulo, avança para o próximo.
                  if (modules[i].lessons.last.id == lastCompletedLessonId &&
                      i + 1 < modules.length) {
                    initialModuleIndex = i + 1;
                  } else {
                    initialModuleIndex = i;
                  }
                  break;
                }
              }
            }
          }

          final pageController =
              PageController(initialPage: initialModuleIndex);

          return PageView.builder(
            controller: pageController,
            physics:
                const BouncingScrollPhysics(), // Melhoramos a física do PageView
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return WorldWidget(
                module: module, // Passamos o objeto Module
                allLessons: allLessons, // Passamos a lista completa de lições
                completedLessonIds: completedLessonIds,
                isFirstModule: index == 0,
                isLastModule: index == modules.length - 1,
                pageController: pageController,
                onLessonCompleted: _refreshData,
              );
            },
          );
        },
      ),
    );
  }
}
