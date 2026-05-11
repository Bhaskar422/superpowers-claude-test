import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
    when(() => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {});
  });

  testWidgets('submits email + password to AuthRepository.signIn',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: SignInScreen()),
    ));

    await tester.enterText(find.byKey(const Key('signin_email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('signin_password')), 'pw');
    await tester.tap(find.byKey(const Key('signin_submit')));
    await tester.pump();

    verify(() => repo.signIn(email: 'a@b.co', password: 'pw')).called(1);
  });
}
