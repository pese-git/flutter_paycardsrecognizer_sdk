import 'dart:async';

import 'package:flutter/services.dart';

class FlutterPaycardsrecognizerSdk {
  static FlutterPaycardsrecognizerSdk newInstance() =>
      FlutterPaycardsrecognizerSdk();

  final MethodChannel _channel =
      const MethodChannel('flutter_paycardsrecognizer_sdk');

  Future<Map<dynamic, dynamic>> scanCard() async {
    final Map<dynamic, dynamic> version =
        await _channel.invokeMethod('startRecognizer');
    return version;
  }
}
