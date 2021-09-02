import Flutter
import UIKit
import PayCardsRecognizer

public class SwiftFlutterPaycardsrecognizerSdkPlugin: NSObject, FlutterPlugin, PayCardsRecognizerPlatformDelegate {
  var recognizer: PayCardsRecognizer!
  var _result: FlutterResult!

  var _viewController: UIViewController

  init(viewController: UIViewController) {
    self._viewController = viewController
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_paycardsrecognizer_sdk", binaryMessenger: registrar.messenger())
    let viewController: UIViewController = (UIApplication.shared.delegate?.window??.rootViewController)!

    let instance = SwiftFlutterPaycardsrecognizerSdkPlugin(viewController: viewController)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    //result("iOS " + UIDevice.current.systemVersion)
    guard call.method == "scanCard" else {
        result(FlutterMethodNotImplemented)
        return
    }

    if (self._result != nil) {
        result(FlutterError(code: "ALREADY_ACTIVE", message: "Scan card is already active", details: nil))
        return
    }
    self._result = result
    self.recognizer = PayCardsRecognizer(delegate: self, resultMode: .sync, container: self._viewController.view, frameColor: .green)
    self.recognizer.startCamera()
  }

  // PayCardsRecognizerPlatformDelegate

  public func payCardsRecognizer(_ payCardsRecognizer: PayCardsRecognizer, didRecognize recognizeResult: PayCardsRecognizerResult) {
/*
  	print(recognizeResult.recognizedNumber) // Card number
  	print(recognizeResult.recognizedHolderName) // Card holder
  	print(recognizeResult.recognizedExpireDateMonth) // Expire month
  	print(recognizeResult.recognizedExpireDateYear) // Expire year
*/
  	let cardDict: [String: Any?] = ["cardHolderName": recognizeResult.recognizedHolderName,
                            "cardNumber": recognizeResult.recognizedNumber,
                            "expiryMonth": recognizeResult.recognizedExpireDateMonth,
                            "expiryYear": recognizeResult.recognizedExpireDateYear]


    self._result(cardDict)

  	self.recognizer.stopCamera()
  	self._result = nil
  }
}
