import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  List<String> _triggers = ['help', 'sos', 'emergency'];

  Future<void> init() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('VoiceService Status: $status'),
      onError: (error) => debugPrint('VoiceService Error: $error'),
    );
    if (available) {
      await _loadTriggers();
    }
  }

  Future<void> _loadTriggers() async {
    final prefs = await SharedPreferences.getInstance();
    final customTriggers = prefs.getStringList('custom_voice_triggers') ?? [];
    _triggers = [..._triggers, ...customTriggers].toSet().toList();
  }

  Future<void> startListening() async {
    if (_isListening) return;

    await _loadTriggers(); // Refresh triggers

    _isListening = true;
    _speech.listen(
      onResult: (result) {
        String heard = result.recognizedWords.toLowerCase();
        debugPrint('Heard: $heard');
        for (var trigger in _triggers) {
          if (heard.contains(trigger.toLowerCase())) {
            debugPrint('VOICE TRIGGER DETECTED: $trigger');
            AlertService().triggerAlert();
            break;
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.deviceDefault,
    );

    // Auto-restart if it stops due to timeout
    Future.delayed(const Duration(seconds: 31), () {
      if (_isListening) {
        _isListening = false;
        startListening();
      }
    });
  }

  void stopListening() {
    debugPrint("VoiceService: Stopping listener...");
    _isListening = false;
    _speech.stop();
  }
}
