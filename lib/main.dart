import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:animal_record/core/theme/app_theme.dart';
import 'package:animal_record/features/auth/presentation/pages/login_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/splash_screen.dart';
import 'package:animal_record/features/home/presentation/pages/home_screen.dart';
import 'package:animal_record/core/injection_container.dart' as di;

import 'package:animal_record/features/auth/presentation/pages/profile_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/edit_profile_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/my_account_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/welcome_social_page.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // - .env.development (for emulator)
  // - .env.physical (for physical device)
  // - .env.production (for production)
  await dotenv.load(fileName: ".env.physical");

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
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/my-account': (context) => const MyAccountScreen(),
          '/welcome-social': (context) => const WelcomeSocialPage(),
        },
      ),
    );
  }
}
