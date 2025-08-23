// lib/features/practice/presentation/viewmodel/melodic_exercise_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/features/practice/presentation/widgets/melodic_input_panel.dart';

class MelodicExerciseViewModel extends ChangeNotifier {
  final MelodicExercise exercise;

  List<String> _userSequence = [];
  bool _isVerified = false;
  int _octaveOffset = 0;
  AccidentalType _currentAccidental = AccidentalType.none;
  late String _selectedNote;
  late String _selectedFigure;

  MelodicExerciseViewModel({required this.exercise}) {
    _selectedFigure = 'quarter';
    _selectedNote = _getInitialNoteName();
  }

  // --- GETTERS ---
  List<String> get userSequence => _userSequence;
  bool get isVerified => _isVerified;
  AccidentalType get currentAccidental => _currentAccidental;
  String get selectedNote => _selectedNote;
  String get selectedFigure => _selectedFigure;

  List<String> get _baseNotePalette {
    final originalPalette = exercise.notePalette;
    if (originalPalette.length < 2) {
      return originalPalette;
    }
    final firstNote = originalPalette.first.replaceAll(RegExp(r'[0-9]'), '');
    final lastNote = originalPalette.last.replaceAll(RegExp(r'[0-9]'), '');
    if (firstNote == 'C' && lastNote == 'B') {
      return originalPalette;
    }
    return originalPalette.sublist(0, originalPalette.length - 1);
  }

  int get displayOctave => _getInitialOctave() + _octaveOffset;

  List<String> get octaveAdjustedNotePalette {
    return _baseNotePalette
        .map((note) => '${note.replaceAll(RegExp(r'[0-9]'), '')}$displayOctave')
        .toList();
  }

  // --- GETTER DO MUSICXML CORRIGIDO ---
  String get musicXml {
    final timeSignature = exercise.timeSignature;
    final clef = exercise.clef;
    final beatsPerMeasure = int.parse(timeSignature.split('/')[0]);

    final Map<String, double> durationToBeats = {
      'whole': 4.0,
      'half': 2.0,
      'quarter': 1.0,
      'eighth': 0.5,
      '16th': 0.25,
      '32nd': 0.125,
    };

    final attributes = '''
      <attributes>
        <divisions>1</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>${timeSignature.split('/')[0]}</beats><beat-type>${timeSignature.split('/')[1]}</beat-type></time>
        <clef><sign>${clef.toLowerCase() == 'treble' ? 'G' : 'F'}</sign><line>${clef.toLowerCase() == 'treble' ? '2' : '4'}</line></clef>
      </attributes>
    ''';

    String measuresXml = '';
    int measureNumber = 1;
    double currentMeasureBeats = 0.0;
    String currentMeasureNotes = '';

    // Adiciona os atributos ao primeiro compasso
    currentMeasureNotes += attributes;

    for (int i = 0; i < _userSequence.length; i++) {
      final noteData = _userSequence[i];
      final durationName = noteData.split('_')[1];
      final beats = durationToBeats[durationName] ?? 1.0;

      String colorAttribute = '';
      if (_isVerified) {
        bool isCorrect = i < exercise.correctSequence.length &&
            noteData == exercise.correctSequence[i];
        colorAttribute =
            ' color="${isCorrect ? AppColors.completedHex : AppColors.errorHex}"';
      }

      if (currentMeasureBeats + beats > beatsPerMeasure) {
        measuresXml +=
            '<measure number="$measureNumber">$currentMeasureNotes</measure>';
        measureNumber++;
        currentMeasureNotes = _noteToXml(noteData, colorAttribute);
        currentMeasureBeats = beats;
      } else {
        currentMeasureNotes += _noteToXml(noteData, colorAttribute);
        currentMeasureBeats += beats;
      }
    }
    // Adiciona o último compasso (que pode estar incompleto)
    measuresXml +=
        '<measure number="$measureNumber">$currentMeasureNotes</measure>';

    return '''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
      <score-partwise version="3.1">
        <part-list>
          <score-part id="P1"><part-name>Music</part-name></score-part>
        </part-list>
        <part id="P1">
          $measuresXml
        </part>
      </score-partwise>
    ''';
  }

  String _noteToXml(String noteData, String colorAttribute) {
    final parts = noteData.split('_');
    final noteName = parts[0];
    final durationName = parts[1];

    if (noteName == 'rest') {
      return '<note$colorAttribute><rest/><duration>1</duration><type>$durationName</type></note>';
    }

    final step = noteName.substring(0, 1).toUpperCase();
    final octave = noteName.replaceAll(RegExp(r'[^0-9]'), '');

    String alter = '';
    if (noteName.contains('#')) {
      alter = '<alter>1</alter>';
    } else if (noteName.contains('b')) {
      alter = '<alter>-1</alter>';
    }

    return '''
        <note$colorAttribute>
          <pitch>
            <step>$step</step>
            $alter
            <octave>$octave</octave>
          </pitch>
          <duration>1</duration>
          <type>$durationName</type>
        </note>
      ''';
  }

  String _getInitialNoteName() {
    return exercise.notePalette.isNotEmpty
        ? exercise.notePalette.first.replaceAll(RegExp(r'[0-9]'), '')
        : 'C';
  }

  int _getInitialOctave() {
    return exercise.notePalette.isNotEmpty
        ? int.tryParse(
                exercise.notePalette.first.replaceAll(RegExp(r'[^0-9]'), '')) ??
            4
        : 4;
  }

  void onNoteSelected(String note) {
    _selectedNote = note.replaceAll(RegExp(r'[0-9]'), '');
    notifyListeners();
  }

  void onFigureSelected(String figure) {
    _selectedFigure = figure;
    notifyListeners();
  }

  void onAccidentalSelected(AccidentalType type) {
    _currentAccidental =
        (_currentAccidental == type) ? AccidentalType.none : type;
    notifyListeners();
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

  void addNoteToSequence() {
    if (_isVerified) {
      return;
    }

    String noteNameOnly = _selectedNote;
    String accidentalSign = "";
    if (_currentAccidental == AccidentalType.sharp) {
      accidentalSign = "#";
    } else if (_currentAccidental == AccidentalType.flat) {
      accidentalSign = "b";
    }

    final finalNoteName = '$noteNameOnly$accidentalSign$displayOctave';
    _userSequence.add("${finalNoteName}_$_selectedFigure");
    _currentAccidental = AccidentalType.none;
    notifyListeners();
  }

  void addRest() {
    if (_isVerified) {
      return;
    }
    _userSequence.add("rest_$_selectedFigure");
    notifyListeners();
  }

  void removeLastNote() {
    if (_isVerified || _userSequence.isEmpty) {
      return;
    }
    _userSequence.removeLast();
    notifyListeners();
  }

  bool verifyAnswer() {
    _isVerified = true;
    notifyListeners(); // Notifica a UI para reconstruir o musicXml com as cores
    return const ListEquality().equals(_userSequence, exercise.correctSequence);
  }

  void reset() {
    _userSequence = [];
    _isVerified = false;
    _octaveOffset = 0;
    _selectedFigure = 'quarter';
    _selectedNote = _getInitialNoteName();
    _currentAccidental = AccidentalType.none;
    notifyListeners();
  }
}
