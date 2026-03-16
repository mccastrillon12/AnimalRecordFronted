import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:animal_record/features/auth/presentation/pages/login_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/splash_screen.dart';
import 'package:animal_record/features/home/presentation/pages/home_screen.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/auth/domain/usecases/validate_password_token_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/validate_pin_token_usecase.dart';

import 'package:animal_record/features/auth/presentation/pages/profile_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/edit_profile_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/my_account_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/welcome_social_page.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/core/services/deep_link_service.dart';
import 'package:animal_record/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/link_expired_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/forgot_pin_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/reset_pin_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // - .env.development (for emulator)
  // - .env.physical (for physical device)
  // - .env.production (for production)
  await dotenv.load(fileName: ".env.physical");

  await di.init();

  final deepLinkService = DeepLinkService();
  deepLinkService.setValidatePasswordTokenUseCase(
    di.sl<ValidatePasswordTokenUseCase>(),
  );
  deepLinkService.setValidatePinTokenUseCase(di.sl<ValidatePinTokenUseCase>());
  await deepLinkService.initDeepLinks(navigatorKey);

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
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/my-account': (context) => const MyAccountScreen(),
          '/welcome-social': (context) => const WelcomeSocialPage(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/link-expired': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return LinkExpiredScreen(isPinFlow: args?['isPinFlow'] == true);
          },
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/forgot-pin': (context) => const ForgotPinScreen(identifier: ''),
          '/reset-pin': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return ResetPinScreen(
              identifier: args?['identifier'] ?? '',
              token: args?['token'] ?? '',
            );
          },
        },
      ),
    );
  }
}
