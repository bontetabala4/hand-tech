import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hand_tech/data/models/user_model.dart';
import 'package:hand_tech/data/repositories/auth_repository.dart';
import 'package:hand_tech/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  const testUser = User(
    id: 'user_123',
    email: 'test@handtech.com',
    name: 'Test User',
  );

  group('AuthNotifier Tests', () {
    test('Initial state is unauthenticated (AsyncValue.data(null)) after auth check completes', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial check
      container.read(authStateProvider.notifier);
      await pumpEventQueue();

      final state = container.read(authStateProvider);
      expect(state, const AsyncValue<User?>.data(null));
      verify(() => mockAuthRepository.getCurrentUser()).called(1);
    });

    test('Successful login flow updates user state and emits no error', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => mockAuthRepository.signInWithEmailAndPassword('test@handtech.com', 'password123'))
          .thenAnswer((_) async => testUser);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      await pumpEventQueue();

      await notifier.signIn('test@handtech.com', 'password123');

      final state = container.read(authStateProvider);
      expect(state.hasError, false);
      expect(state.value, equals(testUser));
      verify(() => mockAuthRepository.signInWithEmailAndPassword('test@handtech.com', 'password123')).called(1);
    });

    test('Invalid credentials handling emits error state and rethrows exception', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      final exception = Exception('Invalid email or password');
      when(() => mockAuthRepository.signInWithEmailAndPassword('invalid@handtech.com', 'wrongpass'))
          .thenThrow(exception);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      await pumpEventQueue();

      expect(
        () => notifier.signIn('invalid@handtech.com', 'wrongpass'),
        throwsA(equals(exception)),
      );

      final state = container.read(authStateProvider);
      expect(state.hasError, true);
      expect(state.error, equals(exception));
    });

    test('Sign-out flow resets user state to unauthenticated (null)', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => testUser);
      when(() => mockAuthRepository.signOut())
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      await pumpEventQueue();

      expect(container.read(authStateProvider).value, equals(testUser));

      await notifier.signOut();

      final state = container.read(authStateProvider);
      expect(state.hasError, false);
      expect(state.value, isNull);
      verify(() => mockAuthRepository.signOut()).called(1);
    });
  });
}
