//
//  CameraPreviewView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import AVFoundation

protocol CameraPreviewViewDelegate: AnyObject {
    func previewView(didPreviewing previewView: CameraPreviewView)
    func previewView(_ previewView: CameraPreviewView, pinchGestureScale scale: CGFloat)
    func previewView(_ previewView: CameraPreviewView, tappedToFocusAt point: CGPoint)
    func previewView(didLeftSwipe previewView: CameraPreviewView)
    func previewView(didRightSwipe previewView: CameraPreviewView)
}

class CameraPreviewView: UIView {
    weak var delegate: CameraPreviewViewDelegate?
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
    lazy var focusView: CameraFocusView = {
        let focusView = CameraFocusView(
            size: CGSize(width: 80, height: 80),
            color: config.tintColor
        )
        focusView.layer.opacity = 0
        focusView.isUserInteractionEnabled = false
        return focusView
    }()
    let config: CameraConfiguration
    var maxScale: CGFloat {
        config.videoMaxZoomScale
    }
    var effectiveScale: CGFloat = 1
    var beginGestureScale: CGFloat = 1
    var previewLayer: AVCaptureVideoPreviewLayer?
    var observe: NSKeyValueObservation?
    init(config: CameraConfiguration) {
        self.config = config
        super.init(frame: .zero)
        previewLayer = layer as? AVCaptureVideoPreviewLayer
        previewLayer?.videoGravity = .resizeAspectFill
        if #available(iOS 13.0, *) {
            let observe =  previewLayer?.observe(
                \.isPreviewing,
                changeHandler: { [weak self] previewLayer, valueObservedChange in
                    guard let self = self else { return }
                    if previewLayer.isPreviewing {
                        self.removeMask()
                        self.delegate?.previewView(didPreviewing: self)
                    }
            })
            self.observe = observe
        }
        addSubview(focusView)
        addSubview(imageMaskView)
        addSubview(shadeView)
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
            effectiveScale = max(scale, 1)
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
    
    func setSession(_ session: AVCaptureSession) {
        previewLayer?.session = session
    }
    
    func resetOrientation() {
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
        previewLayer?.connection?.videoOrientation = videoOrientation
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
    
    func captureDevicePoint(for point: CGPoint) -> CGPoint {
        guard let previewLayer = previewLayer else {
            return CGPoint(x: width * 0.5, y: height * 0.5)
        }
        return previewLayer.captureDevicePointConverted(fromLayerPoint: point)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageMaskView.frame = bounds
        shadeView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        self.observe = nil
    }
}

extension CameraPreviewView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer {
            beginGestureScale = effectiveScale
        }
        return true
    }
}

class CameraFocusView: UIView {
    lazy var rectLayer: CAShapeLayer = {
        let rectLayer = CAShapeLayer()
        rectLayer.lineWidth = 2
        rectLayer.lineJoin = .round
        rectLayer.lineCap = .round
        rectLayer.strokeColor = color.cgColor
        rectLayer.fillColor = UIColor.clear.cgColor
        rectLayer.contentsScale = UIScreen.main.scale
        let path = UIBezierPath(rect: bounds)
        rectLayer.path = path.cgPath
        return rectLayer
    }()
    
    lazy var lineLayer: CAShapeLayer = {
        let lineLayer = CAShapeLayer()
        lineLayer.lineWidth = 1
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
        lineLayer.strokeColor = color.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        let path = UIBezierPath()
        let lineLength: CGFloat = 10
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width * 0.5, y: lineLength))
        
        path.move(to: CGPoint(x: width * 0.5, y: height - lineLength))
        path.addLine(to: CGPoint(x: width * 0.5, y: height))
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        path.addLine(to: CGPoint(x: lineLength, y: height * 0.5))
        
        path.move(to: CGPoint(x: width - lineLength, y: height * 0.5))
        path.addLine(to: CGPoint(x: width, y: height * 0.5))
        
        lineLayer.path = path.cgPath
        return lineLayer
    }()
    let color: UIColor
    init(
        size: CGSize,
        color: UIColor
    ) {
        self.color = color
        super.init(frame: CGRect(origin: .zero, size: size))
        layer.addSublayer(rectLayer)
        layer.addSublayer(lineLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        rectLayer.frame = bounds
        lineLayer.frame = bounds
    }
}
