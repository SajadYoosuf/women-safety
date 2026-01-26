import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  static const _channel = MethodChannel('com.example.safestep/sms');

  Future<bool> sendSms(String phoneNumber, String message) async {
    final String time = DateTime.now().toString().split(' ')[1].split('.')[0];
    debugPrint(
      "\n[SMS REPORT] $time ➔ Step 1: Initiating SOS SMS for $phoneNumber",
    );

    // 1. Check Permissions
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      debugPrint("[SMS REPORT] $time ➔ Step 2: Requesting SMS permission...");
      status = await Permission.sms.request();
    }

    if (status.isGranted) {
      try {
        debugPrint("[SMS REPORT] $time ➔ Step 2: SIM Permissions... OK");

        final prefs = await SharedPreferences.getInstance();
        final int? subId = prefs.getInt('preferred_sim_id');

        String simLabel = "Default SIM";
        if (subId != null) {
          final sims = await getSimCards();
          final currentSim = sims.firstWhere(
            (s) => s['id'] == subId,
            orElse: () => {},
          );
          if (currentSim.isNotEmpty) {
            simLabel = "${currentSim['carrier']} (${currentSim['name']})";
          }
        }

        debugPrint(
          "[SMS REPORT] $time ➔ Step 3: Route ➔ [$simLabel] (ID: ${subId ?? 'Auto'})",
        );

        final bool? success = await _channel.invokeMethod<bool>('sendSms', {
          'phone': phoneNumber,
          'message': message,
          'subId': subId,
        });

        if (success == true) {
          debugPrint(
            "[SMS REPORT] $time ➔ Step 4: Handed to Android system successfully.",
          );
          return true;
        } else {
          debugPrint(
            "[SMS REPORT] $time ➔ FAILURE: Android system rejected the request.",
          );
          return false;
        }
      } on MissingPluginException {
        debugPrint(
          "[SMS REPORT] $time ➔ FAILURE: Native channel not found (Restart app).",
        );
        return false;
      } catch (e) {
        debugPrint("[SMS REPORT] $time ➔ ERROR: $e");
        return false;
      }
    } else {
      debugPrint("[SMS REPORT] $time ➔ FAILURE: SMS Permission DENIED.");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSimCards() async {
    try {
      final List<dynamic>? sims = await _channel.invokeMethod<List<dynamic>>(
        'getSimCards',
      );
      if (sims != null) {
        return sims.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("SmsService: Error fetching SIM cards: $e");
    }
    return [];
  }
}
