import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class ShakeTrainer {
  static final ShakeTrainer _instance = ShakeTrainer._internal();
  factory ShakeTrainer() => _instance;
  ShakeTrainer._internal();

  bool isTraining = false;
  List<List<double>> _currentRecording = [];
  StreamSubscription<AccelerometerEvent>? _subscription;

  Future<void> startTraining(Function(double progress) onProgress, Function() onComplete) async {
    isTraining = true;
    _currentRecording.clear();
    
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (isTraining) {
        _currentRecording.add([event.x, event.y, event.z]);
        
        // Progress based on samples (assuming ~50Hz, 2 seconds is ~100 samples)
        double progress = _currentRecording.length / 100.0;
        onProgress(progress.clamp(0.0, 1.0));

        if (_currentRecording.length >= 100) {
          _finishTraining(onComplete);
        }
      }
    });

    // Auto-stop after 3 seconds as a safety
    Future.delayed(const Duration(seconds: 3), () {
      if (isTraining) _finishTraining(onComplete);
    });
  }

  void _finishTraining(Function() onComplete) async {
    isTraining = false;
    _subscription?.cancel();
    
    if (_currentRecording.isNotEmpty) {
      await _calculateAndSaveThresholds();
    }
    onComplete();
  }

  Future<void> _calculateAndSaveThresholds() async {
    if (_currentRecording.isEmpty) return;

    double maxX = 0;
    double maxY = 0;
    double maxZ = 0;

    for (var sample in _currentRecording) {
      maxX = math.max(maxX, sample[0].abs());
      maxY = math.max(maxY, sample[1].abs());
      maxZ = math.max(maxZ, sample[2].abs());
    }

    // Threshold is 1.2x the maximum recorded value in each axis
    // Minimum threshold of 15.0 to avoid accidental triggers
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('shake_threshold_x', math.max(15.0, maxX * 1.2));
    await prefs.setDouble('shake_threshold_y', math.max(15.0, maxY * 1.2));
    await prefs.setDouble('shake_threshold_z', math.max(15.0, maxZ * 1.2));
    
    print("Thresholds saved: X=${maxX*1.2}, Y=${maxY*1.2}, Z=${maxZ*1.2}");
  }

  Future<Map<String, double>> getThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'x': prefs.getDouble('shake_threshold_x') ?? 25.0,
      'y': prefs.getDouble('shake_threshold_y') ?? 25.0,
      'z': prefs.getDouble('shake_threshold_z') ?? 25.0,
    };
  }
}
