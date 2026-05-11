import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:english_coach/features/auth/auth_controller.dart';
import 'package:english_coach/features/auth/auth_repository.dart';

class _MockRepo extends Mock implements AuthRepository {}
class _FakeUser extends Fake implements User {
  @override
  String get id => 'u1';
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.authStateChanges()).thenAnswer((_) => const Stream.empty());
  });

  test('initial state yields repo.currentUser synchronously (null case)', () async {
    when(() => repo.currentUser).thenReturn(null);
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    // Subscribe to start the async* generator running.
    final sub = container.listen<AsyncValue<User?>>(
      authControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    // Drain microtasks until the async* generator emits its first yield.
    await pumpEventQueue();

    // AsyncData(null), NOT AsyncLoading — the initial yield must have fired.
    expect(
      container.read(authControllerProvider),
      equals(const AsyncData<User?>(null)),
    );
  });

  test('auth state change yields the new User', () async {
    when(() => repo.currentUser).thenReturn(null);
    final streamController = StreamController<AuthState>();
    when(() => repo.authStateChanges())
        .thenAnswer((_) => streamController.stream);
    addTearDown(streamController.close);

    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final user = _FakeUser();
    final session = Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: user,
    );

    // Subscribe so the async* generator starts running.
    final sub = container.listen<AsyncValue<User?>>(
      authControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    // Drain microtasks until the initial yield (null) is in AsyncData.
    await pumpEventQueue();
    expect(container.read(authControllerProvider), const AsyncData<User?>(null));

    // Push a signed-in AuthState and drain again.
    streamController.add(AuthState(AuthChangeEvent.signedIn, session));
    await pumpEventQueue();

    expect(container.read(authControllerProvider), AsyncData<User?>(user));
  });
}
