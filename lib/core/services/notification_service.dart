import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'upload_channel';
  static const String channelName = 'Photo Uploads';

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Shows progress of photo uploads',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: true,
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
      onDidReceiveNotificationResponse: (details) {
        if (details.actionId != null) {
          if (service != null) {
            service.invoke(details.actionId!);
          } else {
            FlutterBackgroundService().invoke(details.actionId!);
          }
        }
      },
    );

    // Create the notification channel for Android
    await ensureChannelCreated();
  }

  static Future<void> showUploadProgress({
    required int id,
    required String title,
    required int progress,
    required int total,
    bool isPaused = false,
    bool isComplete = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: isComplete ? Importance.defaultImportance : Importance.high,
      priority: isComplete ? Priority.defaultPriority : Priority.high,
      showProgress: !isComplete,
      maxProgress: 100,
      progress: progress,
      ongoing: !isComplete,
      onlyAlertOnce: true,
      ticker: 'Upload Progress',
      actions: isComplete
          ? null
          : [
              if (!isPaused)
                const AndroidNotificationAction('pause', 'Pause')
              else
                const AndroidNotificationAction('resume', 'Resume'),
              const AndroidNotificationAction('stop', 'Stop'),
            ],
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: isComplete ? 'All files backed up successfully' : 'Overall Progress: $progress%',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}
