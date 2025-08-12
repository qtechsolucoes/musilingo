// lib/features/home/presentation/view/home_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/features/home/presentation/widgets/lesson_node_widget.dart';
import 'package:musilingo/features/lesson/presentation/view/lesson_screen.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart';

class World {
  final int index;
  final List<Lesson> lessons;
  World({required this.index, required this.lessons});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<Map<String, dynamic>> _homeDataFuture;

  int lastCompletedIndex = -1;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'Usuário não autenticado.';

      final modules = await _databaseService.getModulesAndLessons();
      final completedLessonIds =
          await _databaseService.getCompletedLessonIds(userId);

      final allLessons = modules.expand((module) => module.lessons).toList();
      final List<World> worlds = [];
      const int lessonsPerWorld = 10;

      for (int i = 0; i < allLessons.length; i += lessonsPerWorld) {
        final end = (i + lessonsPerWorld > allLessons.length)
            ? allLessons.length
            : i + lessonsPerWorld;
        worlds.add(World(
          index: worlds.length,
          lessons: allLessons.sublist(i, end),
        ));
      }
      return {
        'worlds': worlds,
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
        title: const Text('Trilha de Aprendizagem',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
          final worlds = data['worlds'] as List<World>;
          final completedLessonIds = data['completedLessonIds'] as Set<int>;
          final allLessons = data['allLessons'] as List<Lesson>;

          int initialWorldIndex = 0;
          if (worlds.isNotEmpty) {
            int lastCompletedLessonIndex = allLessons.lastIndexWhere(
                (lesson) => completedLessonIds.contains(lesson.id));
            if (lastCompletedLessonIndex != -1) {
              const int lessonsPerWorld = 10;
              initialWorldIndex = lastCompletedLessonIndex ~/ lessonsPerWorld;
            }
          }

          final pageController = PageController(initialPage: initialWorldIndex);

          return PageView.builder(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: worlds.length,
            itemBuilder: (context, index) {
              final world = worlds[index];
              bool isWorldComplete = world.lessons
                  .every((lesson) => completedLessonIds.contains(lesson.id));
              return _buildWorldWidget(
                  world,
                  completedLessonIds,
                  isWorldComplete,
                  (index == worlds.length - 1),
                  pageController);
            },
          );
        },
      ),
    );
  }

  Widget _buildWorldWidget(World world, Set<int> completedLessonIds,
      bool isWorldComplete, bool isLastWorld, PageController pageController) {
    const verticalSpacing = 160.0;
    final totalHeight = (world.lessons.length * verticalSpacing) +
        (isWorldComplete && !isLastWorld ? verticalSpacing : 0);

    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(
            painter: MusicBackgroundPainter(),
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: totalHeight,
              child: Stack(
                children: [
                  _buildPathPainter(
                      world.lessons, isWorldComplete && !isLastWorld),
                  ..._buildLessonNodes(world.lessons, completedLessonIds),
                  if (isWorldComplete && !isLastWorld)
                    Positioned(
                      top: _getLessonNodePosition(world.lessons.length).dy,
                      left: _getLessonNodePosition(world.lessons.length).dx,
                      child: _buildNextModuleNode(pageController),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextModuleNode(PageController pageController) {
    return GestureDetector(
      onTap: () {
        pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withAlpha(128),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.door_front_door_outlined,
              color: Colors.white, size: 40),
        ),
      ),
    );
  }

  List<Widget> _buildLessonNodes(
      List<Lesson> lessons, Set<int> completedLessonIds) {
    List<Widget> nodes = [];
    for (int i = lessons.length - 1; i >= 0; i--) {
      if (completedLessonIds.contains(lessons[i].id)) {
        lastCompletedIndex = i;
        break;
      }
    }

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final position = _getLessonNodePosition(i);

      LessonStatus status;
      final isCompleted = completedLessonIds.contains(lesson.id);

      if (isCompleted) {
        status = LessonStatus.completed;
      } else if (i == 0 || i == lastCompletedIndex + 1) {
        status = LessonStatus.unlocked;
      } else {
        status = LessonStatus.locked;
      }

      nodes.add(
        Positioned(
          top: position.dy,
          left: position.dx,
          child: LessonNodeWidget(
            lesson: lesson,
            status: status,
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => LessonScreen(lesson: lesson)),
              );
              // Se a lição foi completada, atualiza os dados da tela
              if (result == true) {
                _refreshData();
              }
            },
          ),
        ),
      );
    }
    return nodes;
  }

  Widget _buildPathPainter(List<Lesson> lessons, bool connectToDoor) {
    final nodeCount = lessons.length + (connectToDoor ? 1 : 0);
    final positions =
        List.generate(nodeCount, (i) => _getLessonNodePosition(i));
    return CustomPaint(
      size: Size.infinite,
      painter: PathPainter(nodePositions: positions),
    );
  }

  Offset _getLessonNodePosition(int index) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    const double nodeWidth = 100.0;
    final double y = 10.0 + (index * 160.0);

    double x;
    switch (index % 4) {
      case 0:
        x = (screenWidth / 2) - (nodeWidth / 2);
        break;
      case 1:
        x = screenWidth * 0.95 - nodeWidth;
        break;
      case 2:
        x = (screenWidth / 2) - (nodeWidth / 2);
        break;
      case 3:
      default:
        x = screenWidth * 0.05;
        break;
    }
    return Offset(x, y);
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> nodePositions;

  const PathPainter({required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5a5a8a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    if (nodePositions.length < 2) return;

    double nodeSize = 100.0;
    final double cornerRadius = nodeSize * 0.1;

    final path = Path();

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final start = Offset(
        nodePositions[i].dx + nodeSize / 2,
        nodePositions[i].dy + nodeSize / 2,
      );

      final end = Offset(
        nodePositions[i + 1].dx + nodeSize / 2,
        nodePositions[i + 1].dy + nodeSize / 2,
      );

      if (i == 0) path.moveTo(start.dx, start.dy);

      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;

      final cornerPoint = Offset(start.dx, end.dy);

      path.lineTo(cornerPoint.dx,
          cornerPoint.dy - cornerRadius * (end.dy - start.dy).sign);

      path.arcToPoint(
        Offset(cornerPoint.dx + cornerRadius * (end.dx - start.dx).sign,
            cornerPoint.dy),
        radius: Radius.circular(cornerRadius),
        clockwise: dx.sign != dy.sign,
      );

      path.lineTo(end.dx, end.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MusicBackgroundPainter extends CustomPainter {
  const MusicBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.background,
    );
    _drawAurora(
        canvas, size, AppColors.primary.withAlpha(30), Alignment.topLeft);
    _drawAurora(
        canvas, size, AppColors.completed.withAlpha(25), Alignment.bottomRight);
  }

  void _drawAurora(Canvas canvas, Size size, Color color, Alignment alignment) {
    final Rect rect = alignment.inscribe(
      Size(size.width * 1.5, size.height * 1.5),
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final paint = Paint()
      ..shader = RadialGradient(
        center: alignment,
        radius: 0.8,
        colors: [color, Colors.transparent],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
