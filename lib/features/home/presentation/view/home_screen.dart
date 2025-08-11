// lib/features/home/presentation/view/home_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
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

      int initialWorldIndex = 0;
      if (worlds.isNotEmpty) {
        int lastCompletedLessonIndex = allLessons
            .lastIndexWhere((lesson) => completedLessonIds.contains(lesson.id));
        if (lastCompletedLessonIndex != -1) {
          initialWorldIndex = lastCompletedLessonIndex ~/ lessonsPerWorld;
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Trilha de Aprendizagem',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const Row(children: [
            Icon(Icons.favorite, color: AppColors.primary),
            SizedBox(width: 4),
            Text('5',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 16),
          ]),
          const Row(children: [
            Icon(Icons.music_note, color: AppColors.accent),
            SizedBox(width: 4),
            Text('816',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: MusicBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _homeDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent));
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Não foi possível carregar o conteúdo.'));
                }

                final worlds = snapshot.data!['worlds'] as List<World>;
                final completedLessonIds =
                    snapshot.data!['completedLessonIds'] as Set<int>;

                return PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: worlds.length,
                  itemBuilder: (context, index) {
                    final world = worlds[index];
                    bool isWorldComplete = world.lessons.every(
                        (lesson) => completedLessonIds.contains(lesson.id));
                    return _buildWorldWidget(world, completedLessonIds,
                        isWorldComplete, (index == worlds.length - 1));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldWidget(World world, Set<int> completedLessonIds,
      bool isWorldComplete, bool isLastWorld) {
    const verticalSpacing = 150.0;
    final totalHeight = (world.lessons.length * verticalSpacing) +
        (isWorldComplete && !isLastWorld ? verticalSpacing : 0);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: SizedBox(
          width: double.infinity,
          height: totalHeight,
          child: Stack(
            children: [
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
          child: Icon(Icons.door_front_door_outlined,
              color: Colors.white, size: 40),
        ),
      ),
    );
  }

  List<Widget> _buildLessonNodes(
      List<Lesson> lessons, Set<int> completedLessonIds) {
    List<Widget> nodes = [];
    int lastCompletedIndex = -1;
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
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => LessonScreen(lesson: lesson)),
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
    final positions =
        List.generate(nodeCount, (i) => _getLessonNodePosition(i));
    return CustomPaint(
      size: Size.infinite,
      painter: PathPainter(nodePositions: positions),
    );
  }

  Offset _getLessonNodePosition(int index) {
    if (!mounted) return Offset.zero;

    final screenWidth = MediaQuery.of(context).size.width - 32;
    const double nodeWidth = 100.0;
    final double y = 10.0 + (index * 150.0);

    double x;
    switch (index % 3) {
      case 0: // Esquerda
        x = screenWidth * 0.1;
        break;
      case 1: // Direita
        x = screenWidth * 0.9 - nodeWidth;
        break;
      case 2: // Centro
      default:
        x = (screenWidth / 2) - (nodeWidth / 2);
        break;
    }
    return Offset(x, y);
  }
}

// --- PINTOR COM LINHAS GROSSAS E CANTOS SUAVES ---
class PathPainter extends CustomPainter {
  final List<Offset> nodePositions;

  const PathPainter({required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A4A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0 // <<< LINHA MAIS GROSSA
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round; // <<< CANTO ARREDONDADO

    if (nodePositions.length < 2) return;

    const double nodeSize = 100.0;
    final path = Path();

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final start = Offset(nodePositions[i].dx + nodeSize / 2,
          nodePositions[i].dy + nodeSize / 2);
      final end = Offset(nodePositions[i + 1].dx + nodeSize / 2,
          nodePositions[i + 1].dy + nodeSize / 2);

      final midY = (start.dy + end.dy) / 2;

      path.moveTo(start.dx, start.dy);
      path.lineTo(start.dx, midY);
      path.lineTo(end.dx, midY);
      path.lineTo(end.dx, end.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MusicBackgroundPainter extends CustomPainter {
  const MusicBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          Color(0xFF1c1c3c),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final notesPaint = Paint()
      ..color = AppColors.primary.withAlpha(20)
      ..style = PaintingStyle.fill;

    _drawQuarterNote(canvas, notesPaint,
        Offset(size.width * 0.85, size.height * 0.2), 3.0, 0.2);
    _drawEighthNote(canvas, notesPaint,
        Offset(size.width * 0.15, size.height * 0.75), 3.5, -0.3);
  }

  void _drawQuarterNote(
      Canvas canvas, Paint paint, Offset center, double scale, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(scale);

    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, 0), radius: 15))
      ..addRect(Rect.fromLTWH(13, -70, 6, 70));

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawEighthNote(
      Canvas canvas, Paint paint, Offset center, double scale, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(scale);

    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, 0), radius: 15))
      ..addRect(Rect.fromLTWH(13, -70, 6, 70));

    path.moveTo(19, -70);
    path.quadraticBezierTo(45, -60, 25, -20);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
