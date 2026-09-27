import 'package:flutter_test/flutter_test.dart';
import 'package:hand_tech/data/repositories/camera_stream_repository.dart';
import 'package:hand_tech/data/repositories/native_camera_stream_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeCameraStreamRepository Unit Tests', () {
    late NativeCameraStreamRepository repository;

    setUp(() {
      repository = NativeCameraStreamRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('should conform to CameraStreamRepository interface', () {
      expect(repository, isA<CameraStreamRepository>());
    });

    test('should return a broadcast video stream', () {
      final stream = repository.getVideoStream();
      expect(stream.isBroadcast, isTrue);
    });

    test('should toggle picture in picture mode without throwing', () async {
      await expectLater(repository.togglePictureInPicture(true), completes);
      await expectLater(repository.togglePictureInPicture(false), completes);
    });

    test('should handle camera stream lifecycle start and stop cleanly', () async {
      await repository.startCameraStream();
      await repository.stopCameraStream();
    });
  });
}
