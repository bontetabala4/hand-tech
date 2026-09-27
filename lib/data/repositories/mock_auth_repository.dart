import '../models/user_model.dart';
import '../services/secure_storage_service.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final SecureStorageService? _storageService;
  User? _currentUser;
  String? _mockToken;

  MockAuthRepository({SecureStorageService? storageService})
      : _storageService = storageService;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email == 'test@example.com' && password == 'password123') {
      _currentUser = User(
        id: '12345',
        email: email,
        name: 'Test User',
      );
      _mockToken = 'mock_jwt_token_12345';
      if (_storageService != null) {
        await _storageService!.saveAuthToken(_mockToken!);
        await _storageService!.saveUserProfile(_currentUser!);
      }
      return _currentUser!;
    } else {
      throw Exception('Invalid email or password');
    }
  }

  @override
  Future<User> register(String fullName, String email, String password, String signLanguage) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: fullName,
    );
    _mockToken = 'mock_jwt_token_${_currentUser!.id}';
    if (_storageService != null) {
      await _storageService!.saveAuthToken(_mockToken!);
      await _storageService!.saveUserProfile(_currentUser!);
    }
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _mockToken = null;
    if (_storageService != null) {
      await _storageService!.clearAll();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_storageService != null) {
      final token = await _storageService!.getAuthToken();
      final user = await _storageService!.getUserProfile();
      if (token != null && user != null) {
        _mockToken = token;
        _currentUser = user;
        return user;
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockToken != null ? _currentUser : null;
  }
}
