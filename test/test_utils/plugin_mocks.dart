import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _homeWidgetChannel = MethodChannel('home_widget');

void setUpHomeWidgetMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_homeWidgetChannel, (call) async {
      if (call.method == 'getWidgetData') return null;
      if (call.method == 'saveWidgetData') return true;
      if (call.method == 'updateWidget') return true;
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_homeWidgetChannel, null);
  });
}
