import Flutter
import UIKit
import AVFoundation
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
        requestCameraPermissionsIfNeeded()
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
        view.backgroundColor = UIColor.black
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

// MARK: - Request camera permissions
extension RecognizerVC {
    private func requestCameraPermissionsIfNeeded() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] success in
            if success == false {
                guard let self = self else { return }
                let title = self.localized("alert_request_permissions_title",
                                           comment: "Camera")
                let message = self.localized("alert_request_permissions_message",
                                             comment: "Allow the app to access the camera to scan card numbers")
                let okTitle = self.localized("alert_request_permissions_ok_button_title",
                                             comment: "OK")
                let cancelTitle = self.localized("alert_request_permissions_cancel_button_title",
                                                 comment: "Cancel")
                let alert = UIAlertController(title: title,
                                              message: message,
                                              preferredStyle: .alert)
                let ok = UIAlertAction(title: okTitle, style: .default) { _ in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    self.delegate?.dismissRecognizerVC(self)
                }
                
                let cancel = UIAlertAction(title: cancelTitle, style: .cancel) { [weak self]  _ in
                    guard let self = self else { return }
                    self.delegate?.dismissRecognizerVC(self)
                }
                
                alert.addAction(ok)
                alert.addAction(cancel)
                
                self.present(alert, animated: true)
            }
        }
    }
}

// MARK: - Localization
extension RecognizerVC {
    private func localized(_ key: String, comment: String) -> String {
        return NSLocalizedString(key,
                                 tableName: "Localizable",
                                 bundle: getBundle(),
                                 comment: comment)
    }
    
    private func getBundle() -> Bundle {
        let bundle = Bundle(for: RecognizerVC.self)
        
        if let path = bundle.path(forResource: Locale.current.identifier, ofType: "lproj") {
            return Bundle(path: path) ?? bundle
        } else {
            return bundle
        }
    }
}
