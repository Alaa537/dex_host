import 'package:flutter_test/flutter_test.dart';
import 'package:dex_host/core/models/models.dart';
import 'package:dex_host/core/network/live_log_controller.dart';

void main() {
  test('server model parses resources', () {
    final server = ServerModel.fromJson({'name': 'P10', 'state': 'running', 'resources': {'memory_bytes': 1024, 'cpu_absolute': 12.5, 'disk_bytes': 2048, 'uptime': 3660}});
    expect(server.running, true);
    expect(server.resources.cpu, 12.5);
    expect(bytesText(1024), '1.0 KB');
    expect(uptimeText(3660), '1h 1m');
  });
  test('bot model parses status metadata', () {
    final bot = BotModel.fromJson({'file': 'bot.py', 'enabled': true, 'state': 'Running', 'env_keys': ['TOKEN'], 'restarts': 3});
    expect(bot.file, 'bot.py');
    expect(bot.state, 'Running');
    expect(bot.restarts, 3);
    expect(bot.envKeys.single, 'TOKEN');
  });
  test('profile and admin stats parse safely', () {
    final profile = UserProfile.fromJson({'id': 1, 'username': 'user', 'role': 'user', 'days_left': 30, 'max_bots': 5, 'has_server': true});
    final stats = AdminStats.fromJson({'users': 10, 'pool_total': 4, 'pool_free': 2, 'registration': true});
    expect(profile.username, 'user');
    expect(profile.daysLeft, 30);
    expect(stats.poolFree, 2);
    expect(stats.registration, true);
  });
  test('live log levels are detected from plain text', () {
    expect(const LogLine('ERROR: connection failed').level, LogLevel.error);
    expect(const LogLine('WARNING: slow response').level, LogLevel.warning);
    expect(const LogLine('SUCCESS Connected').level, LogLevel.success);
    expect(const LogLine('DEBUG payload').level, LogLevel.debug);
  });
}
