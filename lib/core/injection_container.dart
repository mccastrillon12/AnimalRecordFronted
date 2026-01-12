import 'package:animal_record/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:animal_record/features/auth/domain/repositories/auth_repository.dart';
import 'package:animal_record/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:animal_record/features/auth/domain/usecases/register_usecase.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth

  // Bloc
  sl.registerFactory(() => AuthBloc(registerUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  //! Core & External

  // Get configuration from environment variables
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  final int connectTimeout = int.parse(dotenv.env['CONNECT_TIMEOUT'] ?? '60');
  final int receiveTimeout = int.parse(dotenv.env['RECEIVE_TIMEOUT'] ?? '60');
  final int sendTimeout = int.parse(dotenv.env['SEND_TIMEOUT'] ?? '60');

  sl.registerLazySingleton(
    () => Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: connectTimeout),
        receiveTimeout: Duration(seconds: receiveTimeout),
        sendTimeout: Duration(seconds: sendTimeout),
      ),
    ),
  );
}
