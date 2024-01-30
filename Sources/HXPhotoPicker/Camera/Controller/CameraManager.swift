//
//  CameraManager.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import AVFoundation

#if !targetEnvironment(macCatalyst)
class CameraManager: NSObject {
    let config: CameraConfiguration
    
    let sessionQueue: DispatchQueue = .init(
        label: "com.phpicker.sessionQueue",
        qos: .background
    )
    var session: AVCaptureSession = .init()
    var photoOutput: AVCapturePhotoOutput = .init()
    
    let outputQueue: DispatchQueue = DispatchQueue(label: "com.HXPhotoPicker.cameraoutput")
    var videoOutput: AVCaptureVideoDataOutput!
    var audioOutput: AVCaptureAudioDataOutput!
    
    var assetWriter: AVAssetWriter?
    var assetWriterVideoInput: AVAssetWriterInputPixelBufferAdaptor?
    var assetWriterAudioInput: AVAssetWriterInput?
    
    var activeVideoInput: AVCaptureDeviceInput?
    
    var didAddVideoOutput = false
    var didAddAudioOutput = false
    var isRecording: Bool = false
    var flashModeDidChanged: ((AVCaptureDevice.FlashMode) -> Void)?
    var captureDidOutput: ((CVPixelBuffer) -> Void)?
    
    private(set) var flashMode: AVCaptureDevice.FlashMode
    private var recordDuration: TimeInterval = 0
    private var photoWillCapture: (() -> Void)?
    private var photoCompletion: ((Data?) -> Void)?
    private var videoRecordingProgress: ((Float, TimeInterval) -> Void)?
    private var videoCompletion: ((URL?, Error?) -> Void)?
    private var timer: Timer?
    private var dateVideoStarted = Date()
    private var videoDidStartRecording: ((TimeInterval) -> Void)?
    private var captureState: CaptureState = .end
    private var didStartWriter = false
    private var didWriterVideoInput = false
    private var writerVideoInputTime: CMTime?
    private var videoInpuCompletion = false
    private var audioInpuCompletion = false
    private var isDevicePortrait = true
    private let context = CIContext(options: nil)
    
    let videoFilter: CameraRenderer
    let photoFilter: CameraRenderer
    var filterIndex: Int {
        get {
            videoFilter.filterIndex
        }
        set {
            videoFilter.filterIndex = newValue
            photoFilter.filterIndex = newValue
        }
    }
    
    init(config: CameraConfiguration) {
        self.flashMode = config.flashMode
        self.config = config
        if config.cameraType == .metal {
            var photoFilters = self.config.photoFilters
            photoFilters.insert(OriginalFilter(), at: 0)
            var videoFilters = self.config.videoFilters
            videoFilters.insert(OriginalFilter(), at: 0)
            var index = config.defaultFilterIndex
            if index == -1 {
                index = 0
            }else {
                index += 1
            }
            self.photoFilter = .init(photoFilters, index)
            self.videoFilter = .init(videoFilters, index)
        }else {
            self.photoFilter = .init([], 0)
            self.videoFilter = .init([], 0)
        }
        super.init()
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(
            self,
            queue: outputQueue
        )
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(
            self,
            queue: outputQueue
        )
        
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
        if !videoInput.device.supportsSessionPreset(session.sessionPreset) {
            session.sessionPreset = .hd1920x1080
        }
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
    
    func removePhotoOutput() {
        session.removeOutput(photoOutput)
    }
    
    func startRunning(applyQueue: Bool = true) {
        if session.isRunning {
            return
        }
        if applyQueue {
            sessionQueue.async {
                self.session.startRunning()
            }
        }else {
            session.startRunning()
        }
    }
    
    func stopRunning(applyQueue: Bool = true) {
        if !session.isRunning {
            return
        }
        if applyQueue {
            sessionQueue.async {
                self.session.stopRunning()
            }
        }else {
            session.stopRunning()
        }
    }
    
    func addVideoOutput() {
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            didAddVideoOutput = true
        }
    }
    
    func addAudioOutput() {
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
            didAddAudioOutput = true
        }
    }
    deinit {
        if didAddVideoOutput {
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
            didAddVideoOutput = false
        }
        if didAddAudioOutput {
            audioOutput.setSampleBufferDelegate(nil, queue: nil)
            didAddAudioOutput = false
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
    
    @discardableResult
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) -> Bool {
        if flashMode == mode { return true }
        let contains = flashModeContains(mode)
        if contains {
            flashMode = mode
            flashModeDidChanged?(flashMode)
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
            } catch {
                HXLog("相机缩放失败: \(error)")
            }
        }
    }
    
    func rampZoom(to value: CGFloat, withRate rate: Float = 1) throws {
        guard let camera = activeCamera else { return }
        try camera.lockForConfiguration()
        camera.ramp(toVideoZoomFactor: value, withRate: rate)
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
        if !videoInput.device.supportsSessionPreset(config.sessionPreset.system) {
            session.sessionPreset = .hd1920x1080
        }else {
            if session.sessionPreset != config.sessionPreset.system {
                session.sessionPreset = config.sessionPreset.system
            }
        }
        if !session.canAddInput(videoInput) {
            if let input = activeVideoInput {
                session.addInput(input)
            }
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
        let deviceRect: CGRect
        if config.cameraType == .metal {
            let textureRect = CGRect(origin: point, size: .zero)
            deviceRect = videoOutput.metadataOutputRectConverted(fromOutputRect: textureRect)
        }else {
            deviceRect = .init(origin: point, size: .zero)
        }
        let exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
        let focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
        let canResetFocus = device.isFocusPointOfInterestSupported &&
            device.isFocusModeSupported(focusMode)
        let canResetExposure = device.isExposurePointOfInterestSupported &&
            device.isExposureModeSupported(exposureMode)
        
        try device.lockForConfiguration()
        if canResetFocus {
            device.focusPointOfInterest = deviceRect.origin
            device.focusMode = focusMode
        }
        if canResetExposure {
            device.exposurePointOfInterest = deviceRect.origin
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
        let settings = AVCapturePhotoSettings(
            format: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
        )
        var imageWidth = Int(config.sessionPreset.size.height)
        var imageHeight = Int(config.sessionPreset.size.width)
        if !UIDevice.isPad {
            let ratioSize = config.aspectRatio.size
            switch ratioSize {
            case .init(width: -1, height: -1):
                let scale = UIScreen.main.bounds.height / UIScreen.main.bounds.width
                imageHeight = Int(CGFloat(imageWidth) / scale)
            case .zero, .init(width: 9, height: 16):
                break
            default:
                imageWidth = Int(CGFloat(imageHeight) / ratioSize.width * ratioSize.height)
            }
        }
        settings.previewPhotoFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: imageWidth,
            kCVPixelBufferHeightKey as String: imageHeight
        ]
        // Catpure Heif when available.
//        if #available(iOS 11.0, *) {
//            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
//                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
//            }
//        }
        
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
        if let connection = photoOutput.connection(with: .video) {
            connection.videoOrientation = currentOrienation
            if connection.isVideoMirroringSupported {
                if activeCamera?.position == .front {
                    connection.isVideoMirrored = true
                }else {
                    connection.isVideoMirrored = false
                }
            }
        }
        photoOutput.capturePhoto(with: photoCaptureSettings(), delegate: self)
    }
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        photoWillCapture?()
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
        previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
        resolvedSettings: AVCaptureResolvedPhotoSettings,
        bracketSettings: AVCaptureBracketedStillImageSettings?,
        error: Error?
    ) {
        if #available(iOS 11.0, *) {
            return
        }
        let sampleBuffer: CMSampleBuffer
        if let previewPhotoSampleBuffer = previewPhotoSampleBuffer {
            sampleBuffer = previewPhotoSampleBuffer
        }else if let photoSampleBuffer = photoSampleBuffer {
            sampleBuffer = photoSampleBuffer
        }else {
            photoCompletion?(nil)
            return
        }
        guard let photoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            photoCompletion?(nil)
            return
        }
        let metaData = CMCopyDictionaryOfAttachments(
            allocator: kCFAllocatorDefault,
            target: sampleBuffer,
            attachmentMode: kCMAttachmentMode_ShouldPropagate
        )
        finishProcessingPhoto(cropPhotoPixelBuffer(photoPixelBuffer), metaData)
    }
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoPixelBuffer = photo.previewPixelBuffer else {
            photoCompletion?(nil)
            return
        }
        finishProcessingPhoto(cropPhotoPixelBuffer(photoPixelBuffer), photo.metadata as CFDictionary)
    }
    
    func cropPhotoPixelBuffer(_ photoPixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        var pixelBuffer = photoPixelBuffer
        if !UIDevice.isPad {
            var imageWidth = CVPixelBufferGetWidth(pixelBuffer)
            var imageHeight = CVPixelBufferGetHeight(pixelBuffer)
            var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            var hasCrop = false
            let baseWidth = imageWidth
            let baseHeight = imageHeight
            let ratioSize = config.aspectRatio.size
            switch ratioSize {
            case .init(width: -1, height: -1):
                let scale = UIScreen.main.bounds.height / UIScreen.main.bounds.width
                imageHeight = Int(CGFloat(imageWidth) / scale)
                let y = abs((baseHeight - imageHeight) / 2)
                ciImage = ciImage.cropped(
                    to: .init(x: 0, y: y, width: imageWidth, height: imageHeight)
                ).transformed(by: .init(translationX: 0, y: -CGFloat(y)))
                hasCrop = true
            case .zero, .init(width: 9, height: 16):
                break
            default:
                imageWidth = Int(CGFloat(imageHeight) / ratioSize.width * ratioSize.height)
                let x = abs((baseWidth - imageWidth) / 2)
                ciImage = ciImage.cropped(
                    to: .init(x: x, y: 0, width: imageWidth, height: imageHeight)
                ).transformed(by: .init(translationX: -CGFloat(x), y: 0))
                hasCrop = true
            }
            if hasCrop {
                if let newPixelBuffer = PhotoTools.createPixelBuffer(.init(width: imageWidth, height: imageHeight)) {
                    context.render(ciImage, to: newPixelBuffer)
                    pixelBuffer = newPixelBuffer
                }
            }
        }
        return pixelBuffer
    }
    
    func finishProcessingPhoto(
        _ photoPixelBuffer: CVPixelBuffer,
        _ metaData: CFDictionary?
    ) {
        var photoFormatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: photoPixelBuffer,
            formatDescriptionOut: &photoFormatDescription
        )
        DispatchQueue.global().async {
            var finalPixelBuffer = photoPixelBuffer
            if self.config.cameraType == .metal, self.photoFilter.filterIndex > 0 {
                if !self.photoFilter.isPrepared {
                    if let formatDescription = photoFormatDescription {
                        self.photoFilter.prepare(
                            with: formatDescription,
                            outputRetainedBufferCountHint: 2,
                            imageSize: .init(
                                width: CVPixelBufferGetWidth(photoPixelBuffer),
                                height: CVPixelBufferGetHeight(photoPixelBuffer)
                            )
                        )
                    }
                }
                guard let filteredBuffer = self.photoFilter.render(
                    pixelBuffer: photoPixelBuffer
                ) else {
                    DispatchQueue.main.async {
                        self.photoCompletion?(nil)
                    }
                    return
                }
                finalPixelBuffer = filteredBuffer
            }
            let metadataAttachments = metaData
            let jpegData = PhotoTools.jpegData(
                withPixelBuffer: finalPixelBuffer,
                attachments: metadataAttachments
            )
            DispatchQueue.main.async {
                self.photoCompletion?(jpegData)
            }
        }
    }
}

extension CameraManager {
    enum CaptureState {
        case start
        case capturing
        case end
    }
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

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate,
                         AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        var finalVideoPixelBuffer: CVPixelBuffer?
        if output == videoOutput {
            PhotoManager.shared.sampleBuffer = sampleBuffer
            guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
                  let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
            else {
                return
            }
            finalVideoPixelBuffer = videoPixelBuffer
            if config.cameraType == .metal, videoFilter.filterIndex > 0 {
                if !videoFilter.isPrepared {
                    videoFilter.prepare(
                        with: formatDescription,
                        outputRetainedBufferCountHint: 3,
                        imageSize: .init(
                            width: CVPixelBufferGetWidth(videoPixelBuffer),
                            height: CVPixelBufferGetHeight(videoPixelBuffer)
                        )
                    )
                }
                guard let filteredBuffer = videoFilter.render(
                    pixelBuffer: videoPixelBuffer
                ) else {
                    return
                }
                captureDidOutput?(filteredBuffer)
                finalVideoPixelBuffer = filteredBuffer
            }else {
                captureDidOutput?(videoPixelBuffer)
            }
        }
        if captureState == .start && output == videoOutput {
            if !CMSampleBufferDataIsReady(sampleBuffer) {
                return
            }
            if !setupWriter(sampleBuffer) {
                resetAssetWriter()
                DispatchQueue.main.async {
                    self.videoCompletion?(nil, nil)
                }
                return
            }
            guard let assetWriter = assetWriter else { return }
            if !assetWriter.startWriting() {
                DispatchQueue.main.async {
                    self.videoCompletion?(nil, assetWriter.error)
                }
                resetAssetWriter()
                return
            }
            captureState = .capturing
        }else if captureState == .capturing {
            if !didStartWriter {
                guard let assetWriter = assetWriter else { return }
                DispatchQueue.main.async {
                    self.didStartRecording()
                }
                let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let startingTimeDelay = CMTimeMakeWithSeconds(0.1, preferredTimescale: sampleTime.timescale)
                let startTimeToUse = CMTimeAdd(sampleTime, startingTimeDelay)
                assetWriter.startSession(atSourceTime: startTimeToUse)
                didStartWriter = true
            }
            inputAppend(output, sampleBuffer, finalVideoPixelBuffer)
        }else if captureState == .end {
            guard let assetWriter = assetWriter, timer != nil else {
                return
            }
            inputAppend(output, sampleBuffer, finalVideoPixelBuffer)
            if assetWriter.status != .writing {
                return
            }
            if output == videoOutput {
                if !videoInpuCompletion {
                    videoInpuCompletion.toggle()
                    assetWriterVideoInput?.assetWriterInput.markAsFinished()
                }
                if !audioInpuCompletion {
                    return
                }
            }else if output == audioOutput {
                if !audioInpuCompletion {
                    audioInpuCompletion.toggle()
                    assetWriterAudioInput?.markAsFinished()
                }
                if !videoInpuCompletion {
                    return
                }
            }
            invalidateTimer()
            let videoURL = assetWriter.outputURL
            assetWriter.finishWriting { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.didFinishRecording(videoURL)
                }
                self.resetAssetWriter()
            }
        }
    }
    private func inputAppend(
        _ output: AVCaptureOutput,
        _ sampleBuffer: CMSampleBuffer,
        _ pixelBuffer: CVPixelBuffer?
    ) {
        if !didStartWriter { return }
        if output == videoOutput {
            videoInputAppend(sampleBuffer, pixelBuffer)
        }else if output == audioOutput {
            audioInputAppend(sampleBuffer)
        }
    }
    private func audioInputAppend(
        _ sampleBuffer: CMSampleBuffer
    ) {
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        var allowInput: Bool = true
        if let time = writerVideoInputTime, sampleTime < time {
            allowInput = false
        }else if writerVideoInputTime == nil {
            allowInput = false
        }
        if let audioInput = assetWriterAudioInput,
           audioInput.isReadyForMoreMediaData,
           didWriterVideoInput,
           allowInput {
            audioInput.append(sampleBuffer)
        }
    }
    private func videoInputAppend(
        _ sampleBuffer: CMSampleBuffer,
        _ pixelBuffer: CVPixelBuffer?
    ) {
        if let assetWriterVideoInput = assetWriterVideoInput,
           assetWriterVideoInput.assetWriterInput.isReadyForMoreMediaData {
            guard var pixelBuffer = pixelBuffer else { return }
            let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            var videoWidth = CVPixelBufferGetWidth(pixelBuffer)
            var videoHeight = CVPixelBufferGetHeight(pixelBuffer)
            var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            var hasCrop = false
            let baseWidth = videoWidth
            let baseHeight = videoHeight
            
            if !UIDevice.isPad {
                let ratioSize = config.aspectRatio.size
                switch ratioSize {
                case .init(width: -1, height: -1):
                    let scale = UIScreen.main.bounds.height / UIScreen.main.bounds.width
                    videoHeight = Int(CGFloat(videoWidth) / scale)
                    let y = abs((baseHeight - videoHeight) / 2)
                    ciImage = ciImage.cropped(
                        to: .init(x: 0, y: y, width: videoWidth, height: videoHeight)
                    ).transformed(by: .init(translationX: 0, y: -CGFloat(y)))
                    hasCrop = true
                case .zero, .init(width: 9, height: 16):
                    break
                default:
                    videoWidth = Int(CGFloat(videoHeight) / ratioSize.width * ratioSize.height)
                    let x = abs((baseWidth - videoWidth) / 2)
                    ciImage = ciImage.cropped(
                        to: .init(x: x, y: 0, width: videoWidth, height: videoHeight)
                    ).transformed(by: .init(translationX: -CGFloat(x), y: 0))
                    hasCrop = true
                }
                if hasCrop {
                    if let newPixelBuffer = PhotoTools.createPixelBuffer(.init(width: videoWidth, height: videoHeight)) {
                        context.render(ciImage, to: newPixelBuffer)
                        pixelBuffer = newPixelBuffer
                    }
                }
            }
            if assetWriterVideoInput.append(pixelBuffer, withPresentationTime: sampleTime) {
                if !didWriterVideoInput {
                    writerVideoInputTime = sampleTime
                    didWriterVideoInput = true
                }
            }
        }
    }
    
    func setupWriter(_ sampleBuffer: CMSampleBuffer) -> Bool {
        let assetWriter: AVAssetWriter
        do {
            assetWriter = try AVAssetWriter(
                url: PhotoTools.getVideoTmpURL(),
                fileType: .mp4
            )
        } catch {
            return false
        }
        var videoWidth: Int
        var videoHeight: Int
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            videoWidth = CVPixelBufferGetWidth(pixelBuffer)
            videoHeight = CVPixelBufferGetHeight(pixelBuffer)
        }else {
            videoWidth = Int(config.sessionPreset.size.height)
            videoHeight = Int(config.sessionPreset.size.width)
        }
        if !UIDevice.isPad {
            let ratioSize = config.aspectRatio.size
            switch ratioSize {
            case .init(width: -1, height: -1):
                let scale = UIScreen.main.bounds.height / UIScreen.main.bounds.width
                videoHeight = Int(CGFloat(videoWidth) / scale)
            case .zero, .init(width: 9, height: 16):
                break
            default:
                videoWidth = Int(CGFloat(videoHeight) / ratioSize.width * ratioSize.height)
            }
        }
//        var bitsPerPixel: Float
//        let numPixels = videoWidth * videoHeight
//        var bitsPerSecond: Int
//        if numPixels < 640 * 480 {
//            bitsPerPixel = 4.05
//        } else {
//            bitsPerPixel = 10.1
//        }
//
//        bitsPerSecond = Int(Float(numPixels) * bitsPerPixel)
//
//        let compressionProperties = [
//            AVVideoAverageBitRateKey: bitsPerSecond,
//            AVVideoExpectedSourceFrameRateKey: 30,
//            AVVideoMaxKeyFrameIntervalKey: 30
//        ]
        let videoCodecType: Any
        let videoH264Type: Any
        if #available(iOS 11.0, *) {
            videoH264Type = AVVideoCodecType.h264
        } else {
            videoH264Type = AVVideoCodecH264
        }
        if UIDevice.belowIphone7 {
            videoCodecType = videoH264Type
        }else {
            if #available(iOS 11.0, *) {
                videoCodecType = config.videoCodecType
            } else {
                videoCodecType = AVVideoCodecH264
            }
        }
        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: videoCodecType,
                AVVideoWidthKey: videoWidth,
                AVVideoHeightKey: videoHeight
            ]
        )
        videoInput.expectsMediaDataInRealTime = true
        
        var isFront: Bool = false
        if let position = activeCamera?.position, position == .front {
            isFront = true
            videoInput.transform = videoInput.transform.scaledBy(x: -1, y: 1)
        }
        
        if isDevicePortrait {
            if currentOrienation == .landscapeRight {
                if config.cameraType == .metal {
                    if !isFront {
                        videoInput.transform = videoInput.transform.rotated(by: .pi * -0.5)
                    }else {
                        videoInput.transform = videoInput.transform.rotated(by: .pi * 0.5)
                    }
                }else {
                    if isFront {
                        videoInput.transform = videoInput.transform.rotated(by: .pi)
                    }
                }
            }else if currentOrienation == .landscapeLeft {
                if config.cameraType == .metal {
                    if !isFront {
                        videoInput.transform = videoInput.transform.rotated(by: .pi * 0.5)
                    }else {
                        videoInput.transform = videoInput.transform.rotated(by: -.pi * 0.5)
                    }
                }else {
                    if !isFront {
                        videoInput.transform = videoInput.transform.rotated(by: .pi)
                    }
                }
            }else {
                if config.cameraType == .normal {
                    videoInput.transform = videoInput.transform.rotated(by: .pi * 0.5)
                }
            }
        }else {
            if currentOrienation == .landscapeRight {
                if config.cameraType == .normal {
                    if isFront {
                        videoInput.transform = videoInput.transform.rotated(by: .pi)
                    }
                }
            }else if currentOrienation == .landscapeLeft {
                if config.cameraType == .normal {
                    if !isFront {
                        videoInput.transform = videoInput.transform.rotated(by: .pi)
                    }
                }
            }
        }
        
        let audioInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000
            ]
        )
        audioInput.expectsMediaDataInRealTime = true
        if !assetWriter.canAdd(videoInput) ||
            !assetWriter.canAdd(audioInput) {
            return false
        }
        let inputPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: videoWidth,
                kCVPixelBufferHeightKey as String: videoHeight
            ]
        )
        assetWriter.add(videoInput)
        assetWriter.add(audioInput)
        self.assetWriter = assetWriter
        assetWriterVideoInput = inputPixelBufferInput
        assetWriterAudioInput = audioInput
        return true
    }
    
    func resetFilter() {
        if config.cameraType == .metal {
            videoFilter.reset()
            photoFilter.reset()
        }
    }
}

extension CameraManager {
    
    func startRecording(
        didStart: @escaping (TimeInterval) -> Void,
        progress: @escaping (Float, TimeInterval) -> Void,
        completion: @escaping (URL?, Error?) -> Void
    ) {
        if isRecording {
            completion(nil, NSError(domain: "is recording", code: 500, userInfo: nil))
            return
        }
        videoDidStartRecording = didStart
        videoRecordingProgress = progress
        videoCompletion = completion
        if let isSmoothAuto = activeCamera?.isSmoothAutoFocusSupported,
           isSmoothAuto {
            try? activeCamera?.lockForConfiguration()
            activeCamera?.isSmoothAutoFocusEnabled = true
            activeCamera?.unlockForConfiguration()
        }
        if let connection = photoOutput.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }
        isDevicePortrait = UIDevice.isPortrait
        recordDuration = 0
        captureState = .start
        isRecording = true
    }
    
    func didStartRecording() {
        videoDidStartRecording?(config.videoMaximumDuration)
        let timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true,
            block: { [weak self] _ in
                guard let self = self else { return }
                let timeElapsed = Date().timeIntervalSince(self.dateVideoStarted)
                let progress = Float(timeElapsed) / Float(max(1, self.config.videoMaximumDuration))
                self.recordDuration = timeElapsed
                if self.config.takePhotoMode == .press ||
                    (self.config.takePhotoMode == .click && self.config.videoMaximumDuration > 0) {
                    if timeElapsed >= self.config.videoMaximumDuration {
                        self.stopRecording()
                    }
                }
                DispatchQueue.main.async {
                    self.videoRecordingProgress?(progress, timeElapsed)
                }
            }
        )
        dateVideoStarted = Date()
        self.timer = timer
    }
    
    func stopRecording() {
        captureState = .end
    }
    
    func didFinishRecording(_ videoURL: URL) {
        invalidateTimer()
        if recordDuration < config.videoMinimumDuration {
            try? FileManager.default.removeItem(at: videoURL)
            videoCompletion?(
                nil,
                NSError(
                    domain: "Recording time is too short",
                    code: 110,
                    userInfo: nil
                )
            )
            return
        }
        videoCompletion?(videoURL, nil)
        isRecording = false
    }
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    func resetAssetWriter() {
        didStartWriter = false
        didWriterVideoInput = false
        writerVideoInputTime = nil
        videoInpuCompletion = false
        audioInpuCompletion = false
        assetWriterVideoInput = nil
        assetWriterAudioInput = nil
        assetWriter = nil
        invalidateTimer()
        isRecording = false
        captureState = .end
    }
}
#endif
