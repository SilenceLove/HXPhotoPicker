//
//  CaptureVideoPreviewView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/5.
//

import UIKit
import AVKit

class CaptureVideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
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
    lazy var videoOutput: AVCaptureVideoDataOutput = {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "com.hxphpicker.cellcamerapreview")
        )
        videoOutput.alwaysDiscardsLateVideoFrames = true
        return videoOutput
    }()
    let isCell: Bool
    var canAddOutput = false
    var sessionCompletion = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    init(isCell: Bool = false) {
        self.isCell = isCell
        super.init(frame: .zero)
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer?.videoGravity = .resizeAspectFill
        addSubview(imageMaskView)
        addSubview(shadeView)
    }
    func startSession(completion: ((Bool) -> Void)? = nil) {
        if sessionCompletion {
            return
        }
        sessionCompletion = true
        DispatchQueue.global().async {
            let session = AVCaptureSession.init()
            if let videoDevice = AVCaptureDevice.default(for: .video),
               let videoInput = try? AVCaptureDeviceInput.init(device: videoDevice) {
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
    override func layoutSubviews() {
        super.layoutSubviews()
        imageMaskView.frame = bounds
        shadeView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CaptureVideoPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
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
}
