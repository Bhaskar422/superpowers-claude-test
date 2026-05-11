import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider =
    StreamProvider<User?>((ref) async* {
  // ref.read (not watch): the async* generator runs once and suspends at
  // `await for`. Riverpod cannot re-enter mid-stream if the repo provider
  // changes, so a reactive dependency here would be misleading.
  final repo = ref.read(authRepositoryProvider);
  yield repo.currentUser;
  await for (final state in repo.authStateChanges()) {
    yield state.session?.user;
  }
});
