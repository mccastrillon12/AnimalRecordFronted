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
import 'package:animal_record/features/auth/domain/usecases/check_social_auth_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/register_social_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/get_user_profile_usecase.dart';

import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:animal_record/features/locations/data/datasources/locations_remote_datasource.dart';
import 'package:animal_record/features/locations/data/repositories/locations_repository_impl.dart';
import 'package:animal_record/features/locations/domain/repositories/locations_repository.dart';
import 'package:animal_record/features/locations/domain/usecases/get_countries_usecase.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';

import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      registerUseCase: sl(),
      loginUseCase: sl(),
      verifyCodeUseCase: sl(),
      resendCodeUseCase: sl(),
      checkIdentificationExistsUseCase: sl(),
      checkSocialAuthUseCase: sl(),
      registerSocialUseCase: sl(),
      getUserProfileUseCase: sl(),
      tokenStorage: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => VerifyCodeUseCase(sl()));
  sl.registerLazySingleton(() => ResendCodeUseCase(sl()));
  sl.registerLazySingleton(() => CheckIdentificationExistsUseCase(sl()));
  sl.registerLazySingleton(() => CheckSocialAuthUseCase(sl()));
  sl.registerLazySingleton(() => RegisterSocialUseCase(sl()));
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), tokenStorage: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  //! Features - Locations

  // Cubit
  sl.registerFactory(() => LocationsCubit(getCountriesUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetCountriesUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<LocationsRepository>(
    () => LocationsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<LocationsRemoteDataSource>(
    () => LocationsRemoteDataSourceImpl(dio: sl()),
  );

  //! Core & External

  // Token Storage
  sl.registerLazySingleton<TokenStorage>(
    () => TokenStorage(const FlutterSecureStorage()),
  );

  // Get configuration from environment variables
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  final int connectTimeout = int.parse(dotenv.env['CONNECT_TIMEOUT'] ?? '60');
  final int receiveTimeout = int.parse(dotenv.env['RECEIVE_TIMEOUT'] ?? '60');
  final int sendTimeout = int.parse(dotenv.env['SEND_TIMEOUT'] ?? '60');

  // Dio instance
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: connectTimeout),
      receiveTimeout: Duration(seconds: receiveTimeout),
      sendTimeout: Duration(seconds: sendTimeout),
    ),
  );

  // Add Auth Interceptor
  dio.interceptors.add(
    AuthInterceptor(tokenStorage: sl<TokenStorage>(), dio: dio),
  );

  sl.registerLazySingleton(() => dio);

  // Logger
  sl.registerLazySingleton(() => Logger());
}
