import 'dart:async';

import 'package:animal_record/features/auth/domain/services/session_state_cleaner.dart';

class CallbackSessionStateCleaner implements SessionStateCleaner {
  final FutureOr<void> Function() onClear;

  const CallbackSessionStateCleaner(this.onClear);

  @override
  Future<void> clear() async => onClear();
}
