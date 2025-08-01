import 'dart:developer' as developer;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class Logger {
  static const String _tag = 'PennyWise';
  static const bool _enableConsoleLogging = false; // Disable console logging
  static const bool _enableFileLogging = true; // Enable file logging
  static File? _logFile;
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  /// Initialize the logger and create log file
  static Future<void> initialize() async {
    if (!_enableFileLogging) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/pennywise_logs');

      // Create logs directory if it doesn't exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Create log file with current date
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/pennywise_$today.log');

      // Write initial log entry
      await _writeToFile(
        'INFO',
        'Logger',
        'Logger initialized - File: ${_logFile!.path}',
      );
    } catch (e) {
      // Fallback to console if file logging fails
      print('Failed to initialize file logging: $e');
    }
  }

  /// Write log entry to file
  static Future<void> _writeToFile(
    String level,
    String tag,
    String message,
  ) async {
    if (!_enableFileLogging || _logFile == null) return;

    try {
      final timestamp = _dateFormat.format(DateTime.now());
      final logEntry = '[$timestamp] [$level] [$tag] $message\n';

      await _logFile!.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // Silent fail - don't spam console with file errors
    }
  }

  /// Log info message
  static void info(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    if (_enableConsoleLogging) {
      developer.log(message, name: logTag, level: 800);
    }
    _writeToFile('INFO', logTag, message);
  }

  /// Log debug message
  static void debug(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    if (_enableConsoleLogging) {
      developer.log(message, name: logTag, level: 700);
    }
    _writeToFile('DEBUG', logTag, message);
  }

  /// Log warning message
  static void warning(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    if (_enableConsoleLogging) {
      developer.log(message, name: logTag, level: 900);
    }
    _writeToFile('WARN', logTag, message);
  }

  /// Log error message
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logTag = tag ?? _tag;
    final fullMessage = error != null
        ? '$message - Error: $error${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}'
        : message;

    if (_enableConsoleLogging) {
      developer.log(
        message,
        name: logTag,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
    _writeToFile('ERROR', logTag, fullMessage);
  }

  /// Log success message
  static void success(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    final successMessage = '✅ $message';
    if (_enableConsoleLogging) {
      developer.log(successMessage, name: logTag, level: 800);
    }
    _writeToFile('SUCCESS', logTag, successMessage);
  }

  /// Log API request
  static void apiRequest(String method, String url, {String? tag}) {
    final logTag = tag ?? '${_tag}.API';
    final message = '📤 $method $url';
    if (_enableConsoleLogging) {
      developer.log(message, name: logTag, level: 700);
    }
    _writeToFile('API_REQ', logTag, message);
  }

  /// Log API response
  static void apiResponse(int statusCode, {String? tag, String? body}) {
    final logTag = tag ?? '${_tag}.API';
    final emoji = statusCode >= 200 && statusCode < 300 ? '📥' : '❌';
    final message = body != null
        ? '$emoji Response: $statusCode - ${body.length > 200 ? '${body.substring(0, 200)}...' : body}'
        : '$emoji Response: $statusCode';

    if (_enableConsoleLogging) {
      developer.log(
        message,
        name: logTag,
        level: statusCode >= 200 && statusCode < 300 ? 700 : 1000,
      );
    }
    _writeToFile(
      statusCode >= 200 && statusCode < 300 ? 'API_RESP' : 'API_ERROR',
      logTag,
      message,
    );
  }

  /// Log process start
  static void processStart(String process, {String? tag}) {
    final logTag = tag ?? _tag;
    final message = '🔄 Starting $process...';
    if (_enableConsoleLogging) {
      developer.log(message, name: logTag, level: 800);
    }
    _writeToFile('PROCESS', logTag, message);
  }

  /// Log process completion
  static void processComplete(String process, {String? tag}) {
    final logTag = tag ?? _tag;
    final message = '✅ $process completed successfully';
    if (_enableConsoleLogging) {
      developer.log(message, name: logTag, level: 800);
    }
    _writeToFile('PROCESS', logTag, message);
  }

  /// Log data information
  static void data(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    final dataMessage = '📋 $message';
    if (_enableConsoleLogging) {
      developer.log(dataMessage, name: logTag, level: 700);
    }
    _writeToFile('DATA', logTag, dataMessage);
  }

  /// Log validation result
  static void validation(bool isValid, String message, {String? tag}) {
    final logTag = tag ?? '${_tag}.Validation';
    final emoji = isValid ? '✅' : '❌';
    final validationMessage = '$emoji $message';
    if (_enableConsoleLogging) {
      developer.log(
        validationMessage,
        name: logTag,
        level: isValid ? 800 : 1000,
      );
    }
    _writeToFile(
      isValid ? 'VALIDATION' : 'VALIDATION_ERROR',
      logTag,
      validationMessage,
    );
  }

  /// Get current log file path
  static String? get currentLogFilePath => _logFile?.path;

  /// Get logs directory path
  static Future<String?> getLogsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/pennywise_logs';
    } catch (e) {
      return null;
    }
  }

  /// Clear old log files (keep only last 7 days)
  static Future<void> clearOldLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/pennywise_logs');

      if (!await logDir.exists()) return;

      final files = await logDir.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > 7) {
            await file.delete();
            _writeToFile(
              'INFO',
              'Logger',
              'Deleted old log file: ${file.path}',
            );
          }
        }
      }
    } catch (e) {
      _writeToFile('ERROR', 'Logger', 'Failed to clear old logs: $e');
    }
  }
}
