import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_analysis_service.dart';

class CalibrationService {
  static final CalibrationService _instance = CalibrationService._internal();
  factory CalibrationService() => _instance;
  CalibrationService._internal();

  final AudioAnalysisService _audioService = AudioAnalysisService();

  // Parâmetros calibráveis
  double _pitchTolerance = 10.0; // Hz
  double _durationTolerance = 0.1; // segundos
  double _amplitudeThreshold = 0.01;
  double _noiseFloor = 0.0;
  String _userVoiceType = 'tenor'; // soprano, alto, tenor, bass

  Future<void> loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    _pitchTolerance = prefs.getDouble('pitch_tolerance') ?? 10.0;
    _durationTolerance = prefs.getDouble('duration_tolerance') ?? 0.1;
    _amplitudeThreshold = prefs.getDouble('amplitude_threshold') ?? 0.01;
    _noiseFloor = prefs.getDouble('noise_floor') ?? 0.0;
    _userVoiceType = prefs.getString('voice_type') ?? 'tenor';
  }

  Future<void> saveCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pitch_tolerance', _pitchTolerance);
    await prefs.setDouble('duration_tolerance', _durationTolerance);
    await prefs.setDouble('amplitude_threshold', _amplitudeThreshold);
    await prefs.setDouble('noise_floor', _noiseFloor);
    await prefs.setString('voice_type', _userVoiceType);
  }

  // Calibração automática de ruído ambiente
  Future<CalibrationResult> calibrateNoiseFloor() async {
    final samples = <double>[];

    // Coletar 3 segundos de silêncio
    final completer = Completer<CalibrationResult>();
    StreamSubscription? subscription;

    subscription = _audioService.startAnalysis().listen((data) {
      samples.add(data.amplitude);

      if (samples.length >= 60) {
        // ~3 segundos a 20Hz
        subscription?.cancel();

        // Calcular estatísticas
        samples.sort();
        final median = samples[samples.length ~/ 2];
        final percentile95 = samples[(samples.length * 0.95).floor()];

        _noiseFloor = percentile95;
        _amplitudeThreshold = percentile95 * 2;

        completer.complete(CalibrationResult(
          success: true,
          noiseFloor: _noiseFloor,
          recommendedThreshold: _amplitudeThreshold,
          message: 'Calibração concluída com sucesso',
        ));
      }
    });

    // Timeout de segurança
    Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.complete(CalibrationResult(
          success: false,
          message: 'Timeout na calibração',
        ));
      }
    });

    return completer.future;
  }

  // Calibração de extensão vocal
  Future<VoiceRangeResult> calibrateVoiceRange() async {
    final frequencies = <double>[];
    final completer = Completer<VoiceRangeResult>();

    // Instruções: cantar do grave ao agudo
    StreamSubscription? subscription;

    subscription = _audioService.startAnalysis().listen((data) {
      if (data.frequency > 0 && data.amplitude > _amplitudeThreshold) {
        frequencies.add(data.frequency);
      }

      // Após 10 segundos, analisar
      if (frequencies.length >= 200) {
        subscription?.cancel();

        frequencies.sort();
        final lowest = frequencies[frequencies.length ~/ 20]; // 5º percentil
        final highest =
            frequencies[(frequencies.length * 0.95).floor()]; // 95º percentil

        // Determinar tipo de voz
        String voiceType;
        if (lowest > 130 && highest > 500) {
          voiceType = 'soprano';
        } else if (lowest > 130 && highest > 400) {
          voiceType = 'alto';
        } else if (lowest > 80 && highest > 350) {
          voiceType = 'tenor';
        } else {
          voiceType = 'bass';
        }

        _userVoiceType = voiceType;

        completer.complete(VoiceRangeResult(
          lowestFrequency: lowest,
          highestFrequency: highest,
          voiceType: voiceType,
          comfortableRange: _getComfortableRange(voiceType),
        ));
      }
    });

    Timer(const Duration(seconds: 12), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError('Timeout na calibração');
      }
    });

    return completer.future;
  }

  Map<String, double> _getComfortableRange(String voiceType) {
    switch (voiceType) {
      case 'soprano':
        return {'low': 261.63, 'high': 1046.50}; // C4 - C6
      case 'alto':
        return {'low': 196.00, 'high': 698.46}; // G3 - F5
      case 'tenor':
        return {'low': 130.81, 'high': 523.25}; // C3 - C5
      case 'bass':
        return {'low': 87.31, 'high': 349.23}; // F2 - F4
      default:
        return {'low': 130.81, 'high': 523.25}; // Padrão tenor
    }
  }

  // Ajustar tolerâncias baseado no desempenho
  void adjustTolerances(double successRate) {
    if (successRate < 0.3) {
      // Muito difícil, aumentar tolerâncias
      _pitchTolerance = (_pitchTolerance * 1.2).clamp(5.0, 30.0);
      _durationTolerance = (_durationTolerance * 1.2).clamp(0.05, 0.3);
    } else if (successRate > 0.9) {
      // Muito fácil, diminuir tolerâncias
      _pitchTolerance = (_pitchTolerance * 0.9).clamp(5.0, 30.0);
      _durationTolerance = (_durationTolerance * 0.9).clamp(0.05, 0.3);
    }

    saveCalibration();
  }

  // Getters
  double get pitchTolerance => _pitchTolerance;
  double get durationTolerance => _durationTolerance;
  double get amplitudeThreshold => _amplitudeThreshold;
  double get noiseFloor => _noiseFloor;
  String get userVoiceType => _userVoiceType;
}

class CalibrationResult {
  final bool success;
  final double? noiseFloor;
  final double? recommendedThreshold;
  final String message;

  CalibrationResult({
    required this.success,
    this.noiseFloor,
    this.recommendedThreshold,
    required this.message,
  });
}

class VoiceRangeResult {
  final double lowestFrequency;
  final double highestFrequency;
  final String voiceType;
  final Map<String, double> comfortableRange;

  VoiceRangeResult({
    required this.lowestFrequency,
    required this.highestFrequency,
    required this.voiceType,
    required this.comfortableRange,
  });
}
