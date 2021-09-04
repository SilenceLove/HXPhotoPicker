//
//  CameraManager.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import Foundation
import AVFoundation

class CameraManager: NSObject {
    let config: CameraConfiguration
    
    lazy var session: AVCaptureSession = {
        AVCaptureSession()
    }()
    
    lazy var photoOutput: AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput()
        return output
    }()
    
    lazy var movieOutput: AVCaptureMovieFileOutput = {
        let output = AVCaptureMovieFileOutput()
        let timeScale: Int32 = 30 // FPS
        let maxDuration = CMTimeMakeWithSeconds(
            max(1, config.videoMaximumDuration),
            preferredTimescale: timeScale
        )
        output.maxRecordedDuration = maxDuration
        return output
    }()
    
    var didAddVideoOutput = false
    lazy var videoOutput: AVCaptureVideoDataOutput = {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "com.hxphpicker.camerapreview")
        )
        videoOutput.alwaysDiscardsLateVideoFrames = true
        return videoOutput
    }()
    
    let sessionQueue: DispatchQueue = .init(
        label: "com.phpicker.sessionQueue",
        qos: .background
    )
    
    var activeVideoInput: AVCaptureDeviceInput?
    private(set) var flashMode: AVCaptureDevice.FlashMode = .auto
    
    private var recordDuration: TimeInterval = 0
    private var photoWillCapture: (() -> Void)?
    private var photoCompletion: ((Data?) -> Void)?
    private var videoRecordingProgress: ((Float, TimeInterval) -> Void)?
    private var videoCompletion: ((URL, Error?) -> Void)?
    private var timer: Timer?
    private var dateVideoStarted = Date()
    private var videoDidStartRecording: ((TimeInterval) -> Void)?
    
    init(config: CameraConfiguration) {
        self.config = config
        super.init()
        DeviceOrientationHelper.shared.startDeviceOrientationNotifier()
    }
    
    func startSession() throws {
        var sessionPreset = config.sessionPreset.system
        if !session.canSetSessionPreset(sessionPreset) {
            sessionPreset = .high
        }
        session.sessionPreset = sessionPreset
        let position: AVCaptureDevice.Position = config.position == .back ? .back : .front
        let videoDevice: AVCaptureDevice
        if let device = camera(with: position) {
            videoDevice = device
        }else if let device = camera(with: .back) {
            videoDevice = device
        }else {
            throw NSError(
                domain: "Video device is nil",
                code: 500,
                userInfo: nil
            )
        }
        
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        
        if !session.canAddInput(videoInput) {
            throw NSError(
                domain: "Does not support adding video input",
                code: 500,
                userInfo: nil
            )
        }
        session.addInput(videoInput)
        activeVideoInput = videoInput
    }
    
    func addAudioInput() throws {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw NSError(
                domain: "Audio device is nil",
                code: 500,
                userInfo: nil
            )
        }
        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
        if !session.canAddInput(audioInput) {
            throw NSError(
                domain: "Does not support adding audio input",
                code: 500,
                userInfo: nil
            )
        }
        session.addInput(audioInput)
    }
    
    func addPhotoOutput() throws {
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            // Improve capture time by preparing output with the desired settings.
            photoOutput.setPreparedPhotoSettingsArray([photoCaptureSettings()], completionHandler: nil)
            return
        }
        throw NSError(
            domain: "Can't add photo output",
            code: 500,
            userInfo: nil
        )
    }
    
    func addMovieOutput() throws {
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            if let videoConnection = movieOutput.connection(with: .video),
               videoConnection.isVideoStabilizationSupported {
                videoConnection.preferredVideoStabilizationMode = .auto
            }
            return
        }
        throw NSError(
            domain: "Can't add movie output",
            code: 500,
            userInfo: nil
        )
    }
    
    func removePhotoOutput() {
        session.removeOutput(photoOutput)
    }
    
    func removeMovieOutput() {
        session.removeOutput(movieOutput)
    }
    
    func startRunning() {
        if session.isRunning {
            return
        }
        sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    func stopRunning() {
        if !session.isRunning {
            return
        }
        sessionQueue.async {
            self.session.stopRunning()
        }
    }
    
    func addVideoOutput() {
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            didAddVideoOutput = true
        }
    }
    deinit {
        if didAddVideoOutput {
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
            didAddVideoOutput = false
        }
    }
}

extension CameraManager {
    
    func discoverySession(
        with position: AVCaptureDevice.Position = .unspecified
    ) -> AVCaptureDevice.DiscoverySession {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera
        ]
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )
    }
    
    func cameraCount() -> Int {
        discoverySession().devices.count
    }
    
    func camera(
        with position: AVCaptureDevice.Position
    ) -> AVCaptureDevice? {
        let discoverySession = discoverySession(
            with: position
        )
        for device in discoverySession.devices where
            device.position == position {
            return device
        }
        return nil
    }
    
    func canSwitchCameras() -> Bool {
        cameraCount() > 1
    }
    
    var activeCamera: AVCaptureDevice? {
        activeVideoInput?.device
    }
    
    func inactiveCamer() -> AVCaptureDevice? {
        if let device = activeCamera {
            if device.position == .back {
                return camera(with: .front)
            }
            return camera(with: .back)
        }
        return camera(with: .back)
    }
    
    func cameraSupportsTapToFocus() -> Bool {
        guard let camera = activeCamera else {
            return false
        }
        return camera.isFocusPointOfInterestSupported
    }
    
    func cameraHasFlash() -> Bool {
        guard let camera = activeCamera else {
            return false
        }
        return camera.hasFlash
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) -> Bool {
        let contains = flashModeContains(mode)
        if contains {
            flashMode = mode
        }
        return contains
    }
    
    func cameraHasTorch() -> Bool {
        guard let camera = activeCamera else {
            return false
        }
        return camera.hasTorch
    }
    
    func torchMode() -> AVCaptureDevice.TorchMode {
        guard let camera = activeCamera else {
            return .auto
        }
        return camera.torchMode
    }
    
    func setTorchMode(_ mode: AVCaptureDevice.TorchMode) throws {
        guard let device = activeCamera else {
            return
        }
        if device.torchMode != mode && device.isTorchModeSupported(mode) {
            try device.lockForConfiguration()
            device.torchMode = mode
            device.unlockForConfiguration()
        }
    }
    
    var isSupportsZoom: Bool {
        guard let camera = activeCamera else {
            return false
        }
        return camera.activeFormat.videoMaxZoomFactor > 1.0
    }
    
    var maxZoomFactor: CGFloat {
        guard let camera = activeCamera else {
            return 1
        }
        return min(camera.activeFormat.videoMaxZoomFactor, config.videoMaxZoomScale)
    }
    
    var zoomFacto: CGFloat {
        get {
            guard let camera = activeCamera else {
                return 1
            }
            return camera.videoZoomFactor
        }
        set {
            guard let camera = activeCamera,
                  !camera.isRampingVideoZoom else { return }
            let zoom = min(newValue, maxZoomFactor)
            do {
                try camera.lockForConfiguration()
                camera.videoZoomFactor = zoom
                camera.unlockForConfiguration()
            } catch { }
        }
    }
    
    func rampZoom(to value: CGFloat) throws {
        guard let camera = activeCamera else { return }
        try camera.lockForConfiguration()
        camera.ramp(toVideoZoomFactor: value, withRate: 1)
        camera.unlockForConfiguration()
    }
    
    func cancelZoom() throws {
        guard let camera = activeCamera else { return }
        try camera.lockForConfiguration()
        camera.cancelVideoZoomRamp()
        camera.unlockForConfiguration()
    }
}

extension CameraManager {
    
    func switchCameras() throws {
        if !canSwitchCameras() {
            throw NSError(
                domain: "Does not support switch Cameras",
                code: 500,
                userInfo: nil
            )
        }
        guard let device = inactiveCamer() else {
            throw NSError(
                domain: "device is nil",
                code: 500,
                userInfo: nil
            )
        }
        let videoInput = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        if let input = activeVideoInput {
            session.removeInput(input)
        }
        if !session.canAddInput(videoInput) {
            session.commitConfiguration()
            throw NSError(
                domain: "Does not support adding audio input",
                code: 500,
                userInfo: nil
            )
        }
        session.addInput(videoInput)
        activeVideoInput = videoInput
        session.commitConfiguration()
    }
    
    func expose(at point: CGPoint) throws {
        guard let device = activeCamera else {
            return
        }
        let exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
        let focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
        let canResetFocus = device.isFocusPointOfInterestSupported &&
            device.isFocusModeSupported(focusMode)
        let canResetExposure = device.isExposurePointOfInterestSupported &&
            device.isExposureModeSupported(exposureMode)
        
        try device.lockForConfiguration()
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
    
    func resetFocusAndExposeModes() throws {
        let centerPoint = CGPoint(x: 0.5, y: 0.5)
        try expose(at: centerPoint)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    
    func flashModeContains(_ mode: AVCaptureDevice.FlashMode) -> Bool {
        let supportedFlashModes = photoOutput.__supportedFlashModes
        switch mode {
        case .auto:
            if supportedFlashModes.contains(NSNumber(value: AVCaptureDevice.FlashMode.auto.rawValue)) {
                return true
            }
        case .off:
            if supportedFlashModes.contains(NSNumber(value: AVCaptureDevice.FlashMode.off.rawValue)) {
                return true
            }
        case .on:
            if supportedFlashModes.contains(NSNumber(value: AVCaptureDevice.FlashMode.on.rawValue)) {
                return true
            }
        @unknown default:
            fatalError()
        }
        return false
    }
    
    func photoCaptureSettings() -> AVCapturePhotoSettings {
        var settings = AVCapturePhotoSettings()
        
        // Catpure Heif when available.
        if #available(iOS 11.0, *) {
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
        }
        
        // Catpure Highest Quality possible.
        settings.isHighResolutionPhotoEnabled = true
        
        // Set flash mode.
        if let deviceInput = activeCamera {
            if deviceInput.isFlashAvailable && flashModeContains(flashMode) {
                settings.flashMode = flashMode
            }
        }
        
        return settings
    }
    
    func capturePhoto(
        willBegin: @escaping () -> Void,
        completion: @escaping (Data?) -> Void
    ) {
        photoWillCapture = willBegin
        photoCompletion = completion
        let connection = photoOutput.connection(with: .video)
        connection?.videoOrientation = currentOrienation
        photoOutput.capturePhoto(with: photoCaptureSettings(), delegate: self)
    }
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        photoWillCapture?()
    }
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = photo.fileDataRepresentation()
        photoCompletion?(data)
    }
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
        previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
        resolvedSettings: AVCaptureResolvedPhotoSettings,
        bracketSettings: AVCaptureBracketedStillImageSettings?,
        error: Error?
    ) {
        guard let buffer = photoSampleBuffer else {
            photoCompletion?(nil)
            return
        }
        let data = AVCapturePhotoOutput
            .jpegPhotoDataRepresentation(
                forJPEGSampleBuffer: buffer,
                previewPhotoSampleBuffer: previewPhotoSampleBuffer)
        photoCompletion?(data)
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    
    var isRecording: Bool {
        movieOutput.isRecording
    }
    
    func startRecording(
        didStart: @escaping (TimeInterval) -> Void,
        progress: @escaping (Float, TimeInterval) -> Void,
        completion: @escaping (URL, Error?) -> Void
    ) {
        let videoURL = PhotoTools.getVideoTmpURL()
        guard let connection = movieOutput.connection(with: .video),
              !isRecording else {
            completion(videoURL, NSError(domain: "connection is nil", code: 500, userInfo: nil))
            return
        }
        videoDidStartRecording = didStart
        videoRecordingProgress = progress
        videoCompletion = completion
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = currentOrienation
        }
        if UIDevice.belowIphone7 {
            movieOutput.setOutputSettings(
                [AVVideoCodecKey: AVVideoCodecH264],
                for: connection
            )
        }
        if let isSmoothAuto = activeCamera?.isSmoothAutoFocusSupported,
           isSmoothAuto {
            try? activeCamera?.lockForConfiguration()
            activeCamera?.isSmoothAutoFocusEnabled = true
            activeCamera?.unlockForConfiguration()
        }
        recordDuration = 0
        movieOutput.startRecording(
            to: videoURL,
            recordingDelegate: self
        )
    }
    
    func stopRecording() {
        invalidateTimer()
        movieOutput.stopRecording()
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        videoDidStartRecording?(config.videoMaximumDuration)
        let timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true,
            block: { [weak self] timer in
                guard let self = self else { return }
                let timeElapsed = Date().timeIntervalSince(self.dateVideoStarted)
                let progress = Float(timeElapsed) / Float(self.config.videoMaximumDuration)
                self.recordDuration = timeElapsed
                // VideoOutput configuration is responsible for stopping the recording. Not here.
                DispatchQueue.main.async {
                    self.videoRecordingProgress?(progress, timeElapsed)
                }
            }
        )
        dateVideoStarted = Date()
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        invalidateTimer()
        if recordDuration < config.videoMinimumDuration {
            videoCompletion?(
                outputFileURL,
                NSError(
                    domain: "Recording time is too short",
                    code: 110,
                    userInfo: nil
                )
            )
            return
        }
        if let error = error as NSError?,
           let isFullyFinished = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ,
           isFullyFinished {
            videoCompletion?(outputFileURL, nil)
        }else {
            videoCompletion?(outputFileURL, error)
        }
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension CameraManager {
    var currentOrienation: AVCaptureVideoOrientation {
        let orientation = DeviceOrientationHelper.shared.currentDeviceOrientation
        switch orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeRight:
            return .landscapeLeft
        case .landscapeLeft:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if let image = PhotoTools.createImage(from: sampleBuffer)?.rotation(to: .right) {
            PhotoManager.shared.cameraPreviewImage = image
        }
    }
}
