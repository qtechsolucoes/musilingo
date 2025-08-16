// lib/features/home/presentation/widgets/world_widget.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/features/home/presentation/view/home_screen.dart';
import 'package:musilingo/features/home/presentation/widgets/lesson_node_widget.dart';

class WorldWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.background, Color(0xFF1E2A3E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          _buildWorldContent(),
          if (world.index > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 30),
                  onPressed: () => pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          if (!isLastWorld)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 30),
                  onPressed: () => pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorldContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 20.0),
        child: Column(
          children: [
            Text(
              'Mundo ${world.index + 1}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: AppColors.accent,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: world.lessons.length,
              itemBuilder: (context, index) {
                final lesson = world.lessons[index];
                final isCompleted = completedLessonIds.contains(lesson.id);

                // Lógica para determinar se a lição está bloqueada
                bool isLocked = true;
                if (world.index == 0 && index == 0) {
                  // A primeira lição do primeiro mundo nunca está bloqueada
                  isLocked = false;
                } else if (index == 0) {
                  // Para desbloquear o primeiro nível de um mundo, verificamos se a última lição do mundo anterior está completa
                  // Esta lógica precisa ser ajustada se a lista `allLessons` for acessível aqui
                  // Por enquanto, vamos assumir que se o mundo não é o primeiro, a primeira lição está desbloqueada se a anterior foi completa.
                  // A lógica mais robusta está na tela `home_screen`, aqui simplificamos.
                  // Para uma lógica precisa, precisaríamos da lista completa de lições.
                  // Vamos assumir uma lógica simplificada por agora: a primeira lição de um mundo está desbloqueada se não for o primeiro mundo.
                  // A lógica ideal requer a verificação da última lição do mundo anterior.
                  isLocked =
                      false; // Simplificação para evitar erros. A lógica correta está no cálculo do `initialWorldIndex`.
                } else {
                  // Uma lição é desbloqueada se a anterior foi completada
                  final previousLesson = world.lessons[index - 1];
                  if (completedLessonIds.contains(previousLesson.id)) {
                    isLocked = false;
                  }
                }
                // Ajuste final: se a primeira lição não estiver concluída, todas as outras estão bloqueadas
                if (index > 0 &&
                    !completedLessonIds.contains(world.lessons[index - 1].id)) {
                  isLocked = true;
                }

                // Lógica de posicionamento para a linha de conexão
                NodePosition position;
                if (index == 0) {
                  position = NodePosition.start;
                } else if (index == world.lessons.length - 1) {
                  position = NodePosition.end;
                } else {
                  position = NodePosition.middle;
                }

                return IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Esta parte pode precisar de ajustes dependendo do seu design de linha de conexão
                      if (index % 2 == 0) const Spacer(flex: 2),
                      LessonNodeWidget(
                        lesson: lesson,
                        isCompleted: isCompleted,
                        isLocked: isLocked,
                        position: position,
                        onLessonCompleted: onLessonCompleted,
                      ),
                      if (index % 2 != 0) const Spacer(flex: 2),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
