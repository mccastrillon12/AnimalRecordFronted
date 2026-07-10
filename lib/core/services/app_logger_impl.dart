import 'package:animal_record/core/services/app_logger.dart';
import 'package:logger/logger.dart';

class AppLoggerImpl implements AppLogger {
  final Logger logger;

  const AppLoggerImpl(this.logger);

  @override
  void error(String message) => logger.e(message);

  @override
  void warning(String message) => logger.w(message);
}
