import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/secure_storage.dart';
import '../core/theme/app_theme.dart';
import 'providers.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/files/presentation/files_screen.dart';
import '../features/bots/presentation/bots_screen.dart';
import '../features/backups/presentation/backups_screen.dart';
import '../features/profile/presentation/more_screen.dart';
import '../features/admin/presentation/admin_screen.dart';

GoRouter createRouter(SecureStorage storage) => GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final token = await storage.readToken();
    final role = await storage.readRole();
    final path = state.uri.path;
    if (path == '/splash') return token == null ? '/login' : role == 'admin' ? '/admin' : '/home';
    if (token == null && !['/login', '/register'].contains(path)) return '/login';
    if (token != null && ['/login', '/register'].contains(path)) return role == 'admin' ? '/admin' : '/home';
    if (path.startsWith('/admin') && role != 'admin') return '/more';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const AuthScreen(register: false)),
    GoRoute(path: '/register', builder: (_, __) => const AuthScreen(register: true)),
    ShellRoute(builder: (_, __, child) => MainShell(child: child), routes: [
      GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/server', builder: (_, __) => const ServerScreen()),
      GoRoute(path: '/files', builder: (_, __) => const FilesScreen()),
      GoRoute(path: '/bots', builder: (_, __) => const BotsScreen()),
      GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
      GoRoute(path: '/backups', builder: (_, __) => const BackupsScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
    ]),
  ],
);

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: SafeArea(child: Column(children: [
        if (connection != ConnectionStatus.online) _ConnectionBanner(status: connection),
        Expanded(child: child),
      ])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(path),
        onDestinationSelected: (index) => GoRouter.of(context).go(['/home', '/server', '/files', '/bots', '/more'][index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.dns_outlined), selectedIcon: Icon(Icons.dns), label: 'Server'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Files'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'Bots'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.status});
  final ConnectionStatus status;
  @override
  Widget build(BuildContext context) {
    final reconnecting = status == ConnectionStatus.reconnecting || status == ConnectionStatus.connecting;
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), color: reconnecting ? AppTheme.warning.withValues(alpha: .16) : AppTheme.danger.withValues(alpha: .16), child: Row(children: [Icon(reconnecting ? Icons.sync : Icons.wifi_off, size: 16, color: reconnecting ? AppTheme.warning : AppTheme.danger), const SizedBox(width: 8), Text(reconnecting ? 'Connecting…' : 'Offline — retrying automatically', style: TextStyle(color: reconnecting ? AppTheme.warning : AppTheme.danger, fontSize: 12))]));
  }
}

int _index(String path) { if (path.startsWith('/server')) return 1; if (path.startsWith('/files')) return 2; if (path.startsWith('/bots')) return 3; if (path.startsWith('/more') || path.startsWith('/backups') || path.startsWith('/admin')) return 4; return 0; }
