import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'alert_service.dart';
import 'gesture_classifier.dart';

class EmergencyDetector {
  static final EmergencyDetector _instance = EmergencyDetector._internal();
  factory EmergencyDetector() => _instance;
  EmergencyDetector._internal();

  bool _isMonitoring = false;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<double>? _volumeSubscription;
  
  // To detect rapid clicks
  int _volumeClickCount = 0;
  DateTime? _lastVolumeClick;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    debugPrint("Starting Emergency Monitoring...");
    
    final prefs = await SharedPreferences.getInstance();

    // 1. Custom Shake Detection
    try {
      if (prefs.getBool('shake_enabled') ?? true) {
        double thresholdX = prefs.getDouble('shake_threshold_x') ?? 25.0;
        double thresholdY = prefs.getDouble('shake_threshold_y') ?? 25.0;
        double thresholdZ = prefs.getDouble('shake_threshold_z') ?? 25.0;

        _accelSubscription = accelerometerEventStream().listen((event) {
          if (event.x.abs() > thresholdX || event.y.abs() > thresholdY || event.z.abs() > thresholdZ) {
            debugPrint("EmergencyDetector: SHAKE DETECTED");
            AlertService().triggerAlert();
          }
        });
      }
    } catch (e) {
      debugPrint("EmergencyDetector: Shake Detection Error: $e");
    }

    // 2. Hardware Button (Volume) Triggers
    try {
      if (prefs.getBool('hold_button_enabled') ?? true) {
        _volumeSubscription = PerfectVolumeControl.stream.listen((volume) {
          final now = DateTime.now();
          if (_lastVolumeClick == null || now.difference(_lastVolumeClick!) < const Duration(milliseconds: 1000)) {
            _volumeClickCount++;
          } else {
            _volumeClickCount = 1;
          }
          _lastVolumeClick = now;

          // Trigger on 3 rapid volume changes (clicks)
          if (_volumeClickCount >= 3) {
            debugPrint("EmergencyDetector: RAPID BUTTON PRESS DETECTED");
            _volumeClickCount = 0;
            AlertService().triggerAlert();
          }
        });
      }
    } catch (e) {
      debugPrint("EmergencyDetector: Button Trigger Error: $e");
    }
    
    // 3. AI Gesture Detection (Legacy)
    try {
      GestureClassifier().init();
      GestureClassifier().start();
    } catch (e) {
      debugPrint("EmergencyDetector: Gesture Classifier Error: $e");
    }

    // 4. Voice Command (Placeholder - logic removed due to plugin incompatibility)
    debugPrint("Voice detection placeholder active.");
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _accelSubscription?.cancel();
    _volumeSubscription?.cancel();
    GestureClassifier().stop();
    _volumeClickCount = 0;
  }
}
