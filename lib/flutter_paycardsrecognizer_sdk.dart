import 'dart:async';

import 'package:flutter/services.dart';

class PayCardInfo {
  final String? cardHolderName;
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;

  PayCardInfo(
      {this.cardHolderName,
      this.cardNumber,
      this.expiryMonth,
      this.expiryYear});

  @override
  String toString() {
    return 'PayCardInfo{cardHolderName: $cardHolderName, cardNumber: $cardNumber, expiryMonth: $expiryMonth, expiryYear: $expiryYear}';
  }
}

class FlutterPayCardsRecognizerSdk {
  static FlutterPayCardsRecognizerSdk newInstance() =>
      FlutterPayCardsRecognizerSdk();

  final MethodChannel _channel =
      const MethodChannel('flutter_paycardsrecognizer_sdk');

  Future<PayCardInfo> scanCard() {
    return _channel.invokeMethod('scanCard').then(
          (value) => PayCardInfo(
            cardHolderName: value['cardHolderName'],
            cardNumber: value['cardNumber'],
            expiryMonth: value['expiryMonth'],
            expiryYear: value['expiryYear'],
          ),
        );
  }
}
