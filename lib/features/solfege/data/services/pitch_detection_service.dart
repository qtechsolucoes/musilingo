import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fft/fft.dart';

class PitchDetectionService {
  static const int sampleRate = 44100;
  static const double a4Frequency = 440.0;

  // Algoritmo YIN melhorado para detecção de pitch
  static double? detectPitchYIN(List<double> buffer,
      {double threshold = 0.15}) {
    final int bufferSize = buffer.length;
    final int halfBufferSize = bufferSize ~/ 2;

    // Step 1: Difference function
    final List<double> difference = List.filled(halfBufferSize, 0.0);

    for (int tau = 1; tau < halfBufferSize; tau++) {
      double sum = 0.0;
      for (int i = 0; i < halfBufferSize; i++) {
        final delta = buffer[i] - buffer[i + tau];
        sum += delta * delta;
      }
      difference[tau] = sum;
    }

    // Step 2: Cumulative mean normalized difference
    final List<double> cmndf = List.filled(halfBufferSize, 0.0);
    cmndf[0] = 1.0;

    double runningSum = 0.0;
    for (int tau = 1; tau < halfBufferSize; tau++) {
      runningSum += difference[tau];
      cmndf[tau] = difference[tau] / (runningSum / tau);
    }

    // Step 3: Find the first minimum below threshold
    int tau = 2;
    while (tau < halfBufferSize - 1) {
      if (cmndf[tau] < threshold) {
        while (tau + 1 < halfBufferSize && cmndf[tau + 1] < cmndf[tau]) {
          tau++;
        }
        break;
      }
      tau++;
    }

    // Step 4: Parabolic interpolation
    if (tau >= halfBufferSize - 1 || tau == 2) {
      return null;
    }

    final x0 = cmndf[tau - 1];
    final x1 = cmndf[tau];
    final x2 = cmndf[tau + 1];

    final a = (x0 - 2 * x1 + x2) / 2;
    final b = (x2 - x0) / 2;

    final xmax = -b / (2 * a);
    final interpolatedTau = tau + xmax;

    return sampleRate / interpolatedTau;
  }

  // Autocorrelação para validação
  static double? detectPitchAutocorrelation(List<double> buffer) {
    final int bufferSize = buffer.length;
    final int maxLag = bufferSize ~/ 2;

    // Aplicar janela de Hanning
    final windowed = _applyHanningWindow(buffer);

    // Calcular autocorrelação
    final List<double> autocorr = List.filled(maxLag, 0.0);

    for (int lag = 0; lag < maxLag; lag++) {
      double sum = 0.0;
      for (int i = 0; i < bufferSize - lag; i++) {
        sum += windowed[i] * windowed[i + lag];
      }
      autocorr[lag] = sum;
    }

    // Encontrar o primeiro pico após o lag 0
    int peakLag = 0;
    double maxValue = 0.0;

    // Ignorar frequências muito altas (< 80Hz) e muito baixas (> 2000Hz)
    final minLag = sampleRate ~/ 2000; // 2000Hz max
    final maxLagSearch = sampleRate ~/ 80; // 80Hz min

    for (int lag = minLag; lag < math.min(maxLagSearch, maxLag); lag++) {
      if (autocorr[lag] > maxValue) {
        // Verificar se é um pico local
        if (lag > 0 && lag < maxLag - 1) {
          if (autocorr[lag] > autocorr[lag - 1] &&
              autocorr[lag] > autocorr[lag + 1]) {
            maxValue = autocorr[lag];
            peakLag = lag;
          }
        }
      }
    }

    if (peakLag == 0) return null;

    // Interpolação quadrática para maior precisão
    if (peakLag > 0 && peakLag < maxLag - 1) {
      final y1 = autocorr[peakLag - 1];
      final y2 = autocorr[peakLag];
      final y3 = autocorr[peakLag + 1];

      final x0 = (y3 - y1) / (2 * (2 * y2 - y1 - y3));
      final interpolatedLag = peakLag + x0;

      return sampleRate / interpolatedLag;
    }

    return sampleRate / peakLag;
  }

  // Detecção combinada para maior precisão
  static double? detectPitchCombined(List<double> buffer) {
    final yinResult = detectPitchYIN(buffer);
    final autocorrResult = detectPitchAutocorrelation(buffer);

    if (yinResult == null && autocorrResult == null) return null;
    if (yinResult == null) return autocorrResult;
    if (autocorrResult == null) return yinResult;

    // Se os resultados são próximos, fazer média
    final difference = (yinResult - autocorrResult).abs();
    if (difference < 10) {
      // Dentro de 10Hz
      return (yinResult + autocorrResult) / 2;
    }

    // Preferir YIN se houver discrepância
    return yinResult;
  }

  static List<double> _applyHanningWindow(List<double> buffer) {
    final int length = buffer.length;
    final windowed = List<double>.filled(length, 0.0);

    for (int i = 0; i < length; i++) {
      final window = 0.5 - 0.5 * math.cos(2 * math.pi * i / (length - 1));
      windowed[i] = buffer[i] * window;
    }

    return windowed;
  }

  // Converter frequência para nota musical
  static String frequencyToNote(double frequency) {
    final a4 = 440.0;
    final c0 = a4 * math.pow(2, -4.75);

    if (frequency <= 0) return 'N/A';

    final halfStepsBelowA4 = 12 * (math.log(frequency / a4) / math.log(2));
    final noteNumber = (halfStepsBelowA4 + 49).round();

    final noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final octave = (noteNumber - 1) ~/ 12;
    final noteIndex = (noteNumber - 1) % 12;

    if (noteIndex < 0 || noteIndex >= noteNames.length) return 'N/A';

    return '${noteNames[noteIndex]}$octave';
  }

  // Calcular cents de diferença
  static double calculateCents(double frequency, double targetFrequency) {
    if (frequency <= 0 || targetFrequency <= 0) return 0;
    return 1200 * (math.log(frequency / targetFrequency) / math.log(2));
  }

  // Verificar se está afinado (dentro de ±50 cents)
  static bool isInTune(double frequency, double targetFrequency,
      {double centsTolerance = 50}) {
    final cents = calculateCents(frequency, targetFrequency).abs();
    return cents <= centsTolerance;
  }
}

// Classe para análise de amplitude e envelope
class AmplitudeAnalyzer {
  final List<double> _amplitudeHistory = [];
  final int _historySize;
  double _noiseFloor = 0.0;

  AmplitudeAnalyzer({int historySize = 100}) : _historySize = historySize;

  void addSample(double amplitude) {
    _amplitudeHistory.add(amplitude);
    if (_amplitudeHistory.length > _historySize) {
      _amplitudeHistory.removeAt(0);
    }

    // Atualizar noise floor (menor amplitude registrada)
    if (_amplitudeHistory.length > 10) {
      final sorted = List<double>.from(_amplitudeHistory)..sort();
      _noiseFloor = sorted[sorted.length ~/ 10]; // 10º percentil
    }
  }

  double get averageAmplitude {
    if (_amplitudeHistory.isEmpty) return 0;
    return _amplitudeHistory.reduce((a, b) => a + b) / _amplitudeHistory.length;
  }

  bool isSignalPresent({double threshold = 2.0}) {
    return averageAmplitude > _noiseFloor * threshold;
  }

  // Detectar início de nota (onset)
  bool detectOnset() {
    if (_amplitudeHistory.length < 3) return false;

    final current = _amplitudeHistory.last;
    final previous = _amplitudeHistory[_amplitudeHistory.length - 2];

    // Detectar aumento súbito de amplitude
    return current > previous * 1.5 && current > _noiseFloor * 3;
  }

  // Detectar fim de nota (offset)
  bool detectOffset() {
    if (_amplitudeHistory.length < 10) return false;

    final recent = _amplitudeHistory.sublist(_amplitudeHistory.length - 5);
    final average = recent.reduce((a, b) => a + b) / recent.length;

    return average < _noiseFloor * 1.5;
  }
}
