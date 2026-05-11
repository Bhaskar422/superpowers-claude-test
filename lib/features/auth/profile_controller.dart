import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).fetchProfile(user.id);
});
