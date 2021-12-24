import Flutter
import UIKit
import PayCardsRecognizer

fileprivate let flutterChannelName = "flutter_paycardsrecognizer_sdk"
fileprivate let flutterMethodName = "scanCard"

public class SwiftFlutterPaycardsrecognizerSdkPlugin:
    NSObject,
    FlutterPlugin,
    RecognizerVCDelegate {
    
    var vc: UIViewController?
    
    var _flutterResultHandler: FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: flutterChannelName,
                                           binaryMessenger: registrar.messenger())
        let plugin = SwiftFlutterPaycardsrecognizerSdkPlugin()
        registrar.addMethodCallDelegate(plugin, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == flutterMethodName else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        if (self._flutterResultHandler != nil) {
            result(FlutterError(code: "ALREADY_ACTIVE",
                                message: "Scan card is already active",
                                details: nil))
            return
        }
        
        self._flutterResultHandler = result
        
        DispatchQueue.main.async {
            self.showRecognizerVC()
        }
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
        DispatchQueue.main.async {
            self.vc?.dismiss(animated: true, completion: nil)
        }
    }
    
    func dismissRecognizerVC(_ sender: RecognizerVC) {
        _flutterResultHandler = nil
        DispatchQueue.main.async {
            self.vc?.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - RecognizerVCDelegate
protocol RecognizerVCDelegate: AnyObject {
    func recognizerVC(_ sender: RecognizerVC, didRecognize result: [String: Any?])
    func dismissRecognizerVC(_ sender: RecognizerVC)
}

// MARK: - RecognizerVC
class RecognizerVC: UIViewController, PayCardsRecognizerPlatformDelegate {
    
    lazy var recognizer = PayCardsRecognizer(delegate: self,
                                             // `async` needed
                                             // https://github.com/faceterteam/PayCards_iOS/issues/23
                                             resultMode: .async,
                                             container: cameraView,
                                             frameColor: .green)
    
    lazy var backButton = createBackButton()
    lazy var cameraView = UIView(frame: CGRect.zero)
    
    weak var delegate: RecognizerVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        updateFrames()
    }
    private func setupUI() {
        view.addSubview(cameraView)
        view.addSubview(backButton)
    }
    
    private func updateFrames() {
        cameraView.frame = view.bounds
        backButton.frame = CGRect(x: 0, y: 16.0, width: 100.0, height: 100.0)
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
}

// MARK: - PayCardsRecognizerPlatformDelegate
extension RecognizerVC {
    public func payCardsRecognizer(_ payCardsRecognizer: PayCardsRecognizer, didRecognize result: PayCardsRecognizerResult) {
        let cardInfo: [String: Any?] = ["cardHolderName": result.recognizedHolderName,
                                        "cardNumber": result.recognizedNumber,
                                        "expiryMonth": result.recognizedExpireDateMonth,
                                        "expiryYear": result.recognizedExpireDateYear]
        delegate?.recognizerVC(self, didRecognize: cardInfo)
    }
}
