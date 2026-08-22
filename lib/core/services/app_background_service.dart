import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';

class AppBackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: false,
        notificationChannelId: 'upload_channel',
        initialNotificationTitle: 'Photo Service',
        initialNotificationContent: 'Service is running',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  static Future<void> start() async {}
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {}
