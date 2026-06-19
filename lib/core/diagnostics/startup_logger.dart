import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupLogger {
  StartupLogger._();

  static const _storageKey = 'startup_log_entries';
  static const _maxEntries = 80;
  static final Stopwatch _clock = Stopwatch()..start();
  static final List<String> _entries = <String>[];

  static SharedPreferences? _preferences;
  static Future<void>? _persistenceInit;

  static List<String> get entries => List.unmodifiable(_entries);

  static void mark(String message) {
    _write(message);
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    _write(
      'flutter error: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  }

  static void recordError(String message, Object error, StackTrace stackTrace) {
    _write('$message: $error', error: error, stackTrace: stackTrace);
  }

  static Future<void> initializePersistence() {
    return _persistenceInit ??= _initializePersistence();
  }

  static void _write(String message, {Object? error, StackTrace? stackTrace}) {
    final line =
        '${DateTime.now().toIso8601String()} '
        '+${_clock.elapsedMilliseconds}ms '
        '$message';

    _entries.add(line);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }

    debugPrint('[startup] $line');
    developer.log(
      message,
      name: 'WoW100Startup',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );

    unawaited(_persistEntries());
  }

  static Future<void> _initializePersistence() async {
    try {
      _preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      final storedEntries = _preferences?.getStringList(_storageKey) ?? [];
      if (storedEntries.isNotEmpty) {
        _entries.insertAll(0, storedEntries.take(_maxEntries));
      }
      await _persistEntries();
    } on Object catch (error, stackTrace) {
      developer.log(
        'startup log persistence unavailable',
        name: 'WoW100Startup',
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }
  }

  static Future<void> _persistEntries() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    await preferences.setStringList(_storageKey, _entries);
  }
}
