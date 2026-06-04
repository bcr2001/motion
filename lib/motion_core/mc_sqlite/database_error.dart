import 'package:motion/motion_reusable/general_reuseable.dart';

Never logDatabaseError(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  logger.e('Database operation failed: $operation', error, stackTrace);
  Error.throwWithStackTrace(error, stackTrace);
}
