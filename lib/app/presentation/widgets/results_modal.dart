import 'package:flutter/material.dart';
import '../models/solfege_exercise.dart';

class ResultsModal extends StatelessWidget {
  final SolfegeResult results;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  const ResultsModal({
    Key? key,
    required this.results,
    required this.onRetry,
    required this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPerfect = results.overallAccuracy == 1.0;
    final isGood = results.overallAccuracy >= 0.7;
    final isPassing = results.overallAccuracy >= 0.5;

    return Dialog(
      backgroundColor: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de resultado
            Icon(
              isPerfect
                  ? Icons.star
                  : isGood
                      ? Icons.thumb_up
                      : isPassing
                          ? Icons.sentiment_satisfied
                          : Icons.sentiment_dissatisfied,
              size: 60,
              color: isPerfect
                  ? const Color(0xFFFFD700)
                  : isGood
                      ? Colors.green
                      : isPassing
                          ? Colors.orange
                          : Colors.red,
            ),

            const SizedBox(height: 16),

            // Título
            Text(
              isPerfect
                  ? 'Perfeito!'
                  : isGood
                      ? 'Muito Bom!'
                      : isPassing
                          ? 'Bom Trabalho!'
                          : 'Continue Praticando!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Pontuação
            Text(
              '${results.score} pontos',
              style: TextStyle(
                color: results.score > 0 ? Colors.green : Colors.red,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Estatísticas detalhadas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    'Precisão Geral',
                    '${(results.overallAccuracy * 100).toStringAsFixed(1)}%',
                    results.overallAccuracy,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Altura Correta',
                    '${results.correctPitch}/${results.totalNotes}',
                    results.correctPitch / results.totalNotes,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Duração Correta',
                    '${results.correctDuration}/${results.totalNotes}',
                    results.correctDuration / results.totalNotes,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Nome Correto',
                    '${results.correctName}/${results.totalNotes}',
                    results.correctName / results.totalNotes,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detalhamento por nota
            if (results.noteResults.isNotEmpty) ...[
              const Text(
                'Detalhamento por Nota:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: results.noteResults.length,
                  itemBuilder: (context, index) {
                    final noteResult = results.noteResults[index];
                    final isCorrect = noteResult.pitchCorrect &&
                        noteResult.durationCorrect &&
                        noteResult.nameCorrect;

                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            noteResult.note,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            noteResult.expectedName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                Icons.music_note,
                                size: 12,
                                color: noteResult.pitchCorrect
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              Icon(
                                Icons.timer,
                                size: 12,
                                color: noteResult.durationCorrect
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              Icon(
                                Icons.abc,
                                size: 12,
                                color: noteResult.nameCorrect
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Mensagem motivacional
            Text(
              _getMotivationalMessage(results.overallAccuracy),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 24),

            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Tentar Novamente',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onNext();
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    'Próximo',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, double percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: _getColorForPercentage(percentage),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForPercentage(percentage),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 0.9) return Colors.green;
    if (percentage >= 0.7) return Colors.lightGreen;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _getMotivationalMessage(double accuracy) {
    if (accuracy == 1.0) {
      return 'Excelente! Você dominou completamente este exercício!';
    } else if (accuracy >= 0.9) {
      return 'Quase perfeito! Continue assim!';
    } else if (accuracy >= 0.7) {
      return 'Muito bom! Com mais prática você chegará à perfeição!';
    } else if (accuracy >= 0.5) {
      return 'Bom progresso! Continue praticando para melhorar!';
    } else {
      return 'A prática leva à perfeição. Não desista!';
    }
  }
}
