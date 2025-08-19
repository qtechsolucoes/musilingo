import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/home/presentation/widgets/world_widget.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart';

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

  Future<Map<String, dynamic>> _fetchHomeData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'Utilizador não autenticado.';
      final modules = await _databaseService.getModulesAndLessons();
      final completedLessonIds =
          await _databaseService.getCompletedLessonIds(userId);
      final allLessons = modules.expand((module) => module.lessons).toList();
      return {
        'modules': modules,
        'completedLessonIds': completedLessonIds,
        'allLessons': allLessons,
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
        // AJUSTE REALIZADO AQUI
        // O título foi alterado de 'Trilha de Aprendizagem'
        // para 'Jornada Musical' para melhor visualização.
        title: const Text('Jornada Musical',
            style: TextStyle(fontWeight: FontWeight.bold)),
        // FIM DO AJUSTE
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

          int initialModuleIndex = 0;
          if (modules.isNotEmpty) {
            int lastCompletedLessonIndex = allLessons.lastIndexWhere(
                (lesson) => completedLessonIds.contains(lesson.id));

            if (lastCompletedLessonIndex != -1) {
              final lastCompletedLessonId =
                  allLessons[lastCompletedLessonIndex].id;
              for (int i = 0; i < modules.length; i++) {
                if (modules[i]
                    .lessons
                    .any((l) => l.id == lastCompletedLessonId)) {
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
            physics: const BouncingScrollPhysics(),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return WorldWidget(
                module: module,
                allLessons: allLessons,
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
