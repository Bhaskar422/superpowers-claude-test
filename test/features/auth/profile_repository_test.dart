import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:english_coach/features/auth/profile_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockBuilder extends Mock implements SupabaseQueryBuilder {}

/// A Fake that satisfies the PostgrestFilterBuilder<dynamic> type while
/// being immediately awaitable (resolves to null).
class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  final Future<dynamic> _inner = Future.value(null);

  @override
  Future<U> then<U>(FutureOr<U> Function(dynamic) onValue,
          {Function? onError}) =>
      _inner.then(onValue, onError: onError);

  @override
  Future<dynamic> catchError(Function onError,
          {bool Function(Object)? test}) =>
      _inner.catchError(onError, test: test);

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) =>
      _inner.whenComplete(action);

  @override
  Future<dynamic> timeout(Duration timeLimit,
          {FutureOr<dynamic> Function()? onTimeout}) =>
      _inner.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<dynamic> asStream() => _inner.asStream();
}

void main() {
  late _MockClient client;
  late _MockBuilder builder;
  late ProfileRepository repo;

  setUp(() {
    client = _MockClient();
    builder = _MockBuilder();
    when(() => client.from('users')).thenAnswer((_) => builder);
    repo = ProfileRepository(client: client);
  });

  test('upsertProfile sends the right columns', () async {
    when(() => builder.upsert(any())).thenAnswer((_) => _FakeFilterBuilder());

    await repo.upsertProfile(
      userId: 'u1',
      email: 'a@b.co',
      displayName: 'Alex',
      nativeLanguage: 'es',
      englishLevel: 'intermediate',
      dailyGoalMinutes: 15,
    );

    final captured = verify(() => builder.upsert(captureAny())).captured.single
        as Map<String, dynamic>;
    expect(captured['id'], 'u1');
    expect(captured['email'], 'a@b.co');
    expect(captured['display_name'], 'Alex');
    expect(captured['native_language'], 'es');
    expect(captured['english_level'], 'intermediate');
    expect(captured['daily_goal_minutes'], 15);
  });
}
