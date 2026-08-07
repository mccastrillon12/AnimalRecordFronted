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
import 'package:animal_record/features/catalogs/presentation/cubit/catalogs_cubit.dart';
import 'package:animal_record/core/services/deep_link_service.dart';
import 'package:animal_record/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/link_expired_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/forgot_pin_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/reset_pin_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_detail_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_info_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_clinical_history_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_documents_screen.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_screen.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_create_screen.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/navigation/shared_file_upload_route.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/shared_files_navigation_coordinator.dart';

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
        BlocProvider(create: (context) => di.sl<CatalogsCubit>()),
        BlocProvider(create: (context) => di.sl<DiaryCubit>()),
        BlocProvider(
          create: (context) => di.sl<SharedFilesCubit>()..initialize(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AnimalRecord',
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        builder: (context, child) => SharedFilesNavigationCoordinator(
          navigatorKey: navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.sharedFileUpload) {
            return buildSharedFileUploadRoute(settings);
          }
          return null;
        },
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
          AppRoutes.forgotPin: (context) =>
              const ForgotPinScreen(identifier: ''),
          AppRoutes.resetPin: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return ResetPinScreen(
              identifier: args?['identifier'] ?? '',
              token: args?['token'] ?? '',
            );
          },
          AppRoutes.animalDetail: (context) {
            final animal =
                ModalRoute.of(context)!.settings.arguments as AnimalModel;
            return AnimalDetailScreen(animal: animal);
          },
          AppRoutes.animalInfo: (context) {
            final animal =
                ModalRoute.of(context)!.settings.arguments as AnimalModel;
            return AnimalInfoScreen(animal: animal);
          },
          AppRoutes.animalClinicalHistory: (context) {
            final animal =
                ModalRoute.of(context)!.settings.arguments as AnimalModel;
            return AnimalClinicalHistoryScreen(animal: animal);
          },
          AppRoutes.animalDiary: (context) {
            final animal =
                ModalRoute.of(context)!.settings.arguments as AnimalModel;
            return AnimalDiaryScreen(animal: animal);
          },
          AppRoutes.animalDiaryCreate: (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            AnimalModel animal;
            DiaryEntryEntity? entry;

            if (args is AnimalModel) {
              animal = args;
            } else if (args is Map<String, dynamic>) {
              animal = args['animal'] as AnimalModel;
              entry = args['entry'] as DiaryEntryEntity?;
            } else {
              throw Exception('Invalid arguments for animalDiaryCreate route');
            }

            return AnimalDiaryCreateScreen(animal: animal, entry: entry);
          },
          AppRoutes.sharedFileAnalysisReview: (context) {
            final analysis =
                ModalRoute.of(context)!.settings.arguments
                    as SharedFileAnalysisEntity;
            return SharedFileAnalysisReviewScreen(analysis: analysis);
          },
          AppRoutes.sharedFileSend: (context) {
            final analysis =
                ModalRoute.of(context)!.settings.arguments
                    as SharedFileAnalysisEntity;
            return SharedFileSendScreen(analysis: analysis);
          },
          AppRoutes.animalDocuments: (context) {
            final animalId =
                ModalRoute.of(context)!.settings.arguments as String;
            return AnimalDocumentsScreen(animalId: animalId);
          },
        },
      ),
    );
  }
}
