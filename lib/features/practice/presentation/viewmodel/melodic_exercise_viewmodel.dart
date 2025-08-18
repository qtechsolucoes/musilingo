// lib/features/practice/presentation/viewmodel/melodic_exercise_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/features/practice/presentation/widgets/melodic_input_panel.dart';

class MelodicExerciseViewModel extends ChangeNotifier {
  final MelodicExercise exercise;

  // --- ESTADO ---
  // Todas as variáveis que controlam o estado do exercício agora vivem aqui.
  List<String> _userSequence = [];
  bool _isVerified = false;
  int _octaveOffset = 0;
  AccidentalType _currentAccidental = AccidentalType.none;
  late String _selectedNote;
  late String _selectedFigure;

  // --- CONSTRUTOR ---
  // Inicializa o estado com os valores padrão do exercício.
  MelodicExerciseViewModel({required this.exercise}) {
    _selectedFigure = 'quarter';
    _selectedNote = _getInitialNoteName();
  }

  // --- GETTERS ---
  // A UI usará estes getters para ler o estado de forma segura (read-only).
  List<String> get userSequence => _userSequence;
  bool get isVerified => _isVerified;
  AccidentalType get currentAccidental => _currentAccidental;
  String get selectedNote => _selectedNote;
  String get selectedFigure => _selectedFigure;

  List<String> get _baseNotePalette {
    final originalPalette = exercise.notePalette;
    if (originalPalette.length < 2) return originalPalette;
    final firstNoteName =
        originalPalette.first.replaceAll(RegExp(r'[0-9]'), '');
    final lastNoteName = originalPalette.last.replaceAll(RegExp(r'[0-9]'), '');
    if (firstNoteName == lastNoteName) {
      return originalPalette.sublist(0, originalPalette.length - 1);
    }
    return originalPalette;
  }

  List<String> get octaveAdjustedNotePalette {
    return _baseNotePalette.map((note) {
      final noteName = note.substring(0, note.length - 1);
      final octave = int.parse(note.substring(note.length - 1));
      return '$noteName${octave + _octaveOffset}';
    }).toList();
  }

  int get displayOctave {
    if (octaveAdjustedNotePalette.isEmpty) return 4 + _octaveOffset;
    final firstNote = octaveAdjustedNotePalette.first;
    return int.tryParse(firstNote.replaceAll(RegExp(r'[^0-9]'), '')) ?? 4;
  }

  // --- MÉTODOS (AÇÕES) ---
  // A UI chamará estes métodos para modificar o estado.

  String _getInitialNoteName() {
    if (exercise.notePalette.isNotEmpty) {
      return exercise.notePalette.first.replaceAll(RegExp(r'[0-9]'), '');
    }
    return 'C';
  }

  void onNoteSelected(String note) {
    _selectedNote = note.replaceAll(RegExp(r'[0-9]'), '');
    // Não precisa notificar ouvintes, a seleção é interna até a nota ser adicionada.
  }

  void onFigureSelected(String figure) {
    _selectedFigure = figure;
    notifyListeners(); // Notifica para que o chip da figura mude de cor na UI.
  }

  void onOctaveUp() {
    if (_octaveOffset < 2) {
      _octaveOffset++;
      notifyListeners();
    }
  }

  void onOctaveDown() {
    if (_octaveOffset > -2) {
      _octaveOffset--;
      notifyListeners();
    }
  }

  void onAccidentalSelected(AccidentalType type) {
    _currentAccidental =
        (_currentAccidental == type) ? AccidentalType.none : type;
    notifyListeners();
  }

  void addNoteToSequence() {
    if (_isVerified) return;

    String noteNameOnly = _selectedNote;
    String accidentalSign = "";
    if (_currentAccidental == AccidentalType.sharp) {
      accidentalSign = "#";
    } else if (_currentAccidental == AccidentalType.flat) {
      accidentalSign = "b";
    }

    // A nota final é composta pelo nome, acidente e a oitava atual.
    final finalNoteName = '$noteNameOnly$accidentalSign$displayOctave';
    _userSequence.add("${finalNoteName}_$_selectedFigure");
    _currentAccidental = AccidentalType.none; // Reseta o acidente após o uso

    notifyListeners(); // Notifica a UI que a sequência mudou.
  }

  void addRest() {
    if (_isVerified) return;
    _userSequence.add("rest_$_selectedFigure");
    notifyListeners();
  }

  void removeLastNote() {
    if (_isVerified || _userSequence.isEmpty) return;
    _userSequence.removeLast();
    notifyListeners();
  }

  /// Verifica a resposta do usuário e retorna `true` se estiver correta.
  bool verifyAnswer() {
    _isVerified = true;
    final bool isCorrect =
        const ListEquality().equals(_userSequence, exercise.correctSequence);
    notifyListeners();
    return isCorrect;
  }

  /// Reseta o exercício para uma nova tentativa.
  void reset() {
    _userSequence = [];
    _isVerified = false;
    _octaveOffset = 0;
    _currentAccidental = AccidentalType.none;
    _selectedNote = _getInitialNoteName();
    _selectedFigure = 'quarter';
    notifyListeners();
  }
}
