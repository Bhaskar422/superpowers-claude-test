import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/profile_controller.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/home/home_shell.dart';
import '../features/home/home_screen.dart';
import '../features/sessions/sessions_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/profile/profile_screen.dart';

GoRouter buildAppRouter(WidgetRef ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.listen(currentProfileProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authValue = ref.read(authControllerProvider);
      final user = authValue.value;
      final goingToAuth = state.matchedLocation == '/sign-in' ||
                          state.matchedLocation == '/sign-up';

      if (user == null) {
        return goingToAuth ? null : '/sign-in';
      }

      // Signed in. Check profile.
      final profileValue = ref.read(currentProfileProvider);
      // While the profile is loading the first time, allow the current route.
      if (profileValue.isLoading) return null;

      final profile = profileValue.value;
      final goingToProfileSetup = state.matchedLocation == '/profile-setup';

      if (profile == null || !profile.isComplete) {
        return goingToProfileSetup ? null : '/profile-setup';
      }
      if (goingToAuth || goingToProfileSetup) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in',       builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/sign-up',       builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
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
