import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:porter_clone_user/app/app.dart';
import 'package:porter_clone_user/firebase_options.dart';

/// ------------------------------------------------------
/// NOTIFICATION SERVICE
/// ------------------------------------------------------
class NotificationService {
  static const String userNotificationChannelId = 'default_channel';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('🔔 Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> createChannels() async {
    log('📡 Creating notification channels...');

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        userNotificationChannelId,
        'Trip Updates',
        description: 'Notifications about driver requests and trip updates',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('accepted'),
        playSound: true,
      ),
    );

    log('✅ Channels created');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String channelId = userNotificationChannelId,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('accepted'),
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  void registerHandlers() {
    FirebaseMessaging.onMessage.listen((message) {
      log('🟢 Foreground FCM: ${message.notification?.title}');
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      showNotification(title: title, body: body);
    });
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Background FCM: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final token = await FirebaseMessaging.instance.getToken().catchError((e) {
    log('FCM token error: $e');
    return null;
  });
  if (token != null) log('FCM Token: $token');

  final notificationService = NotificationService();
  await notificationService.initialize();
  await Future.delayed(const Duration(milliseconds: 300));
  await notificationService.createChannels();
  notificationService.registerHandlers();

  runApp(const LorryApp());
}
