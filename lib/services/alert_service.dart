import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'sms_service.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  bool _isAlertInProgress = false;

  Future<void> triggerAlert() async {
    if (_isAlertInProgress) return;
    _isAlertInProgress = true;

    debugPrint("🚨 EMERGENCY TRIGGERED 🚨");

    // Immediate haptic feedback - Wrapped in try-catch to avoid background isolate crashes
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 255, 0, 255],
        );
      }
    } catch (e) {
      debugPrint("Vibration failed (common in background isolates): $e");
    }

    String message = "🚨 EMERGENCY 🚨\nSomeone needs HELP!";

    // 1. Get Location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint("Location error: $e. Using last known location.");
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (e) {
        debugPrint("Could not get any location: $e");
      }
    }

    // 2. Prepare Message
    try {
      final user = FirebaseAuth.instance.currentUser;
      String name = 'User';
      List<dynamic> contacts = [];

      if (user != null) {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            contacts = userData['emergencyContacts'] ?? [];
            name = userData['name'] ?? 'User';
          }
        } catch (e) {
          debugPrint("Firebase Fetch Error: $e. Falling back to cache.");
        }
      }

      // Fallback to cached contacts if firebase fails or is empty
      if (contacts.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final String? contactsJson = prefs.getString('cached_contacts');
        if (contactsJson != null) {
          contacts = jsonDecode(contactsJson);
        }
      }

      String locString = position != null
          ? "Location: https://maps.google.com/?q=${position.latitude},${position.longitude}"
          : "Location unavailable.";

      message = "🚨 EMERGENCY 🚨\n$name needs HELP!\n$locString";

      // 3. Send SMS Automatically
      if (contacts.isNotEmpty) {
        for (var contact in contacts) {
          String phone = contact['phone'].toString().replaceAll(
            RegExp(r'\s+'),
            '',
          );

          // Ensure +91 for Indian numbers if only 10 digits provided
          if (phone.length == 10 && !phone.startsWith('+')) {
            phone = "+91$phone";
          }

          debugPrint("Attempting background SMS to $phone");
          try {
            bool success = await SmsService().sendSms(phone, message);
            if (!success) {
              debugPrint(
                "Background SMS failed for $phone. Attempting UI fallback if possible.",
              );
              await _launchSmsFallback(phone, message);
            }
          } catch (e) {
            debugPrint("SmsService call failed: $e");
            await _launchSmsFallback(phone, message);
          }
        }
      } else {
        debugPrint("No emergency contacts found to alert.");
      }

      // 4. Record Ambient Audio in background
      _recordAmbientAudio();
    } catch (e) {
      debugPrint("Error in triggerAlert flow: $e");
    } finally {
      // Cooldown before allowing another trigger from same device
      Future.delayed(const Duration(seconds: 30), () {
        _isAlertInProgress = false;
      });
    }
  }

  Future<void> _recordAmbientAudio() async {
    final record = AudioRecorder();
    try {
      if (await record.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/emergency_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await record.start(const RecordConfig(), path: path);
        debugPrint("Recording ambient audio to $path");

        // Record for 60 seconds then stop
        await Future.delayed(const Duration(seconds: 60));
        await record.stop();
        debugPrint("Recording stopped.");
      }
    } catch (e) {
      debugPrint("Recording error: $e");
    } finally {
      record.dispose();
    }
  }

  Future<void> _launchSmsFallback(String phone, String message) async {
    try {
      final Uri smsLaunchUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: <String, String>{'body': message},
      );

      // url_launcher requires a foreground activity.
      // This will throw PlatformException(NO_ACTIVITY) if called from background.
      if (await canLaunchUrl(smsLaunchUri)) {
        debugPrint("Attempting UI-based SMS fallback for $phone...");
        await launchUrl(smsLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Cannot launch SMS URL for $phone");
      }
    } catch (e) {
      // This is expected in background isolates
      debugPrint(
        "SMS fallback failed (Expected in background/locked screen): $e",
      );
    }
  }
}
