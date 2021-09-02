# flutter_paycardsrecognizer_sdk

Flutter library for automatic recognition of bank card data using built-in camera on Android/IOS devices.

### Installation

* Add the flutter_paycardsrecognizer_sdk library to your project `pubspec.yaml` file.

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_paycardsrecognizer_sdk: ^x.y.z

```

### Usage

Example:

```dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paycardsrecognizer_sdk/flutter_paycardsrecognizer_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PayCardInfo? _payCardInfo;

  @override
  void initState() {
    super.initState();
    //initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    PayCardInfo? platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
      await FlutterPayCardsRecognizerSdk.newInstance().scanCard();
    } on PlatformException {
      //platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _payCardInfo = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(
              children: [
                Text('Running on: ${_payCardInfo?.toString() ?? 'NONE'}\n'),
                ElevatedButton(
                  onPressed: () {
                    initPlatformState();
                  },
                  child: Text('Recognize Card'),
                )
              ],
            )),
      ),
    );
  }
}
```

### License

```
Apache 2.0 License

Copyright 2021 Sergey Penkovsky <sergey.penkovsky@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

