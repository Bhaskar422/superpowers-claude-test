import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:english_coach/features/auth/auth_repository.dart';
import 'package:english_coach/features/auth/auth_controller.dart';
import 'package:english_coach/features/auth/sign_in_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.authStateChanges()).thenAnswer((_) => const Stream.empty());
    when(() => repo.currentUser).thenReturn(null);
  });

  Future<void> pumpScreen(WidgetTester tester) {
    return tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: SignInScreen()),
    ));
  }

  testWidgets('submits email + password to AuthRepository.signIn',
      (tester) async {
    when(() => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.enterText(find.byKey(const Key('signin_email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('signin_password')), 'pw');
    await tester.tap(find.byKey(const Key('signin_submit')));
    await tester.pump();

    verify(() => repo.signIn(email: 'a@b.co', password: 'pw')).called(1);
  });

  testWidgets('shows friendly error text when signIn throws AuthException',
      (tester) async {
    when(() => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const AuthException('Invalid login credentials'));

    await pumpScreen(tester);
    await tester.enterText(find.byKey(const Key('signin_email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('signin_password')), 'wrong');
    await tester.tap(find.byKey(const Key('signin_submit')));
    await tester.pumpAndSettle();

    // User sees AuthException.message, NOT the raw toString().
    expect(find.text('Invalid login credentials'), findsOneWidget);
    expect(find.textContaining('AuthException('), findsNothing);
  });
}
