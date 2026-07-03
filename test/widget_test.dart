import 'package:data_guardian/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the usage access screen when permission is denied', (tester) async {
    const channel = MethodChannel('data_guardian/usage');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'hasUsageAccess' ? false : null,
    );

    await tester.pumpWidget(const DataGuardianApp());
    await tester.pumpAndSettle();

    expect(find.text('Usage access required'), findsOneWidget);
    expect(find.text('Open usage access'), findsOneWidget);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
}
