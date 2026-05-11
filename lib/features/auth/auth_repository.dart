import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class AuthRepository {
  final GoTrueClient _auth;

  AuthRepository({GoTrueClient? auth})
      : _auth = auth ?? AppSupabase.client.auth;

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) {
    return _auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Stream<AuthState> authStateChanges() => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;
}
