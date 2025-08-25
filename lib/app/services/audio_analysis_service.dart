import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/solfege_exercise.dart';

class AudioAnalysisService {
  static final AudioAnalysisService _instance =
      AudioAnalysisService._internal();
  factory AudioAnalysisService() => _instance;
  AudioAnalysisService._internal();

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();

  StreamController<AudioAnalysisData>? _analysisController;
  StreamSubscription? _recordingDataSubscription;

  bool _isRecording = false;
  bool _isInitialized = false;

  // Buffers para análise
  List<double> _audioBuffer = [];
  String _lastDetectedWord = '';
  DateTime? _noteStartTime;

  // Parâmetros de análise
  static const int sampleRate = 44100;
  static const int fftSize = 4096;
  static const double pitchTolerance = 10.0; // Hz
  static const double durationTolerance = 0.1; // segundos

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Solicitar permissões
      final microphoneStatus = await Permission.microphone.request();
      if (!microphoneStatus.isGranted) {
        throw Exception('Permissão de microfone negada');
      }

      // Inicializar recorder
      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 50),
      );

      // Inicializar speech-to-text
      final available = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );

      if (!available) {
        print('Speech recognition não disponível');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Erro ao inicializar AudioAnalysisService: $e');
      return false;
    }
  }

  Stream<AudioAnalysisData> startAnalysis() async* {
    if (!_isInitialized) {
      await initialize();
    }

    _analysisController = StreamController<AudioAnalysisData>();
    _audioBuffer.clear();
    _noteStartTime = DateTime.now();

    // Configurar stream de áudio
    await _recorder.startRecorder(
      toStream: _analysisController!.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
    );

    // Iniciar reconhecimento de voz em paralelo
    if (_speech.isAvailable) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastDetectedWord = result.recognizedWords.toLowerCase();
            print('Palavra detectada: $_lastDetectedWord');
          }
        },
        localeId: 'pt_BR',
      );
    }

    _isRecording = true;

    // Processar stream de áudio
    _recordingDataSubscription = _analysisController!.stream.listen((foodData) {
      if (foodData is FoodData) {
        _processAudioData(foodData.data!);
      }
    });

    // Emitir análises periodicamente
    while (_isRecording) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (_audioBuffer.length >= fftSize) {
        final analysis = _analyzeBuffer();
        yield analysis;
      }
    }
  }

  void _processAudioData(Uint8List data) {
    // Converter bytes para doubles (-1.0 a 1.0)
    for (int i = 0; i < data.length - 1; i += 2) {
      final sample = data[i] | (data[i + 1] << 8);
      final normalizedSample = sample / 32768.0;
      _audioBuffer.add(normalizedSample);
    }

    // Manter buffer com tamanho máximo
    if (_audioBuffer.length > fftSize * 2) {
      _audioBuffer = _audioBuffer.sublist(_audioBuffer.length - fftSize);
    }
  }

  AudioAnalysisData _analyzeBuffer() {
    // Aplicar janela de Hamming
    final windowed = _applyWindow(_audioBuffer.take(fftSize).toList());

    // Calcular FFT
    final fft = FFT(fftSize);
    final spectrum = fft.realFft(windowed);

    // Detectar pitch fundamental
    final detectedFrequency = _detectPitch(spectrum);

    // Calcular duração da nota atual
    final currentDuration = _noteStartTime != null
        ? DateTime.now().difference(_noteStartTime!).inMilliseconds / 1000.0
        : 0.0;

    return AudioAnalysisData(
      frequency: detectedFrequency,
      amplitude: _calculateAmplitude(windowed),
      detectedWord: _lastDetectedWord,
      currentDuration: currentDuration,
    );
  }

  List<double> _applyWindow(List<double> input) {
    final windowed = <double>[];
    for (int i = 0; i < input.length; i++) {
      final window =
          0.54 - 0.46 * math.cos(2 * math.pi * i / (input.length - 1));
      windowed.add(input[i] * window);
    }
    return windowed;
  }

  double _detectPitch(List<Complex> spectrum) {
    // Encontrar pico no espectro
    double maxMagnitude = 0;
    int maxIndex = 0;

    for (int i = 20; i < spectrum.length / 2; i++) {
      // Ignorar frequências muito baixas
      final magnitude = spectrum[i].magnitude;
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
        maxIndex = i;
      }
    }

    // Converter índice para frequência
    final frequency = maxIndex * sampleRate / fftSize;

    // Aplicar correção usando interpolação quadrática
    if (maxIndex > 0 && maxIndex < spectrum.length / 2 - 1) {
      final y1 = spectrum[maxIndex - 1].magnitude;
      final y2 = spectrum[maxIndex].magnitude;
      final y3 = spectrum[maxIndex + 1].magnitude;

      final x0 = (y3 - y1) / (2 * (2 * y2 - y1 - y3));
      return (maxIndex + x0) * sampleRate / fftSize;
    }

    return frequency;
  }

  double _calculateAmplitude(List<double> samples) {
    double sum = 0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return math.sqrt(sum / samples.length);
  }

  void resetNoteTimer() {
    _noteStartTime = DateTime.now();
    _lastDetectedWord = '';
  }

  Future<void> stopAnalysis() async {
    _isRecording = false;

    await _recordingDataSubscription?.cancel();
    await _recorder.stopRecorder();
    await _speech.stop();

    _analysisController?.close();
    _analysisController = null;
    _audioBuffer.clear();
  }

  bool checkPitch(double expectedFrequency, double detectedFrequency) {
    return (detectedFrequency - expectedFrequency).abs() <= pitchTolerance;
  }

  bool checkDuration(double expectedDuration, double actualDuration) {
    return (actualDuration - expectedDuration).abs() <= durationTolerance;
  }

  bool checkNoteName(String expected, String detected) {
    final expectedLower = expected
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o');

    final detectedLower = detected
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o');

    // Verificar se contém o nome da nota
    return detectedLower.contains(expectedLower) ||
        expectedLower.contains(detectedLower);
  }

  void dispose() {
    stopAnalysis();
    _recorder.closeRecorder();
  }
}

class AudioAnalysisData {
  final double frequency;
  final double amplitude;
  final String detectedWord;
  final double currentDuration;

  AudioAnalysisData({
    required this.frequency,
    required this.amplitude,
    required this.detectedWord,
    required this.currentDuration,
  });
}
