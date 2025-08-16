// lib/app/services/sfx_service.dart

import 'package:just_audio/just_audio.dart';

class SfxService {
  // Padrão Singleton para ter uma única instância do serviço
  SfxService._privateConstructor();
  static final SfxService instance = SfxService._privateConstructor();

  final _clickPlayer = AudioPlayer();
  final _successPlayer = AudioPlayer();
  final _errorPlayer = AudioPlayer();

  Future<void> loadSounds() async {
    // Pré-carrega os sons para uma reprodução mais rápida
    await _clickPlayer.setAsset('assets/audio/click.mp3');
    await _successPlayer.setAsset('assets/audio/success.mp3');
    await _errorPlayer.setAsset('assets/audio/error.mp3');
    await _clickPlayer.load();
    await _successPlayer.load();
    await _errorPlayer.load();
  }

  void playClick() {
    _clickPlayer.seek(Duration.zero);
    _clickPlayer.play();
  }

  void playSuccess() {
    _successPlayer.seek(Duration.zero);
    _successPlayer.play();
  }

  void playError() {
    _errorPlayer.seek(Duration.zero);
    _errorPlayer.play();
  }

  void dispose() {
    _clickPlayer.dispose();
    _successPlayer.dispose();
    _errorPlayer.dispose();
  }
}
