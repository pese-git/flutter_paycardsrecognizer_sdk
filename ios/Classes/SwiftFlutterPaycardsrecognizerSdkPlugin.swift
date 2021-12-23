import Flutter
import UIKit
import PayCardsRecognizer

//public class SwiftFlutterPaycardsrecognizerSdkPlugin: NSObject, FlutterPlugin, PayCardsRecognizerPlatformDelegate {
//  var recognizer: PayCardsRecognizer?
//  var _result: FlutterResult?
//
//  var _viewController: UIViewController
//
//  lazy var backButton = createBackButton()
//
//    public override init() {
//    }
////  init(viewController: UIViewController) {
////      self._viewController = viewController
////  }
//
//  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//    //result("iOS " + UIDevice.current.systemVersion)
//    guard call.method == "scanCard" else {
//        result(FlutterMethodNotImplemented)
//        return
//    }
//
//    if (self._result != nil) {
//        result(FlutterError(code: "ALREADY_ACTIVE", message: "Scan card is already active", details: nil))
//        return
//    }
//    self._result = result
//    self.recognizer = PayCardsRecognizer(delegate: self, resultMode: .async, container: self._viewController.view, frameColor: .green)
//    NSLog("Strart recognized card")
//
//    self.recognizer?.startCamera()
//
//
//    _viewController.view.addSubview(backButton)
//    _viewController.view.bringSubviewToFront(backButton)
//  }
//
//    @objc func goBack(){
//        self.recognizer?.stopCamera()
//        backButton.removeFromSuperview()
//        self._result = nil
//    }
//
//  // PayCardsRecognizerPlatformDelegate
//    public func payCardsRecognizer(_ payCardsRecognizer: PayCardsRecognizer, didRecognize recognizeResult: PayCardsRecognizerResult) {
//    NSLog("Parse card data")
//      let cardDict: [String: Any?] = ["cardHolderName": recognizeResult.recognizedHolderName,
//                            "cardNumber": recognizeResult.recognizedNumber,
//                            "expiryMonth": recognizeResult.recognizedExpireDateMonth,
//                            "expiryYear": recognizeResult.recognizedExpireDateYear]
//
//
//    NSLog("Send card data")
//    self._result?(cardDict)
//
//    NSLog("Finish recognized card")
//      self.recognizer?.stopCamera()
//      self._result = nil
//  }
//}

// MARK: - ui components
//extension SwiftFlutterPaycardsrecognizerSdkPlugin {
//    private func createBackButton() -> UIButton {
//        let result = UIButton(frame: CGRect.zero)
//        result.backgroundColor = .clear
//        result.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
//        result.setTitle("✕", for: .normal)
//        result.addTarget(self, action: #selector(goBack), for: .touchUpInside)
//        return result
//    }
//}
//
//// MARK: - factory
//extension SwiftFlutterPaycardsrecognizerSdkPlugin {
//    public static func register(with registrar: FlutterPluginRegistrar) {
//        let channel = FlutterMethodChannel(name: "flutter_paycardsrecognizer_sdk", binaryMessenger: registrar.messenger())
//        let rootViewController: UIViewController = (UIApplication.shared.delegate?.window??.rootViewController)!
//
//        let plugin = SwiftFlutterPaycardsrecognizerSdkPlugin()
//        var vc = RecognizerViewController(nibName: nil, bundle: nil);
//
//
////        let instance = SwiftFlutterPaycardsrecognizerSdkPlugin(viewController: viewController)
//
//        //        viewController.present(<#T##viewControllerToPresent: UIViewController##UIViewController#>, animated: <#T##Bool#>, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
//
//        //        viewController.dismiss(animated: <#T##Bool#>, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
//
//        registrar.addMethodCallDelegate(instance, channel: channel)
//    }
//}

//typealias SwiftFlutterPaycardsrecognizerSdkPlugin =
// MARK: -

public class SwiftFlutterPaycardsrecognizerSdkPlugin: NSObject, FlutterPlugin, RecognizerVCDelegate {
    
    var vc: UIViewController?
    
    var _flutterResultHandler: FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_paycardsrecognizer_sdk", binaryMessenger: registrar.messenger())
        let plugin = SwiftFlutterPaycardsrecognizerSdkPlugin()
        registrar.addMethodCallDelegate(plugin, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "scanCard" else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        if (self._flutterResultHandler != nil) {
            result(FlutterError(code: "ALREADY_ACTIVE", message: "Scan card is already active", details: nil))
            return
        }
        
        self._flutterResultHandler = result
        
        showRecognizerVC()
    }
    
    func showRecognizerVC() {
        let rootVC: UIViewController = (UIApplication.shared.delegate?.window??.rootViewController)!
        let vc = RecognizerVC(nibName: nil, bundle: nil);
        vc.modalPresentationStyle = .fullScreen
        vc.delegate = self
        self.vc = vc
        
        rootVC.present(vc, animated: true, completion: nil)
    }
    
    func recognizerVC(_ sender: RecognizerVC, didRecognize result: [String : Any?]) {
        _flutterResultHandler?(result)
        _flutterResultHandler = nil
        vc?.dismiss(animated: true, completion: nil)
    }
    
    func dismissRecognizerVC(_ sender: RecognizerVC) {
        _flutterResultHandler = nil
        vc?.dismiss(animated: true, completion: nil)
    }
}

protocol RecognizerVCDelegate: AnyObject {
    func recognizerVC(_ sender: RecognizerVC, didRecognize result: [String: Any?])
    func dismissRecognizerVC(_ sender: RecognizerVC)
}

class RecognizerVC: UIViewController, PayCardsRecognizerPlatformDelegate {
    
    lazy var recognizer = PayCardsRecognizer(delegate: self, resultMode: .sync, container: self.view, frameColor: .green)
    
    lazy var backButton = createBackButton()
    
    weak var delegate: RecognizerVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recognizer.startCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        recognizer.stopCamera()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backButton.frame = CGRect(x: 0, y: 16.0, width: 100.0, height: 100.0)
        view.bringSubviewToFront(backButton)
    }
    
    @objc func goBack(){
        delegate?.dismissRecognizerVC(self)
    }
    
    private func createBackButton() -> UIButton {
        let result = UIButton(frame: CGRect.zero)
        result.backgroundColor = .clear
        result.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        result.setTitle("✕", for: .normal)
        result.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        return result
    }
    //}
    //
    //// MARK: - PayCardsRecognizerPlatformDelegate
    //
    //extension RecognizerVC {
    
    func payCardsRecognizer(_ payCardsRecognizer: PayCardsRecognizer, didRecognize result: PayCardsRecognizerResult) {
        let cardInfo: [String: Any?] = ["cardHolderName": result.recognizedHolderName,
                                        "cardNumber": result.recognizedNumber,
                                        "expiryMonth": result.recognizedExpireDateMonth,
                                        "expiryYear": result.recognizedExpireDateYear]
        
        delegate?.recognizerVC(self, didRecognize: cardInfo)
    }
}
