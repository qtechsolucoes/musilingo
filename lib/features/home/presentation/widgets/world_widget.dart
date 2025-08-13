// lib/features/home/presentation/widgets/world_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/features/home/presentation/view/home_screen.dart'; // Para a classe World
import 'package:musilingo/features/home/presentation/widgets/lesson_node_widget.dart';
import 'package:musilingo/features/lesson/presentation/view/lesson_screen.dart';

class WorldWidget extends StatefulWidget {
  final World world;
  final Set<int> completedLessonIds;
  final bool isLastWorld;
  final PageController pageController;
  final VoidCallback onLessonCompleted;

  const WorldWidget({
    super.key,
    required this.world,
    required this.completedLessonIds,
    required this.isLastWorld,
    required this.pageController,
    required this.onLessonCompleted,
  });

  @override
  State<WorldWidget> createState() => _WorldWidgetState();
}

class _WorldWidgetState extends State<WorldWidget> {
  int lastCompletedIndex = -1;

  @override
  void initState() {
    super.initState();
    _calculateLastCompletedIndex();
  }

  void _calculateLastCompletedIndex() {
    lastCompletedIndex = -1;
    for (int i = widget.world.lessons.length - 1; i >= 0; i--) {
      if (widget.completedLessonIds.contains(widget.world.lessons[i].id)) {
        lastCompletedIndex = i;
        break;
      }
    }
  }

  @override
  void didUpdateWidget(covariant WorldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedLessonIds != oldWidget.completedLessonIds) {
      _calculateLastCompletedIndex();
    }
  }

  Offset _getLessonNodePosition(int index, BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    const verticalSpacing = 160.0;
    final bool isWorldComplete = widget.world.lessons
        .every((lesson) => widget.completedLessonIds.contains(lesson.id));
    final totalHeight = (widget.world.lessons.length * verticalSpacing) +
        (isWorldComplete && !widget.isLastWorld ? verticalSpacing : 0);

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
                  _buildPathPainter(context, widget.world.lessons,
                      isWorldComplete && !widget.isLastWorld),
                  ..._buildLessonNodes(
                      context, widget.world.lessons, widget.completedLessonIds),
                  if (isWorldComplete && !widget.isLastWorld)
                    Positioned(
                      top: _getLessonNodePosition(
                              widget.world.lessons.length, context)
                          .dy,
                      left: _getLessonNodePosition(
                              widget.world.lessons.length, context)
                          .dx,
                      child: _buildNextModuleNode(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextModuleNode() {
    return GestureDetector(
      onTap: () {
        widget.pageController.nextPage(
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
      BuildContext context, List<Lesson> lessons, Set<int> completedLessonIds) {
    List<Widget> nodes = [];
    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final position = _getLessonNodePosition(i, context);

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
              if (result == true) {
                widget.onLessonCompleted();
              }
            },
          ),
        ),
      );
    }
    return nodes;
  }

  Widget _buildPathPainter(
      BuildContext context, List<Lesson> lessons, bool connectToDoor) {
    final nodeCount = lessons.length + (connectToDoor ? 1 : 0);
    final positions =
        List.generate(nodeCount, (i) => _getLessonNodePosition(i, context));
    return CustomPaint(
      size: Size.infinite,
      painter: PathPainter(nodePositions: positions),
    );
  }
}

// As classes PathPainter e MusicBackgroundPainter podem ser movidas para este arquivo também
// para manter tudo relacionado à trilha visual junto.
class PathPainter extends CustomPainter {
  // ... (código exatamente como estava na home_screen.dart)
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
  // ... (código exatamente como estava na home_screen.dart)
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
