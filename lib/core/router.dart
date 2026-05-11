import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_shell.dart';
import '../features/home/home_screen.dart';
import '../features/sessions/sessions_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/profile/profile_screen.dart';

GoRouter buildRouter({required Listenable refreshListenable}) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refreshListenable,
    routes: [
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
          GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
          GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
}
