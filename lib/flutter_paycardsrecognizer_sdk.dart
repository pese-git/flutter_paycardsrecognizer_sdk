import 'dart:async';

import 'package:flutter/services.dart';

class FlutterPayCardsRecognizerSdk {
  static FlutterPayCardsRecognizerSdk newInstance() =>
      FlutterPayCardsRecognizerSdk();

  final MethodChannel _channel =
      const MethodChannel('flutter_paycardsrecognizer_sdk');

  Future<Map<dynamic, dynamic>> scanCard() async {
    final Map<dynamic, dynamic> version =
        await _channel.invokeMethod('scanCard');
    return version;
  }
}
