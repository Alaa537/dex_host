import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/repository.dart';
import '../core/network/live_log_controller.dart';
import '../core/storage/secure_storage.dart';
import '../core/models/models.dart';

enum ConnectionStatus { connecting, online, offline, reconnecting }

final connectionProvider = StateNotifierProvider<ConnectionController, ConnectionStatus>((_) => ConnectionController());

class ConnectionController extends StateNotifier<ConnectionStatus> {
  ConnectionController() : super(ConnectionStatus.connecting) {
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
    unawaited(_check());
  }
  final connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Future<void> _check() async { _update(await connectivity.checkConnectivity()); }
  void _update(List<ConnectivityResult> result) { state = result.any((item) => item != ConnectivityResult.none) ? ConnectionStatus.online : ConnectionStatus.offline; }
  @override void dispose() { _subscription?.cancel(); super.dispose(); }
}

final storageProvider = Provider<SecureStorage>((_) => SecureStorage());
final apiProvider = Provider<ApiClient>((r) => ApiClient(r.read(storageProvider)));
final repositoryProvider = Provider<HostingRepository>((r) => HostingRepository(r.read(apiProvider)));
final authProvider = StateNotifierProvider<AuthController, AuthState>((r) => AuthController(r.read(repositoryProvider), r.read(storageProvider)));
final profileProvider = FutureProvider.autoDispose<UserProfile>((r) => r.read(repositoryProvider).me());
final serverProvider = FutureProvider.autoDispose<ServerModel>((r) => r.read(repositoryProvider).server());
final serverResourcesProvider = FutureProvider.autoDispose<ServerResources>((r) => r.read(repositoryProvider).serverResources());
final processesProvider = FutureProvider.autoDispose<List<ProcessModel>>((r) => r.read(repositoryProvider).processes());
final announcementsProvider = FutureProvider.autoDispose<List<AnnouncementModel>>((r) => r.read(repositoryProvider).announcements());
final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((r) => r.read(repositoryProvider).notifications());
final filesProvider = FutureProvider.family.autoDispose<List<FileModel>, String>((r, dir) => r.read(repositoryProvider).files(dir));
final botsProvider = FutureProvider.autoDispose<List<BotModel>>((r) {
  final timer = Timer.periodic(const Duration(seconds: 10), (_) => r.invalidateSelf());
  r.onDispose(timer.cancel);
  return r.read(repositoryProvider).bots();
});
final backupsProvider = FutureProvider.autoDispose<List<BackupModel>>((r) => r.read(repositoryProvider).backups());
final backupPolicyProvider = FutureProvider.autoDispose<BackupPolicy>((r) => r.read(repositoryProvider).backupPolicy());
final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((r) => r.read(repositoryProvider).adminStats());
final liveLogProvider = ChangeNotifierProvider.autoDispose.family<LiveLogController, String>((ref, file) {
  final controller = LiveLogController(file: file, repository: ref.read(repositoryProvider));
  unawaited(controller.start());
  return controller;
});

class AuthState {
  const AuthState({this.loading = false, this.authenticated = false, this.role = 'user', this.username = '', this.error, this.profile});
  final bool loading, authenticated;
  final String role, username;
  final String? error;
  final UserProfile? profile;
  AuthState copyWith({bool? loading, bool? authenticated, String? role, String? username, String? error, UserProfile? profile}) => AuthState(loading: loading ?? this.loading, authenticated: authenticated ?? this.authenticated, role: role ?? this.role, username: username ?? this.username, error: error, profile: profile ?? this.profile);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.repo, this.storage) : super(const AuthState(loading: true)) { restore(); }
  final HostingRepository repo;
  final SecureStorage storage;
  Future<void> restore() async { final token = await storage.readToken(); if (token == null) { state = const AuthState(authenticated: false); return; } try { final profile = await repo.me(); state = AuthState(authenticated: true, role: profile.role, username: profile.username, profile: profile); await storage.saveSession(token: token, role: profile.role, username: profile.username); } catch (_) { await storage.clear(); state = const AuthState(authenticated: false); } }
  Future<bool> login(String username, String password) async { state = state.copyWith(loading: true, error: null); try { final session = await repo.login(username, password); await storage.saveSession(token: session.token, role: session.role, username: username); UserProfile? profile; try { profile = await repo.me(); } catch (_) {} state = AuthState(authenticated: true, role: session.role, username: username, profile: profile); return true; } catch (e) { state = state.copyWith(loading: false, error: e.toString()); return false; } }
  Future<bool> register(String username, String password, String invite) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final session = await repo.register(username, password, invite);
      // The backend may return {status: "pending"} with no token.
      // Never save an empty token as an authenticated session.
      if (session.token.trim().isEmpty) {
        state = const AuthState(
          authenticated: false,
          loading: false,
          error: 'تم إرسال طلب التسجيل إلى الأدمن. انتظر الموافقة قبل تسجيل الدخول.',
        );
        return false;
      }
      await storage.saveSession(token: session.token, role: session.role, username: username);
      state = AuthState(authenticated: true, role: session.role, username: username);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
  Future<void> logout() async { await storage.clear(); state = const AuthState(authenticated: false); }
  Future<void> logoutAll() async { try { await repo.logoutAll(); } finally { await logout(); } }
}
