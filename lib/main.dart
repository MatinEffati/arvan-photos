import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/photos/presentation/bloc/photos/photos_bloc.dart';
import 'features/photos/presentation/bloc/upload/upload_bloc.dart';
import 'features/photos/presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  
  // Initialize dependency injection
  configureDependencies();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<PhotosBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<UploadBloc>(),
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
