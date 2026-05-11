import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:english_coach/features/auth/auth_controller.dart';
import 'package:english_coach/features/auth/auth_repository.dart';
import 'package:english_coach/features/auth/profile_controller.dart';
import 'package:english_coach/features/auth/profile_repository.dart';
import 'package:english_coach/features/auth/profile_setup_screen.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}
class _MockProfileRepo extends Mock implements ProfileRepository {}
class _FakeUser extends Fake implements User {
  @override
  String get id => 'u1';
  @override
  String? get email => 'a@b.co';
}

void main() {
  late _MockAuthRepo authRepo;
  late _MockProfileRepo profileRepo;

  setUp(() {
    authRepo = _MockAuthRepo();
    profileRepo = _MockProfileRepo();
    when(() => authRepo.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    when(() => authRepo.currentUser).thenReturn(_FakeUser());
    when(() => profileRepo.fetchProfile(any())).thenAnswer((_) async => null);
  });

  Future<void> pumpScreen(WidgetTester tester) {
    return tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        profileRepositoryProvider.overrideWithValue(profileRepo),
      ],
      child: const MaterialApp(home: ProfileSetupScreen()),
    ));
  }

  testWidgets('submitting the form calls upsertProfile with chosen values',
      (tester) async {
    when(() => profileRepo.upsertProfile(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          nativeLanguage: any(named: 'nativeLanguage'),
          englishLevel: any(named: 'englishLevel'),
          dailyGoalMinutes: any(named: 'dailyGoalMinutes'),
        )).thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile_native_language')),
      'Spanish',
    );
    await tester.tap(find.byKey(const Key('profile_level_intermediate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_submit')));
    await tester.pump();

    verify(() => profileRepo.upsertProfile(
          userId: 'u1',
          email: 'a@b.co',
          nativeLanguage: 'Spanish',
          englishLevel: 'intermediate',
          dailyGoalMinutes: 10,
        )).called(1);
  });

  testWidgets('shows friendly error text when upsertProfile throws',
      (tester) async {
    when(() => profileRepo.upsertProfile(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          nativeLanguage: any(named: 'nativeLanguage'),
          englishLevel: any(named: 'englishLevel'),
          dailyGoalMinutes: any(named: 'dailyGoalMinutes'),
        )).thenThrow(const AuthException('Network down'));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile_native_language')),
      'Spanish',
    );
    await tester.tap(find.byKey(const Key('profile_level_intermediate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Network down'), findsOneWidget);
    expect(find.textContaining('AuthException('), findsNothing);
  });

  testWidgets('shows validation message when fields are empty',
      (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile_submit')));
    await tester.pump();

    expect(
      find.text('Please enter your native language and select an English level'),
      findsOneWidget,
    );
    verifyNever(() => profileRepo.upsertProfile(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          nativeLanguage: any(named: 'nativeLanguage'),
          englishLevel: any(named: 'englishLevel'),
          dailyGoalMinutes: any(named: 'dailyGoalMinutes'),
        ));
  });
}
