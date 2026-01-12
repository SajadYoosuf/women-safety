import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'alert_service.dart';

class GestureClassifier {
  static final GestureClassifier _instance = GestureClassifier._internal();
  factory GestureClassifier() => _instance;
  GestureClassifier._internal();

  Interpreter? _interpreter;
  StreamSubscription<AccelerometerEvent>? _subscription;
  final List<List<double>> _dataBuffer = [];
  bool _isProcessing = false;

  Future<void> init() async {
    try {
      // For this project, we assume a pre-trained model is available or we use a fallback
      // Since we don't have a model file yet, we will implement the logic and a simple threshold
      //_interpreter = await Interpreter.fromAsset('assets/models/gesture_model.tflite');
      debugPrint("Gesture Classifier Initialized (Threshold Mode)");
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  void start() {
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      _processEvent(event);
    });
  }

  void stop() {
    _subscription?.cancel();
  }

  void _processEvent(AccelerometerEvent event) {
    if (_isProcessing) return;

    // Documentation mentions "A predefined gesture or sudden abnormal movement"
    // We implement a "High-G" event as a proxy for a struggle or specific gesture
    double gForce = (event.x * event.x + event.y * event.y + event.z * event.z);
    
    // threshold: ~3.0 Gs (9.8 * 3 = 29.4) squared is roughly 900
    if (gForce > 800) {
      _verifyAndTrigger();
    }
  }

  void _verifyAndTrigger() {
    _isProcessing = true;
    debugPrint("AI Gesture Detected! Verifying...");
    
    // In a real TFLite implementation, we would pass _dataBuffer to the model here.
    // For the MVP and as per doc, we trigger the emergency protocol.
    AlertService().triggerAlert();

    // cooldown to prevent rapid multi-triggers
    Timer(const Duration(seconds: 10), () {
      _isProcessing = false;
    });
  }
}
