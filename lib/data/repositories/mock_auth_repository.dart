import '../models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  
  // In-memory mock token storage is approved.
  String? _mockToken;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'test@example.com' && password == 'password123') {
      _currentUser = User(
        id: '12345',
        email: email,
        name: 'Test User',
      );
      _mockToken = 'mock_jwt_token_12345';
      return _currentUser!;
    } else {
      throw Exception('Invalid email or password');
    }
  }

  @override
  Future<User> register(String fullName, String email, String password, String signLanguage) async {
    await Future.delayed(const Duration(seconds: 2));
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: fullName,
    );
    _mockToken = 'mock_jwt_token_${_currentUser!.id}';
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _mockToken = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    // Simulate checking secure storage for a token
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockToken != null ? _currentUser : null;
  }
}
