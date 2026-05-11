import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:english_coach/core/router.dart';
import 'package:english_coach/features/auth/auth_controller.dart';
import 'package:english_coach/features/auth/auth_repository.dart';
import 'package:english_coach/features/auth/profile_controller.dart';
import 'package:english_coach/features/auth/profile_repository.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}
class _MockProfileRepo extends Mock implements ProfileRepository {}
class _FakeUser extends Fake implements User {
  @override
  String get id => 'u1';
  @override
  String? get email => 'a@b.co';
}

ProviderScope _app({
  required AuthRepository authRepo,
  required ProfileRepository profileRepo,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      profileRepositoryProvider.overrideWithValue(profileRepo),
    ],
    child: const _Host(),
  );
}

class _Host extends ConsumerStatefulWidget {
  const _Host();
  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> {
  late final GoRouter _router = buildAppRouter(ref);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}

void main() {
  late _MockAuthRepo auth;
  late _MockProfileRepo prof;

  setUp(() {
    auth = _MockAuthRepo();
    prof = _MockProfileRepo();
    when(() => auth.authStateChanges()).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('unauthenticated user lands on /sign-in', (tester) async {
    when(() => auth.currentUser).thenReturn(null);
    when(() => prof.fetchProfile(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(_app(authRepo: auth, profileRepo: prof));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsAtLeastNWidgets(1));
  });

  testWidgets('signed-in user with no profile lands on /profile-setup',
      (tester) async {
    when(() => auth.currentUser).thenReturn(_FakeUser());
    when(() => prof.fetchProfile(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(_app(authRepo: auth, profileRepo: prof));
    await tester.pumpAndSettle();

    expect(find.text('Welcome!'), findsOneWidget);
  });

  testWidgets('signed-in user with complete profile lands on /home',
      (tester) async {
    when(() => auth.currentUser).thenReturn(_FakeUser());
    when(() => prof.fetchProfile(any())).thenAnswer((_) async => const UserProfile(
          id: 'u1',
          email: 'a@b.co',
          displayName: null,
          nativeLanguage: 'Spanish',
          englishLevel: 'intermediate',
          dailyGoalMinutes: 10,
          isPaid: false,
          trialSessionsUsed: 0,
        ));

    await tester.pumpWidget(_app(authRepo: auth, profileRepo: prof));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
