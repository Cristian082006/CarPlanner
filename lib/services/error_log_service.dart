import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Jurnal de erori strict local — nicio linie nu părăsește dispozitivul
/// automat. Scrie într-un fișier text din storage-ul aplicației, pe care
/// utilizatorul îl poate trimite manual (din ecranul de Feedback) atașat la
/// un email, exact ca orice alt document din aplicație. Nu există niciun
/// serviciu extern (Crashlytics etc.) — decizie explicită, vezi CLAUDE.md.
class ErrorLogService {
  ErrorLogService._();
  static final ErrorLogService instance = ErrorLogService._();

  static const _maxEntries = 100;
  File? _file;

  Future<File> _logFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/error_log.txt');
    return _file!;
  }

  void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(_append('FlutterError', details.exceptionAsString(), details.stack));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(_append('Uncaught', error.toString(), stack));
      return true;
    };
  }

  Future<void> _append(String source, String message, StackTrace? stack) async {
    try {
      final file = await _logFile();
      final entry =
          '--- ${DateTime.now().toIso8601String()} [$source] ---\n$message\n${stack ?? ''}\n';
      final existing = await file.exists() ? await file.readAsString() : '';
      final entries = existing.split('--- ').where((e) => e.trim().isNotEmpty).toList();
      entries.add(entry.replaceFirst('--- ', ''));
      final trimmed = entries.length > _maxEntries
          ? entries.sublist(entries.length - _maxEntries)
          : entries;
      await file.writeAsString(trimmed.map((e) => '--- $e').join());
    } catch (_) {
      // Logarea erorilor nu trebuie ea însăși să arunce o eroare nouă.
    }
  }

  void logZoneError(Object error, StackTrace stack) {
    unawaited(_append('ZoneError', error.toString(), stack));
  }

  Future<bool> hasEntries() async {
    final file = await _logFile();
    if (!await file.exists()) return false;
    return (await file.length()) > 0;
  }

  Future<File> exportFile() async => _logFile();

  Future<void> clear() async {
    final file = await _logFile();
    if (await file.exists()) await file.delete();
  }
}
