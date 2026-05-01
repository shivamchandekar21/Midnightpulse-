import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:midnight_pulse/data/services/user_firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmService {
  FcmService(this._userService, this._uid);

  final UserFirestoreService _userService;
  final String? _uid;

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (!kIsWeb) {
      final token = await messaging.getToken();
      if (_uid != null && token != null && token.isNotEmpty) {
        await _userService.updateFcmToken(_uid, token);
      }
    }
  }
}
