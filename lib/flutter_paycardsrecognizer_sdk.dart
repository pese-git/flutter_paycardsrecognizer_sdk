/*
 * Copyright [2021] Sergey Penkovsky <sergey.penkovsky@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayCardInfo &&
          runtimeType == other.runtimeType &&
          cardHolderName == other.cardHolderName &&
          cardNumber == other.cardNumber &&
          expiryMonth == other.expiryMonth &&
          expiryYear == other.expiryYear;

  @override
  int get hashCode =>
      cardHolderName.hashCode ^
      cardNumber.hashCode ^
      expiryMonth.hashCode ^
      expiryYear.hashCode;
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
