// lib/features/home/presentation/view/home_screen.dart

import 'dart:math'; // Import necessário para o gerador de números aleatórios
import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/data/models/module_model.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart';
import 'package:musilingo/app/services/database_service.dart';
import 'package:musilingo/features/home/presentation/widgets/lesson_node_widget.dart';
import 'package:musilingo/features/lesson/presentation/view/lesson_screen.dart';
import 'package:musilingo/main.dart';

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
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _fetchHomeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'Usuário não autenticado.';

      final modules = await _databaseService.getModulesAndLessons();
      final completedLessonIds = await _databaseService.getCompletedLessonIds(userId);

      final allLessons = modules.expand((module) => module.lessons).toList();
      final List<World> worlds = [];
      const int lessonsPerWorld = 10;

      for (int i = 0; i < allLessons.length; i += lessonsPerWorld) {
        final end = (i + lessonsPerWorld > allLessons.length) ? allLessons.length : i + lessonsPerWorld;
        worlds.add(
            World(
              index: worlds.length,
              lessons: allLessons.sublist(i, end),
            )
        );
      }

      int initialWorldIndex = 0;
      for (final world in worlds) {
        bool worldIsComplete = world.lessons.every((lesson) => completedLessonIds.contains(lesson.id));
        if (!worldIsComplete) {
          initialWorldIndex = world.index;
          break;
        }
      }
      _pageController = PageController(initialPage: initialWorldIndex);

      return {
        'worlds': worlds,
        'completedLessonIds': completedLessonIds,
      };

    } catch (error) {
      if (!mounted) return {};
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar dados: $error')),
      );
      return {};
    }
  }

  void _refreshData() {
    setState(() {
      _homeDataFuture = _fetchHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Trilha de Aprendizagem', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const Row(children: [
            Icon(Icons.favorite, color: AppColors.primary),
            SizedBox(width: 4),
            Text('5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 16),
          ]),
          const Row(children: [
            Icon(Icons.music_note, color: AppColors.accent),
            SizedBox(width: 4),
            Text('816', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 16),
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
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Não foi possível carregar o conteúdo.'));
          }

          final worlds = snapshot.data!['worlds'] as List<World>;
          final completedLessonIds = snapshot.data!['completedLessonIds'] as Set<int>;

          return PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: worlds.length,
            itemBuilder: (context, index) {
              final world = worlds[index];
              return _buildWorldWidget(world, completedLessonIds, (index == worlds.length - 1));
            },
          );
        },
      ),
    );
  }

  Widget _buildWorldWidget(World world, Set<int> completedLessonIds, bool isLastWorld) {
    bool isWorldComplete = world.lessons.every((lesson) => completedLessonIds.contains(lesson.id));
    final totalHeight = (world.lessons.length * 120.0) + (isWorldComplete && !isLastWorld ? 120.0 : 0);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: SizedBox(
          width: double.infinity,
          height: totalHeight,
          child: Stack(
            children: [
              const CustomPaint(
                size: Size.infinite,
                painter: CleanBackgroundPainter(),
              ),
              _buildPathPainter(world.lessons, isWorldComplete && !isLastWorld),
              ..._buildLessonNodes(world.lessons, completedLessonIds),
              if (isWorldComplete && !isLastWorld)
                Positioned(
                  top: _getLessonNodePosition(world.lessons.length).dy,
                  left: _getLessonNodePosition(world.lessons.length).dx,
                  child: _buildNextModuleNode(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextModuleNode() {
    return GestureDetector(
      onTap: () {
        _pageController.nextPage(
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
          child: Icon(Icons.door_front_door_outlined, color: Colors.white, size: 40),
        ),
      ),
    );
  }

  List<Widget> _buildLessonNodes(List<Lesson> lessons, Set<int> completedLessonIds) {
    List<Widget> nodes = [];
    bool nextLessonUnlocked = true;

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final position = _getLessonNodePosition(i);

      LessonStatus status;
      final isCompleted = completedLessonIds.contains(lesson.id);

      if (isCompleted) {
        status = LessonStatus.completed;
        nextLessonUnlocked = true;
      } else if (nextLessonUnlocked) {
        status = LessonStatus.unlocked;
        nextLessonUnlocked = false;
      } else {
        status = LessonStatus.locked;
      }

      if (i == 0 && !isCompleted) {
        status = LessonStatus.unlocked;
      }

      nodes.add(
        Positioned(
          top: position.dy,
          left: position.dx,
          child: LessonNodeWidget(
            lesson: lesson,
            status: status,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LessonScreen(lesson: lesson)),
              );
              _refreshData();
            },
          ),
        ),
      );
    }
    return nodes;
  }

  Widget _buildPathPainter(List<Lesson> lessons, bool connectToDoor) {
    final nodeCount = lessons.length + (connectToDoor ? 1 : 0);
    final positions = List.generate(nodeCount, (i) => _getLessonNodePosition(i));
    return CustomPaint(
      size: Size.infinite,
      painter: PathPainter(nodePositions: positions),
    );
  }

  Offset _getLessonNodePosition(int index) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final double y = 10.0 + (index * 120.0);
    final double x = index % 2 == 0
        ? screenWidth * 0.15
        : screenWidth * 0.85 - 100;
    return Offset(x, y);
  }
}

// --- PINTOR DA TRILHA FRACTAL E NATURAL ---
class PathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final Random _random = Random();

  PathPainter({required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A4A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    if (nodePositions.length < 2) return;

    const double nodeSize = 100.0;
    final path = Path();
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final start = Offset(nodePositions[i].dx + nodeSize / 2, nodePositions[i].dy + nodeSize);
      final end = Offset(nodePositions[i + 1].dx + nodeSize / 2, nodePositions[i + 1].dy);

      path.moveTo(start.dx, start.dy);
      _generateFractalPath(path, start, end, 4, 20.0);
    }
    canvas.drawPath(path, paint);
  }

  void _generateFractalPath(Path path, Offset start, Offset end, int depth, double roughness) {
    if (depth <= 0) {
      path.lineTo(end.dx, end.dy);
      return;
    }

    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    // Desloca o ponto médio de forma aleatória
    final offsetX = midX + (_random.nextDouble() * roughness) - (roughness / 2);
    final offsetY = midY + (_random.nextDouble() * roughness) - (roughness / 2);
    final midPoint = Offset(offsetX, offsetY);

    // Gera o caminho recursivamente para os dois novos segmentos
    _generateFractalPath(path, start, midPoint, depth - 1, roughness / 2);
    _generateFractalPath(path, midPoint, end, depth - 1, roughness / 2);
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CleanBackgroundPainter extends CustomPainter {
  const CleanBackgroundPainter();
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}