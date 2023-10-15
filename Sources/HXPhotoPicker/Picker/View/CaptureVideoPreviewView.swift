//
//  CaptureVideoPreviewView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/5.
//

import UIKit
import AVFoundation

#if !targetEnvironment(macCatalyst)
class CaptureVideoPreviewView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    var sessionCompletion = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var imageMaskView: UIImageView!
    private var shadeView: UIVisualEffectView!
    private var videoOutput: AVCaptureVideoDataOutput!
    private let isCell: Bool
    private var canAddOutput = false
    
    init(isCell: Bool = false) {
        self.isCell = isCell
        super.init(frame: .zero)
        initViews()
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer?.videoGravity = .resizeAspectFill
        addSubview(imageMaskView)
        addSubview(shadeView)
    }
    private func initViews() {
        imageMaskView = UIImageView(image: PhotoManager.shared.cameraPreviewImage)
        imageMaskView.contentMode = .scaleAspectFill
        imageMaskView.clipsToBounds = true
        
        let effect = UIBlurEffect(style: .light)
        shadeView = UIVisualEffectView(effect: effect)
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "com.HXPhotoPicker.cellcamerapreview")
        )
        videoOutput.alwaysDiscardsLateVideoFrames = true
    }
    func startSession(completion: ((Bool) -> Void)? = nil) {
        if sessionCompletion {
            return
        }
        sessionCompletion = true
        DispatchQueue.global().async {
            let session = AVCaptureSession()
            if let videoDevice = AVCaptureDevice.default(for: .video),
               let videoInput = try? AVCaptureDeviceInput(device: videoDevice) {
                session.beginConfiguration()
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                }
                if self.isCell {
                    if session.canSetSessionPreset(AVCaptureSession.Preset.low) {
                        session.sessionPreset = .low
                    }
                    if session.canAddOutput(self.videoOutput) && !self.canAddOutput {
                        self.canAddOutput = true
                        session.addOutput(self.videoOutput)
                    }
                }else {
                    if session.canSetSessionPreset(AVCaptureSession.Preset.medium) {
                        session.sessionPreset = .medium
                    }
                }
                session.commitConfiguration()
                session.startRunning()
                self.previewLayer?.session = session
                self.startSessionCompletion(true, completion: completion)
            }else {
                self.startSessionCompletion(false, completion: completion)
            }
        }
    }
    func startSessionCompletion(_ isSuccess: Bool, completion: ((Bool) -> Void)?) {
        DispatchQueue.main.async {
            if isSuccess {
                UIView.animate(withDuration: 0.35) {
                    self.shadeView.effect = nil
                    self.shadeView.viewWithTag(1)?.alpha = 0
                    self.imageMaskView.alpha = 0
                } completion: { _ in
                    self.imageMaskView.removeFromSuperview()
                    self.shadeView.removeFromSuperview()
                }
            }else {
                self.imageMaskView.removeFromSuperview()
                self.shadeView.removeFromSuperview()
            }
            completion?(isSuccess)
        }
    }
    func stopSession() {
        if !sessionCompletion {
            return
        }
        let effect = UIBlurEffect(style: .light)
        shadeView.effect = effect
        shadeView.viewWithTag(1)?.alpha = 1
        imageMaskView.alpha = 1
        addSubview(imageMaskView)
        addSubview(shadeView)
        
        sessionCompletion = false
        DispatchQueue.global().async {
            self.previewLayer?.session?.stopRunning()
        }
    }
    func removeSampleBufferDelegate() {
        if isCell && canAddOutput {
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
            canAddOutput = false
        }
    }
    func removeMask() {
        imageMaskView.removeFromSuperview()
        shadeView.removeFromSuperview()
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if isCell && canAddOutput {
            if let image = PhotoTools.createImage(
                from: sampleBuffer
            )?.rotation(to: .right) {
                PhotoManager.shared.cameraPreviewImage = image
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageMaskView.frame = bounds
        shadeView.frame = bounds
        
        if let connection = previewLayer?.connection {
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
            connection.videoOrientation = videoOrientation
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
