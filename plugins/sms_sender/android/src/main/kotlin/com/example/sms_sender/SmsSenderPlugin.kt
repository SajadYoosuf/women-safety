package com.example.sms_sender

import android.content.Context
import android.telephony.SmsManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SmsSenderPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.safestep/sms")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // Register receiver for SMS status logs
        val intentFilter = android.content.IntentFilter().apply {
            addAction("SMS_SENT")
        }
        
        context.registerReceiver(object : android.content.BroadcastReceiver() {
            override fun onReceive(arg0: Context?, arg1: android.content.Intent?) {
                val time = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.getDefault()).format(java.util.Date())
                val status = when (resultCode) {
                    android.app.Activity.RESULT_OK -> "SUCCESS (Message is in the air)"
                    SmsManager.RESULT_ERROR_GENERIC_FAILURE -> "FAILURE (Network error / No Balance)"
                    SmsManager.RESULT_ERROR_NO_SERVICE -> "FAILURE (No Signal)"
                    SmsManager.RESULT_ERROR_RADIO_OFF -> "FAILURE (Airplane Mode)"
                    else -> "UNKNOWN ERROR"
                }
                android.util.Log.i("SmsSender", "[SMS REPORT] $time ➔ FINAL: $status")
            }
        }, intentFilter, Context.RECEIVER_EXPORTED)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "sendSms") {
            val phoneNumber = call.argument<String>("phone")
            val message = call.argument<String>("message")
            val subId = call.argument<Int>("subId")

            if (phoneNumber != null && message != null) {
                try {
                    val smsManager: SmsManager = if (subId != null && subId != -1) {
                         android.util.Log.i("SmsSender", "Using specific SIM with subId: $subId")
                         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                             context.getSystemService(SmsManager::class.java).createForSubscriptionId(subId)
                         } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                             @Suppress("DEPRECATION")
                             SmsManager.getSmsManagerForSubscriptionId(subId)
                         } else {
                             @Suppress("DEPRECATION")
                             SmsManager.getDefault()
                         }
                    } else {
                        android.util.Log.i("SmsSender", "Using default SIM")
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            context.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }
                    }

                    val SENT = "SMS_SENT"
                    val sentPI = android.app.PendingIntent.getBroadcast(context, 0, android.content.Intent(SENT), android.app.PendingIntent.FLAG_IMMUTABLE)

                    // Divide message to handle long strings (multipart)
                    val parts = smsManager.divideMessage(message)
                    val sentIntents = ArrayList<android.app.PendingIntent>()
                    for (i in parts.indices) {
                        sentIntents.add(sentPI)
                    }

                    smsManager.sendMultipartTextMessage(phoneNumber, null, parts, sentIntents, null)
                    result.success(true)
                } catch (e: Exception) {
                    android.util.Log.e("SmsSender", "Send failure: ${e.message}")
                    result.error("SMS_FAILED", e.message, null)
                }
            } else {
                result.error("INVALID_ARGUMENTS", "Phone or message is null", null)
            }
        } else if (call.method == "getSimCards") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                try {
                    val subscriptionManager = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as android.telephony.SubscriptionManager
                    val infoList = subscriptionManager.activeSubscriptionInfoList
                    val sims = infoList?.map { info ->
                        mapOf(
                            "id" to info.subscriptionId,
                            "name" to info.displayName.toString(),
                            "number" to (info.number ?: ""),
                            "carrier" to info.carrierName.toString()
                        )
                    } ?: listOf<Map<String, Any>>()
                    result.success(sims)
                } catch (e: Exception) {
                    result.error("SIM_FETCH_FAILED", e.message, null)
                }
            } else {
                result.success(listOf<Map<String, Any>>())
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
