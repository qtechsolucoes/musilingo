// lib/features/practice/presentation/view/melodic_perception_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:collection/collection.dart';

// Representa uma nota colocada pelo usuário na pauta
class UserNote {
  final String figure; // ex: "quarter"
  final int staffPosition; // Posição na pauta (0 = linha de baixo, etc.)
  bool? isCorrect; // Nulo = não verificado, true = correto, false = incorreto

  UserNote({required this.figure, required this.staffPosition, this.isCorrect});
}

class MelodicPerceptionExerciseScreen extends StatefulWidget {
  final MelodicExercise exercise;

  const MelodicPerceptionExerciseScreen({super.key, required this.exercise});

  @override
  State<MelodicPerceptionExerciseScreen> createState() =>
      _MelodicPerceptionExerciseScreenState();
}

class _MelodicPerceptionExerciseScreenState
    extends State<MelodicPerceptionExerciseScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Gerencia o estado do exercício
  String? _selectedFigure;
  final List<UserNote> _userSequence = [];
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showReferenceNoteDialog();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    try {
      // TODO: Substituir por URLs reais do Supabase Storage
      await _audioPlayer.setUrl(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
      _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar áudio: $e')),
        );
      }
    }
  }

  void _verifyAnswer() {
    setState(() {
      _isVerified = true;
      final correctSequence = widget.exercise.correctSequence;
      for (int i = 0; i < _userSequence.length; i++) {
        if (i < correctSequence.length) {
          // Lógica de verificação simples (pode ser aprimorada)
          // Aqui, estamos apenas verificando a figura, não a altura.
          final userNoteString = _userSequence[i].figure;
          final correctNoteString = correctSequence[i].split('_').last;
          _userSequence[i].isCorrect = (userNoteString == correctNoteString);
        } else {
          _userSequence[i].isCorrect = false;
        }
      }
    });
  }

  void _addNoteToStaff(int staffPosition) {
    if (_selectedFigure != null && !_isVerified) {
      setState(() {
        _userSequence.add(
            UserNote(figure: _selectedFigure!, staffPosition: staffPosition));
      });
    }
  }

  Future<void> _showReferenceNoteDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nota de Referência'),
        content: Text(
          'O exercício está em ${widget.exercise.keySignature} Maior. A nota de referência é ${widget.exercise.referenceNote}.\n\nDeseja ouvi-la?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              _playAudio(widget.exercise.referenceNoteAudioUrl);
              Navigator.of(context).pop();
            },
            child: const Text('Sim, ouvir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _isVerified
                ? null
                : () {
                    setState(() {
                      if (_userSequence.isNotEmpty) {
                        _userSequence.removeLast();
                      }
                    });
                  },
            tooltip: 'Desfazer',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Pentagrama Interativo
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTapDown: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition =
                      box.globalToLocal(details.globalPosition);
                  final staffHeight = box.size.height;
                  // Simplificação: 11 posições (5 linhas, 4 espaços, 2 suplementares)
                  final position =
                      (localPosition.dy / (staffHeight / 11)).floor();
                  _addNoteToStaff(position);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(128)),
                  ),
                  child: CustomPaint(
                    painter: StaffPainter(
                      clef: widget.exercise.clef,
                      userNotes: _userSequence,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Paleta de Figuras
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8.0,
                alignment: WrapAlignment.center,
                children: widget.exercise.possibleFigures.map((figure) {
                  return ActionChip(
                    label: Text(figure),
                    backgroundColor: _selectedFigure == figure
                        ? AppColors.accent
                        : AppColors.primary,
                    onPressed: _isVerified
                        ? null
                        : () {
                            setState(() {
                              _selectedFigure = figure;
                            });
                          },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Botões de ação
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () => _playAudio(widget.exercise.audioUrl),
                    icon: const Icon(Icons.play_arrow),
                    iconSize: 32,
                    tooltip: 'Ouvir Melodia',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.timer_outlined),
                    iconSize: 32,
                    tooltip: 'Metrônomo',
                  ),
                  ElevatedButton(
                    onPressed: _isVerified || _userSequence.isEmpty
                        ? null
                        : _verifyAnswer,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.completed),
                    child: const Text('Verificar Resposta'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// CustomPainter para desenhar o pentagrama e as notas
class StaffPainter extends CustomPainter {
  final String clef;
  final List<UserNote> userNotes;

  StaffPainter({required this.clef, required this.userNotes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(128)
      ..strokeWidth = 1.5;

    // Desenha as 5 linhas da pauta
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.3 + i * 0.1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Desenha a clave
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    if (clef == 'treble') {
      textPainter.text = TextSpan(
        text: '𝄞', // Símbolo da clave de Sol
        style: TextStyle(fontSize: size.height * 0.5, color: Colors.white),
      );
    } else {
      // 'bass'
      textPainter.text = TextSpan(
        text: '𝄢', // Símbolo da clave de Fá
        style: TextStyle(fontSize: size.height * 0.3, color: Colors.white),
      );
    }

    textPainter.layout();
    final yOffset = (clef == 'treble') ? size.height * 0.2 : size.height * 0.35;
    textPainter.paint(canvas, Offset(size.width * 0.02, yOffset));

    // Desenha as notas inseridas pelo usuário
    for (int i = 0; i < userNotes.length; i++) {
      final note = userNotes[i];
      final notePaint = Paint()
        ..color = note.isCorrect == null
            ? Colors.white
            : (note.isCorrect! ? Colors.greenAccent : Colors.redAccent);

      final x = size.width * (0.25 + i * 0.1);
      final y = size.height * (0.05 * note.staffPosition);

      canvas.drawCircle(Offset(x, y), 10, notePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
