import 'package:web_socket_channel/web_socket_channel.dart';
import '../../app/config.dart';

class WebSocketConnection {
  WebSocketConnection(this.channel);
  final WebSocketChannel channel;
  Stream<dynamic> get stream => channel.stream;
  Future<void> close() async { await channel.sink.close(); }

  static Future<WebSocketConnection> open({required String token, required String bot}) async {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final uri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/logs',
      queryParameters: {'token': token, 'bot': bot},
    );
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    return WebSocketConnection(channel);
  }
}
