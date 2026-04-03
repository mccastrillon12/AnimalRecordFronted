import 'package:animal_record/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:animal_record/features/auth/domain/repositories/auth_repository.dart';
import 'package:animal_record/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:animal_record/features/auth/domain/usecases/register_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/login_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/logout_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/verify_code_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/resend_code_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/check_identification_exists_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/check_availability_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/check_social_auth_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/register_social_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/save_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/verify_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/change_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/update_biometric_status_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/get_biometric_status_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/validate_password_token_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/forgot_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/reset_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/validate_pin_token_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/get_profile_picture_upload_url_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/confirm_profile_picture_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animal_record/features/locations/data/datasources/locations_local_datasource.dart';
import 'package:animal_record/core/services/s3_upload_service.dart';

import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:animal_record/features/locations/data/datasources/locations_remote_datasource.dart';
import 'package:animal_record/features/locations/data/repositories/locations_repository_impl.dart';
import 'package:animal_record/features/locations/domain/repositories/locations_repository.dart';
import 'package:animal_record/features/locations/domain/usecases/get_countries_usecase.dart';
import 'package:animal_record/features/locations/domain/usecases/get_departments_usecase.dart';
import 'package:animal_record/features/locations/domain/usecases/get_cities_usecase.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';

import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/core/services/microsoft_auth_service.dart';
import 'package:animal_record/core/services/apple_auth_service.dart';
import 'package:animal_record/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:animal_record/core/network/api_log_interceptor.dart';
import 'package:animal_record/core/network/api_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton(
    () => AuthBloc(
      registerUseCase: sl(),
      loginUseCase: sl(),
      verifyCodeUseCase: sl(),
      resendCodeUseCase: sl(),
      checkIdentificationExistsUseCase: sl(),
      checkAvailabilityUseCase: sl(),
      checkSocialAuthUseCase: sl(),
      registerSocialUseCase: sl(),
      getUserProfileUseCase: sl(),
      updateProfileUseCase: sl(),
      changePasswordUseCase: sl(),
      forgotPasswordUseCase: sl(),
      resetPasswordUseCase: sl(),
      validatePasswordTokenUseCase: sl(),
      savePinUseCase: sl(),
      verifyPinUseCase: sl(),
      changePinUseCase: sl(),
      updateBiometricStatusUseCase: sl(),
      getBiometricStatusUseCase: sl(),
      forgotPinUseCase: sl(),
      resetPinUseCase: sl(),
      logoutUseCase: sl(),
      tokenStorage: sl(),
      getProfilePictureUploadUrlUseCase: sl(),
      confirmProfilePictureUseCase: sl(),
      s3UploadService: sl(),
    ),
  );

  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => VerifyCodeUseCase(sl()));
  sl.registerLazySingleton(() => ResendCodeUseCase(sl()));
  sl.registerLazySingleton(() => CheckIdentificationExistsUseCase(sl()));
  sl.registerLazySingleton(() => CheckAvailabilityUseCase(sl()));
  sl.registerLazySingleton(() => CheckSocialAuthUseCase(sl()));
  sl.registerLazySingleton(() => RegisterSocialUseCase(sl()));
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ValidatePasswordTokenUseCase(sl()));
  sl.registerLazySingleton(() => SavePinUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPinUseCase(sl()));
  sl.registerLazySingleton(() => ChangePinUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBiometricStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetBiometricStatusUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPinUseCase(sl()));
  sl.registerLazySingleton(() => ResetPinUseCase(sl()));
  sl.registerLazySingleton(() => ValidatePinTokenUseCase(sl()));
  sl.registerLazySingleton(() => GetProfilePictureUploadUrlUseCase(sl()));
  sl.registerLazySingleton(() => ConfirmProfilePictureUseCase(sl()));
  sl.registerLazySingleton(() => S3UploadService());

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), tokenStorage: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  sl.registerFactory(
    () => LocationsCubit(
      getCountriesUseCase: sl(),
      getDepartmentsByCountryUseCase: sl(),
      getCitiesByDepartmentUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetCountriesUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => GetDepartmentsByCountryUseCase(repository: sl()),
  );
  sl.registerLazySingleton(
    () => GetCitiesByDepartmentUseCase(repository: sl()),
  );

  sl.registerLazySingleton<LocationsRepository>(
    () =>
        LocationsRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  sl.registerLazySingleton<LocationsRemoteDataSource>(
    () => LocationsRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<LocationsLocalDataSource>(
    () => LocationsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<TokenStorage>(
    () => TokenStorage(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ),
    ),
  );

  sl.registerLazySingleton<MicrosoftAuthService>(
    () => MicrosoftAuthService(logger: sl()),
  );

  sl.registerLazySingleton<AppleAuthService>(
    () => AppleAuthService(logger: sl()),
  );

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  final int connectTimeout = int.parse(dotenv.env['CONNECT_TIMEOUT'] ?? '60');
  final int receiveTimeout = int.parse(dotenv.env['RECEIVE_TIMEOUT'] ?? '60');
  final int sendTimeout = int.parse(dotenv.env['SEND_TIMEOUT'] ?? '60');

  sl.registerLazySingleton(() => Logger());

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: connectTimeout),
      receiveTimeout: Duration(seconds: receiveTimeout),
      sendTimeout: Duration(seconds: sendTimeout),
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(tokenStorage: sl<TokenStorage>(), dio: dio),
    ApiLogInterceptor(logger: sl<Logger>()),
  ]);

  sl.registerLazySingleton(() => dio);
  sl.registerLazySingleton(() => ApiClient(dio: dio, logger: sl<Logger>()));
}
