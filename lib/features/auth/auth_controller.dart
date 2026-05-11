import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider =
    StreamProvider<User?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield repo.currentUser;
  await for (final state in repo.authStateChanges()) {
    yield state.session?.user;
  }
});
