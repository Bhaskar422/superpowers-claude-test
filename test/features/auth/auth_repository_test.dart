import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:english_coach/features/auth/auth_repository.dart';

class _MockGoTrueClient extends Mock implements GoTrueClient {}
class _FakeAuthResponse extends Fake implements AuthResponse {}

void main() {
  late _MockGoTrueClient auth;
  late AuthRepository repo;

  setUp(() {
    auth = _MockGoTrueClient();
    repo = AuthRepository(auth: auth);
  });

  test('signInWithPassword forwards email and password', () async {
    when(() => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _FakeAuthResponse());

    await repo.signIn(email: 'a@b.co', password: 'pw');

    verify(() => auth.signInWithPassword(email: 'a@b.co', password: 'pw'))
        .called(1);
  });

  test('signUp forwards email and password', () async {
    when(() => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _FakeAuthResponse());

    await repo.signUp(email: 'a@b.co', password: 'pw');

    verify(() => auth.signUp(email: 'a@b.co', password: 'pw')).called(1);
  });

  test('signOut calls the underlying client', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});
    await repo.signOut();
    verify(() => auth.signOut()).called(1);
  });
}
