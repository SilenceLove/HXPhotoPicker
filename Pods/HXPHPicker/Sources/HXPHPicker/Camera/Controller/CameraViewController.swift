//
//  CameraViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import CoreLocation
import AVFoundation

/// 需要有导航栏
open class CameraViewController: BaseViewController {
    public weak var delegate: CameraViewControllerDelegate?
    
    /// 相机配置
    public let config: CameraConfiguration
    /// 相机类型
    public let type: CameraController.CaptureType
    /// 自动dismiss
    public var autoDismiss: Bool = true
    
    public init(
        config: CameraConfiguration,
        type: CameraController.CaptureType,
        delegate: CameraViewControllerDelegate? = nil
    ) {
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        self.config = config
        self.type = type
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    lazy var previewView: CameraPreviewView = {
        let view = CameraPreviewView(
            config: config
        )
        view.delegate = self
        return view
    }()
    
    lazy var cameraManager: CameraManager = {
        let manager = CameraManager(config: config)
        return manager
    }()
    
    #if canImport(GPUImage)
    lazy var gpuView: CameraGPUImageView = {
        let gpuView = CameraGPUImageView(config: config)
        gpuView.delegate = self
        return gpuView
    }()
    #endif
    
    lazy var bottomView: CameraBottomView = {
        let view = CameraBottomView(tintColor: config.tintColor)
        view.delegate = self
        return view
    }()
    
    lazy var topMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(true)
        return layer
    }()
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestWhenInUseAuthorization()
        return manager
    }()
    var didLocation: Bool = false
    var currentLocation: CLLocation?
    
    private var requestCameraSuccess = false
    private var currentZoomFacto: CGFloat = 1
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        view.backgroundColor = .black
        navigationController?.navigationBar.tintColor = .white
        DeviceOrientationHelper
            .shared
            .startDeviceOrientationNotifier()
        if config.cameraType == .normal {
            view.addSubview(previewView)
        }else {
            #if canImport(GPUImage)
            view.addSubview(gpuView)
            #endif
        }
        view.addSubview(bottomView)
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            PhotoTools.showConfirm(
                viewController: self,
                title: "相机不可用!".localized,
                message: nil,
                actionTitle: "确定".localized
            ) { _ in
                self.dismiss(animated: true)
            }
            return
        }
        AssetManager.requestCameraAccess { isGranted in
            if isGranted {
                self.setupCamera()
            }else {
                PhotoTools.showNotCameraAuthorizedAlert(viewController: self)
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc
    func willEnterForeground() {
        if requestCameraSuccess {
            if config.cameraType == .normal {
                try? cameraManager.addMovieOutput()
            }
        }
    }
    
    @objc
    func didSwitchCameraClick() {
        if config.cameraType == .normal {
            do {
                try cameraManager.switchCameras()
            } catch {
                print(error)
                switchCameraFailed()
            }
        }else {
            #if canImport(GPUImage)
            gpuView.switchCamera()
            #endif
        }
        resetZoom()
    }
    
    func switchCameraFailed() {
        ProgressHUD.showWarning(
            addedTo: view,
            text: "摄像头切换失败!".localized,
            animated: true,
            delayHide: 1.5
        )
    }
    
    func resetZoom() {
        if config.cameraType == .normal {
            try? cameraManager.rampZoom(to: 1)
            previewView.effectiveScale = 1
        }else {
            #if canImport(GPUImage)
            gpuView.rampZoom(to: 1)
            #endif
        }
    }
    
    func setupCamera() {
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            gpuView.startRunning()
            addOutputCompletion()
            return
        }
        #endif
        DispatchQueue.global().async {
            do {
                self.cameraManager.session.beginConfiguration()
                try self.cameraManager.startSession()
                var needAddAudio = false
                switch self.type {
                case .photo:
                    try self.cameraManager.addPhotoOutput()
                    self.cameraManager.addVideoOutput()
                case .video:
                    try self.cameraManager.addMovieOutput()
                    needAddAudio = true
                case .all:
                    try self.cameraManager.addPhotoOutput()
                    try self.cameraManager.addMovieOutput()
                    needAddAudio = true
                }
                if !needAddAudio {
                    self.addOutputCompletion()
                }else {
                    self.addAudioInput()
                }
            } catch {
                print(error)
                self.cameraManager.session.commitConfiguration()
                DispatchQueue.main.async {
                    PhotoTools.showConfirm(
                        viewController: self,
                        title: "相机初始化失败!".localized,
                        message: nil,
                        actionTitle: "确定".localized
                    ) { _ in
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    func addAudioInput() {
        AVCaptureDevice.requestAccess(for: .audio) { isGranted in
            DispatchQueue.global().async {
                if isGranted {
                    do {
                        try self.cameraManager.addAudioInput()
                    } catch {
                        DispatchQueue.main.async {
                            self.addAudioInputFailed()
                        }
                    }
                }else {
                    DispatchQueue.main.async {
                        PhotoTools.showAlert(
                            viewController: self,
                            title: "无法使用麦克风".localized,
                            message: "请在设置-隐私-相机中允许访问麦克风".localized,
                            leftActionTitle: "取消".localized,
                        leftHandler: { alertAction in
                            self.addAudioInputFailed()
                        },
                            rightActionTitle: "设置".localized
                        ) { alertAction in
                            PhotoTools.openSettingsURL()
                        }
                    }
                }
                self.addOutputCompletion()
            }
        }
    }
    
    func addAudioInputFailed() {
        ProgressHUD.showWarning(
            addedTo: self.view,
            text: "麦克风添加失败，录制视频会没有声音哦!".localized,
            animated: true,
            delayHide: 1.5
        )
    }
    
    func addOutputCompletion() {
        if config.cameraType == .normal {
            self.cameraManager.session.commitConfiguration()
            self.cameraManager.startRunning()
            self.previewView.setSession(self.cameraManager.session)
        }
        self.requestCameraSuccess = true
        DispatchQueue.main.async {
            self.sessionCompletion()
        }
    }
    
    func sessionCompletion() {
        if config.cameraType == .normal {
            if cameraManager.canSwitchCameras() {
                addSwithCameraButton()
            }
            previewView.setupGestureRecognizer()
        }else {
            addSwithCameraButton()
        }
        bottomView.addGesture(for: type)
        startLocation()
    }
    
    func addSwithCameraButton() {
        view.layer.addSublayer(topMaskLayer)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: "hx_camera_overturn".image,
            style: .plain,
            target: self,
            action: #selector(didSwitchCameraClick)
        )
    }
    
    @objc open override func deviceOrientationDidChanged(notify: Notification) {
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            gpuView.resetMetal()
        }
        #endif
        previewView.resetOrientation()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutSubviews()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let nav = navigationController else {
            return
        }
        let navHeight = nav.navigationBar.frame.maxY
        nav.navigationBar.setBackgroundImage(
            UIImage.image(
                for: .clear,
                havingSize: CGSize(width: view.width, height: navHeight)
            ),
            for: .default
        )
        nav.navigationBar.shadowImage = UIImage()
    }
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if requestCameraSuccess {
            if config.cameraType == .normal {
                cameraManager.startRunning()
            }else {
                #if canImport(GPUImage)
                gpuView.startRunning()
                #endif
            }
        }
    }
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        PhotoManager.shared.saveCameraPreview()
        if config.cameraType == .normal {
            cameraManager.stopRunning()
        }
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            gpuView.stopRunning()
        }
        #endif
    }
    
    func layoutSubviews() {
        let previewRect: CGRect
        if UIDevice.isPad || !UIDevice.isPortrait {
            if UIDevice.isPad {
                previewRect = view.bounds
            }else {
                let size = CGSize(width: view.height * 16 / 9, height: view.height)
                previewRect = CGRect(
                    x: (view.width - size.width) * 0.5,
                    y: (view.height - size.height) * 0.5,
                    width: size.width, height: size.height
                )
            }
        }else {
            let size = CGSize(width: view.width, height: view.width / 9 * 16)
            previewRect = CGRect(
                x: (view.width - size.width) * 0.5,
                y: (view.height - size.height) * 0.5,
                width: size.width, height: size.height
            )
        }
        if config.cameraType == .normal {
            previewView.frame = previewRect
        }else {
            #if canImport(GPUImage)
            gpuView.frame = previewRect
            #endif
        }
        
        let bottomHeight: CGFloat = 130
        let bottomY: CGFloat
        if UIDevice.isPortrait && !UIDevice.isPad {
            let bottomMargin: CGFloat
            if UIDevice.isAllIPhoneX {
                bottomMargin = 110
            }else {
                bottomMargin = 150
            }
            bottomY = view.height - bottomMargin - previewRect.minY
        }else {
            bottomY = view.height - bottomHeight
        }
        bottomView.frame = CGRect(
            x: 0,
            y: bottomY,
            width: view.width,
            height: bottomHeight
        )
        if let nav = navigationController {
            topMaskLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: nav.navigationBar.frame.maxY + 10
            )
        }
    }
    
    open override var prefersStatusBarHidden: Bool {
        config.prefersStatusBarHidden
    }
    open override var shouldAutorotate: Bool {
        config.shouldAutorotate
    }
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        config.supportedInterfaceOrientations
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        if allowLocation && didLocation {
            locationManager.stopUpdatingLocation()
        }
        DeviceOrientationHelper.shared.stopDeviceOrientationNotifier()
    }
}

extension CameraViewController: CameraBottomViewDelegate {
    func bottomView(beganTakePictures bottomView: CameraBottomView) {
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            gpuView.capturePhoto { [weak self] image in
                guard let self = self else { return }
                self.capturePhotoCompletion(image: image)
            }
            return
        }
        #endif
        if !cameraManager.session.isRunning {
            return
        }
        bottomView.isGestureEnable = false
        cameraManager.capturePhoto {
            
        } completion: { [weak self] data in
            guard let self = self else { return }
            if let data = data ,
               let image = UIImage(data: data) {
                self.capturePhotoCompletion(image: image)
            }else {
                self.capturePhotoCompletion(image: nil)
            }
        }
    }
    func capturePhotoCompletion(image: UIImage?) {
        if let image = image?.normalizedImage() {
            resetZoom()
            if config.cameraType == .normal {
                cameraManager.stopRunning()
                previewView.resetMask(image)
            }else {
                #if canImport(GPUImage)
                gpuView.stopRunning()
                gpuView.resetMask(image)
                #endif
            }
            bottomView.isGestureEnable = false
            saveCameraImage(image)
            #if HXPICKER_ENABLE_EDITOR
            if config.allowsEditing {
                openPhotoEditor(image)
            }else {
                openPhotoResult(image)
            }
            #else
            openPhotoResult(image)
            #endif
        }else {
            bottomView.isGestureEnable = true
            ProgressHUD.showWarning(
                addedTo: self.view,
                text: "拍摄失败!".localized,
                animated: true,
                delayHide: 1.5
            )
        }
    }
    func bottomView(beganRecording bottomView: CameraBottomView) {
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            gpuView.startRecording { [weak self] duration in
                self?.bottomView.startTakeMaskLayerPath(duration: duration)
            } progress: { _, _ in
                
            } completion: { [weak self] videoURL, error in
                guard let self = self else { return }
                self.recordingCompletion(videoURL: videoURL, error: error)
            }
            return
        }
        #endif
        cameraManager.startRecording { [weak self] duration in
            self?.bottomView.startTakeMaskLayerPath(duration: duration)
        } progress: { progress, time in
            
        } completion: { [weak self] videoURL, error in
            guard let self = self else { return }
            self.recordingCompletion(videoURL: videoURL, error: error)
        }
    }
    func recordingCompletion(videoURL: URL, error: Error?) {
        bottomView.stopRecord()
        if error == nil {
            resetZoom()
            let image = PhotoTools.getVideoThumbnailImage(videoURL: videoURL, atTime: 0.1)
            if config.cameraType == .normal {
                cameraManager.stopRunning()
                previewView.resetMask(image)
            }else {
                #if canImport(GPUImage)
                gpuView.stopRunning()
                gpuView.resetMask(image)
                #endif
            }
            bottomView.isGestureEnable = false
            saveCameraVideo(videoURL)
            #if HXPICKER_ENABLE_EDITOR
            if config.allowsEditing {
                openVideoEditor(videoURL)
            }else {
                openVideoResult(videoURL)
            }
            #else
            openVideoResult(videoURL)
            #endif
        }else {
            let text: String
            if let error = error as NSError?,
               error.code == 110 {
                text = String(
                    format: "拍摄时长不足%d秒".localized,
                    arguments: [Int(config.videoMinimumDuration)]
                )
            }else {
                text = "拍摄失败!".localized
            }
            ProgressHUD.showWarning(
                addedTo: view,
                text: text,
                animated: true,
                delayHide: 1.5
            )
        }
    }
    func bottomView(endRecording bottomView: CameraBottomView) {
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            gpuView.stopRecording()
            return
        }
        #endif
        cameraManager.stopRecording()
    }
    func bottomView(longPressDidBegan bottomView: CameraBottomView) {
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            currentZoomFacto = gpuView.effectiveScale
            return
        }
        #endif
        currentZoomFacto = previewView.effectiveScale
    }
    func bottomView(_ bottomView: CameraBottomView, longPressDidChanged scale: CGFloat) {
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            let remaining = gpuView.maxScale - currentZoomFacto
            let zoomScale = currentZoomFacto + remaining * scale
            gpuView.rampZoom(to: zoomScale)
            return
        }
        #endif
        let remaining = previewView.maxScale - currentZoomFacto
        let zoomScale = currentZoomFacto + remaining * scale
        cameraManager.zoomFacto = zoomScale
    }
    func bottomView(longPressDidEnded bottomView: CameraBottomView) {
        #if canImport(GPUImage)
        if config.cameraType == .gpu {
            gpuView.stopRecording()
            return
        }
        #endif
        previewView.effectiveScale = cameraManager.zoomFacto
    }
    func bottomView(didBackButton bottomView: CameraBottomView) {
        delegate?.cameraViewController(didCancel: self)
        if autoDismiss {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func openPhotoResult(_ image: UIImage) {
        let vc = CameraResultViewController(
            image: image,
            tintColor: config.tintColor
        )
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: false)
    }
    func openVideoResult(_ videoURL: URL) {
        let vc = CameraResultViewController(
            videoURL: videoURL,
            tintColor: config.tintColor
        )
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: false)
    }
}

extension CameraViewController: CameraPreviewViewDelegate {
    func previewView(didPreviewing previewView: CameraPreviewView) {
        bottomView.hiddenTip()
        bottomView.isGestureEnable = true
    }
    func previewView(_ previewView: CameraPreviewView, pinchGestureScale scale: CGFloat) {
        cameraManager.zoomFacto = scale
    }
    
    func previewView(_ previewView: CameraPreviewView, tappedToFocusAt point: CGPoint) {
        try? cameraManager.expose(at: point)
    }
    
    func previewView(didLeftSwipe previewView: CameraPreviewView) {
        
    }
    
    func previewView(didRightSwipe previewView: CameraPreviewView) {
        
    }
}

extension CameraViewController: CameraResultViewControllerDelegate {
    func cameraResultViewController(
        didDone cameraResultViewController: CameraResultViewController
    ) {
        let vc = cameraResultViewController
        switch vc.type {
        case .photo:
            if let image = vc.image {
                didFinish(withImage: image)
            }
        case .video:
            if let videoURL = vc.videoURL {
                didFinish(withVideo: videoURL)
            }
        }
    }
    func didFinish(withImage image: UIImage) {
        delegate?.cameraViewController(
            self,
            didFinishWithResult: .image(image),
            location: currentLocation
        )
        if autoDismiss {
            dismiss(animated: true, completion: nil)
        }
    }
    func didFinish(withVideo videoURL: URL) {
        delegate?.cameraViewController(
            self,
            didFinishWithResult: .video(videoURL),
            location: currentLocation
        )
        if autoDismiss {
            dismiss(animated: true, completion: nil)
        }
    }
    func saveCameraImage(_ image: UIImage) {
        let previewSize = previewView.size
        DispatchQueue.global().async {
            let thumbImage = image.scaleToFillSize(size: previewSize)
            PhotoManager.shared.cameraPreviewImage = thumbImage
        }
    }
    func saveCameraVideo(_ videoURL: URL) {
        PhotoTools.getVideoThumbnailImage(
            url: videoURL,
            atTime: 0.1
        ) { _, image, _ in
            if let image = image {
                PhotoManager.shared.cameraPreviewImage = image
            }
        }
    }
}
#if canImport(GPUImage)
extension CameraViewController: CameraGPUImageViewDelegate {
    func gpuImageView(didPreviewing gpuImageView: CameraGPUImageView) {
        bottomView.isGestureEnable = true
        bottomView.hiddenTip()
    }
}
#endif
