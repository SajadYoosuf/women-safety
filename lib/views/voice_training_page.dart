import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class VoiceTrainingPage extends StatefulWidget {
  const VoiceTrainingPage({super.key});

  @override
  State<VoiceTrainingPage> createState() => _VoiceTrainingPageState();
}

class _VoiceTrainingPageState extends State<VoiceTrainingPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Press Start and say "Hey I need help"';
  double _level = 0.0;
  bool _isInitialized = false;
  int _successCount = 0;
  final int _requiredSuccess = 3;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech Status: $status'),
        onError: (errorNotification) => debugPrint('Speech Error: $errorNotification'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  void _listen() async {
    if (!_isInitialized) {
      await _initSpeech();
      if (!_isInitialized) return;
    }

    if (!_isListening) {
      setState(() {
        _isListening = true;
        _text = "Listening...";
      });
      
      await _speech.listen(
        onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
            if (_text.toLowerCase().contains("help") || _text.toLowerCase().contains("need help")) {
              _onHelpSegmentDetected();
            }
          });
        },
        onSoundLevelChange: (level) => setState(() => _level = level),
      );
    } else {
      _stopListening();
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _level = 0.0;
    });
  }

  void _onHelpSegmentDetected() {
    _successCount++;
    if (_successCount >= _requiredSuccess) {
      _completeTraining();
    } else {
      _stopListening();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Detection $_successCount/$_requiredSuccess successful! Say it again."),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
      // Briefly wait then start again
      Future.delayed(const Duration(milliseconds: 500), _listen);
    }
  }

  void _completeTraining() async {
    _stopListening();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_trained', true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              const Text("Voice Calibrated!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                "SafeStep is now familiar with your voice pattern for emergency detection.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Finish Setup"),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Voice Calibration", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildProgressIndicator(),
            const SizedBox(height: 60),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    "Say clearly:",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "\"Hey I need help\"",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  const SizedBox(height: 60),
                  _buildVisualizer(),
                  const SizedBox(height: 40),
                  Text(
                    _text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18, 
                      fontStyle: FontStyle.italic,
                      color: _isListening ? Colors.blue : Colors.black45
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _listen,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red.shade400 : Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(
                _isListening ? "STOPPING..." : "START CALIBRATION",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Calibration Step $_successCount/$_requiredSuccess", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("${(_successCount / _requiredSuccess * 100).toInt()}%"),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _successCount / _requiredSuccess,
            minHeight: 10,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualizer() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          double h = 10 + (_level.abs() * (index + 1) * 5 % 60);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: _isListening ? h : 4,
            decoration: BoxDecoration(
              color: _isListening ? Colors.blue.shade400 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }
}
