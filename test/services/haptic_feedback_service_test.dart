import 'package:flutter_test/flutter_test.dart';
import 'package:hand_tech/data/services/haptic_feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterHapticFeedbackService Unit Tests', () {
    late FlutterHapticFeedbackService service;

    setUp(() {
      service = FlutterHapticFeedbackService();
    });

    test('selectionClick completes cleanly', () async {
      await expectLater(service.selectionClick(), completes);
    });

    test('successNotification completes cleanly', () async {
      await expectLater(service.successNotification(), completes);
    });

    test('warningNotification completes cleanly', () async {
      await expectLater(service.warningNotification(), completes);
    });

    test('errorNotification completes cleanly', () async {
      await expectLater(service.errorNotification(), completes);
    });
  });
}
