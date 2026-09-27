import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_tech/main.dart';

void main() {
  testWidgets('HandTechApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HandTechApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(HandTechApp), findsOneWidget);
  });
}
