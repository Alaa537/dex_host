/// Console architecture intentionally uses POST /server/command only.
/// The supplied OpenAPI contract has no console log stream endpoint.
/// A WebSocket adapter can be added here later without changing the UI.
abstract class ConsoleStream { Stream<String> get output; Future<void> send(String command); Future<void> dispose(); }
