# SafeStep - Women's Safety Application

SafeStep is a high-performance Flutter application designed to provide immediate assistance and monitoring for personal safety. It integrates advanced detection mechanisms with automated emergency responses to ensure peace of mind.

## 🚀 Key Features

### 1. **AI-Powered Emergency Detection**
*   **Gesture Recognition**: Uses `sensors_plus` and a movement-pattern analyzer to detect struggle gestures or sudden abnormal movements.
*   **Shake-to-Alert**: Instantly triggers an emergency signal when the device is shaken vigorously.
*   **Voice Phrase Recognition**: Hands-free SOS activation using keywords like "Help", "SOS", or "Save me" (even when the app is in the background).

### 2. **Silent & Discreet Operation**
*   **Stealth Mode (Notes App)**: A disguised interface that looks like a Note Taker app. Users can access the real SOS dashboard via a secret long-press or typed command.
*   **Ambient Audio Recording**: Automatically captures 30 seconds of high-quality ambient audio upon SOS trigger for evidence gathering.
*   **Active Guardian Monitoring**: Runs a low-energy foreground service that keeps monitoring active even when the phone is locked.

### 3. **Automated Response & Reliability**
*   **Precision Location Tracking**: Fetches high-accuracy GPS coordinates at the moment of trigger.
*   **Instant SMS Alerts**: Pre-populates emergency messages with a live Google Maps link.
*   **Offline Support**: Caches emergency contacts locally to ensure alerts can still be prepared in low-network situations.

### 4. **Secure Data Management**
*   **Firebase Authentication**: Secure user accounts and session management.
*   **Cloud Contact Sync**: Emergency contacts are saved securely in the cloud (Firestore) and synced across devices.
*   **Trusted Contacts**: Manage up to 5 emergency contacts with verified phone numbers.

## 🛠 Tech Stack
*   **Frontend**: Flutter (Dart)
*   **Backend**: Firebase (Auth, Firestore)
*   **Detection**: Speech-to-Text, Shake, Geolocator
*   **Service**: Flutter Background Service

## 📱 Android Implementation & Testing Notes

### Permissions Required
The following permissions must be granted for full functionality:
- `Location`: For sending your exact coordinates.
- `Microphone`: For voice recognition monitoring.
- `SMS`: To launch the messaging application.
- `Background Execution`: To ensure monitoring doesn't stop when you lock your phone.

### Android Testing Checklist & Fixes
- [x] **Foreground Service Type**: Configured as `location|microphone` in `AndroidManifest` for Android 14 compatibility.
- [x] **Kotin Upgrade**: Successfully migrated to **Kotlin 2.1.0** to meet modern Flutter SDK requirements.
- [x] **Plugin Compatibility**: Upgraded `speech_to_text` to **7.3.0** to resolve compilation errors with the new Flutter embedding.
- [x] **Gradle Strategy**: Implemented a resolution strategy to ensure `kotlin-stdlib` alignment across all plugins.

### Known Platform Behavior
- **SMS Multi-send**: On Android, the system will open the default SMS app. The user may need to press "Send" due to modern Android security restrictions on automated background SMS (unless special permissions are requested).
- **Voice Recognition**: Background voice recognition performance varies by device; "On-device" mode is enabled to improve latency.

## 🏗 Setup Instructions
1.  **Clone the repository**: `git clone <repo-url>`
2.  **Install dependencies**: `flutter pub get`
3.  **Firebase Setup**:
    -   Create a project on Firebase Console.
    -   Add Android/iOS apps.
    -   Download `google-services.json` / `GoogleService-Info.plist`.
    -   Run `flutterfire configure`.
4.  **Run the app**: `flutter run`

---
*Built with ❤️ for safety and peace of mind.*
