import '../models/user_model.dart';

abstract class AuthRepository {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> register(String fullName, String email, String password, String signLanguage);
  Future<void> signOut();
  Future<User?> getCurrentUser();
}
