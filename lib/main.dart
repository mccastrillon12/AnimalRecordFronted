import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:animal_record/core/theme/app_theme.dart';
import 'package:animal_record/features/auth/presentation/pages/login_screen.dart';
import 'package:animal_record/features/home/presentation/pages/home_screen.dart';
import 'package:animal_record/core/injection_container.dart' as di;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  // Change fileName to switch between environments:
  // - .env.development (for emulator)
  // - .env.physical (for physical device)
  // - .env.production (for production)
  await dotenv.load(fileName: ".env.development");

  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<AuthBloc>()),
        BlocProvider(create: (context) => di.sl<LocationsCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AnimalRecord',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
