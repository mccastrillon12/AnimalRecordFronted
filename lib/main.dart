import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:animal_record/features/auth/presentation/pages/login_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/splash_screen.dart';
import 'package:animal_record/features/home/presentation/pages/home_screen.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/auth/domain/usecases/validate_password_token_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/validate_pin_token_usecase.dart';

import 'package:animal_record/features/auth/presentation/pages/profile_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/edit_profile_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/my_account_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/welcome_social_page.dart';

import 'package:animal_record/core/theme/app_theme.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
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
        BlocProvider(create: (context) => di.sl<AnimalCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AnimalRecord',
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          AppRoutes.editProfile: (context) => const EditProfileScreen(),
          AppRoutes.myAccount: (context) => const MyAccountScreen(),
          AppRoutes.welcomeSocial: (context) => const WelcomeSocialPage(),
          AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),
          AppRoutes.linkExpired: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return LinkExpiredScreen(isPinFlow: args?['isPinFlow'] == true);
          },
          AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
          AppRoutes.forgotPin: (context) => const ForgotPinScreen(identifier: ''),
          AppRoutes.resetPin: (context) {
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
