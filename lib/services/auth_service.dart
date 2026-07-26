import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String contactNumber,
    required String barangay,
    required UserRole role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userProfile = UserModel(
          uid: response.user!.id,
          email: email,
          fullName: fullName,
          contactNumber: contactNumber,
          barangay: barangay,
          role: role,
          createdAt: DateTime.now(),
        );

        await _client.from('users').insert(userProfile.toJson());

        return userProfile;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await getUserProfile(response.user!.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final response =
          await _client.from('users').select().eq('uid', uid).single();

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    if (currentUserId == null) return null;
    return getUserProfile(currentUserId!);
  }

  Future<void> updateProfile(UserModel user) async {
    await _client
        .from('users')
        .update(user.toJson())
        .eq('uid', user.uid);
  }

  Future<void> updateResponderStatus(ResponderStatus status) async {
    if (currentUserId == null) return;
    await _client.from('users').update({
      'responder_status': status.name,
    }).eq('uid', currentUserId!);
  }
}
