import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hand_tech/data/models/user_model.dart';
import 'package:hand_tech/data/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterSecureStorageService Unit Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late FlutterSecureStorageService service;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      service = FlutterSecureStorageService(storage: mockStorage);
    });

    test('saveAuthToken writes JWT token to secure storage', () async {
      when(() => mockStorage.write(key: 'auth_jwt_token', value: 'token_123'))
          .thenAnswer((_) async {});

      await service.saveAuthToken('token_123');

      verify(() => mockStorage.write(key: 'auth_jwt_token', value: 'token_123')).called(1);
    });

    test('getAuthToken reads JWT token from secure storage', () async {
      when(() => mockStorage.read(key: 'auth_jwt_token'))
          .thenAnswer((_) async => 'token_123');

      final token = await service.getAuthToken();

      expect(token, equals('token_123'));
      verify(() => mockStorage.read(key: 'auth_jwt_token')).called(1);
    });

    test('deleteAuthToken removes JWT token from secure storage', () async {
      when(() => mockStorage.delete(key: 'auth_jwt_token'))
          .thenAnswer((_) async {});

      await service.deleteAuthToken();

      verify(() => mockStorage.delete(key: 'auth_jwt_token')).called(1);
    });

    test('saveUserProfile & getUserProfile serializes and deserializes user correctly', () async {
      const user = User(id: 'u1', email: 'test@handtech.io', name: 'Hand Tech User');

      when(() => mockStorage.write(key: 'user_profile_json', value: any(named: 'value')))
          .thenAnswer((_) async {});

      await service.saveUserProfile(user);

      verify(() => mockStorage.write(key: 'user_profile_json', value: any(named: 'value'))).called(1);

      when(() => mockStorage.read(key: 'user_profile_json'))
          .thenAnswer((_) async => '{"id":"u1","email":"test@handtech.io","name":"Hand Tech User"}');

      final restoredUser = await service.getUserProfile();

      expect(restoredUser, isNotNull);
      expect(restoredUser!.id, equals('u1'));
      expect(restoredUser.email, equals('test@handtech.io'));
      expect(restoredUser.name, equals('Hand Tech User'));
    });

    test('clearAll wipes both token and profile', () async {
      when(() => mockStorage.delete(key: 'auth_jwt_token')).thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'user_profile_json')).thenAnswer((_) async {});

      await service.clearAll();

      verify(() => mockStorage.delete(key: 'auth_jwt_token')).called(1);
      verify(() => mockStorage.delete(key: 'user_profile_json')).called(1);
    });
  });
}
