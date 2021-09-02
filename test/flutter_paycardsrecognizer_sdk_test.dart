import 'package:flutter/services.dart';
import 'package:flutter_paycardsrecognizer_sdk/flutter_paycardsrecognizer_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_paycardsrecognizer_sdk');

  final PayCardInfo payCardInfo = PayCardInfo(
    cardHolderName: 'Personal Name',
    cardNumber: '1111222233334444',
    expiryMonth: '12',
    expiryYear: '24',
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return {
        'cardHolderName': 'Personal Name',
        'cardNumber': '1111222233334444',
        'expiryMonth': '12',
        'expiryYear': '24',
      };
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('scanCard', () async {
    expect(await FlutterPayCardsRecognizerSdk.newInstance().scanCard(),
        payCardInfo);
  });
}
