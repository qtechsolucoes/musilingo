// lib/app/services/sfx_service.dart

import 'package:just_audio/just_audio.dart';

class SfxService {
  // Padrão Singleton para ter uma única instância do serviço
  SfxService._privateConstructor();
  static final SfxService instance = SfxService._privateConstructor();

  final _clickPlayer = AudioPlayer();
  final _lessonCompletePlayer = AudioPlayer(); // Renomeado de _successPlayer
  final _errorPlayer = AudioPlayer();
  final _correctAnswerPlayer = AudioPlayer(); // Novo player para acertos

  Future<void> loadSounds() async {
    // Pré-carrega os sons para uma reprodução mais rápida
    await _clickPlayer.setAsset('assets/audio/click.wav');
    await _lessonCompletePlayer.setAsset('assets/audio/success.mp3');
    await _errorPlayer.setAsset('assets/audio/error.mp3');
    await _correctAnswerPlayer
        .setAsset('assets/audio/correct.mp3'); // Carrega o novo som

    await _clickPlayer.load();
    await _lessonCompletePlayer.load();
    await _errorPlayer.load();
    await _correctAnswerPlayer.load();
  }

  void playClick() {
    _clickPlayer.seek(Duration.zero);
    _clickPlayer.play();
  }

  // Método renomeado para maior clareza
  void playLessonComplete() {
    _lessonCompletePlayer.seek(Duration.zero);
    _lessonCompletePlayer.play();
  }

  void playError() {
    _errorPlayer.seek(Duration.zero);
    _errorPlayer.play();
  }

  // Novo método para o som de acerto de pergunta
  void playCorrectAnswer() {
    _correctAnswerPlayer.seek(Duration.zero);
    _correctAnswerPlayer.play();
  }

  void dispose() {
    _clickPlayer.dispose();
    _lessonCompletePlayer.dispose();
    _errorPlayer.dispose();
    _correctAnswerPlayer.dispose();
  }
}
