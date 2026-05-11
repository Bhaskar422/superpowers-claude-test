import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:english_coach/features/auth/auth_controller.dart';
import 'package:english_coach/features/auth/auth_repository.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.authStateChanges()).thenAnswer((_) => const Stream.empty());
  });

  test('initial state reflects repo.currentUser when null', () {
    when(() => repo.currentUser).thenReturn(null);
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    expect(container.read(authControllerProvider).value, isNull);
  });
}
