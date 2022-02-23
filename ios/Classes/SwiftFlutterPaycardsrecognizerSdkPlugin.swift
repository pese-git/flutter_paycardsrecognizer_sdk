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
        
        vc.modalPresentationStyle = .fullScreen
        rootVC.present(vc, animated: true, completion: nil)
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

struct Padding {
    static let `default` = 8.0
    static let large = 16.0
    static let doubleLarge = 16.0
    static let textLabelFontSize = 19.0
    static let closeButtonFontSize = 17.0
}

// MARK: - RecognizerVC
class RecognizerVC: UIViewController, PayCardsRecognizerPlatformDelegate {
    private lazy var recognizer = PayCardsRecognizer(delegate: self,
                                                     // `async` needed
                                                     // https://github.com/faceterteam/PayCards_iOS/issues/23
                                                     resultMode: .async,
                                                     container: cameraView,
                                                     frameColor: .clear)
    
    private var preferredLanguageCode: String?
    private lazy var localizatioBundle = findBundle()
    private lazy var cameraView = UIView(frame: .zero)
    private lazy var cameraElementsView = CameraElementsView(frame: .zero)
    private var label: UIView?
    
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
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // for case if UIViewControllerBasedStatusBarAppearance is NO in plist
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent,
                                               animated: animated)
        startCameraIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // for case if UIViewControllerBasedStatusBarAppearance is NO in plist
        UIApplication.shared.setStatusBarStyle(statusBarStyle,
                                               animated: animated)
        
        stopCameraIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFrames()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black
        view.addSubview(cameraView)
        
        cameraElementsView.setLabelText(self.localized("recognizer_screen_hint_position_card",
                                                       comment: "Hold the card inside the frame.\nIt will be read automatically."))
        cameraElementsView.setBackButtonText(self.localized("recognizer_screen_cancel_button_title",
                                                            comment: "Cancel"))
        
        cameraElementsView.setBackButtonHandler { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.dismissRecognizerVC(self)
        }

        view.addSubview(cameraElementsView)
    }
    
    private var isPortrait: Bool {
        return view.bounds.width < view.bounds.height
    }
    
    private func updateFrames() {
        if isPortrait {
            let sideSize = view.bounds.width
            let top = view.safeAreaInsets.top
            cameraView.frame = CGRect(x: 0.0,
                                      y: round(0.5 * max(view.bounds.height - top - sideSize, top)),
                                      width: sideSize,
                                      height: sideSize)
            cameraElementsView.frame = cameraView.frame
        } else {
            let sideSize = min(view.bounds.width, view.bounds.height)
            cameraView.frame = CGRect(x: round(0.5 * abs(view.bounds.width - sideSize)),
                                      y: round(0.5 * abs(view.bounds.height - sideSize)),
                                      width: sideSize,
                                      height: sideSize)
            cameraElementsView.frame = cameraView.frame
        }
        
        findLabel()?.alpha = 0.0
    }

    private func findLabel() -> UIView? {
        guard let result = label else {
            self.label = cameraView.subviews.first?.subviews.first(where: { view in
                return view as? UIButton != nil
            })
            return self.label
        }

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
    private func showRequestCameraPermissionsAlert() {
        let message = self.localized("alert_request_permissions_message",
                                     comment: "Allow the app to access the camera to scan card numbers")
        let settingsTitle = self.localized("alert_request_permissions_settings_button_title",
                                     comment: "Settings")
        let cancelTitle = self.localized("alert_request_permissions_cancel_button_title",
                                         comment: "OK")
        let alert = UIAlertController(title: message,
                                      message: nil,
                                      preferredStyle: .alert)
        let settings = UIAlertAction(title: settingsTitle, style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        
        let cancel = UIAlertAction(title: cancelTitle, style: .default) { [weak self]  _ in
            guard let self = self else { return }
            self.delegate?.dismissRecognizerVC(self)
        }
        
        alert.addAction(cancel)
        alert.addAction(settings)
        
        self.present(alert, animated: true)
    }
    
    private func startCameraIfNeeded() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch (status) {
        case .authorized:
            recognizer.startCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if isGranted {
                        self.recognizer.startCamera()
                    } else {
                        self.delegate?.dismissRecognizerVC(self)
                    }
                }
                
            }
        case .denied, .restricted:
            showRequestCameraPermissionsAlert()
        @unknown default:
            showRequestCameraPermissionsAlert()
        }
    }
    
    private func stopCameraIfNeeded() {
        if isCameraPermissionsGranted() {
            recognizer.stopCamera()
        }
    }
    
    private func isCameraPermissionsGranted() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch (status) {
        case .authorized:
            return true
        case .denied, .notDetermined, .restricted:
            return false
        @unknown default:
            return false
        }
    }
//    private func requestCameraPermissions() {
//        AVCaptureDevice.requestAccess(for: .video, completionHandler: {_ in })
//    }
}

// MARK: - Localization
extension RecognizerVC {
    private func localized(_ key: String, comment: String) -> String {
        return NSLocalizedString(key,
                                 tableName: localizationTableName,
                                 bundle: localizatioBundle,
                                 value: comment,
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


// MARK: - CameraContainerView
class CameraElementsView: UIView {
    static let cardRatio = 5.5 / 8.5
    static let cardPadding = 14.0
    
    private lazy var cache = Cache()
    private lazy var frameLimiterLT = UIImageView(image: cache.frameLimiterLT)
    private lazy var frameLimiterRT = UIImageView(image: cache.frameLimiterRT)
    private lazy var frameLimiterRB = UIImageView(image: cache.frameLimiterRB)
    private lazy var frameLimiterLB = UIImageView(image: cache.frameLimiterLB)
    private lazy var textLabel = UILabel(frame: .zero)
    private lazy var backButton = createBackButton()
    
    private var buttonHandler: ((UIButton) -> Void)?
    
    func setLabelText(_ text: String) {
        textLabel.text = text
    }
    
    func setBackButtonText(_ text: String) {
        backButton.setTitle(text, for: .normal)
    }
    
    func setBackButtonHandler(_ handler: ((UIButton) -> Void)?) {
        buttonHandler = handler
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(frameLimiterLT)
        addSubview(frameLimiterRT)
        addSubview(frameLimiterRB)
        addSubview(frameLimiterLB)
        addSubview(textLabel)
        addSubview(backButton)
        
        configureLabel()
    }
    
    private func configureLabel() {
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: Padding.textLabelFontSize,
                                           weight: .semibold)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cardWidth = bounds.width - 2.0 * Self.cardPadding
        let cardHeight = round(Self.cardRatio * cardWidth)
        
        let topLimitersY = round(0.5 * (bounds.height - cardHeight))
        let bottomLimitersY = topLimitersY + cardHeight - Cache.frameLimiterSize.height
        let limitersLeftX = bounds.minX + Self.cardPadding
        let limitersRightX = bounds.maxX - Self.cardPadding - Cache.frameLimiterSize.width
        
        frameLimiterLT.frame = CGRect(origin: CGPoint(x: limitersLeftX,
                                                      y: topLimitersY),
                                      size: Cache.frameLimiterSize)
        frameLimiterRT.frame = CGRect(origin: CGPoint(x: limitersRightX,
                                                      y: topLimitersY),
                                      size: Cache.frameLimiterSize)
        
        frameLimiterRB.frame = CGRect(origin: CGPoint(x: limitersRightX,
                                                      y: bottomLimitersY),
                                      size: Cache.frameLimiterSize)
        
        frameLimiterLB.frame = CGRect(origin: CGPoint(x: limitersLeftX,
                                                      y: bottomLimitersY),
                                      size: Cache.frameLimiterSize)
        
        textLabel.frame = CGRect(x: frameLimiterLT.frame.minX + Padding.default,
                                 y: frameLimiterRT.frame.minY + Padding.default,
                                 width: cardWidth - 2.0 * Padding.default,
                                 height: cardHeight - 2.0 * Padding.default)
        
        let backButtonSize = backButton.sizeThatFits(bounds.size)
        
        backButton.frame = CGRect(origin: CGPoint(x: bounds.minX,
                                                  y: bounds.maxY - backButtonSize.height),
                                  size: backButtonSize)
    }
    
    private func createBackButton() -> UIButton {
        let result = UIButton(frame: CGRect(x: 0, y: 0.0,
                                            width: Padding.doubleLarge,
                                            height: Padding.doubleLarge))
        result.backgroundColor = .clear
        result.contentEdgeInsets = UIEdgeInsets(top: Padding.default,
                                                left: Padding.default,
                                                bottom: Padding.default,
                                                right: Padding.default)
        result.titleLabel?.font = UIFont.boldSystemFont(ofSize: Padding.closeButtonFontSize)

        result.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        result.setTitleColor(.white, for: .normal)
        return result
    }
    
    @objc func goBack(){
        buttonHandler?(backButton)
    }
}

// MARK: - Cache
extension CameraElementsView {
    class Cache {
        static let frameLimiterSize = CGSize(width: 50.0, height: 50.0)
        static let frameLimiterCornerRadus = 5.0
        static let frameLimiterStrokeWidth = 5.0
        
        lazy var frameLimiterLT = ImageFactory.drawTopLeftFrameLimiter(size: Self.frameLimiterSize,
                                                                       cornerRadus: Self.frameLimiterCornerRadus,
                                                                       strokeColor: .yellow,
                                                                       strokeWidth: Self.frameLimiterStrokeWidth)
        lazy var frameLimiterRT =  ImageFactory.imageWithOrientation(source: frameLimiterLT,
                                                                     orientation: .right)
        lazy var frameLimiterLB =  ImageFactory.imageWithOrientation(source: frameLimiterLT,
                                                                     orientation: .downMirrored)
        lazy var frameLimiterRB = ImageFactory.imageWithOrientation(source: frameLimiterLT,
                                                                    orientation: .rightMirrored)
    }
}

// MARK: - ImageFactory
struct ImageFactory {
    static func drawTopLeftFrameLimiter(size: CGSize,
                                        cornerRadus: CGFloat,
                                        strokeColor: UIColor,
                                        strokeWidth: CGFloat) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        let strokeW = strokeWidth
        
        ctx.addArc(center: CGPoint(x: cornerRadus + strokeW, y: cornerRadus + strokeW),
                   radius: cornerRadus,
                   startAngle: .pi,
                   endAngle: 1.5 * .pi,
                   clockwise: false)
        
        ctx.addLine(to: CGPoint(x: size.width - strokeW, y: strokeW))
        
        ctx.move(to: CGPoint(x: strokeW, y: size.height))
        ctx.addLine(to: CGPoint(x: strokeW, y: cornerRadus + strokeW))
        
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.strokePath()
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    static func imageWithOrientation(source: UIImage, orientation: UIImage.Orientation) -> UIImage {
        return UIImage(cgImage: source.cgImage!, scale: source.scale, orientation: orientation)
    }
}
