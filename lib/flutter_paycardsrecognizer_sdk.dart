import 'dart:async';

import 'package:flutter/services.dart';

class FlutterPaycardsrecognizerSdk {
  static FlutterPaycardsrecognizerSdk newInstance() =>
      FlutterPaycardsrecognizerSdk();

  final MethodChannel _channel =
      const MethodChannel('flutter_paycardsrecognizer_sdk');

  Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
