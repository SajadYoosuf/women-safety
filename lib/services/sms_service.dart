import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  static const _channel = MethodChannel('com.example.safestep/sms');

  Future<bool> sendSms(String phoneNumber, String message) async {
    debugPrint("SmsService: Attempting to send SMS to $phoneNumber via Native MethodChannel");
    
    // 1. Check Permissions
    var status = await Permission.sms.status;
    if (!status.isGranted) {
       debugPrint("SmsService: Requesting SMS permission...");
       status = await Permission.sms.request();
    }

    if (status.isGranted) {
      try {
        debugPrint("SmsService: Permission granted. Invoking native sendSms...");
        final bool? success = await _channel.invokeMethod<bool>('sendSms', {
          'phone': phoneNumber,
          'message': message,
        });
        
        if (success == true) {
          debugPrint("SmsService: Native sendSms returned SUCCESS for $phoneNumber");
          return true;
        } else {
          debugPrint("SmsService: Native sendSms returned FAILURE for $phoneNumber");
          return false;
        }
      } catch (e) {
        debugPrint("SmsService: FATAL ERROR in Native MethodChannel: $e");
        return false;
      }
    } else {
      debugPrint("SmsService: SMS Permission DENIED. Cannot send SMS.");
      return false;
    }
  }
}
