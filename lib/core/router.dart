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

/// Builds the app router.
///
/// The caller owns `refresh` and is responsible for `refresh.dispose()` after
/// the router itself is disposed. GoRouter does NOT dispose its `refreshListenable`
/// — if we created it inside this function, it would leak.
GoRouter buildAppRouter(WidgetRef ref, ValueNotifier<int> refresh) {
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.listen(currentProfileProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      // AsyncValue.value returns null for both AsyncError and AsyncData(null).
      // We deliberately treat a transient auth error the same as signed-out:
      // the user is sent to /sign-in. This is the safest fallback — if Supabase
      // is unreachable, requiring re-auth is preferable to silently leaving an
      // unauthenticated user on a gated screen.
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
