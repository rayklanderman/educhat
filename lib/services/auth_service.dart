import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': 'user',
      },
    );

    if (response.user != null) {
      // Create user profile in users table
      await _supabase.from(SupabaseConfig.users).insert({
        'user_id': response.user!.id,
        'email': email,
        'name': fullName,
        'role': 'user',
      });
    }

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update user profile
  Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    if (currentUser == null) return;

    await _supabase.from(SupabaseConfig.users).update({
      'name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('user_id', currentUser!.id);
  }

  // Stream of auth changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}
