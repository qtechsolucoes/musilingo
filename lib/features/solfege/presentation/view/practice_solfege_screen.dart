import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/solfege_exercise.dart';
import '../controllers/solfege_controller.dart';
import '../services/osmd_service.dart';

class PracticeSolfegeScreen extends StatefulWidget {
  const PracticeSolfegeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeSolfegeScreen> createState() => _PracticeSolfegeScreenState();
}

class _PracticeSolfegeScreenState extends State<PracticeSolfegeScreen> {
  final SolfegeController _controller = SolfegeController();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<SolfegeExercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Inicializar controlador
      await _controller.initialize();

      // Carregar exercícios do Supabase
      await _loadExercises();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Erro na inicialização: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao inicializar: $e')),
        );
      }
    }
  }

  Future<void> _loadExercises() async {
    try {
      final response = await _supabase
          .from('practice_solfege')
          .select()
          .order('difficulty_value', ascending: true);

      setState(() {
        _exercises = (response as List)
            .map((json) => SolfegeExercise.fromJson(json))
            .toList();
      });

      // Carregar primeiro exercício
      if (_exercises.isNotEmpty) {
        await _controller.loadExercise(_exercises.first);
      }
    } catch (e) {
      print('Erro ao carregar exercícios: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2A3E),
          title: const Text(
            'Prática de Solfejo',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Consumer<SolfegeController>(
                builder: (context, controller, child) {
                  return Column(
                    children: [
                      // Seletor de exercícios
                      _buildExerciseSelector(),

                      // Display da partitura
                      _buildScoreDisplay(),

                      // Controles
                      _buildControls(),

                      // Status e feedback
                      _buildStatusDisplay(),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildExerciseSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2A2A3E),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          final isSelected = _controller.currentExercise?.id == exercise.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                exercise.title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF6C63FF),
              backgroundColor: const Color(0xFF3A3A4E),
              onSelected: (_controller.state == SolfegeState.idle)
                  ? (selected) async {
                      if (selected) {
                        await _controller.loadExercise(exercise);
                      }
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: WebViewWidget(
            controller: _controller._osmdService.controller,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final state = _controller.state;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botão Play
          _buildControlButton(
            icon: Icons.play_arrow,
            label: 'Ouvir',
            onPressed: state == SolfegeState.idle
                ? () => _controller.playExercise()
                : null,
            color: const Color(0xFF4CAF50),
          ),

          // Botão Solfejar
          _buildControlButton(
            icon: Icons.mic,
            label: state == SolfegeState.listening ? 'Gravando...' : 'Solfejar',
            onPressed: state == SolfegeState.idle
                ? () => _controller.startSolfege()
                : null,
            color: const Color(0xFF6C63FF),
            isAnimated: state == SolfegeState.listening,
          ),

          // Botão Reset
          _buildControlButton(
            icon: Icons.refresh,
            label: 'Reiniciar',
            onPressed: state == SolfegeState.finished
                ? () => _controller.reset()
                : null,
            color: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool isAnimated = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isAnimated
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDisplay() {
    final state = _controller.state;

    if (state == SolfegeState.preparing) {
      return _buildCountdown();
    }

    if (state == SolfegeState.finished) {
      return _buildResultsDisplay();
    }

    if (state == SolfegeState.listening) {
      return _buildListeningIndicator();
    }

    return const SizedBox(height: 100);
  }

  Widget _buildCountdown() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.0),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1.0 + value * 0.5,
            child: Text(
              '${_controller.countdownValue}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(1 - value * 0.5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListeningIndicator() {
    final currentNote =
        _controller.currentExercise?.noteSequence[_controller.currentNoteIndex];

    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Cante agora:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currentNote?.lyric} (${currentNote?.note})',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_controller.currentNoteIndex + 1) /
                (_controller.currentExercise?.noteSequence.length ?? 1),
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsDisplay() {
    final results = _controller.getResults();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF2A2A3E),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Resultado: ${results.score.round()} pontos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultItem(
                    'Altura',
                    '${results.correctPitch}/${results.totalNotes}',
                    results.correctPitch / results.totalNotes,
                  ),
                  _buildResultItem(
                    'Duração',
                    '${results.correctDuration}/${results.totalNotes}',
                    results.correctDuration / results.totalNotes,
                  ),
                  _buildResultItem(
                    'Nome',
                    '${results.correctName}/${results.totalNotes}',
                    results.correctName / results.totalNotes,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: results.overallAccuracy,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  results.overallAccuracy == 1.0
                      ? Colors.green
                      : results.overallAccuracy >= 0.5
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, double percentage) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: percentage == 1.0
                ? Colors.green
                : percentage >= 0.5
                    ? Colors.orange
                    : Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
