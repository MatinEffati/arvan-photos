import 'package:arvan_photos/core/di/injection.dart';
import 'package:arvan_photos/core/services/app_background_service.dart';
import 'package:arvan_photos/core/services/notification_service.dart';
import 'package:arvan_photos/core/theme/app_theme.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/backup_status/backup_status_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/device_gallery/device_gallery_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'package:arvan_photos/features/cloud/presentation/bloc/cloud_bloc.dart';
import 'package:arvan_photos/features/photos/presentation/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from assets/env file
  await dotenv.load(fileName: 'assets/env');
  
  // Initialize notification service
  await NotificationService.initialize();
  await NotificationService.ensureChannelCreated();

  // Initialize unified background service
  await AppBackgroundService.initialize();

  // Initialize dependency injection
  await configureDependencies();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<UploadBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<DeviceGalleryBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<BackupStatusBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<CloudBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Arvan Photos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
