import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

abstract class SecureStorageService {
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> deleteAuthToken();
  Future<void> saveUserProfile(User user);
  Future<User?> getUserProfile();
  Future<void> clearAll();
}

class FlutterSecureStorageService implements SecureStorageService {
  static const String _authTokenKey = 'auth_jwt_token';
  static const String _userProfileKey = 'user_profile_json';

  final FlutterSecureStorage _storage;

  FlutterSecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  @override
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  @override
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  @override
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  @override
  Future<void> saveUserProfile(User user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _storage.write(key: _userProfileKey, value: jsonStr);
  }

  @override
  Future<User?> getUserProfile() async {
    final jsonStr = await _storage.read(key: _userProfileKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return User.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearAll() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _userProfileKey);
  }
}
