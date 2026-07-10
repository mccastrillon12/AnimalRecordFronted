import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await di.sl.reset();
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=http://localhost:3000
CONNECT_TIMEOUT=60
RECEIVE_TIMEOUT=60
SEND_TIMEOUT=60
GOOGLE_SERVER_CLIENT_ID=test-client-id
''',
    );
    await di.init();
  });

  tearDown(() => di.sl.reset());

  test('resuelve los gestores principales con todas sus dependencias', () {
    expect(di.sl<AuthBloc>(), isA<AuthBloc>());
    expect(di.sl<AnimalCubit>(), isA<AnimalCubit>());
    expect(di.sl<DiaryCubit>(), isA<DiaryCubit>());
    expect(di.sl<SharedFilesCubit>(), isA<SharedFilesCubit>());
  });
}
