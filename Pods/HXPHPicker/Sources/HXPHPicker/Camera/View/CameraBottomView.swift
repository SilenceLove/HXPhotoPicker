//
//  CameraBottomView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit

protocol CameraBottomViewDelegate: AnyObject {
    func bottomView(beganTakePictures bottomView: CameraBottomView)
    func bottomView(beganRecording bottomView: CameraBottomView)
    func bottomView(endRecording bottomView: CameraBottomView)
    func bottomView(longPressDidBegan bottomView: CameraBottomView)
    func bottomView(_ bottomView: CameraBottomView, longPressDidChanged scale: CGFloat)
    func bottomView(longPressDidEnded bottomView: CameraBottomView)
    func bottomView(didBackButton bottomView: CameraBottomView)
}

class CameraBottomView: UIView {
    weak var delegate: CameraBottomViewDelegate?
    lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage("hx_camera_down_back".image, for: .normal)
        button.addTarget(self, action: #selector(didBackButtonClick), for: .touchUpInside)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.imageView?.tintColor = .white
        return button
    }()
    lazy var maskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(false)
        return layer
    }()
    lazy var takeMaskLayer: CAShapeLayer = {
        let takeLayer = CAShapeLayer()
        takeLayer.contentsScale = UIScreen.main.scale
        takeLayer.fillColor = UIColor.clear.cgColor
        takeLayer.lineWidth = 5
        takeLayer.strokeColor = color.cgColor
        takeLayer.isHidden = true
        return takeLayer
    }()
    lazy var takeBgView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .extraLight)
        let view = UIVisualEffectView(effect: effect)
        view.size = CGSize(width: 80, height: 80)
        view.layer.cornerRadius = view.width * 0.5
        view.layer.masksToBounds = true
        view.layer.addSublayer(takeMaskLayer)
        return view
    }()
    lazy var takeView: UIView = {
        let view = UIView()
        view.size = CGSize(width: 60, height: 60)
        view.backgroundColor = .white
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = view.width * 0.5
        view.layer.masksToBounds = true
        return view
    }()
    lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(tapGestureRecognizerClick(tap:))
        )
        tapGesture.isEnabled = false
        return tapGesture
    }()
    lazy var longPress: UILongPressGestureRecognizer = {
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(longPressGestureRecognizerClick(longPress:))
        )
        longPress.isEnabled = false
        return longPress
    }()
    lazy var tipLb: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.mediumPingFang(ofSize: 14)
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.shadowColor = UIColor.black.withAlphaComponent(0.6)
        label.shadowOffset = CGSize(width: 0, height: 1)
        return label
    }()
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
    init(tintColor: UIColor) {
        self.color = tintColor
        super.init(frame: .zero)
        layer.addSublayer(maskLayer)
        addSubview(backButton)
        addSubview(takeBgView)
        addSubview(takeView)
        addSubview(tipLb)
        setTakeMaskLayerPath()
    }
    
    @objc
    func didBackButtonClick() {
        delegate?.bottomView(didBackButton: self)
    }
    
    func addGesture(for type: CameraController.CaptureType) {
        switch type {
        case .photo:
            takeBgView.addGestureRecognizer(tapGesture)
            tipLb.text = "轻触拍照".localized
        case .video:
            takeBgView.addGestureRecognizer(longPress)
            tipLb.text = "按住摄像".localized
        case .all:
            takeBgView.addGestureRecognizer(tapGesture)
            takeBgView.addGestureRecognizer(longPress)
            tipLb.text = "轻触拍照，按住摄像".localized
        }
    }
    
    @objc
    func tapGestureRecognizerClick(tap: UITapGestureRecognizer) {
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
    
    func stopRecord() {
        tapGesture.isEnabled = true
        takeMaskLayer.removeAllAnimations()
        takeMaskLayer.isHidden = true
        if !isRecording { return }
        isRecording = false
        delegate?.bottomView(endRecording: self)
        UIView.animate(withDuration: 0.25) {
            self.takeBgView.transform = .identity
            self.takeView.transform = .identity
        }
    }
    
    func startTakeMaskLayerPath(duration: TimeInterval) {
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
    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = CGRect(x: 0, y: -20, width: width, height: height + 20)
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
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
