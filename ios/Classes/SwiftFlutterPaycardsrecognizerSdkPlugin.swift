import Flutter
import UIKit
import AVFoundation
import PayCardsRecognizer

fileprivate let flutterChannelName = "flutter_paycardsrecognizer_sdk"
fileprivate let flutterMethodName = "scanCard"
fileprivate let alreadyActiveErrorCode = "ALREADY_ACTIVE"
fileprivate let alreadyActiveErrorMessage = "Scan card is already active"
fileprivate let libName = "flutter_paycardsrecognizer_sdk"
fileprivate let localizationTableName = "Localizable"

public class SwiftFlutterPaycardsrecognizerSdkPlugin:
    NSObject,
    FlutterPlugin,
    RecognizerVCDelegate {
    
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
            result(FlutterError(code: alreadyActiveErrorCode,
                                message: alreadyActiveErrorMessage,
                                details: nil))
            return
        }
        
        self._flutterResultHandler = result
        
        let languageCode: String?

        if let argumentsDictionary = call.arguments as? Dictionary<String, Any> {
            languageCode = argumentsDictionary["languageCode"] as? String
        } else {
            languageCode = nil
        }
        
        DispatchQueue.main.async {
            self.showRecognizerVC(languageCode: languageCode)
        }
    }
    
    func showRecognizerVC(languageCode: String?) {
        let rootVC: UIViewController = (UIApplication.shared.delegate?.window??.rootViewController)!
        let vc = RecognizerVC(nibName: nil, bundle: nil);
        if let languageCode = languageCode {
            vc.setPreferredLanguageCode(languageCode: languageCode)
        }
        vc.delegate = self
        
        let nc = UINavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .fullScreen
        rootVC.present(nc, animated: true, completion: nil)
    }
    
    func recognizerVC(_ sender: RecognizerVC, didRecognize result: [String : Any?]) {
        _flutterResultHandler?(result)
        _flutterResultHandler = nil
        DispatchQueue.main.async {
            sender.dismiss(animated: true, completion: nil)
        }
    }
    
    func dismissRecognizerVC(_ sender: RecognizerVC) {
        _flutterResultHandler = nil
        DispatchQueue.main.async {
            sender.dismiss(animated: true, completion: nil)
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
    static let padding = 16.0
    static let doublePadding = 16.0
    static let textLabelFontSize = 19.0
    static let closeSignFontSize = 30.0
    
    private lazy var recognizer = PayCardsRecognizer(delegate: self,
                                                     // `async` needed
                                                     // https://github.com/faceterteam/PayCards_iOS/issues/23
                                                     resultMode: .async,
                                                     container: cameraView,
                                                     frameColor: .green)
    
    private var preferredLanguageCode: String?
    private lazy var localizatioBundle = findBundle()
    private lazy var backButton = createBackButton()
    private lazy var cameraView = UIView(frame: .zero)
    private lazy var textLabel = UILabel(frame: .zero)
    // needed for case if UIViewControllerBasedStatusBarAppearance is NO in plist
    private let statusBarStyle = UIApplication.shared.statusBarStyle
    
    weak var delegate: RecognizerVCDelegate?
    
    func setPreferredLanguageCode( languageCode: String) {
        preferredLanguageCode = languageCode
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestCameraPermissionsIfNeeded()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // for case if UIViewControllerBasedStatusBarAppearance is NO in plist
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent,
                                               animated: animated)
        recognizer.startCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // for case if UIViewControllerBasedStatusBarAppearance is NO in plist
        UIApplication.shared.setStatusBarStyle(statusBarStyle,
                                               animated: false)
        recognizer.stopCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFrames()
    }
    
    private func setupUI() {
        setupNavigationBar()
        view.backgroundColor = UIColor.black
        view.addSubview(cameraView)

        if isPortrait {
            textLabel.textAlignment = .center
            view.addSubview(textLabel)
            textLabel.text = self.localized("recognizer_screen_hint_position_card",
                                            comment: "Position your card in the frame.")
            textLabel.numberOfLines = 0
            textLabel.textColor = .white
            textLabel.font = UIFont.systemFont(ofSize: Self.textLabelFontSize,
                                               weight: .semibold)
        }
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear

        navigationItem.setLeftBarButton(UIBarButtonItem(customView: backButton),animated: false)
    }
    
    private var isPortrait: Bool {
        return view.bounds.width < view.bounds.height
    }
    
    private func updateFrames() {
        if isPortrait {
            let sideSize = view.bounds.width
            let top = view.safeAreaInsets.top
            cameraView.frame = CGRect(x: 0.0,
                                      y: top,
                                      width: sideSize,
                                      height: sideSize)
            let textLabelY = top + sideSize + Self.padding
            textLabel.frame = CGRect(x: Self.padding,
                                     y: textLabelY,
                                     width: sideSize - Self.doublePadding,
                                     height: view.bounds.height - Self.doublePadding - textLabelY)
        } else {
            let sideSize = min(view.bounds.width, view.bounds.height)
            cameraView.frame = CGRect(x: round(0.5 * abs(view.bounds.width - sideSize)),
                                      y: round(0.5 * abs(view.bounds.height - sideSize)),
                                      width: sideSize,
                                      height: sideSize)
        }
    }

    
    @objc func goBack(){
        delegate?.dismissRecognizerVC(self)
    }
    
    private func createBackButton() -> UIButton {
        let result = UIButton(frame: CGRect(x: 0, y: 0.0,
                                            width: Self.doublePadding,
                                            height: Self.doublePadding))
        result.backgroundColor = .clear
        result.titleLabel?.font = UIFont.boldSystemFont(ofSize: Self.closeSignFontSize)
        result.setTitle("✕", for: .normal)
        result.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        result.setTitleColor(.white, for: .normal)
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
                                 tableName: localizationTableName,
                                 bundle: localizatioBundle,
                                 comment: comment)
    }
    
    private func findBundle() -> Bundle {
        let bundle = Bundle(for: RecognizerVC.self)
        
        if let path = bundle.path(forResource: libName, ofType: "bundle") {
            
            let libBundle = Bundle(path: path) ?? bundle
            
            if let languageCode = preferredLanguageCode {
                if let resourceBundlePath = libBundle.path(forResource: languageCode, ofType: "lproj") {
                    return Bundle(path: resourceBundlePath) ?? libBundle
                }
            }
            return libBundle
        }
        else {
            return bundle
        }
    }
}
