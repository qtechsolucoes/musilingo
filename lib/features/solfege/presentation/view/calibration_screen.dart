import 'package:flutter/material.dart';
import '../services/calibration_service.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({Key? key}) : super(key: key);

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final CalibrationService _calibrationService = CalibrationService();

  bool _isCalibrating = false;
  String _status = 'Pronto para calibrar';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCalibration();
  }

  Future<void> _loadCurrentCalibration() async {
    await _calibrationService.loadCalibration();
    setState(() {});
  }

  Future<void> _calibrateNoiseFloor() async {
    setState(() {
      _isCalibrating = true;
      _status = 'Calibrando ruído ambiente...';
      _progress = 0.0;
    });

    // Simular progresso
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _progress = i / 100);
    }

    final result = await _calibrationService.calibrateNoiseFloor();

    setState(() {
      _isCalibrating = false;
      _status = result.success ? 'Calibração concluída!' : 'Erro na calibração';
      _progress = 0.0;
    });

    if (result.success) {
      await _calibrationService.saveCalibration();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ruído: ${result.noiseFloor?.toStringAsFixed(4)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _calibrateVoiceRange() async {
    setState(() {
      _isCalibrating = true;
      _status = 'Cante do grave ao agudo...';
      _progress = 0.0;
    });

    // Simular progresso
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _progress = i / 100);
    }

    try {
      final result = await _calibrationService.calibrateVoiceRange();

      setState(() {
        _isCalibrating = false;
        _status = 'Tipo de voz: ${result.voiceType}';
        _progress = 0.0;
      });

      await _calibrationService.saveCalibration();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Extensão Vocal Detectada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tipo de voz: ${result.voiceType}'),
              Text(
                  'Frequência mais grave: ${result.lowestFrequency.toStringAsFixed(1)} Hz'),
              Text(
                  'Frequência mais aguda: ${result.highestFrequency.toStringAsFixed(1)} Hz'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isCalibrating = false;
        _status = 'Erro: $e';
        _progress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Calibração', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: const Color(0xFF2A2A3E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isCalibrating ? Icons.mic : Icons.settings,
                      size: 48,
                      color: const Color(0xFF6C63FF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isCalibrating) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Calibração de Ruído
            _buildCalibrationTile(
              title: 'Calibrar Ruído Ambiente',
              subtitle: 'Fique em silêncio por 3 segundos',
              icon: Icons.volume_off,
              onTap: _isCalibrating ? null : _calibrateNoiseFloor,
            ),

            const SizedBox(height: 12),

            // Calibração de Voz
            _buildCalibrationTile(
              title: 'Calibrar Extensão Vocal',
              subtitle: 'Cante do grave ao agudo',
              icon: Icons.record_voice_over,
              onTap: _isCalibrating ? null : _calibrateVoiceRange,
            ),

            const SizedBox(height: 24),

            // Configurações Atuais
            Card(
              color: const Color(0xFF2A2A3E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configurações Atuais',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingRow(
                      'Tolerância de Pitch',
                      '±${_calibrationService.pitchTolerance.toStringAsFixed(1)} Hz',
                    ),
                    _buildSettingRow(
                      'Tolerância de Duração',
                      '±${(_calibrationService.durationTolerance * 1000).toStringAsFixed(0)} ms',
                    ),
                    _buildSettingRow(
                      'Tipo de Voz',
                      _calibrationService.userVoiceType.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Card(
      color: const Color(0xFF2A2A3E),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6C63FF)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
