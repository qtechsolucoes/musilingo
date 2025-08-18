// test/features/practice/presentation/viewmodel/melodic_exercise_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:musilingo/app/data/models/melodic_exercise_model.dart';
import 'package:musilingo/features/practice/presentation/viewmodel/melodic_exercise_viewmodel.dart';
import 'package:musilingo/features/practice/presentation/widgets/melodic_input_panel.dart'; // Para o AccidentalType

void main() {
  // --- DADOS DE TESTE (MOCK) ---
  // Criamos um objeto MelodicExercise fixo para usar em todos os testes.
  // Isso garante que nossos testes sejam consistentes e previsíveis.
  final mockExercise = MelodicExercise(
    id: 1,
    title: 'Exercício de Teste',
    difficulty: 1,
    clef: 'treble',
    keySignature: 'C',
    timeSignature: '4/4',
    referenceNote: 'C4',
    musicXml: '',
    correctSequence: ['C4_quarter', 'D4_quarter', 'E4_half'],
    notePalette: ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"],
    figurePalette: ['quarter', 'half', 'eighth'],
    tempo: 120,
  );

  // 'group' nos ajuda a organizar testes relacionados.
  group('MelodicExerciseViewModel Tests', () {
    test('ViewModel deve inicializar o estado corretamente', () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);

      expect(viewModel.userSequence.isEmpty, isTrue,
          reason: 'A sequência do usuário deve começar vazia.');
      expect(viewModel.isVerified, isFalse,
          reason: 'O estado de verificação deve começar como falso.');
      expect(viewModel.displayOctave, 4,
          reason: 'A oitava inicial deve ser 4.');
      expect(viewModel.selectedNote, 'C',
          reason: 'A nota selecionada inicial deve ser a primeira da paleta.');
      expect(viewModel.selectedFigure, 'quarter',
          reason: 'A figura rítmica inicial deve ser "quarter".');
    });

    test('onNoteSelected deve atualizar a nota selecionada', () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);
      viewModel.onNoteSelected('G4');
      expect(viewModel.selectedNote, 'G');
    });

    test(
        'onFigureSelected deve atualizar a figura selecionada e notificar os ouvintes',
        () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);
      int listenerCallCount = 0;
      viewModel.addListener(() => listenerCallCount++);

      viewModel.onFigureSelected('half');

      expect(viewModel.selectedFigure, 'half');
      expect(listenerCallCount, 1,
          reason: 'A mudança de figura deve notificar a UI.');
    });

    test(
        'Controles de oitava devem funcionar dentro dos limites e notificar os ouvintes',
        () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);
      int listenerCallCount = 0;
      viewModel.addListener(() => listenerCallCount++);

      // Sobe a oitava
      viewModel.onOctaveUp();
      expect(viewModel.displayOctave, 5);

      // Sobe novamente
      viewModel.onOctaveUp();
      expect(viewModel.displayOctave, 6);

      // Tenta subir além do limite
      viewModel.onOctaveUp();
      expect(viewModel.displayOctave, 6,
          reason: 'Não deve subir além do limite de +2.');

      // Desce a oitava
      viewModel.onOctaveDown();
      expect(viewModel.displayOctave, 5);

      expect(listenerCallCount, 3,
          reason: 'Cada mudança de oitava bem-sucedida deve notificar a UI.');
    });

    test(
        'addNoteToSequence deve adicionar a nota correta com a oitava e figura atuais',
        () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);

      // Configura o estado desejado
      viewModel.onNoteSelected('E4');
      viewModel.onFigureSelected('half');
      viewModel.onOctaveUp(); // Oitava agora é 5

      // Ação
      viewModel.addNoteToSequence();

      // Verificação
      expect(viewModel.userSequence, ['E5_half']);
    });

    test('addNoteToSequence deve incluir acidentes (sustenido/bemol)', () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);

      // Teste com Sustenido
      viewModel.onNoteSelected('F4');
      viewModel.onFigureSelected('quarter');
      viewModel.onAccidentalSelected(AccidentalType.sharp);
      viewModel.addNoteToSequence();

      // Teste com Bemol
      viewModel.onNoteSelected('B4');
      viewModel.onFigureSelected('eighth');
      viewModel.onAccidentalSelected(AccidentalType.flat);
      viewModel.addNoteToSequence();

      expect(viewModel.userSequence, ['F#4_quarter', 'Bb4_eighth']);
      expect(viewModel.currentAccidental, AccidentalType.none,
          reason: 'O acidente deve ser resetado após o uso.');
    });

    test('addRest deve adicionar uma pausa com a figura selecionada', () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);
      viewModel.onFigureSelected('whole');
      viewModel.addRest();
      expect(viewModel.userSequence, ['rest_whole']);
    });

    test('removeLastNote deve remover o último elemento da sequência', () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);
      viewModel.addNoteToSequence();
      viewModel.addRest();

      expect(viewModel.userSequence.length, 2);

      viewModel.removeLastNote();
      expect(viewModel.userSequence.length, 1);
      expect(viewModel.userSequence, ['C4_quarter']);
    });

    test(
        'verifyAnswer deve retornar true e marcar como verificado para a resposta correta',
        () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);

      // Simula a entrada da sequência correta
      viewModel.onNoteSelected('C4');
      viewModel.onFigureSelected('quarter');
      viewModel.addNoteToSequence();

      viewModel.onNoteSelected('D4');
      viewModel.onFigureSelected('quarter');
      viewModel.addNoteToSequence();

      viewModel.onNoteSelected('E4');
      viewModel.onFigureSelected('half');
      viewModel.addNoteToSequence();

      // Ação
      final isCorrect = viewModel.verifyAnswer();

      // Verificação
      expect(isCorrect, isTrue);
      expect(viewModel.isVerified, isTrue);
    });

    test(
        'verifyAnswer deve retornar false e marcar como verificado para a resposta incorreta',
        () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);

      // Simula uma entrada incorreta
      viewModel.addNoteToSequence();
      viewModel.addNoteToSequence();

      // Ação
      final isCorrect = viewModel.verifyAnswer();

      // Verificação
      expect(isCorrect, isFalse);
      expect(viewModel.isVerified, isTrue);
    });

    test('reset deve restaurar o ViewModel para seu estado inicial', () {
      final viewModel = MelodicExerciseViewModel(exercise: mockExercise);

      // Modifica o estado
      viewModel.addNoteToSequence();
      viewModel.onOctaveUp();
      viewModel.verifyAnswer();

      // Ação
      viewModel.reset();

      // Verificação
      expect(viewModel.userSequence.isEmpty, isTrue);
      expect(viewModel.isVerified, isFalse);
      expect(viewModel.displayOctave, 4);
    });
  });
}
