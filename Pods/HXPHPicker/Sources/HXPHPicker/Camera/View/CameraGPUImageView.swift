//
//  CameraGPUImageView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/2.
//

#if canImport(GPUImage)
import UIKit
import AVFoundation
import GPUImage

protocol CameraGPUImageViewDelegate: AnyObject {
    func gpuImageView(didPreviewing gpuImageView: CameraGPUImageView)
}

class CameraGPUImageView: UIView {
    weak var delegate: CameraGPUImageViewDelegate?
    lazy var gpuImageView: GPUImageView = {
        let view = GPUImageView()
        return view
    }()
    var camera: GPUImageStillCamera!
    var videoWriter: GPUImageMovieWriter!
    
    lazy var imageMaskView: UIImageView = {
        let view = UIImageView(image: PhotoManager.shared.cameraPreviewImage)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    lazy var shadeView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()
    lazy var focusView: CameraFocusView = {
        let focusView = CameraFocusView(
            size: CGSize(width: 80, height: 80),
            color: config.tintColor
        )
        focusView.layer.opacity = 0
        focusView.isUserInteractionEnabled = false
        return focusView
    }()
    
    let videoURL = PhotoTools.getVideoTmpURL()
    
    var maxScale: CGFloat = 5
    var effectiveScale: CGFloat = 1
    var beginGestureScale: CGFloat = 1
    var didPreviewing = false
    var isRecording = false
    private var capturePhotoCompletion: ((Data?) -> Void)?
    private var recordingStart: ((TimeInterval) -> Void)?
    private var recordingProgress: ((Float, TimeInterval) -> Void)?
    private var recordingCompletion: ((URL, Error?) -> Void)?
    private var dateVideoStarted = Date()
    
    lazy var fileGroup: GPUImageFilterGroup = {
        let fileterGroup = GPUImageFilterGroup()
        
        let bilateralFilter = GPUImageBilateralFilter()
        let exposurefilter = GPUImageExposureFilter()
        let brightnessFilter = GPUImageBrightnessFilter()
        let satureationFilter = GPUImageSaturationFilter()
        
        bilateralFilter.addTarget(brightnessFilter)
        brightnessFilter.addTarget(exposurefilter)
        exposurefilter.addTarget(satureationFilter)
        
        fileterGroup.initialFilters = [bilateralFilter]
        fileterGroup.terminalFilter = satureationFilter
        return fileterGroup
    }()
    
    let config: CameraConfiguration
    init(config: CameraConfiguration) {
        self.config = config
        super.init(frame: .zero)
        addSubview(gpuImageView)
        addSubview(focusView)
        addSubview(imageMaskView)
        addSubview(shadeView)
        setup()
    }
    
    func setup() {
        let position: AVCaptureDevice.Position = config.position == .back ? .back : .front
        camera = GPUImageStillCamera(sessionPreset: config.sessionPreset.system.rawValue, cameraPosition: position)
        guard let camera = camera else { return }
        camera.delegate = self
        camera.outputImageOrientation = UIApplication.shared.statusBarOrientation
        camera.addTarget(fileGroup)
        fileGroup.addTarget(gpuImageView)
        
        videoWriter = GPUImageMovieWriter(movieURL: videoURL, size: config.sessionPreset.size)
        videoWriter.encodingLiveVideo = true
        
        camera.audioEncodingTarget = videoWriter
        fileGroup.addTarget(videoWriter)
        do {
            if try canZoomCamera() {
                setupGestureRecognizer()
            }
        } catch {}
        addSwipeGesture()
    }
    
    func setupGestureRecognizer() {
        let pinch = UIPinchGestureRecognizer(
            target: self,
            action: #selector(handlePinchGesture(_:))
        )
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture(_:))
        )
        
        gpuImageView.addGestureRecognizer(pinch)
        gpuImageView.addGestureRecognizer(tap)
    }
    
    func addSwipeGesture() {
        let leftSwipe = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleLeftSwipeGesture(_:))
        )
        leftSwipe.direction = .left

        let rightSwipe = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleRightSwipeGesture(_:))
        )
        leftSwipe.direction = .right

        gpuImageView.addGestureRecognizer(leftSwipe)
        gpuImageView.addGestureRecognizer(rightSwipe)
    }
    
    @objc
    func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) {
        if pinch.state == .began {
            beginGestureScale = effectiveScale
        }else if pinch.state == .changed {
            var scale = beginGestureScale * pinch.scale
            scale = min(scale, maxScale)
            scale = max(scale, 1)
            rampZoom(to: scale)
        }
    }
    
    func rampZoom(to value: CGFloat) {
        zoomFacto = value
        effectiveScale = value
    }
    
    @objc
    func handleTapGesture(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: self)
        PhotoTools.focusAnimation(for: focusView, at: point)
        expose(at: point)
    }
    
    @objc
    func handleLeftSwipeGesture(_ swipe: UISwipeGestureRecognizer) {
        if swipe.direction == .left {
            
        }
    }
    
    @objc
    func handleRightSwipeGesture(_ swipe: UISwipeGestureRecognizer) {
        if swipe.direction == .right {
            
        }
    }
    
    func startRunning() {
        guard let camera = camera else { return }
        camera.startCapture()
    }
    
    func stopRunning() {
        guard let camera = camera else { return }
        camera.stopCapture()
        didPreviewing = false
    }
    
    func resetMetal() {
        if !didPreviewing {
            return
        }
        guard let camera = camera else { return }
        camera.outputImageOrientation = UIApplication.shared.statusBarOrientation
        let videoOrientation: AVCaptureVideoOrientation
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        switch interfaceOrientation {
        case .portrait:
            videoOrientation = .portrait
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoOrientation = .landscapeRight
        default:
            videoOrientation = .portrait
        }
        camera.videoCaptureConnection().videoOrientation = videoOrientation
    }
    
    func canZoomCamera() throws -> Bool {
        guard let camera = camera else { return false }
        return camera.inputCamera.activeFormat.videoMaxZoomFactor > 1
    }
    var maxZoomFactor: CGFloat {
        guard let camera = camera else { return 1}
        return min(camera.inputCamera.activeFormat.videoMaxZoomFactor, config.videoMaxZoomScale)
    }
    var zoomFacto: CGFloat {
        get {
            guard let camera = camera else { return 1}
            return camera.inputCamera.videoZoomFactor
        }
        set {
            guard let camera = camera.inputCamera,
                  !camera.isRampingVideoZoom else { return }
            let zoom = min(newValue, maxZoomFactor)
            do {
                try camera.lockForConfiguration()
                camera.videoZoomFactor = zoom
                camera.unlockForConfiguration()
            } catch { }
        }
    }
    
    func switchCamera() {
        guard let camera = camera else { return }
        camera.rotateCamera()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let camera = camera, !isRecording else { return }
        camera.capturePhotoAsImageProcessedUp(toFilter: fileGroup) { image, error in
            if let image = image {
                completion(image)
            }else {
                completion(nil)
            }
        }
    }
    
    func startRecording(
        didStart: @escaping (TimeInterval) -> Void,
        progress: @escaping (Float, TimeInterval) -> Void,
        completion: @escaping (URL, Error?) -> Void
    ) {
        if isRecording {
            return
        }
        if FileManager.default.fileExists(atPath: videoURL.path) {
            do {
                try FileManager.default.removeItem(at: videoURL)
            } catch {
                completion(videoURL, NSError(domain: "videoURL is error", code: 500, userInfo: nil))
                return
            }
        }
        isRecording = true
        recordingStart = didStart
        recordingProgress = progress
        recordingCompletion = completion
        videoWriter.startRecording()
        dateVideoStarted = Date()
        recordingStart?(config.videoMaximumDuration)
//        videoWriter.videoInputReadyCallback = { [weak self] in
//            guard let self = self else { return }
//        }
//        videoWriter.enableSynchronizationCallbacks()
        
//        videoWriter.start { [weak self] time in
//            guard let self = self else { return }
//            self.dateVideoStarted = Date()
//            DispatchQueue.main.async {
//                self.recordingStart?(self.config.videoMaximumDuration)
//            }
//        } progress: { [weak self] progressType in
//            guard let self = self else { return }
//            let timeElapsed = Date().timeIntervalSince(self.dateVideoStarted)
//            if timeElapsed >= self.config.videoMaximumDuration {
//                DispatchQueue.main.async {
//                    self.stopRecording()
//                }
//                return
//            }
//        }
//        self.videoWriter = videoWriter
    }
    
    func stopRecording() {
        if !isRecording {
            return
        }
        videoWriter.finishRecording { [weak self ] in
            guard let self = self else { return }
            let timeElapsed = Date().timeIntervalSince(self.dateVideoStarted)
            var error: Error?
            if timeElapsed < self.config.videoMinimumDuration {
                error = NSError(
                    domain: "Recording time is too short",
                    code: 110,
                    userInfo: nil
                )
            }
            DispatchQueue.main.async {
                self.recordingCompletion?(self.videoURL, error)
            }
        }
        isRecording = false
    }
    
    func resetMask(_ image: UIImage?) {
        imageMaskView.image = image
        imageMaskView.alpha = 1
        addSubview(imageMaskView)
        shadeView.viewWithTag(1)?.alpha = 1
        let effect = UIBlurEffect(style: .light)
        shadeView.effect = effect
        addSubview(shadeView)
    }
    
    func removeMask(_ animation: Bool = true) {
        if shadeView.superview == nil {
            return
        }
        if animation {
            UIView.animate(withDuration: 0.35) {
                self.shadeView.effect = nil
                self.shadeView.viewWithTag(1)?.alpha = 0
                self.imageMaskView.alpha = 0
            } completion: { _ in
                self.shadeView.removeFromSuperview()
                self.imageMaskView.removeFromSuperview()
                self.initialFocus()
            }
        }else {
            shadeView.effect = nil
            shadeView.removeFromSuperview()
            imageMaskView.removeFromSuperview()
            initialFocus()
        }
    }
    
    func initialFocus() {
        let point = CGPoint(x: width * 0.5, y: height * 0.5)
        PhotoTools.focusAnimation(for: focusView, at: point)
        expose(at: point)
    }
    
    func expose(at point: CGPoint) {
        guard let device = camera.inputCamera else {
            return
        }
        let point = captureDevicePointConverted(at: point)
        let exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
        let focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
        let canResetFocus = device.isFocusPointOfInterestSupported &&
            device.isFocusModeSupported(focusMode)
        let canResetExposure = device.isExposurePointOfInterestSupported &&
            device.isExposureModeSupported(exposureMode)
        try? device.lockForConfiguration()
        if canResetFocus {
            device.focusPointOfInterest = point
            device.focusMode = focusMode
        }
        if canResetExposure {
            device.exposurePointOfInterest = point
            device.exposureMode = exposureMode
        }
        device.unlockForConfiguration()
    }
    
    func resetFocusAndExposeModes() {
        let centerPoint = CGPoint(x: 0.5, y: 0.5)
        expose(at: centerPoint)
    }
    
    func captureDevicePointConverted(at point: CGPoint) -> CGPoint {
        let x: CGFloat
        let y: CGFloat
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        switch interfaceOrientation {
        case .portrait:
            x = point.y / height
            y = 1 - point.x / width
        case .portraitUpsideDown:
            x = 1 - point.y / height
            y = point.x / width
        case .landscapeLeft:
            x = point.y / height
            y = 1 - point.x / width
        case .landscapeRight:
            x = point.y / height
            y = point.x / width
        default:
            x = point.y / height
            y = 1 - point.x / width
        }
        return CGPoint(x: x, y: y)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gpuImageView.frame = bounds
        shadeView.frame = bounds
        imageMaskView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CameraGPUImageView: GPUImageVideoCameraDelegate {
    func willOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer!) {
        if !self.didPreviewing {
            DispatchQueue.main.async {
                self.delegate?.gpuImageView(didPreviewing: self)
                self.removeMask()
            }
            self.didPreviewing = true
        }
        if let image = PhotoTools.createImage(from: sampleBuffer)?.rotation(to: .right) {
            PhotoManager.shared.cameraPreviewImage = image
        }
    }
}
#endif
