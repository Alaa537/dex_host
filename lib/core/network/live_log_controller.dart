import 'dart:async';
import 'package:flutter/foundation.dart';
import 'repository.dart';

enum LiveLogConnection { connecting, live, reconnecting, offline }
enum LogLevel { all, info, success, warning, error, debug }

class LogLine {
  const LogLine(this.text);
  final String text;
  LogLevel get level {
    final value = text.toLowerCase();
    if (value.contains('error') || value.contains('exception') || value.contains('traceback') || value.contains('fatal')) return LogLevel.error;
    if (value.contains('warning') || value.contains('warn')) return LogLevel.warning;
    if (value.contains('success') || value.contains('started') || value.contains('connected') || value.contains('ready')) return LogLevel.success;
    if (value.contains('debug')) return LogLevel.debug;
    return LogLevel.info;
  }
}

class LiveLogState {
  const LiveLogState({this.lines = const [], this.connection = LiveLogConnection.connecting, this.paused = false, this.lastError});
  final List<LogLine> lines;
  final LiveLogConnection connection;
  final bool paused;
  final String? lastError;
  LiveLogState copyWith({List<LogLine>? lines, LiveLogConnection? connection, bool? paused, String? lastError}) => LiveLogState(
    lines: lines ?? this.lines,
    connection: connection ?? this.connection,
    paused: paused ?? this.paused,
    lastError: lastError,
  );
}

/// Reliable log controller for the current DEX Host backend.
/// The current OpenAPI exposes HTTP log history, not a WebSocket log endpoint,
/// so polling is used as the source of truth. A future WS transport can be
/// added without changing the screen API.
class LiveLogController extends ChangeNotifier {
  LiveLogController({required this.file, required this.repository});
  final String file;
  final HostingRepository repository;

  LiveLogState _state = const LiveLogState();
  LiveLogState get state => _state;

  Timer? _timer;
  bool _started = false;
  bool _disposed = false;
  bool _refreshing = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _set(connection: LiveLogConnection.connecting);
    await refresh();
    if (_disposed) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => unawaited(refresh()));
  }

  Future<void> refresh() async {
    if (_disposed || _refreshing) return;
    _refreshing = true;
    try {
      final text = await repository.botLogs(file, lines: 2000);
      final lines = text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map(LogLine.new)
          .toList(growable: false);
      _set(lines: lines, connection: LiveLogConnection.live, lastError: null);
    } catch (error) {
      _set(connection: LiveLogConnection.offline, lastError: error.toString());
    } finally {
      _refreshing = false;
    }
  }

  void pause() => _set(paused: true);
  void resume() => _set(paused: false);
  void clearView() => _set(lines: const []);

  Future<void> clearServer() async {
    await repository.clearBotLogs(file);
    clearView();
    await refresh();
  }

  Future<void> restart() => repository.restartBot(file);

  List<LogLine> visibleLines({LogLevel filter = LogLevel.all, String search = ''}) {
    final query = search.trim().toLowerCase();
    return _state.lines.where((line) {
      final levelOk = filter == LogLevel.all || line.level == filter;
      final searchOk = query.isEmpty || line.text.toLowerCase().contains(query);
      return levelOk && searchOk;
    }).toList(growable: false);
  }

  void _set({List<LogLine>? lines, LiveLogConnection? connection, bool? paused, String? lastError}) {
    if (_disposed) return;
    _state = _state.copyWith(lines: lines, connection: connection, paused: paused, lastError: lastError);
    if (!_state.paused || connection != null) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
