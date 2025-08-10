// lib/features/home/presentation/view/home_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/lesson_model.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart';
import 'package:musilingo/features/home/presentation/widgets/lesson_node_widget.dart';
import 'package:musilingo/features/lesson/data/models/drag_drop_question_model.dart';
import 'package:musilingo/features/lesson/data/models/ear_training_question_model.dart';
import 'package:musilingo/features/lesson/data/models/lesson_step_model.dart';
import 'package:musilingo/features/lesson/data/models/question_model.dart';
import 'package:musilingo/features/lesson/presentation/view/lesson_screen.dart';
import 'package:musilingo/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Lesson> _lessons = [
    Lesson(
      title: 'Introdução ao Ritmo',
      icon: Icons.timer,
      status: LessonStatus.completed,
      steps: [],
    ),
    Lesson(
      title: 'Notas na Pauta',
      icon: Icons.music_note,
      status: LessonStatus.completed,
      steps: [],
    ),
    Lesson(
      title: 'Escalas Maiores',
      icon: Icons.show_chart,
      status: LessonStatus.unlocked,
      steps: [
        TheoryStep(
          title: 'O que são Notas?',
          content: 'Pentagrama, ou pauta, é o conjunto de cinco linhas e quatro espaços onde escrevemos as notas musicais. Cada nota representa um som com uma altura específica.',
        ),
        QuestionStep(
          Question(
            statement: 'Qual o nome desta nota?',
            imageAsset: 'assets/images/staff_note_mi.svg',
            options: ['Dó', 'Ré', 'Mi', 'Fá'],
            correctAnswer: 'Mi',
          ),
        ),
      ],
    ),
    Lesson(
      title: 'Intervalos Musicais',
      icon: Icons.hearing,
      status: LessonStatus.locked,
      steps: [
        TheoryStep(
          title: 'O que são Intervalos?',
          content: 'Um intervalo é a distância entre duas notas. A qualidade de um intervalo pode ser maior, menor, justa, aumentada ou diminuta. Vamos treinar nosso ouvido para reconhecê-los!',
        ),
        EarTrainingStep(
          EarTrainingQuestion(
            statement: 'Que intervalo é este?',
            audioAssetPath: 'terca_maior.mp3',
            options: ['Segunda Maior', 'Terça Maior', 'Quinta Justa', 'Oitava Justa'],
            correctAnswer: 'Terça Maior',
          ),
        ),
      ],
    ),
    Lesson(
      title: 'Formação de Acordes',
      icon: Icons.grid_on,
      status: LessonStatus.locked,
      steps: [
        TheoryStep(
          title: 'O que é um Acorde?',
          content: 'Um acorde é um conjunto de três ou mais notas tocadas simultaneamente. O acorde mais básico é a tríade, formada pela Tônica, Terça e Quinta de uma escala.',
        ),
        DragAndDropStep(
          DragAndDropQuestion(
            statement: 'Monte o acorde de Dó Maior (C)',
            correctAnswers: ['C', 'E', 'G'],
            options: [
              DraggableNote(name: 'D'),
              DraggableNote(name: 'G'),
              DraggableNote(name: 'A'),
              DraggableNote(name: 'C'),
              DraggableNote(name: 'F'),
              DraggableNote(name: 'E'),
            ],
          ),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Teoria Musical Essencial', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
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
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: _lessons.length * 150.0,
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: BackgroundMusicPainter(),
              ),
              _buildPathPainter(),
              ..._buildLessonNodes(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLessonNodes() {
    List<Widget> nodes = [];
    for (int i = 0; i < _lessons.length; i++) {
      final lesson = _lessons[i];
      final position = _getLessonNodePosition(i);

      nodes.add(
        Positioned(
          top: position.dy,
          left: position.dx,
          child: LessonNodeWidget(
            lesson: lesson,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LessonScreen(lesson: lesson),
                ),
              );
            },
          ),
        ),
      );
    }
    return nodes;
  }

  Widget _buildPathPainter() {
    List<Offset> positions = [];
    for (int i = 0; i < _lessons.length; i++) {
      positions.add(_getLessonNodePosition(i));
    }
    return CustomPaint(
      size: Size.infinite,
      painter: PathPainter(nodePositions: positions),
    );
  }

  Offset _getLessonNodePosition(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double y = 50.0 + (index * 150.0);
    final double x = index % 2 == 0
        ? screenWidth * 0.25 - 50
        : screenWidth * 0.75 - 50;
    return Offset(x, y);
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final double nodeSize = 100.0;

  PathPainter({required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A4A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    if (nodePositions.length < 2) return;

    final path = Path();
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final startPoint = Offset(nodePositions[i].dx + nodeSize / 2, nodePositions[i].dy + nodeSize);
      final endPoint = Offset(nodePositions[i + 1].dx + nodeSize / 2, nodePositions[i + 1].dy);
      final cornerRadius = 30.0;
      final midY = (startPoint.dy + endPoint.dy) / 2;

      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(startPoint.dx, midY - cornerRadius);
      path.quadraticBezierTo(
        startPoint.dx,
        midY,
        startPoint.dx + (endPoint.dx > startPoint.dx ? cornerRadius : -cornerRadius),
        midY,
      );
      path.lineTo(endPoint.dx - (endPoint.dx > startPoint.dx ? cornerRadius : -cornerRadius), midY);
      path.quadraticBezierTo(
        endPoint.dx,
        midY,
        endPoint.dx,
        midY + cornerRadius,
      );
      path.lineTo(endPoint.dx, endPoint.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class BackgroundMusicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(123);
    const symbols = ['♩', '♪', '♫', '♭', '♯', '𝄞', '𝄽', '𝄾'];
    final symbolColor = Colors.white.withOpacity(0.05);

    const double gridSpacing = 100.0;

    for (double y = 0; y < size.height; y += gridSpacing) {
      for (double x = 0; x < size.width; x += gridSpacing) {
        final double jitterX = random.nextDouble() * 40 - 20;
        final double jitterY = random.nextDouble() * 40 - 20;

        final symbol = symbols[random.nextInt(symbols.length)];
        final fontSize = random.nextDouble() * 15 + 15;

        final textSpan = TextSpan(
          text: symbol,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: symbolColor,
            fontSize: fontSize,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        textPainter.paint(canvas, Offset(x + jitterX, y + jitterY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
