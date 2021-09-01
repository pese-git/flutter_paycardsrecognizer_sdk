import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_paycardsrecognizer_sdk/flutter_paycardsrecognizer_sdk.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_paycardsrecognizer_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterPaycardsrecognizerSdk.platformVersion, '42');
  });
}
