import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const tokenKey = 'dex_host_jwt';
  static const roleKey = 'dex_host_role';
  static const usernameKey = 'dex_host_username';

  Future<void> saveSession({required String token, required String role, String? username}) async {
    await _storage.write(key: tokenKey, value: token);
    await _storage.write(key: roleKey, value: role);
    if (username != null) await _storage.write(key: usernameKey, value: username);
  }
  Future<String?> readToken() => _storage.read(key: tokenKey);
  Future<String?> readRole() => _storage.read(key: roleKey);
  Future<String?> readUsername() => _storage.read(key: usernameKey);
  Future<void> clear() => _storage.deleteAll();
}
