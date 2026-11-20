import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_keys.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint('[BACKGROUND] ${message.notification?.title}');
  debugPrint('[BACKGROUND] ${message.notification?.body}');
  debugPrint('[BACKGROUND DATA] ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<AuthorizationStatus> requestPermission() async {
    if (Firebase.apps.isEmpty) return AuthorizationStatus.denied;
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus.name}');
    return settings.authorizationStatus;
  }

  Future<String?> getToken() async {
    if (Firebase.apps.isEmpty) return null;
    // ignore: deprecated_member_use
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    return token;
  }

  void listenTokenRefresh(void Function(String token) onRefresh) {
    if (Firebase.apps.isEmpty) return;
    _tokenSubscription?.cancel();
    // ignore: deprecated_member_use
    _tokenSubscription = _messaging.onTokenRefresh.listen(onRefresh);
  }

  Future<void> saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('device_tokens').upsert({
      'token': token,
      'user_id': user.id,
      'platform': defaultTargetPlatform.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('Firebase belum dikonfigurasi. FCM tidak aktif.');
      return;
    }

    await requestPermission();

    final token = await getToken();
    if (token != null) await saveTokenToSupabase(token);
    listenTokenRefresh(saveTokenToSupabase);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint('[FOREGROUND] Notification received');
      debugPrint('title: ${message.notification?.title}');
      debugPrint('body : ${message.notification?.body}');
      debugPrint('data : ${message.data}');

      final title = message.notification?.title ?? 'Notifikasi';
      final body = message.notification?.body ?? '';
      messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('$title\n$body')),
      );
    });
  }

  Future<void> setupInteractedMessage() async {
    if (Firebase.apps.isEmpty) return;

    await _openedSubscription?.cancel();
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleTap,
    );
  }

  void _handleTap(RemoteMessage message) {
    final courseId = message.data['course_id'];
    final title = message.notification?.title ?? 'Notifikasi course';
    final body = message.notification?.body ?? '';
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          courseId == null
              ? '$title\n$body'
              : '$title\n$body (Course ID: $courseId)',
        ),
      ),
    );
  }
}
