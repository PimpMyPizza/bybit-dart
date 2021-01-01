import 'package:logger/logger.dart';

/// Use the logger as a singleton to share the same log level everywhere
class LoggerSingleton extends Logger {
  factory LoggerSingleton() => LoggerSingleton._internal();
  LoggerSingleton._internal() : super(printer: SimplePrinter(colors: true));
}
