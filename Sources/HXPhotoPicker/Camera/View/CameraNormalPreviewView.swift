//
//  CameraNormalPreviewView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/12/16.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import AVFoundation

#if !targetEnvironment(macCatalyst)
protocol CameraNormalPreviewViewDelegate: AnyObject {
    func previewView(didPreviewing previewView: CameraNormalPreviewView)
    func previewView(_ previewView: CameraNormalPreviewView, pinchGestureScale scale: CGFloat)
    func previewView(_ previewView: CameraNormalPreviewView, tappedToFocusAt point: CGPoint)
}
class CameraNormalPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    weak var delegate: CameraNormalPreviewViewDelegate?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    var observe: NSKeyValueObservation?
    let config: CameraConfiguration
    init(config: CameraConfiguration) {
        self.config = config
        super.init(frame: .zero)
        initViews()
    }
    
    func setSession(_ session: AVCaptureSession) {
        previewLayer?.session = session
        
        if let connection = previewLayer?.connection {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                if config.position == .back {
                    connection.isVideoMirrored = false
                }else {
                    connection.isVideoMirrored = true
                }
            }
        }
    }
    
    private var imageMaskView: UIImageView!
    private var shadeView: UIVisualEffectView!
    private var focusView: CameraFocusView!
    
    private var isPreviewingOvserve: NSKeyValueObservation?
    var effectiveScale: CGFloat = 1
    var beginGestureScale: CGFloat = 1
    var maxScale: CGFloat { config.videoMaxZoomScale }
    
    private func initViews() {
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer?.videoGravity = .resizeAspectFill
        
        if #available(iOS 13.0, *) {
            isPreviewingOvserve = previewLayer?.observe(\.isPreviewing, changeHandler: { [weak self] layer, value in
                guard let self = self, layer.isPreviewing else {
                    return
                }
                self.removeMask()
                self.delegate?.previewView(didPreviewing: self)
            })
            imageMaskView = UIImageView(image: PhotoManager.shared.cameraPreviewImage)
            imageMaskView.contentMode = .scaleAspectFill
            imageMaskView.clipsToBounds = true
            addSubview(imageMaskView)
            
            shadeView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            addSubview(shadeView)
        }
        
        focusView = CameraFocusView(
            size: CGSize(width: 80, height: 80),
            color: config.focusColor
        )
        focusView.layer.opacity = 0
        focusView.isUserInteractionEnabled = false
        addSubview(focusView)
    }
    
    func setupGestureRecognizer() {
        let pinch = UIPinchGestureRecognizer(
            target: self,
            action: #selector(handlePinchGesture(_:))
        )
        pinch.delegate = self
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture(_:))
        )
            
        addGestureRecognizer(pinch)
        addGestureRecognizer(tap)
    }

    @objc
    func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) {
        if pinch.state == .changed {
            let scale = beginGestureScale * pinch.scale
            effectiveScale = min(scale, maxScale)
            effectiveScale = max(effectiveScale, 1)
            delegate?.previewView(self, pinchGestureScale: effectiveScale)
        }
    }
    
    @objc
    func handleTapGesture(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: self)
        PhotoTools.focusAnimation(for: focusView, at: point)
        delegate?.previewView(self, tappedToFocusAt: captureDevicePoint(for: point))
    }
    
    func initialFocus() {
        let point = CGPoint(x: width * 0.5, y: height * 0.5)
        PhotoTools.focusAnimation(for: focusView, at: point)
        delegate?.previewView(self, tappedToFocusAt: captureDevicePoint(for: point))
    }
    
    func resetMask(_ image: UIImage?) {
        if #available(iOS 13.0, *) {
            if let image = image {
                imageMaskView.image = image
            }
            imageMaskView.alpha = 1
            addSubview(imageMaskView)
            shadeView.viewWithTag(1)?.alpha = 1
            let effect = UIBlurEffect(style: .light)
            shadeView.effect = effect
            addSubview(shadeView)
        }
    }
    
    func removeMask(_ animation: Bool = true) {
        guard #available(iOS 13.0, *) else {
            return
        }
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
    
    func resetOrientation() {
        guard let capture = previewLayer?.connection,
              capture.isVideoOrientationSupported else { return }
        let videoOrientation: AVCaptureVideoOrientation
        let interfaceOrientation = UIApplication.interfaceOrientation
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
        capture.videoOrientation = videoOrientation
    }
    
    func captureDevicePoint(for point: CGPoint) -> CGPoint {
        guard let previewLayer = previewLayer else {
            return CGPoint(x: width * 0.5, y: height * 0.5)
        }
        return previewLayer.captureDevicePointConverted(fromLayerPoint: point)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 13.0, *) {
            imageMaskView.frame = bounds
            shadeView.frame = bounds
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        isPreviewingOvserve = nil
    }
}

extension CameraNormalPreviewView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer {
            beginGestureScale = effectiveScale
        }
        return true
    }
}
#endif
