import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'general_channel';
  static const String channelName = 'General Notifications';

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'General notifications for Arvan Photos',
        importance: Importance.defaultImportance,
      );

  static Future<void> ensureChannelCreated() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  static Future<bool> requestPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidPlugin?.requestNotificationsPermission() ?? false;
  }

  static Future<void> initialize([ServiceInstance? service]) async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
    );

    await ensureChannelCreated();
  }

  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  static Future<void> showUploadProgress({
    required int id,
    required String title,
    required int progress,
    bool isComplete = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Upload progress notifications',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      ongoing: !isComplete,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: isComplete ? 'Upload complete' : 'Uploading...',
      notificationDetails: notificationDetails,
    );
  }
}
