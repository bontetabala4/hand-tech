import '../models/camera_frame.dart';

abstract class CameraStreamRepository {
  Stream<CameraFrame> getVideoStream();
  Future<void> startCameraStream();
  Future<void> stopCameraStream();
  Future<void> togglePictureInPicture(bool expand);
}
