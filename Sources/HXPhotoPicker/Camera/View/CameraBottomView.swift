//
//  CameraBottomView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit

#if !targetEnvironment(macCatalyst)
protocol CameraBottomViewDelegate: AnyObject {
    func bottomView(beganTakePictures bottomView: CameraBottomView)
    func bottomView(beganRecording bottomView: CameraBottomView)
    func bottomView(endRecording bottomView: CameraBottomView)
    func bottomView(longPressDidBegan bottomView: CameraBottomView)
    func bottomView(_ bottomView: CameraBottomView, longPressDidChanged scale: CGFloat)
    func bottomView(longPressDidEnded bottomView: CameraBottomView)
    func bottomView(didBackButton bottomView: CameraBottomView)
    func bottomView(_ bottomView: CameraBottomView, didChangeTakeType takeType: CameraBottomViewTakeType)
}

class CameraBottomView: UIView {
    weak var delegate: CameraBottomViewDelegate?
    private var backButton: UIButton!
    private var maskLayer: CAGradientLayer!
    private var takeMaskLayer: CAShapeLayer!
    private var takeBgView: UIVisualEffectView!
    private var takeView: UIView!
    private var tapGesture: UITapGestureRecognizer!
    private var longPress: UILongPressGestureRecognizer!
    private var tipLb: UILabel!
    private var typeView: UIView!
    private var photoButton: UIButton!
    private var videoButton: UIButton!
    private var videoTimeLb: UILabel!
    
    var isGestureEnable: Bool = false {
        didSet {
            tapGesture.isEnabled = isGestureEnable
            longPress.isEnabled = isGestureEnable
        }
    }
    var isTaking: Bool = false
    var isRecording: Bool = false
    var longPressBeganPoint: CGPoint = .zero
    let color: UIColor
    let takePhotoMode: CameraConfiguration.TakePhotoMode
    var captureType: CameraController.CaptureType?
    var takeType: CameraBottomViewTakeType = .photo
    
    init(
        tintColor: UIColor,
        takePhotoMode: CameraConfiguration.TakePhotoMode
    ) {
        self.color = tintColor
        self.takePhotoMode = takePhotoMode
        super.init(frame: .zero)
        initViews()
        setTakeMaskLayerPath()
    }
    
    private func initViews() {
        maskLayer = PhotoTools.getGradientShadowLayer(false)
        layer.addSublayer(maskLayer)
        
        backButton = UIButton(type: .system)
        backButton.setImage(.imageResource.camera.back.image, for: .normal)
        backButton.addTarget(self, action: #selector(didBackButtonClick), for: .touchUpInside)
        backButton.size = backButton.currentImage?.size ?? .zero
        backButton.tintColor = .white
        backButton.imageView?.tintColor = .white
        addSubview(backButton)
        
        takeMaskLayer = CAShapeLayer()
        takeMaskLayer.contentsScale = UIScreen._scale
        takeMaskLayer.fillColor = UIColor.clear.cgColor
        takeMaskLayer.lineWidth = 5
        takeMaskLayer.strokeColor = color.cgColor
        takeMaskLayer.isHidden = true
        
        takeBgView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        takeBgView.size = CGSize(width: 80, height: 80)
        takeBgView.layer.cornerRadius = takeBgView.width * 0.5
        takeBgView.layer.masksToBounds = true
        takeBgView.layer.addSublayer(takeMaskLayer)
        addSubview(takeBgView)
        
        takeView = UIView()
        takeView.size = CGSize(width: 60, height: 60)
        takeView.backgroundColor = .white
        takeView.isUserInteractionEnabled = false
        takeView.layer.cornerRadius = takeView.width * 0.5
        takeView.layer.masksToBounds = true
        addSubview(takeView)
        
        tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(tapGestureRecognizerClick(tap:))
        )
        tapGesture.isEnabled = false
        
        longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(longPressGestureRecognizerClick(longPress:))
        )
        longPress.isEnabled = false
        
        tipLb = UILabel()
        tipLb.textColor = .white
        tipLb.textAlignment = .center
        tipLb.font = .mediumPingFang(ofSize: 14)
        tipLb.numberOfLines = 0
        tipLb.adjustsFontSizeToFitWidth = true
        tipLb.shadowColor = .black.withAlphaComponent(0.6)
        tipLb.shadowOffset = CGSize(width: 0, height: 1)
        addSubview(tipLb)
        
        if takePhotoMode == .click {
            typeView = UIView()
            typeView.backgroundColor = .clear
            addSubview(typeView)
        }
        
        photoButton = UIButton(type: .custom)
        photoButton.setTitle(.textManager.camera.capturePhotoTitle.text, for: .normal)
        photoButton.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
        photoButton.setTitleColor(.white, for: .selected)
        photoButton.titleLabel?.font = .systemFont(ofSize: 15)
        photoButton.addTarget(self, action: #selector(didPhotoButtonClick), for: .touchUpInside)
        
        videoButton = UIButton(type: .custom)
        videoButton.setTitle(.textManager.camera.captureVideoTitle.text.localized, for: .normal)
        videoButton.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
        videoButton.setTitleColor(.white, for: .selected)
        videoButton.titleLabel?.font = .systemFont(ofSize: 15)
        videoButton.addTarget(self, action: #selector(didVideoButtonClick), for: .touchUpInside)
        
        videoTimeLb = UILabel()
        videoTimeLb.alpha = 0
        videoTimeLb.text = "00:00"
        videoTimeLb.textColor = .white
        videoTimeLb.textAlignment = .center
        videoTimeLb.font = .mediumPingFang(ofSize: 16)
        videoTimeLb.numberOfLines = 0
        videoTimeLb.shadowColor = .black.withAlphaComponent(0.4)
        videoTimeLb.shadowOffset = CGSize(width: 0, height: 1)
        videoTimeLb.isUserInteractionEnabled = false
    }
    
    func stopRecord() {
        tapGesture.isEnabled = true
        if takePhotoMode == .press {
            takeMaskLayer.removeAllAnimations()
            takeMaskLayer.isHidden = true
        }else {
            UIView.animate(withDuration: 0.2) {
                self.videoTimeLb.alpha = 0
                self.typeView.alpha = 1
            } completion: { _ in
                self.videoTimeLb.text = "00:00"
            }
        }
        if !isRecording { return }
        isRecording = false
        delegate?.bottomView(endRecording: self)
        UIView.animate(withDuration: 0.25) {
            self.takeBgView.transform = .identity
            self.takeView.transform = .identity
            self.takeView.backgroundColor = .white
        }
    }
    func updateVideoTime(_ time: TimeInterval) {
        if takePhotoMode == .click {
            videoTimeLb.text = PhotoTools.transformVideoDurationToString(duration: time)
        }
    }
    func startTakeMaskLayerPath(duration: TimeInterval) {
        if takePhotoMode == .click {
            UIView.animate(withDuration: 0.2) {
                self.typeView.alpha = 0
                self.videoTimeLb.alpha = 1
            }
            return
        }
        if !isRecording { return }
        takeMaskLayer.isHidden = false
        let maskAnimation = PhotoTools.getBasicAnimation(
            "strokeEnd",
            0,
            1,
            duration
        )
        maskAnimation.isRemovedOnCompletion = false
//        maskAnimation.delegate = self
        takeMaskLayer.add(maskAnimation, forKey: "takeMaskLayer")
    }
    func setTakeMaskLayerPath() {
        let path = UIBezierPath(
            arcCenter: CGPoint(
                x: takeBgView.width * 0.5,
                y: takeBgView.height * 0.5
            ),
            radius: takeBgView.width * 0.5 - 2.5,
            startAngle: -CGFloat.pi * 0.5,
            endAngle: CGFloat.pi * 1.5,
            clockwise: true
        )
        takeMaskLayer.path = path.cgPath
    }
    func hiddenTip() {
        UIView.animate(withDuration: 0.25, delay: 1.5) {
            self.tipLb.alpha = 0
        }
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if takePhotoMode == .click && typeView.frame.contains(point) {
            return true
        }
        return super.point(inside: point, with: event)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let zqmargin: CGFloat = -10
        let clickArea = backButton.frame.insetBy(dx: zqmargin, dy: zqmargin)
        if clickArea.contains(point) && backButton.isUserInteractionEnabled {
            return backButton
        }
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = CGRect(x: 0, y: -20, width: width, height: height + UIDevice.bottomMargin + 20)
        backButton.x = width * 0.5 - 120
        backButton.centerY = height * 0.5
        takeBgView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        takeView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        tipLb.frame = CGRect(
            x: UIDevice.leftMargin + 15,
            y: takeBgView.y - 40,
            width: width - UIDevice.leftMargin - UIDevice.rightMargin - 30,
            height: 30
        )
        if takePhotoMode == .click {
            guard let captureType = captureType else {
                return
            }
            typeView.frame = CGRect(
                x: UIDevice.leftMargin + 15,
                y: takeBgView.y - 40,
                width: width - UIDevice.leftMargin - UIDevice.rightMargin - 30,
                height: 30
            )
            switch captureType {
            case .photo:
                photoButton.frame = typeView.bounds
            case .video:
                videoButton.frame = typeView.bounds
                videoTimeLb.frame = typeView.frame
                maskLayer.frame = CGRect(x: 0, y: -30, width: width, height: height + 30)
            case .all:
                maskLayer.frame = CGRect(x: 0, y: -40, width: width, height: height + 40)
                photoButton.frame = .init(x: typeView.width * 0.5 - 110, y: 0, width: 100, height: typeView.height)
                videoButton.frame = .init(x: typeView.width * 0.5 + 10, y: 0, width: 100, height: typeView.height)
                videoTimeLb.frame = typeView.frame
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CameraBottomView {
    
    @objc
    func didPhotoButtonClick() {
        if isTaking || isRecording {
            return
        }
        photoButton.isSelected = true
        videoButton.isSelected = false
        takeType = .photo
        delegate?.bottomView(self, didChangeTakeType: takeType)
    }
    
    @objc
    func didVideoButtonClick() {
        if isTaking || isRecording {
            return
        }
        videoButton.isSelected = true
        photoButton.isSelected = false
        takeType = .video
        delegate?.bottomView(self, didChangeTakeType: takeType)
    }
    
    @objc
    func didBackButtonClick() {
        delegate?.bottomView(didBackButton: self)
    }
    
    func addGesture(for type: CameraController.CaptureType) {
        captureType = type
        switch type {
        case .photo:
            takeBgView.addGestureRecognizer(tapGesture)
            tipLb.text = .textManager.camera.capturePhotoTipTitle.text
            if takePhotoMode == .click {
                photoButton.isSelected = true
                takeType = .photo
            }
        case .video:
            if takePhotoMode == .press {
                takeBgView.addGestureRecognizer(longPress)
                tipLb.text = .textManager.camera.captureVideoTipTitle.text
            }else {
                takeMaskLayer.lineWidth = 10
                takeMaskLayer.strokeEnd = 1
                takeMaskLayer.isHidden = false
                takeBgView.layer.mask = takeMaskLayer
                takeBgView.addGestureRecognizer(tapGesture)
                videoButton.isSelected = true
                tipLb.text = .textManager.camera.captureVideoClickTipTitle.text
                addSubview(videoTimeLb)
                takeType = .video
            }
        case .all:
            takeBgView.addGestureRecognizer(tapGesture)
            if takePhotoMode == .press {
                takeBgView.addGestureRecognizer(longPress)
                tipLb.text = .textManager.camera.captureTipTitle.text
            }else {
                takeMaskLayer.lineWidth = 10
                takeMaskLayer.strokeEnd = 1
                takeMaskLayer.isHidden = false
                takeBgView.layer.mask = takeMaskLayer
                typeView.addSubview(photoButton)
                typeView.addSubview(videoButton)
                photoButton.contentHorizontalAlignment = .right
                videoButton.contentHorizontalAlignment = .left
                addSubview(videoTimeLb)
                layoutSubviews()
                didPhotoButtonClick()
            }
        }
    }
    
    @objc
    func tapGestureRecognizerClick(tap: UITapGestureRecognizer) {
        if takePhotoMode == .click {
            if photoButton.isSelected {
                if isTaking {
                    return
                }
                isTaking = true
                backButton.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.15) {
                    self.takeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                } completion: { _ in
                    self.delegate?.bottomView(beganTakePictures: self)
                    UIView.animate(withDuration: 0.15) {
                        self.takeView.transform = .identity
                    } completion: { _ in
                        self.isTaking = false
                        self.backButton.isUserInteractionEnabled = true
                    }
                }
                return
            }
            if videoButton.isSelected {
                if isRecording {
                    delegate?.bottomView(longPressDidEnded: self)
                    backButton.isUserInteractionEnabled = true
                    stopRecord()
                    return
                }
                isRecording = true
                backButton.isUserInteractionEnabled = false
                delegate?.bottomView(longPressDidBegan: self)
                UIView.animate(withDuration: 0.25) {
                    self.takeView.backgroundColor = self.color
                    self.takeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                } completion: { _ in
                    if self.isRecording {
                        self.delegate?.bottomView(beganRecording: self)
                    }
                }
            }
            return
        }
        if isTaking || isRecording {
            return
        }
        longPress.isEnabled = false
        isTaking = true
        backButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.15) {
            self.takeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        } completion: { _ in
            self.delegate?.bottomView(beganTakePictures: self)
            UIView.animate(withDuration: 0.15) {
                self.takeView.transform = .identity
            } completion: { _ in
                self.isTaking = false
                self.backButton.isUserInteractionEnabled = true
                self.longPress.isEnabled = true
            }
        }
    }
    
    @objc
    func longPressGestureRecognizerClick(longPress: UILongPressGestureRecognizer) {
        switch longPress.state {
        case .began:
            if isRecording || isTaking {
                return
            }
            longPressBeganPoint = longPress.location(in: self)
            tapGesture.isEnabled = false
            isRecording = true
            backButton.isUserInteractionEnabled = false
            delegate?.bottomView(longPressDidBegan: self)
            UIView.animate(withDuration: 0.25) {
                self.takeBgView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.takeView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            } completion: { _ in
                if self.isRecording {
                    self.delegate?.bottomView(beganRecording: self)
                }
            }
        case .changed:
            let point = longPress.location(in: self)
            let marginY = point.y + 20
            if longPressBeganPoint.y <= marginY {
                return
            }
            let max: CGFloat = 100
            let distance = min(longPressBeganPoint.y - marginY, max)
            let scale = distance / max
            delegate?.bottomView(self, longPressDidChanged: scale)
        case .ended, .cancelled, .failed:
            delegate?.bottomView(longPressDidEnded: self)
            backButton.isUserInteractionEnabled = true
            if isTaking {
                return
            }
            stopRecord()
        default:
            break
        }
    }
}

public enum CameraBottomViewTakeType {
    case photo
    case video
}
//    extension CameraBottomView: CAAnimationDelegate {
//        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
//            if anim == takeMaskLayer.animation(forKey: "takeMaskLayer") && flag {
//                delegate?.bottomView(endRecording: self)
//                stopRecord()
//            }else {
//                takeMaskLayer.removeAllAnimations()
//            }
//        }
//    }

#endif
